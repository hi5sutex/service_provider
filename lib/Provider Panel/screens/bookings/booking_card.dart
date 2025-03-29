import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'package:shimmer/shimmer.dart';
import 'booking_details_sheet.dart';

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingCard({required this.booking, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');
    final DateFormat timeFormat = DateFormat('hh:mm a');
    final DateTime serviceDate = (booking['serviceDate'] as Timestamp).toDate();

    return FutureBuilder<Map<String, dynamic>?>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('users').doc(booking['userId']).get().then((doc) => doc.data()),
        FirebaseFirestore.instance.collection('services').doc(booking['serviceId']).get().then((doc) => doc.data())
      ]).then((results) => {'userData': results[0], 'serviceData': results[1]}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: ProviderTheme.dividerColor,
            highlightColor: ProviderTheme.cardHighlightColor,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Slightly larger margin
              elevation: 4,
              shape: ProviderTheme.themeData.cardTheme.shape,
              child: Container(
                height: 200, // Increased height for shimmer effect
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ProviderTheme.dividerColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 20,
                                color: ProviderTheme.dividerColor,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 100,
                                height: 14,
                                color: ProviderTheme.dividerColor,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 32,
                          color: ProviderTheme.dividerColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 150,
                      height: 16,
                      color: ProviderTheme.dividerColor,
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 20, thickness: 1, color: ProviderTheme.dividerColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 100, height: 14, color: ProviderTheme.dividerColor),
                            const SizedBox(height: 4),
                            Container(width: 80, height: 14, color: ProviderTheme.dividerColor),
                            const SizedBox(height: 4),
                            Container(width: 120, height: 14, color: ProviderTheme.dividerColor),
                          ],
                        ),
                        Container(width: 60, height: 16, color: ProviderTheme.dividerColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data as Map<String, dynamic>;
        final userData = data['userData'];
        final serviceData = data['serviceData'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Consistent with shimmer
          elevation: 4,
          shape: ProviderTheme.themeData.cardTheme.shape,
          color: ProviderTheme.surfaceColor,
          child: Container(
            constraints: const BoxConstraints(minHeight: 180), // Match shimmer height
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(userData['profileImage'] ?? ''),
                      radius: 28,
                      backgroundColor: ProviderTheme.dividerColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'] ?? 'User Name',
                            style: ProviderTheme.themeData.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking['location']['local'] ?? 'Location',
                            style: ProviderTheme.themeData.textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => showBookingDetailsBottomSheet(context, booking),
                        style: ProviderTheme.themeData.elevatedButtonTheme.style?.copyWith(
                          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 8)),
                          textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 12)),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (serviceData != null)
                  Text(
                    serviceData['name'] ?? 'Service Name',
                    style: ProviderTheme.themeData.textTheme.bodyLarge?.copyWith(
                      color: ProviderTheme.secondaryTextColor,
                    ),
                  ),
                Divider(height: 20, thickness: 1, color: ProviderTheme.dividerColor),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: ${dateFormat.format(serviceDate)}',
                            style: ProviderTheme.themeData.textTheme.bodyMedium,
                          ),
                          Text(
                            'Time: ${timeFormat.format(serviceDate)}',
                            style: ProviderTheme.themeData.textTheme.bodyMedium,
                          ),
                          Text(
                            'Payment: ₹${booking['paymentAmount']} (${booking['paymentMode']})',
                            style: ProviderTheme.themeData.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Text(
                        booking['status'],
                        style: TextStyle(
                          color: _getStatusColor(booking['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (booking['status'] == 'Cancelled' && booking['cancelReason'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Reason: ${booking['cancelReason']}',
                      style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                        color: ProviderTheme.errorTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return ProviderTheme.pendingColor;
      case 'Confirmed':
        return ProviderTheme.confirmedColor;
      case 'Ongoing':
        return ProviderTheme.ongoingColor;
      case 'Completed':
        return ProviderTheme.completedColor;
      case 'Cancelled':
        return ProviderTheme.canceledColor;
      default:
        return ProviderTheme.secondaryTextColor;
    }
  }
}