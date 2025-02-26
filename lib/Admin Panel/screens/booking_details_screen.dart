import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  BookingDetailsScreen({Key? key, required this.bookingData}) : super(key: key);

  Future<Map<String, dynamic>> _fetchAllDetails() async {
    final providerDoc = await FirebaseFirestore.instance.collection('providers').doc(bookingData['providerId']).get();
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(bookingData['userId']).get();
    final serviceDoc = await FirebaseFirestore.instance.collection('services').doc(bookingData['serviceId']).get();

    return {
      'provider': providerDoc.data() as Map<String, dynamic>,
      'user': userDoc.data() as Map<String, dynamic>,
      'service': serviceDoc.data() as Map<String, dynamic>,
    };
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(6, (index) =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                width: double.infinity,
                height: 20.0,
                color: Colors.white,
              ),
            ),
        ),
      ),
    );
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
              return _buildShimmer();
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

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service: $serviceName',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Category: ${service['category']}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Provider: $providerName',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'User: $userName',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Status: ${bookingData['status'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Booking Date: ${bookingData['bookingDate']}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Service Date: ${DateFormat('dd/MM/yyyy').format(bookingData['serviceDate'].toDate())}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Payment Amount: ₹${bookingData['paymentAmount'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
