import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'package:service_provider/Provider%20Panel/screens/live_tracking.dart';


class BookingActionButtons extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingActionButtons({required this.booking, Key? key}) : super(key: key);

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
          title: Text(
            'Cancel Booking',
            style: ProviderTheme.themeData.textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to cancel this booking?',
                style: ProviderTheme.themeData.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for cancellation',
                  border: ProviderTheme.themeData.inputDecorationTheme.border,
                  focusedBorder: ProviderTheme.themeData.inputDecorationTheme.focusedBorder,
                  labelStyle: ProviderTheme.themeData.inputDecorationTheme.labelStyle,
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'No',
                style: ProviderTheme.themeData.textTheme.labelLarge?.copyWith(
                  color: ProviderTheme.secondaryTextColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelBooking(context, booking['bId'], reasonController.text);
              },
              child: Text(
                'Yes, Cancel',
                style: ProviderTheme.themeData.textTheme.labelLarge?.copyWith(
                  color: ProviderTheme.errorTextColor,
                ),
              ),
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
                onPressed: () => _showCancelConfirmationDialog(context),
                style: ProviderTheme.themeData.outlinedButtonTheme.style?.copyWith(
                  side: MaterialStateProperty.all(const BorderSide(color: ProviderTheme.canceledColor)),
                  foregroundColor: MaterialStateProperty.all(ProviderTheme.canceledColor),
                ),
                child: const Text('Cancel'),
              ),
            ),
          if (booking['status'] == 'Pending' || booking['status'] == 'Confirmed' || booking['status'] == 'Ongoing')
            const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (booking['status'] == 'Pending') {
                  _confirmBooking(context, booking['bId']);
                  Navigator.pop(context);
                } else if (booking['status'] == 'Confirmed') {
                  _startService(context, booking['bId']);
                  Navigator.pop(context);
                } else if (booking['status'] == 'Ongoing') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveTrackingPage(
                        bookingId: booking['bId'],
                        bookingData: booking,
                      ),
                    ),
                  ).then((_) => Navigator.pop(context));
                }
              },
              style: ProviderTheme.themeData.elevatedButtonTheme.style,
              child: Text(
                booking['status'] == 'Pending'
                    ? 'Confirm'
                    : booking['status'] == 'Confirmed'
                    ? 'Start Service'
                    : booking['status'] == 'Ongoing'
                    ? 'Start Tracking'
                    : 'Close',
              ),
            ),
          ),
        ],
      ),
    );
  }
}