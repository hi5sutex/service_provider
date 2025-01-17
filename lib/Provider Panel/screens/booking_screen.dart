import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Provider Panel/screens/booking_detail_screen.dart';
import 'package:intl/intl.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> fetchBookings(String status) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: status)
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'bId': doc.id,
                })
            .toList());
  }

  Future<Map<String, dynamic>?> fetchServiceDetails(String serviceId) async {
    final serviceDoc = await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .get();
    return serviceDoc.data();
  }

  Widget bookingCard(Map<String, dynamic> booking) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');

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

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailScreen(booking: booking),
              ),
            );
          },
          child: Card(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'] ?? 'User Name',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            booking['location']['local'] ?? 'Location',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Spacer(),
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: booking['status'] == 'Pending'
                                ? Colors.orange
                                : Colors.green,
                            // Example based on status
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            booking['status'],
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
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
                              'Service Date: ${dateFormat.format((booking['serviceDate'] as Timestamp).toDate())}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            Text(
                              'Payment: ₹${booking['paymentAmount']} (${booking['paymentMode']})',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        if (booking['status'] == 'Pending')
                          Text('Pending', style: TextStyle(color: Colors.grey)),
                        if (booking['status'] == 'Confirmed')
                          Text('Confirmed',
                              style: TextStyle(color: Colors.blueGrey)),
                        if (booking['status'] == 'Completed')
                          Text('Completed',
                              style: TextStyle(color: Colors.green)),
                        if (booking['status'] == 'Cancelled')
                          Text('Cancelled',
                              style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  )
                ],
              ),
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
          // Change this color as per your theme
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
      body: TabBarView(
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
    );
  }
}
