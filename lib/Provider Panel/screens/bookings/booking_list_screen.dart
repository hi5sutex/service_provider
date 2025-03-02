import 'package:flutter/material.dart';
import 'booking_list.dart';
import 'booking_utils.dart';

class BookingListScreen extends StatelessWidget {
  final String category;
  final String providerId;

  const BookingListScreen({required this.category, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Bookings'),
      ),
      body: BookingList(
        stream: fetchBookings(category, providerId),
      ),
    );
  }
}