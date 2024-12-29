import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage

class ServiceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> serviceData;
  final String adminId = FirebaseAuth.instance.currentUser!.uid.toString();

  ServiceDetailsScreen({Key? key, required this.serviceData}) : super(key: key);

  Future<Map<String, dynamic>> _fetchAllDetails() async {
    // Fetch provider, user, and service details concurrently
    final serviceDoc = serviceData;
    final providerDoc = await FirebaseFirestore.instance.collection('providers').doc(serviceDoc['providerId']).get();
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(serviceDoc['userId']).get();
    final serviceImageUrl = await FirebaseStorage.instance
        .ref('service_images/${serviceData['serviceId']}.jpg') // Fetch the image URL from Firebase Storage
        .getDownloadURL();

    return {
      'service': serviceDoc as Map<String, dynamic>,
      'provider': providerDoc.data() as Map<String, dynamic>,
      'user': userDoc.data() as Map<String, dynamic>,
      'imageUrl': serviceImageUrl,
    };
  }

  Future<bool> _hasManageServicesPermission() async {
    DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admins').doc(adminId).get();
    return adminDoc['permissions']['manageServices'] ?? false; // Return bool
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchAllDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text('Error loading details.'));
            }

            final details = snapshot.data!;
            final service = details['service'];
            final provider = details['provider'];
            final user = details['user'];
            final serviceImageUrl = details['imageUrl'];

            final providerName = provider['name'] ?? 'N/A';
            final userName = user['name'] ?? 'N/A';
            final serviceName = service['name'] ?? 'N/A';
            final serviceDescription = service['description'] ?? 'N/A';

            return ListView(
              children: [
                if (serviceImageUrl.isNotEmpty)
                  Image.network(
                    serviceImageUrl,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                SizedBox(height: 16),
                Text(
                  'Service: $serviceName',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Category: ${service['category']}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Subcategory: ${service['subcategory']}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Provider: $providerName',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'User: $userName',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Status: ${service['status'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Service Date: ${DateFormat('dd/MM/yyyy').format(service['serviceDate'].toDate())}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Payment Amount: ${service['price']['minPrice']} - ${service['price']['maxPrice']}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 16),
                FutureBuilder<bool>(
                  future: _hasManageServicesPermission(),
                  builder: (context, permissionSnapshot) {
                    if (permissionSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (permissionSnapshot.hasError || !permissionSnapshot.hasData || !permissionSnapshot.data!) {
                      return Container(); // Hide if permission not granted
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to edit service screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServiceDetailsScreen(serviceData: service),
                              ),
                            );
                          },
                          child: Text('Edit Service'),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            // Show confirmation dialog for deletion
                            bool confirmDelete = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete Service'),
                                content: Text('Are you sure you want to delete this service?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _deleteService();
                                      Navigator.of(context).pop(true);
                                    },
                                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text('Delete Service', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteService() async {
    // try {
    //   await FirebaseFirestore.instance
    //       .collection('services')
    //       .doc(serviceData['serviceId'])
    //       .update({'isDeleted': true});
    //
    //   // Show success message and navigate back if necessary
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Service deleted successfully')),
    //   );
    //   Navigator.pop(context); // Close the details screen
    // } catch (e) {
    //   print("Error deleting service: $e");
    //   // Handle errors
    // }
  }
}
