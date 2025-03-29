import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:service_provider/User%20Panel/provider_services_page.dart';
import 'package:service_provider/User%20Panel/subcategories_list.dart';
import 'package:service_provider/User%20Panel/user_profile.dart';
import 'package:service_provider/User%20Panel/user_setting.dart';
import 'package:service_provider/User%20Panel/service_details_screen.dart';
import 'package:service_provider/theme.dart';



class UserHome extends StatefulWidget {
  @override
  _UserHomeState createState() => _UserHomeState();

}

class _UserHomeState extends State<UserHome> with AutomaticKeepAliveClientMixin {

  String selectedCategory = 'All';
  String userCity = 'Loading...';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _profileImageUrl;
  final TextEditingController _searchController = TextEditingController();
  List<Service> _searchResults = [];
  bool _showSuggestions = false;
  final FocusNode _searchFocusNode = FocusNode();
  List<Service> _allServices = [];
  Timer? _searchDebounceTimer;
  bool _isLoadingServices = false;


  Future<String> getUserName() async {
    try {
      User? user = _auth.currentUser;
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
      statusBarColor: ProviderTheme.primaryColor,
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

  Future<void> _searchServices(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
      });
      return;
    }

    _searchDebounceTimer?.cancel();



    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(5)
          .get();

      setState(() {
        _searchResults = snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
        _showSuggestions = true;
      });
    } catch (e) {
      print('Error searching services: $e');
    }
  }

  Future<void> _prefetchServices() async {
    if (_allServices.isNotEmpty) return;

    try {
      setState(() => _isLoadingServices = true);
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('services')
          .limit(50) // Initial batch
          .get();

      setState(() {
        _allServices = snapshot.docs
            .map((doc) => Service.fromFirestore(doc))
            .toList();
      });

      // Load more in background
      _loadMoreServices();
    } catch (e) {
      print('Error prefetching services: $e');
    } finally {
      setState(() => _isLoadingServices = false);
    }
  }

  Future<void> _loadMoreServices() async {
    if (_allServices.isEmpty) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('services')
          .startAfterDocument(_allServices.last as DocumentSnapshot<Object?>)
          .limit(50) // Next batch
          .get();

      setState(() {
        _allServices.addAll(snapshot.docs
            .map((doc) => Service.fromFirestore(doc)));
      });
    } catch (e) {
      print('Error loading more services: $e');
    }
  }



  @override
  void initState() {
    super.initState();
    _getCurrentCity();
    _changeStatusBarColor();
    _fetchProfilePic();
    _searchController.addListener(() {
      _searchServices(_searchController.text);
    });
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });

    // Prefetch services when the app starts
    _prefetchServices();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

  // Set up new debounce timer (300ms delay)




  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: ProviderTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: ProviderTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(screenWidth * 0.05),
                  bottomRight: Radius.circular(screenWidth * 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ProviderTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.04, screenHeight * 0.015, screenWidth * 0.04, screenHeight * 0.012),
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
                                color: ProviderTheme.onPrimaryTextColor,
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.006),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.025, vertical: screenHeight * 0.005),
                              decoration: BoxDecoration(
                                color: ProviderTheme.onPrimaryTextColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: ProviderTheme.onPrimaryTextColor,
                                    size: screenWidth * 0.035,
                                  ),
                                  SizedBox(width: screenWidth * 0.008),
                                  Text(
                                    userCity,
                                    style: TextStyle(
                                      color: ProviderTheme.onPrimaryTextColor,
                                      fontSize: screenWidth * 0.032,
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
                    width: screenWidth * 0.09,
                    height: screenWidth * 0.09,
                    decoration: BoxDecoration(
                      color: ProviderTheme.onPrimaryTextColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(screenWidth * 0.012),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      icon: _profileImageUrl != null
                          ? CircleAvatar(
                        radius: screenWidth * 0.035,
                        backgroundImage: NetworkImage(_profileImageUrl!),
                        backgroundColor: ProviderTheme.dividerColor,
                      )
                          : Icon(
                        Icons.account_circle,
                        color: ProviderTheme.onPrimaryTextColor,
                        size: screenWidth * 0.06,
                      ),
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
            // In your UserHome class's build method, modify the search section:

            Container(
              margin: EdgeInsets.fromLTRB(
                  screenWidth * 0.05, screenHeight * 0.018, screenWidth * 0.05, screenHeight * 0.018),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: ProviderTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(screenWidth * 0.037),
                      boxShadow: [
                        BoxShadow(
                          color: ProviderTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 15,
                          offset: Offset(0, 6),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: TextStyle(
                        color: ProviderTheme.primaryTextColor,
                        fontSize: screenWidth * 0.04,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for services, providers...',
                        hintStyle: TextStyle(
                          color: ProviderTheme.secondaryTextColor.withOpacity(0.7),
                          fontSize: screenWidth * 0.035,
                        ),
                        prefixIcon: Container(
                          margin: EdgeInsets.only(left: screenWidth * 0.02, right: screenWidth * 0.02),
                          child: Icon(
                            Icons.search,
                            color: ProviderTheme.primaryColor,
                            size: screenWidth * 0.06,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: ProviderTheme.secondaryTextColor,
                            size: screenWidth * 0.05,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _showSuggestions = false;
                            });
                            _searchFocusNode.unfocus();
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.037),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.037),
                          borderSide: BorderSide(
                            color: ProviderTheme.primaryColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.018,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _searchResults = [];
                            _showSuggestions = false;
                          });
                        } else {
                          _searchServices(value);
                        }
                      },
                      onTap: () {
                        if (_searchController.text.isNotEmpty && _searchResults.isNotEmpty) {
                          setState(() => _showSuggestions = true);
                        }
                      },
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SizeTransition(
                        sizeFactor: animation,
                        child: child,
                      );
                    },
                    child: (_showSuggestions && _searchController.text.isNotEmpty)
                        ? Container(
                      margin: EdgeInsets.only(top: screenHeight * 0.01),
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.3,
                      ),
                      decoration: BoxDecoration(
                        color: ProviderTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(screenWidth * 0.037),
                        boxShadow: [
                          BoxShadow(
                            color: ProviderTheme.shadowColor.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isLoadingServices
                          ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          child: CircularProgressIndicator(
                            color: ProviderTheme.primaryColor,
                          ),
                        ),
                      )
                          : _searchResults.isEmpty
                          ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          child: Text(
                            'No services found',
                            style: TextStyle(
                              color: ProviderTheme.secondaryTextColor,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ),
                      )
                          : ListView.separated(
                        shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => Divider(
                          color: ProviderTheme.dividerColor.withOpacity(0.3),
                          height: 1,
                          indent: screenWidth * 0.05,
                          endIndent: screenWidth * 0.05,
                        ),
                        itemBuilder: (context, index) {
                          final service = _searchResults[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.01,
                            ),
                            leading: Container(
                              width: screenWidth * 0.12,
                              height: screenWidth * 0.12,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                image: service.imageUrl.isNotEmpty
                                    ? DecorationImage(
                                  image: NetworkImage(service.imageUrl),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                                color: service.imageUrl.isEmpty
                                    ? ProviderTheme.dividerColor
                                    : null,
                              ),
                              child: service.imageUrl.isEmpty
                                  ? Icon(
                                Icons.image,
                                color: ProviderTheme.secondaryTextColor,
                              )
                                  : null,
                            ),
                            title: Text(
                              service.title,
                              style: TextStyle(
                                color: ProviderTheme.primaryTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                            subtitle: Text(
                              service.category,
                              style: TextStyle(
                                color: ProviderTheme.secondaryTextColor,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                            trailing: Text(
                              '\$${service.price}/hr',
                              style: TextStyle(
                                color: ProviderTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                            onTap: () {
                              setState(() => _showSuggestions = false);
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ServiceDetailsScreen(
                                    serviceId: service.id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    )
                        : SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            Container(
              margin: EdgeInsets.only(top: 0),
              height: screenHeight * 0.05,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: ProviderTheme.primaryColor,
                      ),
                    );
                  }

                  List<String> categories = ['All'];
                  categories.addAll(
                      snapshot.data!.docs.map((doc) => doc['name'] as String).toList());

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: screenWidth * 0.03),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => selectedCategory = categories[index]);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: categories[index] == selectedCategory
                                  ? ProviderTheme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(screenWidth * 0.05),
                              border: Border.all(
                                color: ProviderTheme.primaryColor,
                                width: 1,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.012, horizontal: screenWidth * 0.05),
                            child: Center(
                              child: Text(
                                categories[index],
                                style: TextStyle(
                                  color: categories[index] == selectedCategory
                                      ? ProviderTheme.onPrimaryTextColor
                                      : ProviderTheme.primaryColor,
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
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + screenHeight * 0.04),

                  child: Column(
                    children: [
                      _buildSectionHeader('Popular Services'),
                      _buildPopularServices(),
                      _buildSectionHeader('Top Rated Providers'),
                      _buildProviders(),
                      _buildSectionHeader('All Categories'),
                      _buildCategories(),
                      SizedBox(height: screenHeight * 0.025),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          screenWidth * 0.05, screenHeight * 0.03, screenWidth * 0.05, screenHeight * 0.018),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: ProviderTheme.primaryColor,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'See All',
              style: TextStyle(
                color: ProviderTheme.primaryColor,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServices() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: screenHeight * 0.28,
      child: StreamBuilder<List<Service>>(
        stream: getServices(selectedCategory),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: ProviderTheme.primaryColor,
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Service service = snapshot.data![index];
              return ServiceCard(
                id: service.id, // Add this
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
    final screenWidth = MediaQuery.of(context).size.width;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('providers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: ProviderTheme.primaryColor,
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final provider = Provider.fromFirestore(snapshot.data!.docs[index]);
            return ProviderCard(
              id: provider.id, // Add this
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: ProviderTheme.primaryColor,
            ),
          );
        }

        final categories = snapshot.data!.docs
            .map((doc) => {
          'name': doc['name'] as String?,
          'imageUrl': doc['imageUrl'] as String?,
        })
            .toList();

        return GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: screenWidth * 0.04,
            mainAxisSpacing: screenHeight * 0.02,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.012),
        decoration: BoxDecoration(
          color: selected
              ? ProviderTheme.primaryColor
              : ProviderTheme.surfaceColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.06),
          border: Border.all(
            color: selected
                ? ProviderTheme.primaryColor
                : ProviderTheme.dividerColor,
            width: 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: ProviderTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? ProviderTheme.onPrimaryTextColor
                : ProviderTheme.secondaryTextColor,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: screenWidth * 0.035,
          ),
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String id; // Add this
  final String title;
  final String price;
  final String imageUrl;
  final String category;

  const ServiceCard({
    required this.id, //
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(serviceId: id),
          ),
        );
      },
      child: Container(
        width: screenWidth * 0.45,
        margin: EdgeInsets.only(right: screenWidth * 0.04),
        decoration: BoxDecoration(
          color: ProviderTheme.surfaceColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.037),
          boxShadow: [
            BoxShadow(
              color: ProviderTheme.shadowColor,
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.037)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: ProviderTheme.dividerColor,
                      child: Icon(
                        Icons.error,
                        color: ProviderTheme.disabledTextColor,
                      ),
                    );
                  },
                )
                    : Container(
                  color: ProviderTheme.dividerColor,
                  child: Icon(
                    Icons.image,
                    color: ProviderTheme.disabledTextColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.037),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                      color: ProviderTheme.primaryTextColor,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.015),
                  Text(
                    price,
                    style: TextStyle(
                      color: ProviderTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.037,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: ProviderTheme.warningColor,
                        size: screenWidth * 0.04,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        "4.5",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: ProviderTheme.secondaryTextColor,
                          fontSize: screenWidth * 0.035,
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

class ProviderCard extends StatelessWidget {
  final String id;
  final String name;
  final String phoneNumber;
  final String profilePicUrl;

  const ProviderCard({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.profilePicUrl,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        _navigateToProviderServices(context);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth * 0.04),
        decoration: BoxDecoration(
          color: ProviderTheme.surfaceColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.037),
          boxShadow: [
            BoxShadow(
              color: ProviderTheme.shadowColor,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.03),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.18,
                height: screenWidth * 0.18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  color: ProviderTheme.dividerColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  child: profilePicUrl.isNotEmpty
                      ? Image.network(
                    profilePicUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        color: ProviderTheme.secondaryTextColor,
                        size: screenWidth * 0.09,
                      );
                    },
                  )
                      : Icon(
                    Icons.person,
                    color: ProviderTheme.secondaryTextColor,
                    size: screenWidth * 0.09,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.04,
                        color: ProviderTheme.primaryTextColor,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        color: ProviderTheme.primaryColor,
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.015),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: ProviderTheme.warningColor,
                          size: screenWidth * 0.04,
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          "4.8",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.032,
                            color: ProviderTheme.primaryTextColor,
                          ),
                        ),
                        Text(
                          " (120 reviews)",
                          style: TextStyle(
                            color: ProviderTheme.secondaryTextColor,
                            fontSize: screenWidth * 0.032,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: ProviderTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    size: screenWidth * 0.04,
                    color: ProviderTheme.primaryColor,
                  ),
                  onPressed: () {
                    _navigateToProviderServices(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProviderServices(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderServicesPage(providerId: id),
      ),
    );
  }
}

class GridCategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;

  const GridCategoryCard({
    required this.title,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
        ),
        color: ProviderTheme.surfaceColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.025)),
                child: Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: ProviderTheme.onPrimaryTextColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.02),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                  color: ProviderTheme.primaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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