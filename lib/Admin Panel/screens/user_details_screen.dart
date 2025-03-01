import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
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

    for (var booking in bookings) {
      DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
          .collection('services')
          .doc(booking['serviceId'])
          .get();
      booking['serviceName'] = (serviceDoc.data() as Map<String, dynamic>)['name'];
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
          title: const Text('Delete User'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted successfully!')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
        title: const Text('User Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserDetails(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return _buildUserShimmerEffect();
          }
          if (userSnapshot.hasError || !userSnapshot.hasData) {
            return const Center(child: Text('Error loading user details.'));
          }

          final user = userSnapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
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
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                      ? DateFormat('dd/MM/yyyy HH:mm').format((user['createdAt'] as Timestamp).toDate())
                      : 'N/A',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              if (_isAdmin())
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('users').doc(userId).update({'isBlocked': true});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User blocked successfully!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Block User', style: TextStyle(color: Colors.white),),
                  ),
                ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchUserBookings(),
                builder: (context, bookingSnapshot) {
                  if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildBookingsShimmerEffect();
                  }
                  if (bookingSnapshot.hasError || !bookingSnapshot.hasData) {
                    return const Text('No bookings found.');
                  }
                  final bookings = bookingSnapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookings (${bookings.length}):',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...bookings.map((booking) => _buildBookingCard(booking, context)).toList(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchUserPayments(),
                builder: (context, paymentSnapshot) {
                  if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildPaymentsShimmerEffect();
                  }
                  if (paymentSnapshot.hasError || !paymentSnapshot.hasData) {
                    return const Text('No payments found.');
                  }
                  final payments = paymentSnapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payments (${payments.length}):',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...payments.map((payment) => _buildPaymentCard(payment)).toList(),
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

  Widget _buildBookingCard(Map<String, dynamic> booking, BuildContext context) {
    final bookingDate = (booking['bookingDate'] as Timestamp?)?.toDate();
    final serviceDate = (booking['serviceDate'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          booking['serviceName'] ?? 'Unknown Service',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Status: ${booking['status'] ?? 'N/A'}'),
            Text('Service Date: ${serviceDate != null ? DateFormat('dd MMM yyyy HH:mm').format(serviceDate) : 'N/A'}'),
            Text('Location: ${booking['location']?['local'] ?? 'N/A'}'),
            Text('Payment: ${booking['paymentAmount'] ?? 'N/A'} (${booking['paymentStatus'] ?? 'N/A'})'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => BookingDetailsScreen(bookingData: booking),
          ));
        },
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final paymentDate = (payment['paymentDate'] as Timestamp?)?.toDate();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text('Amount: ${payment['paymentAmount'] ?? 'N/A'}'),
        subtitle: Text(
          'Date: ${paymentDate != null ? DateFormat('dd MMM yyyy HH:mm').format(paymentDate) : 'N/A'}',
        ),
        trailing: const Icon(Icons.receipt),
      ),
    );
  }

  Widget _buildUserShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: CircleAvatar(radius: 80, backgroundColor: Colors.grey[300]),
          ),
          const SizedBox(height: 16),
          Center(child: Container(width: 150, height: 24, color: Colors.grey[300])),
          const SizedBox(height: 8),
          Center(child: Container(width: 200, height: 16, color: Colors.grey[300])),
          const SizedBox(height: 4),
          Center(child: Container(width: 120, height: 16, color: Colors.grey[300])),
          const SizedBox(height: 4),
          Center(child: Container(width: 140, height: 16, color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildBookingsShimmerEffect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(width: 120, height: 18, color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        ...List.generate(
          3,
              (_) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Container(width: 150, height: 16, color: Colors.grey[300]),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Container(width: 100, height: 14, color: Colors.grey[300]),
                    const SizedBox(height: 4),
                    Container(width: 180, height: 14, color: Colors.grey[300]),
                    const SizedBox(height: 4),
                    Container(width: 120, height: 14, color: Colors.grey[300]),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward, color: Colors.transparent),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsShimmerEffect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(width: 120, height: 18, color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        ...List.generate(
          3,
              (_) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Container(width: 100, height: 16, color: Colors.grey[300]),
                subtitle: Container(width: 140, height: 14, color: Colors.grey[300]),
                trailing: const Icon(Icons.receipt, color: Colors.transparent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}