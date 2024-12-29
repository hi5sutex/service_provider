import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Provider {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String bio;
  final String address;

  Provider({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.bio,
    required this.address,
  });

  factory Provider.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Provider(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profileImage: data['profileImage'] ?? '',
      bio: data['bio'] ?? '',
      address: data['address'] ?? '',
    );
  }
}

class AvailableProvidersPage extends StatelessWidget {
  final String serviceId;

  AvailableProvidersPage({required this.serviceId});

  Stream<List<Provider>> getServiceProviders() {
    return FirebaseFirestore.instance
        .collection('providers')
        .where('servicesOffered', arrayContains: serviceId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Provider.fromFirestore(doc)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Service Providers'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<List<Provider>>(
        stream: getServiceProviders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.isEmpty) {
            return Center(
              child: Text('No providers available for this service'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Provider provider = snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: provider.profileImage.isNotEmpty
                        ? NetworkImage(provider.profileImage)
                        : null,
                    child: provider.profileImage.isEmpty
                        ? Icon(Icons.person)
                        : null,
                  ),
                  title: Text(provider.name),
                  subtitle: Text(provider.address),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Add booking or details navigation logic if needed
                    },
                    child: Text('View Details'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
