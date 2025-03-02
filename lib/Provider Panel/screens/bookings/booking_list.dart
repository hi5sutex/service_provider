import 'package:flutter/material.dart';
import 'booking_card.dart';

class BookingList extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> stream;

  const BookingList({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
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
            return BookingCard(booking: snapshot.data![index]);
          },
        );
      },
    );
  }
}