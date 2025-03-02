import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_tab_view.dart';
import 'booking_utils.dart';

class ProviderBooking extends StatefulWidget {
  @override
  _ProviderBookingState createState() => _ProviderBookingState();
}

class _ProviderBookingState extends State<ProviderBooking> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? providerId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    checkAndUpdateExpiredBookings(providerId); // From booking_utils.dart
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(0xFF060644),
          labelColor: Color(0xFF060644),
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3.0,
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await checkAndUpdateExpiredBookings(providerId);
          setState(() {});
        },
        child: BookingTabView(tabController: _tabController, providerId: providerId!),
      ),
    );
  }
}