import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:service_provider/Admin%20Panel/screens/PendingServicesScreen.dart';
import 'package:service_provider/Admin%20Panel/screens/bookings_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/payments_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/users_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/providers_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/services_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/manage_categories.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> fetchDashboardData() async {
    final totalUsers = await FirebaseFirestore.instance.collection('users').get();
    final totalProviders = await FirebaseFirestore.instance.collection('providers').get();
    final totalBookings = await FirebaseFirestore.instance.collection('bookings').get();
    final pendingServices = await FirebaseFirestore.instance.collection('pending_services').get();
    final completedBookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: 'Completed')
        .get();
    final payments = await FirebaseFirestore.instance.collection('payments').get();
    final services = await FirebaseFirestore.instance.collection('services').get();
    final categories = await FirebaseFirestore.instance.collection('categories').get();

    double totalRevenue = payments.docs.fold(0.0, (sum, doc) => sum + (doc['amount'] ?? 0));

    return {
      'totalUsers': totalUsers.docs.length,
      'totalProviders': totalProviders.docs.length,
      'totalBookings': totalBookings.docs.length,
      'completedBookings': completedBookings.docs.length,
      'totalRevenue': totalRevenue,
      'totalServices': services.docs.length,
      'totalCategories': categories.docs.length,
      'totalPendingServices': pendingServices.docs.length,
    };
  }

  void navigateOrShowMessage(BuildContext context, String title, Widget Function() screenBuilder) {
    final allowedItems = [
      'Users',
      'Providers',
      'Services',
      'Bookings',
      'Revenue',
      'Manage Categories',
    ];
    if (allowedItems.contains(title)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screenBuilder()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You don't have permission to access $title.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC), // Light gray background
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerEffect();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available.'));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stat Cards - Paired logically
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Users", "${data['totalUsers']}", Icons.group, Colors.blue, context, () => navigateOrShowMessage(context, "Users", () => UsersScreen()))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Providers", "${data['totalProviders']}", Icons.work, Colors.green, context, () => navigateOrShowMessage(context, "Providers", () => ProvidersScreen()))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Services", "${data['totalServices']}", Icons.build, Colors.teal, context, () => navigateOrShowMessage(context, "Services", () => ServicesScreen()))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Pending", "${data['totalPendingServices']}", Icons.hourglass_empty, Colors.red, context, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PendingServicesScreen())))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Bookings", "${data['totalBookings']}", Icons.event, Colors.orange, context, () => navigateOrShowMessage(context, "Bookings", () => BookingsScreen()))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Completed", "${data['completedBookings']}", Icons.check_circle, Colors.indigo, context, () => navigateOrShowMessage(context, "Bookings", () => BookingsScreen()))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Revenue", "\$${data['totalRevenue'].toStringAsFixed(2)}", Icons.attach_money, Colors.purple, context, () => navigateOrShowMessage(context, "Revenue", () => PaymentsScreen()))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Categories", "${data['totalCategories']}", Icons.category, Colors.deepOrange, context, () => navigateOrShowMessage(context, "Manage Categories", () => ManageCategoriesScreen()))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer for Stat Cards
            Row(
              children: [
                Expanded(child: _buildShimmerCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerCard()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildShimmerCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerCard()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildShimmerCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerCard()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildShimmerCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerCard()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      height: 80, // Matches the approximate height of stat cards
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}