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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled successfully')));
  }

  Future<void> _confirmBooking(BuildContext context, String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Confirmed',
      'confirmedAt': Timestamp.now(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking confirmed successfully')));
  }

  Future<void> _startService(BuildContext context, String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Ongoing',
      'ongoingAt': Timestamp.now(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service started successfully')));
  }

  void _showCancelConfirmationDialog(BuildContext context) {
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
                decoration: const InputDecoration(labelText: 'Reason for cancellation', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelBooking(context, booking['bId'], reasonController.text);
              },
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (booking['status'] == 'Pending' || booking['status'] == 'Confirmed' || booking['status'] == 'Ongoing')
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _showCancelConfirmationDialog(context); // Show cancel dialog without popping immediately
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
              ),
            ),
          if (booking['status'] == 'Pending' || booking['status'] == 'Confirmed' || booking['status'] == 'Ongoing') const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (booking['status'] == 'Pending') {
                  _confirmBooking(context, booking['bId']);
                  Navigator.pop(context); // Close bottom sheet after action
                } else if (booking['status'] == 'Confirmed') {
                  _startService(context, booking['bId']);
                  Navigator.pop(context); // Close bottom sheet after action
                } else if (booking['status'] == 'Ongoing') {
                  // Navigate to LiveTrackingPage without popping immediately
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveTrackingPage(
                        bookingId: booking['bId'],
                        bookingData: booking,
                      ),
                    ),
                  ).then((_) => Navigator.pop(context)); // Close bottom sheet after returning
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF060644),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                booking['status'] == 'Pending'
                    ? 'Confirm Booking'
                    : booking['status'] == 'Confirmed'
                    ? 'Start Service'
                    : booking['status'] == 'Ongoing'
                    ? 'Start Tracking'
                    : 'Close',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}