import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'package:service_provider/Provider%20Panel/CustomSnackBar.dart';
import 'package:shimmer/shimmer.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final String? providerId = FirebaseAuth.instance.currentUser?.uid;

  Stream<List<Map<String, dynamic>>> fetchNotifications() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .where('isNotificationCleared', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {...doc.data(), 'bId': doc.id})
        .toList());
  }

  Future<void> clearAllNotifications() async {
    final batch = FirebaseFirestore.instance.batch();
    final notificationsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .where('isNotificationCleared', isEqualTo: false)
        .get();

    for (var doc in notificationsSnapshot.docs) {
      batch.update(doc.reference, {
        'isNotificationCleared': true,
        'clearedAt': Timestamp.now(),
      });
    }

    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const CustomSnackBar(message: 'All notifications cleared'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget notificationCard(Map<String, dynamic> booking) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final DateTime serviceDate = (booking['serviceDate'] as Timestamp).toDate();

    return FutureBuilder<Map<String, dynamic>?>(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(booking['userId'])
            .get()
            .then((doc) => doc.data()),
        FirebaseFirestore.instance
            .collection('services')
            .doc(booking['serviceId'])
            .get()
            .then((doc) => doc.data())
      ]).then((results) => {'userData': results[0], 'serviceData': results[1]}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildNotificationShimmer();
        }

        final data = snapshot.data ?? {};
        final userData = data['userData'] ?? {};
        final serviceData = data['serviceData'] ?? {};

        String title = booking['status'] == 'Reported'
            ? 'New Booking Request'
            : 'Booking Notification';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: ProviderTheme.surfaceColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: ProviderTheme.cardHighlightColor,
                  backgroundImage: userData['profileImage'] != null
                      ? NetworkImage(userData['profileImage'])
                      : null,
                  child: userData['profileImage'] == null
                      ? const FaIcon(FontAwesomeIcons.user,
                      color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ProviderTheme.primaryTextColor,
                              ),
                            ),
                          ),
                          FaIcon(
                            booking['status'] == 'Reported'
                                ? FontAwesomeIcons.bookmark
                                : FontAwesomeIcons.bell,
                            color: booking['status'] == 'Reported'
                                ? ProviderTheme.primaryColor
                                : ProviderTheme.secondaryTextColor,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Service: ${serviceData['name'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: ProviderTheme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: ${userData['name'] ?? 'Unknown User'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: ProviderTheme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${dateFormat.format(serviceDate)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: ProviderTheme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Amount: ₹${booking['paymentAmount']?.toString() ?? '0'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ProviderTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationShimmer() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: Colors.grey[300]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 150, height: 16, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(
                        width: 200, height: 14, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(
                        width: 150, height: 14, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(
                        width: 120, height: 14, color: Colors.grey[300]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProviderTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: ProviderTheme.primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Adjust this value for more/less curve
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  title: const Text('Clear All Notifications'),
                  content: const Text(
                      'Are you sure you want to clear all notifications?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        clearAllNotifications();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.clear_all, color: Colors.white),
            label: const Text(
              'Clear All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => _buildNotificationShimmer(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.bellSlash,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) =>
                notificationCard(snapshot.data![index]),
          );
        },
      ),
    );
  }
}