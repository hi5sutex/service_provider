import 'package:flutter/material.dart';
import 'booking_list.dart';
import 'booking_utils.dart';

class BookingTabView extends StatelessWidget {
  final TabController tabController;
  final String providerId;

  const BookingTabView({required this.tabController, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: ['Pending', 'Confirmed', 'Completed', 'Cancelled'].map((status) {
        return BookingList(
          stream: fetchBookings(status, providerId),
        );
      }).toList(),
    );
  }
}