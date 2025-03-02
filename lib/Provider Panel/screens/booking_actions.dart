import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Provider%20Panel/screens/live_tracking.dart';

class BookingActionButtons extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingActionButtons({required this.booking});

  Future<void> _cancelBooking(BuildContext context, String bookingId, String reason) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Cancelled',
      'cancelReason': reason.isEmpty ? 'Cancelled by provider' : reason,
      'cancelledAt': Timestamp.now(),
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking cancelled successfully')));
  }

  Future<void> _confirmBooking(BuildContext context, String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Confirmed',
      'confirmedAt': Timestamp.now(),
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking confirmed successfully')));
  }

  Future<void> _completeBooking(BuildContext context, String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Completed',
      'completedAt': Timestamp.now(),
    });

    DocumentSnapshot bookingDoc = await FirebaseFirestore.instance.collection('bookings').doc(bookingId).get();
    Map<String, dynamic> bookingData = bookingDoc.data() as Map<String, dynamic>;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Service marked as completed')));
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LiveTrackingPage(bookingId: bookingId, bookingData: bookingData)),
    );
  }

  void _showCancelConfirmationDialog(BuildContext context) {
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
                decoration: InputDecoration(labelText: 'Reason for cancellation', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('No')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelBooking(context, booking['bId'], reasonController.text);
              },
              child: Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          if (booking['status'] == 'Pending' || booking['status'] == 'Confirmed')
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showCancelConfirmationDialog(context);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Cancel order', style: TextStyle(color: Colors.red)),
              ),
            ),
          if (booking['status'] == 'Pending' || booking['status'] == 'Confirmed') SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (booking['status'] == 'Pending') {
                  _confirmBooking(context, booking['bId']);
                } else if (booking['status'] == 'Confirmed') {
                  _completeBooking(context, booking['bId']);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF060644),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    );
  }
}