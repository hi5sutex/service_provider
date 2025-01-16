import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Admin%20Panel/screens/booking_details_screen.dart';

class BookingsScreen extends StatefulWidget {
  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool hasViewPermission = false;
  bool hasManagePermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Simulated permission check (replace with real logic)
    setState(() {
      hasViewPermission = true; // Example: Replace with actual permission
      hasManagePermission = true; // Example: Replace with actual permission
    });
  }

  Future<List<Map<String, dynamic>>> _fetchBookings() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('bookings').get();
    List<Map<String, dynamic>> bookings = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add document ID to the booking data

      // Fetch user, service, and provider details using IDs
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(data['userId']).get();
      final serviceDoc = await FirebaseFirestore.instance.collection('services').doc(data['serviceId']).get();
      final providerDoc = await FirebaseFirestore.instance.collection('providers').doc(data['providerId']).get();

      // Check if the user, service, and provider documents exist
      if (userDoc.exists) {
        data['userName'] = userDoc.data()?['name'] ?? 'Unknown'; // Default if field does not exist
      } else {
        data['userName'] = 'Unknown';
      }

      if (serviceDoc.exists) {
        data['serviceName'] = serviceDoc.data()?['name'] ?? 'Unknown'; // Default if field does not exist
      } else {
        data['serviceName'] = 'Unknown';
      }

      if (providerDoc.exists) {
        data['providerName'] = providerDoc.data()?['name'] ?? 'Unknown'; // Default if field does not exist
      } else {
        data['providerName'] = 'Unknown';
      }

      bookings.add(data);
    }

    return bookings;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings'),
      ),
      body: hasViewPermission
          ? FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading bookings. ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No bookings found.'));
          }

          final bookings = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingCard(booking);
            },
          );
        },
      )
          : Center(
        child: Text(
          'You do not have permission to view bookings.',
          style: TextStyle(fontSize: 16, color: Colors.redAccent),
        ),
      ),
      floatingActionButton: hasManagePermission
          ? FloatingActionButton(
        onPressed: () {
          // Implement add booking or other management functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Manage Bookings functionality coming soon!')),
          );
        },
        backgroundColor: Colors.lightBlue,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      )
          : null,
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return GestureDetector(
      onTap: hasManagePermission
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailsScreen(bookingData: booking),
          ),
        );
      }
          : null,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking ID: ${booking['id']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'User: ${booking['userName'] ?? 'N/A'}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                'Service: ${booking['serviceName'] ?? 'N/A'}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'Provider: ${booking['providerName'] ?? 'N/A'}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'Date: ${booking['bookingDate'] ?? 'N/A'}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                'Status: ${booking['status'] ?? 'N/A'}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
