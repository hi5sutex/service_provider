import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final String adminId = FirebaseAuth.instance.currentUser!.uid.toString(); // Pass admin ID to check permissions

  BookingDetailsScreen({Key? key, required this.bookingData})
      : super(key: key);

  Future<Map<String, dynamic>> _fetchAllDetails() async {
    // Fetch provider, user, and service details concurrently
    final providerDoc = await FirebaseFirestore.instance.collection('providers').doc(bookingData['providerId']).get();
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(bookingData['userId']).get();
    final serviceDoc = await FirebaseFirestore.instance.collection('services').doc(bookingData['serviceId']).get();


    return {
      'provider': providerDoc.data() as Map<String, dynamic>,
      'user': userDoc.data() as Map<String, dynamic>,
      'service': serviceDoc.data() as Map<String, dynamic>,
    };
  }

  Future<bool> _hasManageBookingsPermission() async {
    DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admins').doc(adminId).get();
    return adminDoc['permissions']['manageBookings'] ?? false; // Return bool
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
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
            final provider = details['provider'];
            final user = details['user'];
            final service = details['service'];
            final providerName = provider['name'] ?? 'N/A';
            final userName = user['name'] ?? 'N/A';
            final serviceName = service['name'] ?? 'N/A';

            return ListView(
              children: [
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
                  'Status: ${bookingData['status'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Booking Date: ${bookingData['bookingDate']}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Service Date: ${DateFormat('dd/MM/yyyy').format(bookingData['serviceDate'].toDate())}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Payment Amount: ${bookingData['paymentAmount'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 16),
                Divider(),
                const SizedBox(height: 16),
                FutureBuilder<bool>(
                  future: _hasManageBookingsPermission(),
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
                            // Implement edit functionality
                          },
                          child: Text('Edit Booking'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Implement delete booking functionality
                          },
                          child: Text('Delete Booking', style: TextStyle(color: Colors.white)),
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
}
