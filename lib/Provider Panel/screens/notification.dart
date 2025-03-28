import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:service_provider/CustomSnackBar.dart'; // Import your CustomSnackBar

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final String? providerId = FirebaseAuth.instance.currentUser?.uid;
  String _selectedFilter = 'All'; // Default filter

  // Filter options with icons
  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'All', 'icon': Icons.all_inclusive},
    {'label': 'New Booking Request', 'icon': Icons.bookmark_added},
    {'label': 'Report', 'icon': Icons.report},
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
      query = query.where('status', isEqualTo: 'Reported'); // Example condition
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => {
      ...doc.data(),
      'bId': doc.id,
    })
        .toList());
  }

  // Clear all notifications and show custom SnackBar
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const CustomSnackBar(
          message: 'All Notifications cleared',
          type: 'success', // Green background for success
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent, // Let CustomSnackBar handle background
        elevation: 0,
        duration: const Duration(seconds: 2),
      ),
    );
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
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text('Loading...', style: TextStyle(color: Colors.black87)),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final userData = data['userData'] ?? {};
        final serviceData = data['serviceData'] ?? {};

        String title = 'New Booking Request';
        if (booking['status'] == 'Reported') {
          title = 'Report Notification';
        }

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(userData['profileImage'] ?? ''),
              radius: 24,
              backgroundColor: Colors.grey[300],
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('Service: ${serviceData['name'] ?? 'Unknown Service'}',
                    style: TextStyle(color: Colors.black54)),
                Text('From: ${userData['name'] ?? 'Unknown User'}',
                    style: TextStyle(color: Colors.black54)),
                Text('Date: ${dateFormat.format(serviceDate)}',
                    style: TextStyle(color: Colors.black54)),
                Text('Amount: ₹${booking['paymentAmount'] ?? '0'}',
                    style: TextStyle(color: Colors.black54)),
              ],
            ),
            trailing: Icon(
              booking['status'] == 'Pending'
                  ? Icons.bookmark_added
                  : Icons.report,
              color: Color(0xFF060644),
              size: 20,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF060644), // Primary color as background
      appBar: AppBar(
        backgroundColor: Color(0xFF060644),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: Text('Clear All Notifications',
                      style: TextStyle(color: Color(0xFF060644))),
                  content: Text(
                      'Are you sure you want to clear all notifications?',
                      style: TextStyle(color: Colors.black87)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child:
                      Text('Cancel', style: TextStyle(color: Colors.black87)),
                    ),
                    TextButton(
                      onPressed: () {
                        clearAllNotifications();
                        Navigator.pop(context);
                      },
                      child: Text('Clear All',
                          style: TextStyle(color: Color(0xFF060644))),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              'Clear All',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips/buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filterOptions.map((filter) {
                bool isSelected = _selectedFilter == filter['label'];
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = filter['label'];
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isSelected ? Colors.white : Color(0xFF060644),
                      foregroundColor:
                      isSelected ? Color(0xFF060644) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter['icon'],
                          size: 18,
                          color: isSelected ? Color(0xFF060644) : Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          filter['label'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Notification list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // Secondary color for the content area
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: fetchNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: Color(0xFF060644)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No new notifications',
                            style: TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 3),
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