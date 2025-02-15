import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Admin%20Panel/screens/PendingServicesScreen.dart';
import 'package:service_provider/Admin%20Panel/screens/bookings_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/payments_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/users_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/providers_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/services_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/manage_categories.dart'; // Import ManageCategories

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
      'totalCategories': categories.docs.length, // Added categories count
      'totalPendingServices': pendingServices.docs.length,
    };
  }

  void navigateOrShowMessage(BuildContext context, String title, Widget Function() screenBuilder) {
    final allowedItems = ['Users', 'Providers', 'Services', 'Bookings', 'Revenue', 'Manage Categories'];
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available.'));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDashboardCard(
                        title: 'Users',
                        value: '${data['totalUsers']}',
                        color: Colors.blue.shade100,
                        onTap: () => navigateOrShowMessage(context, 'Users', () => UsersScreen()),
                      ),
                      _buildDashboardCard(
                        title: 'Providers',
                        value: '${data['totalProviders']}',
                        color: Colors.green.shade100,
                        onTap: () => navigateOrShowMessage(context, 'Providers', () => ProvidersScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDashboardCard(
                        title: 'Total Bookings',
                        value: '${data['totalBookings']}',
                        color: Colors.orange.shade100,
                        onTap: () => navigateOrShowMessage(context, 'Bookings', () => BookingsScreen()),
                      ),
                      _buildDashboardCard(
                        title: 'Completed Bookings',
                        value: '${data['completedBookings']}',
                        color: Colors.purple.shade100,
                        onTap: () => navigateOrShowMessage(context, 'Bookings', () => BookingsScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDashboardCard(
                        title: 'Revenue',
                        value: '\$${data['totalRevenue'].toStringAsFixed(2)}',
                        color: Colors.indigo.shade100,
                        onTap: () => navigateOrShowMessage(context, 'Revenue', () => PaymentsScreen()),
                      ),
                      _buildDashboardCard(
                        title: 'Services',
                        value: '${data['totalServices']}',
                        color: Colors.teal.shade100,
                        onTap: () => navigateOrShowMessage(context, 'Services', () => ServicesScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDashboardCard(
                        title: 'Manage Categories',
                        value: '${data['totalCategories']}', // Display total categories
                        color: Colors.deepOrange.shade100,
                        onTap: () =>
                            navigateOrShowMessage(context, 'Manage Categories', () => ManageCategoriesScreen()),
                      ),
                      _buildDashboardCard(
                        title: 'Pending Services',
                        value: '${data['totalPendingServices']}',
                        color: Colors.red.shade100,
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => PendingServicesScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickActionCard(
                        icon: Icons.add,
                        label: 'Add Service',
                        onTap: () {
                          // Navigate to Add Service Screen
                        },
                      ),
                      _buildQuickActionCard(
                        icon: Icons.category,
                        label: 'Manage Categories',
                        onTap: () => navigateOrShowMessage(context, 'Manage Categories', () => ManageCategoriesScreen()),
                      ),
                      _buildQuickActionCard(
                        icon: Icons.analytics,
                        label: 'Analytics',
                        onTap: () {
                          // Navigate to Analytics Screen
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: Color(0xFF060644), size: 28),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
