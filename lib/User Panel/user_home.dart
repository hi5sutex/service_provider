import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lottie/lottie.dart';
import 'package:service_provider/User%20Panel/subcategories_list.dart';
import 'package:service_provider/User%20Panel/user_profile.dart';
import 'package:service_provider/User%20Panel/user_setting.dart';

class UserHome extends StatefulWidget {
  // Add callback to notify parent about loading state
  final Function(bool isLoading)? onLoadingStateChanged;

  UserHome({this.onLoadingStateChanged});

  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String selectedCategory = 'All';
  String userCity = '';
  bool _isLoading = true;
  final Color primaryColor = Color(0xFF060644);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _profileImageUrl;

  Future<String> getUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return userDoc['name'] ?? 'User';
      } else {
        return 'User not logged in';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Error';
    }
  }

  Future<void> _fetchProfilePic() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          _profileImageUrl = userDoc['profileImage'] as String?;
        });
      }
    } catch (e) {
      print('Error fetching profile picture: $e');
    }
  }

  void _changeStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFF060644),
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Stream<List<Service>> getServices(String category) {
    Query query = FirebaseFirestore.instance.collection('services');
    if (category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _changeStatusBarColor();
    _fetchProfilePic();
    _initializeData();
  }

  // Update loading state and notify parent
  void _updateLoadingState(bool isLoading) {
    setState(() => _isLoading = isLoading);
    if (widget.onLoadingStateChanged != null) {
      widget.onLoadingStateChanged!(isLoading);
    }
  }

  Future<void> _initializeData() async {
    _updateLoadingState(true);
    await _getCurrentCity();
    _updateLoadingState(false);
  }

  Future<void> _getCurrentCity() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => userCity = 'Location access denied');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() => userCity = placemarks.first.locality ?? 'Unknown');
      }
    } catch (e) {
      setState(() => userCity = 'Location error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isLoading ? Colors.white : Colors.grey[50],
      // No appBar to make the loading screen fullscreen
      body: _isLoading
          ? _buildLoadingScreen()
          : SafeArea(child: _buildMainContent()),
      // Remove any bottom navigation bar or other UI elements while loading
    );
  }

  // Loading screen with Lottie animation (fullscreen)
  Widget _buildLoadingScreen() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Colors.white,
      child: Center(
        child: Lottie.asset(
          'android/assets/location.json',
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.width * 0.7,
          fit: BoxFit.contain,
          repeat: true,
          animate: true,
        ),
      ),
    );
  }

  // Main content of the page
  Widget _buildMainContent() {
    return Column(
      children: [
        // Enhanced Header Section
        Container(
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: FutureBuilder<String>(
                  future: getUserName(),
                  builder: (context, snapshot) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${snapshot.data ?? 'User'} 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: Colors.white, size: 14),
                              SizedBox(width: 3),
                              Text(
                                userCity,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: _profileImageUrl != null
                      ? CircleAvatar(
                    radius: 14,
                    backgroundImage: NetworkImage(_profileImageUrl!),
                    backgroundColor: Colors.grey.shade300,
                  )
                      : const Icon(Icons.account_circle, color: Colors.white, size: 25),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserProfile()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        Container(
          margin: EdgeInsets.fromLTRB(20, 15, 20, 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search services...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: primaryColor),
              border: InputBorder.none,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
        // Categories Section
        Container(
          margin: EdgeInsets.only(top: 0),
          height: 40,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('categories')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                    child: CircularProgressIndicator(color: primaryColor));
              }

              List<String> categories = ['All'];
              categories.addAll(snapshot.data!.docs
                  .map((doc) => doc['name'] as String)
                  .toList());

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => selectedCategory = categories[index]);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: categories[index] == selectedCategory
                              ? primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryColor,
                            width: 1,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        child: Center(
                          child: Text(
                            categories[index],
                            style: TextStyle(
                              color: categories[index] == selectedCategory
                                  ? Colors.white
                                  : primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Content Sections
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 35,
              ),
              child: Column(
                children: [
                  _buildSectionHeader('Popular Services'),
                  _buildPopularServices(),

                  _buildSectionHeader('Top Rated Providers'),
                  _buildProviders(),

                  _buildSectionHeader('All Categories'),
                  _buildCategories(),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 25, 20, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'See All',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServices() {
    return Container(
      height: 220,
      child: StreamBuilder<List<Service>>(
        stream: getServices(selectedCategory),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Service service = snapshot.data![index];
              return ServiceCard(
                title: service.title,
                price: '\$${service.price}/hr',
                imageUrl: service.imageUrl,
                category: service.category,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProviders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('providers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final provider = Provider.fromFirestore(snapshot.data!.docs[index]);
            return ProviderCard(
              name: provider.name,
              phoneNumber: provider.phoneNumber,
              profilePicUrl: provider.profilePicUrl,
            );
          },
        );
      },
    );
  }

  Widget _buildCategories() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final categories = snapshot.data!.docs
            .map((doc) => {
          'name': doc['name'] as String?,
          'imageUrl': doc['imageUrl'] as String?,
        })
            .toList();

        return GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 3 / 4,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final categoryName = category['name'] ?? 'Unknown Category';
            final imageUrl = category['imageUrl'] ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubcategoriesPage(categoryName: categoryName),
                  ),
                );
              },
              child: GridCategoryCard(
                title: categoryName,
                imagePath: imageUrl,
              ),
            );
          },
        );
      },
    );
  }
}

// Service Model and other class definitions should remain the same

// Service Model and other classes remain the same
// ... Rest of the code (all the widget classes) should remain unchanged

// Enhanced CategoryChip Widget
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;

  const CategoryChip({
    required this.label,
    this.selected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Color(0xFF060644) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? Color(0xFF060644) : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: Color(0xFF060644).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[600],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Enhanced ServiceCard Widget
class ServiceCard extends StatelessWidget {
  final String title;
  final String price;
  final String imageUrl;
  final String category;

  const ServiceCard({
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
          width: 180,
          margin: EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Expanded(
          child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      child: imageUrl.isNotEmpty
          ? Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(Icons.error, color: Colors.grey),
          );
        },
      )
          : Container(
        color: Colors.grey[200],
        child: Icon(Icons.image, color: Colors.grey),
      ),
    ),
    ),
    Padding(
    padding: EdgeInsets.all(15),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    title,
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
    ),
      SizedBox(height: 6),
      Text(
        price,
        style: TextStyle(
          color: Color(0xFF060644),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      SizedBox(height: 8),
      Row(
        children: [
          Icon(
            Icons.star,
            color: Colors.amber,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            "4.5",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      ],
    ),
    ),
              ],
          ),
      ),
    );
  }
}

// Enhanced ProviderCard Widget
class ProviderCard extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String profilePicUrl;

  const ProviderCard({
    required this.name,
    required this.phoneNumber,
    required this.profilePicUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: profilePicUrl.isNotEmpty
                    ? Image.network(
                  profilePicUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.person,
                        color: Colors.grey[400], size: 35);
                  },
                )
                    : Icon(Icons.person, color: Colors.grey[400], size: 35),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    phoneNumber,
                    style: TextStyle(
                      color: Color(0xFF060644),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "4.8",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        " (120 reviews)",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF060644).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF060644),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced GridCategoryCard Widget
class GridCategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;

  const GridCategoryCard({
    required this.title,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // Added bottom padding
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ensures it doesn't take extra space
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFFFFF),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// Service Model
class Service {
  final String id;
  final String title;
  final String category;
  final double price;
  final String imageUrl;

  Service({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.imageUrl,
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      title: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['images'] != null && (data['images'] as List).isNotEmpty
          ? data['images'][0]
          : '',
    );
  }
}

// Provider Model
class Provider {
  final String id;
  final String name;
  final String phoneNumber;
  final String profilePicUrl;

  Provider({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.profilePicUrl,
  });

  factory Provider.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Provider(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phone'] ?? '',
      profilePicUrl: data['profileImage'] ?? '',
    );
  }
}