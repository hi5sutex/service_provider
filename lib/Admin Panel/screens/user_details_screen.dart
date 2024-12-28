import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Import FirebaseAuth

class UserDetailsScreen extends StatelessWidget {
  final String userId;
  final FirebaseAuth _auth = FirebaseAuth.instance;  // Initialize FirebaseAuth

  UserDetailsScreen({Key? key, required this.userId}) : super(key: key);

  Future<Map<String, dynamic>> _fetchUserDetails() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _fetchUserBookings() async {
    QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();
    return bookingsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> _fetchServiceDetails(String serviceId) async {
    DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .get();
    return serviceDoc.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _fetchBookingsAndServices() async {
    List<Map<String, dynamic>> bookings = await _fetchUserBookings();
    List<Future<Map<String, dynamic>>> serviceDetailsFutures = bookings
        .map((booking) => _fetchServiceDetails(booking['serviceId']))
        .toList();

    List<Map<String, dynamic>> servicesDetails = await Future.wait(serviceDetailsFutures);
    for (int i = 0; i < bookings.length; i++) {
      bookings[i]['serviceDetails'] = servicesDetails[i];
    }
    return bookings;
  }

  Future<List<Map<String, dynamic>>> _fetchUserPayments() async {
    QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .get();
    return paymentsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  bool _isAdmin() {
    final currentUser = _auth.currentUser;
    return currentUser != null && currentUser.uid != null;  // Check if the current user is admin or has required permissions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserDetails(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError || !userSnapshot.hasData) {
            return Center(child: Text('Error loading user details.'));
          }

          final user = userSnapshot.data!;

          return ListView(
            padding: EdgeInsets.all(16.0),
            children: [
              CircleAvatar(
                radius: 69,
                backgroundImage: NetworkImage(
                  user['profileImage'] ?? 'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735399079/icons8-user-default-100_hakusn.png',
                ),
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                user['name'] ?? 'N/A',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(user['email'] ?? 'N/A', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text(user['phone'] ?? 'N/A', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Text(
                'Joined: ${_formatTimestamp(user['createdAt'])}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Divider(),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchBookingsAndServices(),
                builder: (context, bookingSnapshot) {
                  if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (bookingSnapshot.hasError || !bookingSnapshot.hasData) {
                    return Text('No bookings found.');
                  }
                  final bookings = bookingSnapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookings (${bookings.length}):',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          final serviceDetails = booking['serviceDetails'];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Service: ${serviceDetails['name']}'),
                                  Text('Subcategory: ${serviceDetails['subcategory']}'),
                                  Text('Service Date: ${_formatTimestamp(booking['serviceDate'])}'),
                                  Text('Booking Date: ${_formatTimestamp(booking['bookingDate'])}'),
                                  Text('Status: ${booking['status']}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchUserPayments(),
                builder: (context, paymentSnapshot) {
                  if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (paymentSnapshot.hasError || !paymentSnapshot.hasData) {
                    return Text('No payment details found.');
                  }
                  final payments = paymentSnapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payments (${payments.length}):',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Amount: ${payment['paymentAmount']}'),
                                  Text('Payment Method: ${payment['paymentMode']}'),
                                  Text('Date: ${_formatTimestamp(payment['paymentDate'])}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_isAdmin())  // Admin condition check
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Implement edit user functionality
                        // Redirect to user edit screen
                      },
                      child: Text('Edit User'),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Implement delete user functionality
                        // Show confirmation dialog before deletion
                      },
                      child: Text('Delete User'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day} ${date.month}/${date.year}';
  }
}
