import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:service_provider/Admin%20Panel/screens/booking_details_screen.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    List<Map<String, dynamic>> bookings = bookingsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    // Fetch service details for each booking
    for (var booking in bookings) {
      DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
          .collection('services')
          .doc(booking['serviceId'])
          .get();

      booking['serviceName'] = (serviceDoc.data() as Map<String, dynamic>)['name'];
      booking['bookingDate'] = booking['bookingDate'].toDate().toString(); // Format booking date
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete User'),
          content: Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User deleted successfully!')),
                );
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  bool _isAdmin() {
    final currentUser = _auth.currentUser;
    return currentUser != null;
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
              Center(
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: NetworkImage(
                    user['profileImage'] ??
                        'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735399079/icons8-user-default-100_hakusn.png',
                  ),
                  backgroundColor: Colors.blueGrey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user['name'] ?? 'N/A',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(user['email'] ?? 'N/A', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(user['phone'] ?? 'N/A', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  user['createdAt'] != null
                      ? DateFormat('dd/MM/yyyy  kk:mm').format((user['createdAt'] as Timestamp).toDate()) // Format the Timestamp
                      : 'N/A',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              Divider(),
              const SizedBox(height: 16),
              _isAdmin()
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Implement edit functionality here
                    },
                    child: Text('Edit User'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _showDeleteConfirmation(context),
                    child: Text('Delete User'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              )
                  : SizedBox(),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchUserBookings(),
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...bookings.map((booking) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('Service: ${booking['serviceName']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ${booking['status']}'),
                                SizedBox(height: 4),
                                Text(
                                  'Booking Date: ${booking['bookingDate']}',

                                ),
                              ],
                            ),
                            trailing: Icon(Icons.arrow_forward),
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => BookingDetailsScreen(bookingData: booking),
                              ));
                            },
                          ),
                        );
                      }).toList(),
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
                    return Text('No payments found.');
                  }
                  final payments = paymentSnapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payments (${payments.length}):',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...payments.map((payment) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('Amount: ${payment['paymentAmount']}'),
                            subtitle: Text('Date: ${payment['paymentDate']}'),
                            trailing: Icon(Icons.receipt),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
