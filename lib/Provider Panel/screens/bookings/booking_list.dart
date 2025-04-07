import 'package:flutter/material.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'booking_card.dart';

class BookingList extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> stream;

  const BookingList({required this.stream, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No bookings found',
              style: ProviderTheme.themeData.textTheme.bodyLarge?.copyWith(
                color: ProviderTheme.secondaryTextColor,
                fontSize: 18,
              ),
            ),
          );
        }
        return ListView(
          // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Consistent padding
          children: snapshot.data!.map((booking) => BookingCard(booking: booking)).toList(),
        );
        // return ListView.builder(
        //   itemCount: snapshot.data!.length,
        //   itemBuilder: (context, index) {
        //     return BookingCard(booking: snapshot.data![index]);
        //   },
       // );
      },
    );
  }
}