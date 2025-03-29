import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/theme.dart'; // Import ProviderTheme

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
      // Background color is set by ProviderTheme.scaffoldBackgroundColor (#F5F7FA)
      appBar: AppBar(
        // Background color is set by ProviderTheme.appBarTheme (Primary #060644)
        title: Text(
          'Available Service Providers',
          style: TextStyle(
            color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
          ),
        ),
      ),
      body: StreamBuilder<List<Provider>>(
        stream: getServiceProviders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
              ),
            );
          }

          if (snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No providers available for this service',
                style: TextStyle(
                  color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Provider provider = snapshot.data![index];
              return Card(
                color: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: provider.profileImage.isNotEmpty
                        ? NetworkImage(provider.profileImage)
                        : null,
                    child: provider.profileImage.isEmpty
                        ? Icon(
                      Icons.person,
                      color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
                    )
                        : null,
                  ),
                  title: Text(
                    provider.name,
                    style: TextStyle(
                      color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                    ),
                  ),
                  subtitle: Text(
                    provider.address,
                    style: TextStyle(
                      color: ProviderTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                    ),
                  ),
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