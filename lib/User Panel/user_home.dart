import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/service_detail.dart';

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
      title: data['category'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['images'] != null && (data['images'] as List).isNotEmpty
          ? data['images'][0]
          : '',
    );
  }
}

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

class UserHome extends StatefulWidget {
  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String selectedCategory = 'All';

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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: FutureBuilder<String>(
            future: getUserName(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Loading...',
                    style: TextStyle(color: Colors.black));
              } else if (snapshot.hasError) {
                return Text('Error', style: TextStyle(color: Colors.red));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text(
                    'Hello, ${snapshot.data ?? 'User'}',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue, size: 16),
                      SizedBox(width: 5),
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
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Categories
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }

                List<String> categories = ['All'];
                categories.addAll(snapshot.data!.docs
                    .map((doc) => doc['name'] as String)
                    .toList());

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories
                        .map((category) => CategoryChip(
                              label: category,
                              selected: category == selectedCategory,
                              onSelected: () {
                                setState(() {
                                  selectedCategory = category;
                                });
                              },
                            ))
                        .toList(),
                  ),
                );
              },
            ),

            SizedBox(height: 20),

            // Popular Services
            Text(
              'Popular Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Services List
            Expanded(
              flex: 2,
              child: StreamBuilder<List<Service>>(
                stream: getServices(selectedCategory),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      Service service = snapshot.data![index];
                      return ServiceCard(
                        title: service.title,
                        price: '\$${service.price}/hr',
                        imageUrl: service.imageUrl,
                        category: service.category, // Pass category here
                      );
                    },
                  );
                },
              ),
            ),


            SizedBox(height: 20),

            // Top Rated Providers
            Text(
              'Top Rated Providers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Providers List
            Expanded(
              flex: 3,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('providers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      Provider provider =
                          Provider.fromFirestore(snapshot.data!.docs[index]);
                      return ProviderCard(
                        name: provider.name,
                        phoneNumber: provider.phoneNumber,
                        profilePicUrl: provider.profilePicUrl,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CategoryChip Widget
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
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onSelected,
        child: Chip(
          label: Text(label),
          backgroundColor: selected ? Colors.blue : Colors.grey[200],
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

// ServiceCard Widget
class ServiceCard extends StatelessWidget {
  final String title;
  final String price;
  final String imageUrl;
  final String category; // Add category field

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
        // Navigate to ServiceDetailsPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsPage(category: category),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.only(right: 16),
        child: Container(
          width: 150,
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error),
                      );
                    },
                  ),
                )
                    : Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.image),
                ),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                price,
                style: TextStyle(color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
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

// ProviderCard Widget
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
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
          child: profilePicUrl.isEmpty ? Icon(Icons.person) : null,
        ),
        title: Text(name),
        subtitle: Text(
          phoneNumber,
          style: TextStyle(color: Colors.blue),
        ),
      ),
    );
  }
}
