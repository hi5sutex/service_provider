import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_category_card.dart';
import 'booking_utils.dart';
import 'booking_list_screen.dart';

class ProviderBooking extends StatefulWidget {
  @override
  _ProviderBookingState createState() => _ProviderBookingState();
}

class _ProviderBookingState extends State<ProviderBooking> {
  final String? providerId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    checkAndUpdateExpiredBookings(providerId);
  }

  void _navigateToCategoryScreen(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingListScreen(
          category: category,
          providerId: providerId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await checkAndUpdateExpiredBookings(providerId);
          setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<Map<String, int>>(
            stream: fetchBookingCounts(providerId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final counts = snapshot.data ??
                  {'Pending': 0, 'Confirmed': 0, 'Ongoing': 0, 'Completed': 0, 'Cancelled': 0};
              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  BookingCategoryCard(
                    category: 'Pending',
                    count: counts['Pending']!,
                    icon: Icons.hourglass_empty,
                    color: Colors.orange,
                    onTap: () => _navigateToCategoryScreen('Pending'),
                  ),
                  BookingCategoryCard(
                    category: 'Confirmed',
                    count: counts['Confirmed']!,
                    icon: Icons.check_circle_outline,
                    color: Colors.blueGrey,
                    onTap: () => _navigateToCategoryScreen('Confirmed'),
                  ),
                  BookingCategoryCard(
                    category: 'Ongoing',
                    count: counts['Ongoing']!,
                    icon: Icons.play_circle_outline,
                    color: Colors.purple,
                    onTap: () => _navigateToCategoryScreen('Ongoing'),
                  ),
                  BookingCategoryCard(
                    category: 'Completed',
                    count: counts['Completed']!,
                    icon: Icons.done_all,
                    color: Colors.green,
                    onTap: () => _navigateToCategoryScreen('Completed'),
                  ),
                  BookingCategoryCard(
                    category: 'Cancelled',
                    count: counts['Cancelled']!,
                    icon: Icons.cancel,
                    color: Colors.red,
                    onTap: () => _navigateToCategoryScreen('Cancelled'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}