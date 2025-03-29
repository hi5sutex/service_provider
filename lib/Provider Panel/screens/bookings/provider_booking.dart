import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_category_card.dart';
import 'booking_utils.dart';
import 'booking_list_screen.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';

class ProviderBooking extends StatefulWidget {
  const ProviderBooking({Key? key}) : super(key: key);

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
    final screenWidth = MediaQuery.of(context).size.width;

    return Theme(
      data: ProviderTheme.themeData,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: ProviderTheme.primaryGradient, // Gradient background
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Icon(
              Icons.event_note_rounded, // Normal, static calendar icon
              color: ProviderTheme.accentColor, // Gold accent
              size: 28,
            ),
          ),
          title: const Text('Bookings'), // Title after the leading icon
          centerTitle: false, // Align title to the left after the icon
          elevation: 4, // Depth with shadow
          shadowColor: ProviderTheme.shadowColor.withOpacity(0.4),
        ),
        body: RefreshIndicator(
          color: ProviderTheme.accentColor,
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
                  return const Center(child: CircularProgressIndicator());
                }
                final counts = snapshot.data ??
                    {'Pending': 0, 'Confirmed': 0, 'Ongoing': 0, 'Completed': 0, 'Cancelled': 0};
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: (screenWidth / 2 - 32) / 160,
                  children: [
                    BookingCategoryCard(
                      category: 'Pending',
                      count: counts['Pending']!,
                      icon: Icons.hourglass_empty,
                      color: ProviderTheme.pendingColor,
                      onTap: () => _navigateToCategoryScreen('Pending'),
                    ),
                    BookingCategoryCard(
                      category: 'Confirmed',
                      count: counts['Confirmed']!,
                      icon: Icons.check_circle_outline,
                      color: ProviderTheme.confirmedColor,
                      onTap: () => _navigateToCategoryScreen('Confirmed'),
                    ),
                    BookingCategoryCard(
                      category: 'Ongoing',
                      count: counts['Ongoing']!,
                      icon: Icons.play_circle_outline,
                      color: ProviderTheme.ongoingColor,
                      onTap: () => _navigateToCategoryScreen('Ongoing'),
                    ),
                    BookingCategoryCard(
                      category: 'Completed',
                      count: counts['Completed']!,
                      icon: Icons.done_all,
                      color: ProviderTheme.completedColor,
                      onTap: () => _navigateToCategoryScreen('Completed'),
                    ),
                    BookingCategoryCard(
                      category: 'Cancelled',
                      count: counts['Cancelled']!,
                      icon: Icons.cancel,
                      color: ProviderTheme.canceledColor,
                      onTap: () => _navigateToCategoryScreen('Cancelled'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}