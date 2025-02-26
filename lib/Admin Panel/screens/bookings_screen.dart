import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
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
    List<Map<String, dynamic>> bookings = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    // Collect unique IDs for users, services, and providers
    Set<String> userIds = bookings.map((b) => b['userId'] as String).toSet();
    Set<String> serviceIds = bookings.map((b) => b['serviceId'] as String).toSet();
    Set<String> providerIds = bookings.map((b) => b['providerId'] as String).toSet();

    // Fetch all related documents in parallel and create MapEntries explicitly
    Map<String, DocumentSnapshot> userDocs = Map.fromEntries(
      await Future.wait(
        userIds.map(
              (id) async => MapEntry(
            id,
            await FirebaseFirestore.instance.collection('users').doc(id).get(),
          ),
        ),
      ),
    );
    Map<String, DocumentSnapshot> serviceDocs = Map.fromEntries(
      await Future.wait(
        serviceIds.map(
              (id) async => MapEntry(
            id,
            await FirebaseFirestore.instance.collection('services').doc(id).get(),
          ),
        ),
      ),
    );
    Map<String, DocumentSnapshot> providerDocs = Map.fromEntries(
      await Future.wait(
        providerIds.map(
              (id) async => MapEntry(
            id,
            await FirebaseFirestore.instance.collection('providers').doc(id).get(),
          ),
        ),
      ),
    );

    // Attach fetched data to bookings with proper null safety
    for (var booking in bookings) {
      final userDoc = userDocs[booking['userId']];
      final serviceDoc = serviceDocs[booking['serviceId']];
      final providerDoc = providerDocs[booking['providerId']];

      booking['userName'] = userDoc != null && userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
          : 'Unknown';
      booking['serviceName'] = serviceDoc != null && serviceDoc.exists
          ? (serviceDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
          : 'Unknown';
      booking['providerName'] = providerDoc != null && providerDoc.exists
          ? (providerDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
          : 'Unknown';
    }

    return bookings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
      ),
      body: hasViewPermission
          ? FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerEffect();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading bookings: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No bookings found.'));
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
          : const Center(
        child: Text(
          'You do not have permission to view bookings.',
          style: TextStyle(fontSize: 16, color: Colors.redAccent),
        ),
      ),
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

  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5, // Display 5 shimmer placeholders
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 150, height: 16, color: Colors.white),
              const SizedBox(height: 4),
              Container(width: 100, height: 14, color: Colors.white),
              const SizedBox(height: 4),
              Container(width: 120, height: 14, color: Colors.white),
              const SizedBox(height: 4),
              Container(width: 120, height: 14, color: Colors.white),
              const SizedBox(height: 4),
              Container(width: 80, height: 14, color: Colors.white),
              const SizedBox(height: 4),
              Container(width: 80, height: 14, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}