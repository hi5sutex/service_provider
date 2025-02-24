import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class UserBooking extends StatelessWidget {
  String formatDate(Timestamp timestamp) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  String formatTime(Timestamp timestamp) {
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  Future<Map<String, dynamic>> fetchBookingDetails(String serviceId, String providerId) async {
    String serviceName = 'Loading...';
    String providerName = 'Loading...';
    String providerImage = 'https://via.placeholder.com/50';

    try {
      var serviceSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .get();
      if (serviceSnapshot.exists) {
        serviceName = serviceSnapshot.data()?['name'] ?? 'Unknown Service';
      }
    } catch (e) {
      print("Error fetching service: $e");
    }

    try {
      var providerSnapshot = await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .get();
      if (providerSnapshot.exists) {
        providerImage = providerSnapshot.data()?['profileImage'] ?? providerImage;
        providerName = providerSnapshot.data()?['name'] ?? 'Unknown Provider';
      }
    } catch (e) {
      print("Error fetching provider details: $e");
    }

    return {
      'serviceName': serviceName,
      'providerName': providerName,
      'providerImage': providerImage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmed Bookings', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search bookings...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.search),
              ),
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),

            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('userId', isEqualTo: currentUser?.uid)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      itemCount: 3, // Show 3 shimmer cards while loading
                      itemBuilder: (context, index) => ShimmerBookingCard(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://via.placeholder.com/200',
                            height: 200,
                          ),
                          Text(
                            'No Bookings Yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;

                      String formattedServiceDate = data['serviceDate'] != null
                          ? formatDate(data['serviceDate'] as Timestamp)
                          : 'Not specified';

                      String formattedBookingDate = data['bookingDate'] != null
                          ? formatDate(data['bookingDate'] as Timestamp)
                          : 'Not specified';

                      String serviceTime = data['serviceDate'] != null
                          ? formatTime(data['serviceDate'] as Timestamp)
                          : 'Not specified';

                      return FutureBuilder<Map<String, dynamic>>(
                        future: fetchBookingDetails(
                          data['serviceId'] ?? '',
                          data['providerId'] ?? '',
                        ),
                        builder: (context, detailsSnapshot) {
                          if (detailsSnapshot.connectionState == ConnectionState.waiting) {
                            return ShimmerBookingCard();
                          }

                          final details = detailsSnapshot.data ?? {
                            'serviceName': 'Unknown Service',
                            'providerName': 'Unknown Provider',
                            'providerImage': 'https://via.placeholder.com/50',
                          };

                          return BookingCard(
                            serviceName: details['serviceName'],
                            serviceDate: formattedServiceDate,
                            serviceTime: serviceTime,
                            bookingDate: formattedBookingDate,
                            providerName: details['providerName'],
                            providerImage: details['providerImage'],
                            location: data['location'] != null && data['location'] is Map
                                ? data['location']['local'] ?? 'Unknown Location'
                                : 'Unknown Location',
                            price: '\$${data['paymentAmount'] ?? '0'}',
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 45),
                backgroundColor: Color(0xFF060644),
              ),
              child: Text('Book New Service', style: TextStyle(fontSize: 14, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerBookingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200,
                height: 20,
                color: Colors.white,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Container(
                    width: 150,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Container(
                    width: 100,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Container(
                    width: 180,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        color: Colors.white,
                      ),
                      SizedBox(height: 4),
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Container(
                    width: 200,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: 6),
              Container(
                width: 80,
                height: 14,
                color: Colors.white,
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.white,
                  ),
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.white,
                  ),
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String serviceName;
  final String serviceDate;
  final String serviceTime;
  final String bookingDate;
  final String providerName;
  final String providerImage;
  final String location;
  final String price;

  BookingCard({
    required this.serviceName,
    required this.serviceDate,
    required this.serviceTime,
    required this.bookingDate,
    required this.providerName,
    required this.providerImage,
    required this.location,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serviceName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Service Date: $serviceDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Time: $serviceTime',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.event_note, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Booking Date: $bookingDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(providerImage),
                  radius: 20,
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(providerName,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                    ),
                    Text('Service Provider',
                        style: TextStyle(fontSize: 12, color: Colors.grey)
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'Price: $price',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF060644)),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text('View Details', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Reschedule', style: TextStyle(color: Color(0xFF060644), fontSize: 12)),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}