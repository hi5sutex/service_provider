import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'booking_details_sheet.dart';

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingCard({required this.booking});

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
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(backgroundImage: NetworkImage(userData['profileImage'] ?? ''), radius: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userData['name'] ?? 'User Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text(booking['location']['local'] ?? 'Location', style: TextStyle(color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => showBookingDetailsBottomSheet(context, booking),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF060644),
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          textStyle: TextStyle(fontSize: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text('View Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (serviceData != null) Text(serviceData['name'] ?? 'Service Name', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                Divider(height: 20, thickness: 1),
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${dateFormat.format(serviceDate)}', style: TextStyle(color: Colors.grey[700])),
                          Text('Time: ${timeFormat.format(serviceDate)}', style: TextStyle(color: Colors.grey[700])),
                          Text('Payment: ₹${booking['paymentAmount']} (${booking['paymentMode']})', style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                      Text(
                        booking['status'],
                        style: TextStyle(
                          color: booking['status'] == 'Pending'
                              ? Colors.orange
                              : booking['status'] == 'Confirmed'
                              ? Colors.blueGrey
                              : booking['status'] == 'Ongoing'
                              ? Colors.purple // Updated for Ongoing
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
                    child: Text('Reason: ${booking['cancelReason']}', style: TextStyle(color: Colors.red[700], fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}