import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> getUserName() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') // Ensure your users collection is named 'users'
          .doc(user.uid)
          .get();

      // Extract the 'name' field
      return userDoc['name'] ?? 'User'; // Fallback to 'User' if name is not found
    } else {
      return 'User not logged in';
    }
  } catch (e) {
    print('Error fetching user name: $e');
    return 'Error';
  }
}

class UserHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0), // Increase the height here
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: FutureBuilder<String>(
            future: getUserName(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Loading...', style: TextStyle(color: Colors.black));
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
              icon: Icon(Icons.settings),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryChip(label: 'All', selected: true),
                  CategoryChip(label: 'Cleaning'),
                  CategoryChip(label: 'Plumbing'),
                  CategoryChip(label: 'Electrical'),
                  CategoryChip(label: 'Painting'),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Popular Services
            Text(
              'Popular Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              flex: 2,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ServiceCard(
                    title: 'House Cleaning',
                    rating: 4.8,
                    reviews: '2.5k',
                    price: '\$25/hr',
                  ),
                  ServiceCard(
                    title: 'Plumbing Service',
                    rating: 4.9,
                    reviews: '1.8k',
                    price: '\$40/hr',
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Top Rated Providers
            Text(
              'Top Rated Providers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: ListView(
                children: [
                  ProviderCard(
                    name: 'John Smith',
                    profession: 'Professional Cleaner',
                    rating: 4.9,
                    reviews: '523 reviews',
                  ),
                  ProviderCard(
                    name: 'Sarah Johnson',
                    profession: 'Expert Plumber',
                    rating: 4.8,
                    reviews: '428 reviews',
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

// CategoryChip Widget
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;

  const CategoryChip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        backgroundColor: selected ? Colors.blue : Colors.grey[200],
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

// ServiceCard Widget
class ServiceCard extends StatelessWidget {
  final String title;
  final double rating;
  final String reviews;
  final String price;

  const ServiceCard({
    required this.title,
    required this.rating,
    required this.reviews,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(right: 16),
      child: Container(
        width: 150,
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[300],
              ),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('⭐ $rating ($reviews)'),
            Text(price, style: TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}

// ProviderCard Widget
class ProviderCard extends StatelessWidget {
  final String name;
  final String profession;
  final double rating;
  final String reviews;

  const ProviderCard({
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(name),
        subtitle: Text(profession),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('⭐ $rating'),
            Text('($reviews)'),
          ],
        ),
      ),
    );
  }
}
