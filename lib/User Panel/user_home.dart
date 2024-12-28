import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/service_list.dart';

class UserHome extends StatefulWidget {
  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String selectedCategory = 'All';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // User Info and Settings
                  Container(
                    padding: EdgeInsets.all(16),
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
                                    'Hello, ${snapshot.data ?? 'User'}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, color: Colors.blue, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Surat',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.settings),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  // Search Bar
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search services...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                  // Category Chips
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('categories')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        List<String> categories = ['All'];
                        categories.addAll(snapshot.data!.docs
                            .map((doc) => doc['name'] as String)
                            .toList());

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories
                                .map((category) => Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: CategoryChip(
                                label: category,
                                selected: category == selectedCategory,
                                onSelected: () {
                                  setState(() {
                                    selectedCategory = category;
                                  });
                                },
                              ),
                            ))
                                .toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Popular Services Section
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Popular Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      height: 200,
                      child: StreamBuilder<List<Service>>(
                        stream: getServices(selectedCategory),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
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
                    ),
                    SizedBox(height: 24),

                    // Top Rated Providers Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Top Rated Providers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('providers')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        return ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final provider = Provider.fromFirestore(
                                snapshot.data!.docs[index]);
                            return ProviderCard(
                              name: provider.name,
                              phoneNumber: provider.phoneNumber,
                              profilePicUrl: provider.profilePicUrl,
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: 24),

                    // All Categories Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'All Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('categories')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final categories = snapshot.data!.docs
                            .map((doc) => doc['name'] as String)
                            .toList();

                        return GridView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
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
                            final categoryName = categories[index];
                            final imagePath = 'android/assets/${categoryName.toLowerCase()}.png';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceListPage(
                                      category: categoryName,
                                    ),
                                  ),
                                );
                              },
                              child: GridCategoryCard(  // Changed from CategoryCard to GridCategoryCard
                                title: categoryName,
                                imagePath: imagePath,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CategoryChip Widget for horizontal scrolling categories
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
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// Models
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
      title: data['title'] ?? '',
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

// Widgets
class GridCategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;

  const GridCategoryCard({
    required this.title,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceListPage(category: category),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.error, color: Colors.grey),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    price,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
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
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey.shade200,
          backgroundImage:
          profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
          child: profilePicUrl.isEmpty
              ? Icon(Icons.person, color: Colors.grey, size: 30)
              : null,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          phoneNumber,
          style: TextStyle(
            color: Colors.blue,
            fontSize: 14,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}