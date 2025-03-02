import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'booking_actions.dart';

void showBookingDetailsBottomSheet(BuildContext context, Map<String, dynamic> booking) {
  final DateFormat dateFormat = DateFormat('dd MMM, yyyy');
  final DateFormat timeFormat = DateFormat('h:mm a');
  final DateTime serviceDate = (booking['serviceDate'] as Timestamp).toDate();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (BuildContext context) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: Future.wait([
          FirebaseFirestore.instance.collection('users').doc(booking['userId']).get().then((doc) => doc.data()),
          FirebaseFirestore.instance.collection('services').doc(booking['serviceId']).get().then((doc) => doc.data())
        ]).then((results) => {'userData': results[0], 'serviceData': results[1]}),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(height: MediaQuery.of(context).size.height * 0.6, padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Container(height: MediaQuery.of(context).size.height * 0.3, child: Center(child: Text("No details available")));
          }

          final data = snapshot.data as Map<String, dynamic>;
          final userData = data['userData'];
          final serviceData = data['serviceData'];

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(alignment: Alignment.topRight, child: IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Order status", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(serviceData['name'] ?? 'Service Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(radius: 12, backgroundImage: NetworkImage(userData['profileImage'] ?? '')),
                          SizedBox(width: 8),
                          Text(userData['name'] ?? 'User Name', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
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
                      Text("Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.grey),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(timeFormat.format(serviceDate), style: TextStyle(fontWeight: FontWeight.w500)),
                              Text("Service time", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: Colors.grey),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booking['location']['local'] ?? 'Location', style: TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 2),
                                Text("Location", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateFormat.format(serviceDate), style: TextStyle(fontWeight: FontWeight.w500)),
                              Text("Date", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.grey),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("₹${booking['paymentAmount']}", style: TextStyle(fontWeight: FontWeight.w500)),
                              Text("Price", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Spacer(),
                BookingActionButtons(booking: booking),
              ],
            ),
          );
        },
      );
    },
  );
}