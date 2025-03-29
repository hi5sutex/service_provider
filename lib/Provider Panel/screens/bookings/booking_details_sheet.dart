import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'booking_actions.dart';

void showBookingDetailsBottomSheet(BuildContext context, Map<String, dynamic> booking) {
  final DateFormat dateFormat = DateFormat('dd MMM, yyyy');
  final DateFormat timeFormat = DateFormat('h:mm a');
  final DateTime serviceDate = (booking['serviceDate'] as Timestamp).toDate();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    backgroundColor: ProviderTheme.surfaceColor,
    builder: (BuildContext context) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: Future.wait([
          FirebaseFirestore.instance.collection('users').doc(booking['userId']).get().then((doc) => doc.data()),
          FirebaseFirestore.instance.collection('services').doc(booking['serviceId']).get().then((doc) => doc.data())
        ]).then((results) => {'userData': results[0], 'serviceData': results[1]}),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: Center(
                child: Text(
                  "No details available",
                  style: ProviderTheme.themeData.textTheme.bodyLarge?.copyWith(
                    color: ProviderTheme.secondaryTextColor,
                  ),
                ),
              ),
            );
          }

          final data = snapshot.data as Map<String, dynamic>;
          final userData = data['userData'];
          final serviceData = data['serviceData'];

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: ProviderTheme.secondaryTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Order status",
                      style: ProviderTheme.themeData.textTheme.displayMedium,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceData['name'] ?? 'Service Name',
                        style: ProviderTheme.themeData.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(userData['profileImage'] ?? ''),
                            backgroundColor: ProviderTheme.dividerColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            userData['name'] ?? 'User Name',
                            style: ProviderTheme.themeData.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Details",
                        style: ProviderTheme.themeData.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: ProviderTheme.secondaryTextColor),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                timeFormat.format(serviceDate),
                                style: ProviderTheme.themeData.textTheme.bodyLarge,
                              ),
                              Text(
                                "Service time",
                                style: ProviderTheme.themeData.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: ProviderTheme.secondaryTextColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking['location']['local'] ?? 'Location',
                                  style: ProviderTheme.themeData.textTheme.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                Text(
                                  "Location",
                                  style: ProviderTheme.themeData.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: ProviderTheme.secondaryTextColor),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateFormat.format(serviceDate),
                                style: ProviderTheme.themeData.textTheme.bodyLarge,
                              ),
                              Text(
                                "Date",
                                style: ProviderTheme.themeData.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: ProviderTheme.secondaryTextColor),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "₹${booking['paymentAmount']}",
                                style: ProviderTheme.themeData.textTheme.bodyLarge,
                              ),
                              Text(
                                "Price",
                                style: ProviderTheme.themeData.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                BookingActionButtons(booking: booking),
              ],
            ),
          );
        },
      );
    },
  );
}