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
  String _selectedFilter = 'All'; // Default filter

  // Filter options with icons
  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'All', 'icon': FontAwesomeIcons.list},
    {'label': 'New Booking Request', 'icon': FontAwesomeIcons.bookmark},
    {'label': 'Report', 'icon': FontAwesomeIcons.triangleExclamation},
  ];

  // Stream to fetch notifications based on filter
  Stream<List<Map<String, dynamic>>> fetchNotifications() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .where('isNotificationCleared', isEqualTo: false);

    if (_selectedFilter == 'New Booking Request') {
      query = query.where('status', isEqualTo: 'Pending');
    } else if (_selectedFilter == 'Report') {
      query = query.where('status', isEqualTo: 'Reported');
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => {
      ...doc.data(),
      'bId': doc.id,
    })
        .toList());
  }

  // Clear all notifications
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
          content: const CustomSnackBar(
            message: 'All notifications cleared',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 3),
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
      ]).then((results) {
        return {'userData': results[0], 'serviceData': results[1]};
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildNotificationShimmer();
        }

        final data = snapshot.data ?? {};
        final userData = data['userData'] ?? {};
        final serviceData = data['serviceData'] ?? {};

        String title = 'New Booking Request';
        if (booking['status'] == 'Reported') {
          title = 'Report Notification';
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: ProviderTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ProviderTheme.dividerColor.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: ProviderTheme.shadowColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: userData['profileImage'] != null
                      ? NetworkImage(userData['profileImage'])
                      : null,
                  radius: 24,
                  backgroundColor: ProviderTheme.cardHighlightColor,
                  child: userData['profileImage'] == null
                      ? const FaIcon(
                    FontAwesomeIcons.user,
                    color: ProviderTheme.secondaryTextColor,
                    size: 24,
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: ProviderTheme.themeData.textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ProviderTheme.primaryTextColor,
                            ),
                          ),
                          FaIcon(
                            booking['status'] == 'Pending'
                                ? FontAwesomeIcons.bookmark
                                : FontAwesomeIcons.triangleExclamation,
                            color: ProviderTheme.primaryColor,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Service: ${serviceData['name'] ?? 'Unknown Service'}',
                        style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                          color: ProviderTheme.secondaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: ${userData['name'] ?? 'Unknown User'}',
                        style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                          color: ProviderTheme.secondaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${dateFormat.format(serviceDate)}',
                        style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                          color: ProviderTheme.secondaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Amount: ₹${booking['paymentAmount']?.toString() ?? '0'}',
                        style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                          color: ProviderTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: ProviderTheme.dividerColor,
        highlightColor: ProviderTheme.backgroundColor,
        child: Container(
          height: 120, // Matches the approximate height of the notification card
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ProviderTheme.dividerColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 150,
                            height: 16,
                            color: Colors.white,
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: ProviderTheme.primaryGradient,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: ProviderTheme.onPrimaryTextColor,
              size: 28,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: ProviderTheme.onPrimaryTextColor),
        ),
        centerTitle: false,
        elevation: ProviderTheme.themeData.appBarTheme.elevation,
        shadowColor: ProviderTheme.shadowColor.withOpacity(0.4),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: ProviderTheme.surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Clear All Notifications',
                    style: ProviderTheme.themeData.textTheme.titleLarge?.copyWith(
                      color: ProviderTheme.primaryTextColor,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to clear all notifications?',
                    style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                      color: ProviderTheme.secondaryTextColor,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                          color: ProviderTheme.secondaryTextColor,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        clearAllNotifications();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear All',
                        style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                          color: ProviderTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              'Clear All',
              style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                color: ProviderTheme.onPrimaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips/buttons
          Container(
            color: ProviderTheme.primaryColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _filterOptions.map((filter) {
                  bool isSelected = _selectedFilter == filter['label'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = filter['label'];
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? ProviderTheme.completedColor // Use completedColor instead of accentColor
                            : ProviderTheme.surfaceColor,
                        foregroundColor: isSelected
                            ? ProviderTheme.onPrimaryTextColor
                            : ProviderTheme.primaryTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            filter['icon'],
                            size: 18,
                            color: isSelected
                                ? ProviderTheme.onPrimaryTextColor
                                : ProviderTheme.primaryTextColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            filter['label'],
                            style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? ProviderTheme.onPrimaryTextColor
                                  : ProviderTheme.primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Notification list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ProviderTheme.backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: fetchNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: 5, // Simulate 5 shimmer cards
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
                            size: 64,
                            color: ProviderTheme.secondaryTextColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No new notifications',
                            style: ProviderTheme.themeData.textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              color: ProviderTheme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return notificationCard(snapshot.data![index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}