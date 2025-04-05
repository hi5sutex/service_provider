import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'admin_theme.dart'; // Import your theme file

class BookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingDetailsScreen({Key? key, required this.bookingData})
      : super(key: key);

  Future<Map<String, dynamic>> _fetchAllDetails() async {
    final providerDoc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(bookingData['providerId'])
        .get();
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(bookingData['userId'])
        .get();
    final serviceDoc = await FirebaseFirestore.instance
        .collection('services')
        .doc(bookingData['serviceId'])
        .get();

    return {
      'provider': providerDoc.data() as Map<String, dynamic>,
      'user': userDoc.data() as Map<String, dynamic>,
      'service': serviceDoc.data() as Map<String, dynamic>,
    };
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AdminTheme.dividerColor,
      highlightColor: AdminTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          6,
              (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: double.infinity,
              height: 20.0,
              color: AdminTheme.surfaceColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchAllDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: _buildShimmer(),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Text(
                    'Error loading details.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: AdminTheme.errorTextColor),
                  ),
                );
              }

              final details = snapshot.data!;
              final provider = details['provider'];
              final user = details['user'];
              final service = details['service'];
              final providerName = provider['name'] ?? 'N/A';
              final userName = user['name'] ?? 'N/A';
              final serviceName = service['name'] ?? 'N/A';

              String bookingDateStr;
              if (bookingData['bookingDate'] is Timestamp) {
                bookingDateStr = DateFormat('dd/MM/yyyy')
                    .format(bookingData['bookingDate'].toDate());
              } else {
                bookingDateStr = bookingData['bookingDate']?.toString() ?? 'N/A';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, serviceName),
                  const SizedBox(height: 16),
                  _buildDetailCard(context, [
                    _buildDetailRow(context, 'Category', service['category']),
                    _buildDetailRow(context, 'Provider', providerName),
                    _buildDetailRow(context, 'User', userName),
                    _buildDetailRow(context, 'Status',
                        bookingData['status'] ?? 'N/A',
                        statusColor: _getStatusColor(bookingData['status'])),
                    _buildDetailRow(context, 'Booking Date', bookingDateStr),
                    _buildDetailRow(
                        context,
                        'Service Date',
                        DateFormat('dd/MM/yyyy')
                            .format(bookingData['serviceDate'].toDate())),
                    _buildDetailRow(context, 'Payment Amount',
                        '₹${bookingData['paymentAmount'] ?? 'N/A'}',
                        isBold: true, valueColor: AdminTheme.successColor),
                  ]),

                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String serviceName) {
    return Text(
      serviceName,
      style: Theme.of(context)
          .textTheme
          .displayMedium!
          .copyWith(color: AdminTheme.accentColor),
    );
  }

  Widget _buildDetailCard(BuildContext context, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {bool isBold = false, Color? valueColor, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: AdminTheme.secondaryTextColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: statusColor ??
                    valueColor ??
                    AdminTheme.primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AdminTheme.completedColor;
      case 'pending':
        return AdminTheme.pendingColor;
      case 'cancelled':
        return AdminTheme.canceledColor;
      case 'confirmed':
        return AdminTheme.confirmedColor;
      case 'ongoing':
        return AdminTheme.ongoingColor;
      default:
        return AdminTheme.secondaryTextColor;
    }
  }

}