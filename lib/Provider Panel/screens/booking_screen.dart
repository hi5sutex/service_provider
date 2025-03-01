import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:service_provider/Provider%20Panel/screens/live_tracking.dart'; // Ensure this path is correct
import 'package:shimmer/shimmer.dart';

class ProviderBooking extends StatefulWidget {
  @override
  _ProviderBookingState createState() => _ProviderBookingState();
}

class _ProviderBookingState extends State<ProviderBooking> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? providerId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    checkAndUpdateExpiredBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> checkAndUpdateExpiredBookings() async {
    final now = DateTime.now();
    final bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .where('status', whereIn: ['Pending', 'Ongoing'])
        .get();

    final batch = FirebaseFirestore.instance.batch();
    bool hasBatchOperations = false;

    for (var doc in bookingsSnapshot.docs) {
      final bookingData = doc.data();
      final serviceDate = (bookingData['serviceDate'] as Timestamp).toDate();

      if (serviceDate.isBefore(now)) {
        batch.update(doc.reference, {
          'status': 'Cancelled',
          'cancelReason': 'Expired booking',
          'cancelledAt': Timestamp.now(),
        });
        hasBatchOperations = true;
      }
    }

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

      if (status == 'Pending' || status == 'Ongoing') {
        bookings.sort((a, b) {
          DateTime aDate = (a['serviceDate'] as Timestamp).toDate();
          DateTime bDate = (b['serviceDate'] as Timestamp).toDate();
          DateTime aJustDate = DateTime(aDate.year, aDate.month, aDate.day);
          DateTime bJustDate = DateTime(bDate.year, bDate.month, bDate.day);
          DateTime nowJustDate = DateTime(now.year, now.month, now.day);

          int aDayDiff = aJustDate.difference(nowJustDate).inDays;
          int bDayDiff = bJustDate.difference(nowJustDate).inDays;

          if (aDayDiff < 0 && bDayDiff >= 0) return 1;
          if (bDayDiff < 0 && aDayDiff >= 0) return -1;

          if (aDayDiff != bDayDiff) {
            return aDayDiff.abs() - bDayDiff.abs();
          }

          return aDate.compareTo(bDate);
        });
      } else {
        bookings.sort((a, b) {
          DateTime aDate = (a['serviceDate'] as Timestamp).toDate();
          DateTime bDate = (b['serviceDate'] as Timestamp).toDate();
          return bDate.compareTo(aDate);
        });
      }

      return bookings;
    });
  }

  void _showBookingDetailsBottomSheet(Map<String, dynamic> booking) {
    final DateFormat dateFormat = DateFormat('dd MMM, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');
    final DateTime serviceDate = (booking['serviceDate'] as Timestamp).toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: Future.wait([
            FirebaseFirestore.instance.collection('users').doc(booking['userId']).get().then((doc) => doc.data()),
            FirebaseFirestore.instance.collection('services').doc(booking['serviceId']).get().then((doc) => doc.data())
          ]).then((results) {
            return {'userData': results[0], 'serviceData': results[1]};
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.all(20),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.3,
                child: const Center(child: Text("No details available")),
              );
            }

            final data = snapshot.data as Map<String, dynamic>;
            final userData = data['userData'];
            final serviceData = data['serviceData'];

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Order status",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(userData['profileImage'] ?? ''),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userData['name'] ?? 'User Name',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
                        const Text(
                          "Details",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.grey),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  timeFormat.format(serviceDate),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  "Service time",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking['location']['local'] ?? 'Location',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateFormat.format(serviceDate),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  "Date",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.attach_money, color: Colors.grey),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "₹${booking['paymentAmount']}",
                                  style: const TextStyle(fontWeight: FontWeight.w500),
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
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        if (booking['status'] == 'Pending' || booking['status'] == 'Ongoing')
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showCancelConfirmationDialog(booking);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel order', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        if (booking['status'] == 'Pending' || booking['status'] == 'Ongoing')
                          const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (booking['status'] == 'Pending') {
                                _confirmBooking(booking['bId']);
                              } else if (booking['status'] == 'Ongoing') {
                                _navigateToLiveTracking(booking);
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF060644),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              booking['status'] == 'Pending'
                                  ? 'Confirm Booking'
                                  : booking['status'] == 'Ongoing'
                                  ? 'Complete Order'
                                  : 'Close',
                              style: const TextStyle(color: Colors.white),
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

  void _showCancelConfirmationDialog(Map<String, dynamic> booking) {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to cancel this booking?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
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
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelBooking(booking['bId'], reasonController.text);
              },
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelBooking(String bookingId, String reason) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Cancelled',
      'cancelReason': reason.isEmpty ? 'Cancelled by provider' : reason,
      'cancelledAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking cancelled successfully')),
    );
  }

  Future<void> _confirmBooking(String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Ongoing',
      'confirmedAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking confirmed and moved to Ongoing')),
    );
  }

  void _navigateToLiveTracking(Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTrackingPage(
          bookingId: booking['bId'],
          bookingData: booking,
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
        FirebaseFirestore.instance.collection('users').doc(booking['userId']).get().then((doc) => doc.data()),
        FirebaseFirestore.instance.collection('services').doc(booking['serviceId']).get().then((doc) => doc.data())
      ]).then((results) {
        return {'userData': results[0], 'serviceData': results[1]};
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(height: 120),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }

        final data = snapshot.data as Map<String, dynamic>;
        final userData = data['userData'];
        final serviceData = data['serviceData'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'] ?? 'User Name',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking['location']['local'] ?? 'Location',
                            style: TextStyle(color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {
                          if (booking['status'] == 'Ongoing') {
                            _navigateToLiveTracking(booking); // Direct navigation for Ongoing
                          } else {
                            _showBookingDetailsBottomSheet(booking); // Bottom sheet for others
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF060644),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(fontSize: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (serviceData != null)
                  Text(
                    serviceData['name'] ?? 'Service Name',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                const Divider(height: 20, thickness: 1),
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
                      Text(
                        booking['status'],
                        style: TextStyle(
                          color: booking['status'] == 'Pending'
                              ? Colors.orange
                              : booking['status'] == 'Ongoing'
                              ? Colors.blue
                              : booking['status'] == 'Completed'
                              ? Colors.green
                              : Colors.red,
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
        title: const Text('Bookings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF060644),
          labelColor: const Color(0xFF060644),
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await checkAndUpdateExpiredBookings();
          setState(() {});
        },
        child: TabBarView(
          controller: _tabController,
          children: ['Pending', 'Ongoing', 'Completed', 'Cancelled'].map((status) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: fetchBookings(status),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No bookings found'));
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