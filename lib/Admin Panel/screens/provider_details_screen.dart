import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:service_provider/Admin%20Panel/screens/booking_details_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/service_details_screen.dart';

class ProviderDetailsScreen extends StatelessWidget {
  final String providerId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProviderDetailsScreen({Key? key, required this.providerId}) : super(key: key);

  Future<Map<String, dynamic>> _fetchProviderDetails() async {
    DocumentSnapshot providerDoc = await FirebaseFirestore.instance.collection('providers').doc(providerId).get();
    return providerDoc.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _fetchProviderServices() async {
    QuerySnapshot servicesSnapshot = await FirebaseFirestore.instance
        .collection('services')
        .where('createdBy', isEqualTo: providerId)
        .get();

    return servicesSnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add the document ID
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchProviderBookings() async {
    QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .get();

    List<Map<String, dynamic>> bookings = bookingsSnapshot.docs.map((doc) {
      Map<String, dynamic> booking = doc.data() as Map<String, dynamic>;
      booking['id'] = doc.id; // Add booking ID
      return booking;
    }).toList();

    await Future.wait(bookings.map((booking) async {
      if (booking['userId'] != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(booking['userId'])
            .get();
        if (userDoc.exists) {
          booking['userName'] = (userDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown User';
        }
      }

      if (booking['serviceId'] != null) {
        DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
            .collection('services')
            .doc(booking['serviceId'])
            .get();
        if (serviceDoc.exists) {
          booking['serviceName'] = (serviceDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown Service';
        }
      }

      if (booking['bookingDate'] is Timestamp) {
        booking['bookingDate'] = DateFormat('dd/MM/yyyy kk:mm').format((booking['bookingDate'] as Timestamp).toDate());
      }
    }));

    return bookings;
  }

  Future<List<Map<String, dynamic>>> _fetchProviderPayments() async {
    QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('providerId', isEqualTo: providerId)
        .get();
    return paymentsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  bool _isAdmin() {
    final currentUser = _auth.currentUser;
    return currentUser != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProviderDetails(),
        builder: (context, providerSnapshot) {
          if (providerSnapshot.connectionState == ConnectionState.waiting) {
            return _buildProviderShimmer();
          }
          if (providerSnapshot.hasError || !providerSnapshot.hasData) {
            return const Center(child: Text('Error loading provider details.'));
          }

          final provider = providerSnapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: NetworkImage(
                    provider['profileImage'] ?? 'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735399079/icons8-user-default-100_hakusn.png',
                  ),
                  backgroundColor: Colors.blueGrey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  provider['name'] ?? 'N/A',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(provider['email'] ?? 'N/A', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(provider['phone'] ?? 'N/A', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  provider['createdAt'] != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format((provider['createdAt'] as Timestamp).toDate())
                      : 'N/A',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                      await FirebaseFirestore.instance.collection('providers').doc(providerId).update({'isBlocked': true});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Provider blocked successfully!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Block Provider'),
                  ),
                ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchProviderServices(),
                builder: (context, servicesSnapshot) {
                  if (servicesSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildServicesShimmer();
                  }
                  if (servicesSnapshot.hasError || !servicesSnapshot.hasData) {
                    return const Text('No services found.');
                  }
                  final services = servicesSnapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services (${services.length}):',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...services.map((service) => _buildServiceCard(service, context)).toList(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchProviderBookings(),
                builder: (context, bookingSnapshot) {
                  if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildBookingsShimmer();
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
                future: _fetchProviderPayments(),
                builder: (context, paymentSnapshot) {
                  if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildPaymentsShimmer();
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

  Widget _buildServiceCard(Map<String, dynamic> service, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ServiceDetailsScreen(serviceId: service['id']),
        ));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Text(
            service['name'] ?? 'N/A',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${service['category'] ?? 'N/A'}'),
              Text('Price: \$${service['price']?.toString() ?? 'N/A'}'),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text('Service: ${booking['serviceName'] ?? 'N/A'}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${booking['userName'] ?? 'N/A'}'),
            Text('Status: ${booking['status'] ?? 'N/A'}'),
            const SizedBox(height: 4),
            Text('Booking Date: ${booking['bookingDate'] ?? 'N/A'}'),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text('Amount: ${payment['paymentAmount'] ?? 'N/A'}'),
        subtitle: Text('Date: ${payment['paymentDate'] ?? 'N/A'}'),
        trailing: const Icon(Icons.receipt),
      ),
    );
  }

  Widget _buildProviderShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(child: CircleAvatar(radius: 80, backgroundColor: Colors.grey[300])),
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

  Widget _buildServicesShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(width: 120, height: 18, color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        ...List.generate(3, (_) => _buildShimmerCard()),
      ],
    );
  }

  Widget _buildBookingsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(width: 120, height: 18, color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        ...List.generate(3, (_) => _buildShimmerCard()),
      ],
    );
  }

  Widget _buildPaymentsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(width: 120, height: 18, color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        ...List.generate(3, (_) => _buildShimmerCard()),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Container(width: 150, height: 16, color: Colors.grey[300]),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 100, height: 14, color: Colors.grey[300]),
              const SizedBox(height: 4),
              Container(width: 180, height: 14, color: Colors.grey[300]),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward, color: Colors.transparent),
        ),
      ),
    );
  }
}