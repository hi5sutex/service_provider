import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:service_provider/Provider%20Panel/screens/live_tracking.dart';
import 'package:shimmer/shimmer.dart';

class ProviderBooking extends StatefulWidget {
  @override
  _ProviderBookingState createState() => _ProviderBookingState();
}

class _ProviderBookingState extends State<ProviderBooking>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? providerId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Check for expired bookings when the page loads
    checkAndUpdateExpiredBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to check and update expired bookings
  Future<void> checkAndUpdateExpiredBookings() async {
    final now = DateTime.now();

    // Get all pending and confirmed bookings for this provider
    final bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .where('status', whereIn: ['Pending', 'Confirmed'])
        .get();

    // Batch write to update all expired bookings at once
    final batch = FirebaseFirestore.instance.batch();
    bool hasBatchOperations = false;

    for (var doc in bookingsSnapshot.docs) {
      final bookingData = doc.data();
      final serviceDate = (bookingData['serviceDate'] as Timestamp).toDate();

      // If the service date/time has passed, mark as cancelled
      if (serviceDate.isBefore(now)) {
        batch.update(doc.reference, {
          'status': 'Cancelled',
          'cancelReason': 'Expired booking',
          'cancelledAt': Timestamp.now(),
        });
        hasBatchOperations = true;
      }
    }

    // Commit the batch if there are any operations
    if (hasBatchOperations) {
      await batch.commit();
    }
  }

  Stream<List<Map<String, dynamic>>> fetchBookings(String status) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: status)
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final bookings = snapshot.docs
          .map((doc) => {
        ...doc.data(),
        'bId': doc.id,
      })
          .toList();

      if (status == 'Pending' || status == 'Confirmed') {
        // Sort by closest upcoming date first
        bookings.sort((a, b) {
          DateTime aDate = (a['serviceDate'] as Timestamp).toDate();
          DateTime bDate = (b['serviceDate'] as Timestamp).toDate();

          // Compare dates first (ignoring time)
          DateTime aJustDate = DateTime(aDate.year, aDate.month, aDate.day);
          DateTime bJustDate = DateTime(bDate.year, bDate.month, bDate.day);
          DateTime nowJustDate = DateTime(now.year, now.month, now.day);

          // Calculate difference in days from today
          int aDayDiff = aJustDate.difference(nowJustDate).inDays;
          int bDayDiff = bJustDate.difference(nowJustDate).inDays;

          // Negative day difference means past date
          if (aDayDiff < 0 && bDayDiff >= 0) return 1; // b comes first
          if (bDayDiff < 0 && aDayDiff >= 0) return -1; // a comes first

          // If both dates are in the past or both in the future, compare difference
          if (aDayDiff != bDayDiff) {
            // For future dates, smaller difference (closer date) comes first
            // For past dates, smaller absolute difference (more recent) comes first
            return aDayDiff.abs() - bDayDiff.abs();
          }

          // If dates are the same day, sort by time
          return aDate.compareTo(bDate);
        });
      } else {
        // For completed and cancelled, most recent first
        bookings.sort((a, b) {
          DateTime aDate = (a['serviceDate'] as Timestamp).toDate();
          DateTime bDate = (b['serviceDate'] as Timestamp).toDate();
          return bDate.compareTo(aDate);
        });
      }

      return bookings;
    });
  }

  // Method to show booking details in a bottom sheet
  void _showBookingDetailsBottomSheet(Map<String, dynamic> booking) {
    final DateFormat dateFormat = DateFormat('dd MMM, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');
    final DateTime serviceDate = (booking['serviceDate'] as Timestamp).toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
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
              return Container(
                height: MediaQuery.of(context).size.height * 0.6,
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.3,
                child: Center(child: Text("No details available")),
              );
            }

            final data = snapshot.data as Map<String, dynamic>;
            final userData = data['userData'];
            final serviceData = data['serviceData'];

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button at top right
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Order status title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Order status",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Service name and provider name
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceData['name'] ?? 'Service Name',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(userData['profileImage'] ?? ''),
                            ),
                            SizedBox(width: 8),
                            Text(
                              userData['name'] ?? 'User Name',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Details section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Time row
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.grey),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  //"${booking['duration'] ?? '2 h 30 min'}",
                                  "${timeFormat.format(serviceDate)}",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                  //"${timeFormat.format(serviceDate)} ?? '2 h 30 min'",
                                ),
                                Text(
                                  "Service time",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Location row
                        // Location row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on, color: Colors.grey),
                            SizedBox(width: 12),
                            Expanded(  // Add this to make the column take remaining width
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking['location']['local'] ?? 'Location',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,  // Optional: truncate with ellipsis
                                    maxLines: 2,  // Optional: limit to 2 lines
                                  ),
                                  Text(
                                    "Location",
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Date row
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateFormat.format(serviceDate),
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  "Date",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Price row
                        Row(
                          children: [
                            Icon(Icons.attach_money, color: Colors.grey),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "₹${booking['paymentAmount']} ",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  "Price",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Additional booking details can be added here

                  Spacer(),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        if (booking['status'] == 'Pending' || booking['status'] == 'Confirmed')
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Handle cancel order logic
                                Navigator.pop(context);
                                _showCancelConfirmationDialog(booking);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Cancel order',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        if (booking['status'] == 'Pending' || booking['status'] == 'Confirmed')
                          SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle confirm payment or complete service
                              if (booking['status'] == 'Pending') {
                                _confirmBooking(booking['bId']);
                              } else if (booking['status'] == 'Confirmed') {
                                _completeBooking(booking['bId']);
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF060644),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              booking['status'] == 'Pending'
                                  ? 'Confirm booking'
                                  : booking['status'] == 'Confirmed'
                                  ? 'Complete service'
                                  : 'Close',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Show cancel confirmation dialog
  void _showCancelConfirmationDialog(Map<String, dynamic> booking) {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to cancel this booking?'),
              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for cancellation',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelBooking(booking['bId'], reasonController.text);
              },
              child: Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Cancel booking method
  Future<void> _cancelBooking(String bookingId, String reason) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Cancelled',
      'cancelReason': reason.isEmpty ? 'Cancelled by provider' : reason,
      'cancelledAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking cancelled successfully')),
    );
  }

  // Confirm booking method
  Future<void> _confirmBooking(String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Confirmed',
      'confirmedAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking confirmed successfully')),
    );
  }

  // Complete booking method
  Future<void> _completeBooking(String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Completed',
      'completedAt': Timestamp.now(),
    });

    // Fetch the booking details to get the customer's location
    DocumentSnapshot bookingDoc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get();

    Map<String, dynamic> bookingData = bookingDoc.data() as Map<String, dynamic>;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Service marked as completed')),
    );

    // Navigate to the live tracking page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTrackingPage(
          bookingId: bookingId,
          bookingData: bookingData,
        ),
      ),
    );
  }

  Widget bookingCard(Map<String, dynamic> booking) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');
    final DateFormat timeFormat = DateFormat('hh:mm a');
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
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(height: 120),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return SizedBox();
        }

        final data = snapshot.data as Map<String, dynamic>;
        final userData = data['userData'];
        final serviceData = data['serviceData'];

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 4,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundImage:
                      NetworkImage(userData['profileImage'] ?? ''),
                      radius: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'] ?? 'User Name',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            booking['location']['local'] ?? 'Location',
                            style: TextStyle(color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // View Details button - Updated to show bottom sheet
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {
                          _showBookingDetailsBottomSheet(booking);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF060644),
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          textStyle: TextStyle(fontSize: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'View Details',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (serviceData != null)
                  Text(
                    serviceData['name'] ?? 'Service Name',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                Divider(height: 20, thickness: 1),
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: ${dateFormat.format(serviceDate)}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Text(
                            'Time: ${timeFormat.format(serviceDate)}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Text(
                            'Payment: ₹${booking['paymentAmount']} (${booking['paymentMode']})',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      // Show status text
                      Text(
                        booking['status'],
                        style: TextStyle(
                          color: booking['status'] == 'Pending'
                              ? Colors.orange
                              : booking['status'] == 'Confirmed'
                              ? Colors.blueGrey
                              : booking['status'] == 'Completed'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Show cancel reason if available
                if (booking['status'] == 'Cancelled' && booking['cancelReason'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Reason: ${booking['cancelReason']}',
                      style: TextStyle(color: Colors.red[700], fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(0xFF060644),
          labelColor: Color(0xFF060644),
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3.0,
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Check for expired bookings when the user manually refreshes
          await checkAndUpdateExpiredBookings();
          setState(() {}); // Refresh the UI
        },
        child: TabBarView(
          controller: _tabController,
          children:
          ['Pending', 'Confirmed', 'Completed', 'Cancelled'].map((status) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: fetchBookings(status),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No bookings found'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return bookingCard(snapshot.data![index]);
                  },
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}