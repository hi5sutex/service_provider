import 'package:flutter/material.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'package:service_provider/Provider Panel/screens/bookings/booking_list.dart';
import 'booking_utils.dart';

class BookingListScreen extends StatelessWidget {
  final String category;
  final String providerId;

  const BookingListScreen({required this.category, required this.providerId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProviderTheme.themeData,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$category Bookings'),
        ),
        body: BookingList(
          stream: fetchBookings(category, providerId),
        ),
      ),
    );
  }
}