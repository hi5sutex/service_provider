import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'providers_screen.dart';
import 'services_screen.dart';
import 'bookings_screen.dart';
import 'payments_screen.dart';
import 'analytics_screen.dart';
import 'notifications_screen.dart';
import 'manage_categories.dart'; // Import ManageCategories page

class MainAdminPanel extends StatefulWidget {
  @override
  _MainAdminPanelState createState() => _MainAdminPanelState();
}

class _MainAdminPanelState extends State<MainAdminPanel> {
  int _selectedIndex = 0;
  String? adminName, adminEmail, adminProfileUrl;
  Map<String, bool> permissions = {};

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data()!;
        setState(() {
          adminName = data['name'] ?? 'Admin';
          adminEmail = data['email'] ?? 'admin@example.com';
          adminProfileUrl = data['profileImage'];
          permissions = Map<String, bool>.from(data['permissions'] ?? {});
        });
      }
    } catch (e) {
      print('Error fetching admin data: $e');
    }
  }

  final List<Map<String, dynamic>> _pages = [
    {'title': 'Dashboard', 'widget': DashboardScreen()},
    {'title': 'Users', 'widget': UsersScreen()},
    {'title': 'Providers', 'widget': ProvidersScreen()},
    {'title': 'Services', 'widget': ServicesScreen()},
    {'title': 'Bookings', 'widget': BookingsScreen()},
    {'title': 'Payments', 'widget': PaymentsScreen()},
    {'title': 'Analytics', 'widget': AnalyticsScreen()},
    {'title': 'Notifications', 'widget': NotificationsScreen()},
    {'title': 'Manage Categories', 'widget': ManageCategoriesScreen()}, // Added Manage Categories
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
    Navigator.pop(context); // Close the drawer
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_selectedIndex]['title']),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            if (adminName != null && adminEmail != null)
              UserAccountsDrawerHeader(
                accountName: Text(adminName!),
                accountEmail: Text(adminEmail!),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(
                    adminProfileUrl ?? 'https://avatar.iran.liara.run/public',
                  ),
                ),
              ),
            _buildDrawerItem(Icons.dashboard_outlined, 'Dashboard', 0),
            if (permissions['viewUsers'] ?? false)
              _buildDrawerItem(Icons.people_outline, 'Users', 1),
            if (permissions['viewProviders'] ?? false)
              _buildDrawerItem(Icons.business_outlined, 'Providers', 2),
            if (permissions['viewServices'] ?? false)
              _buildDrawerItem(Icons.design_services_outlined, 'Services', 3),
            if (permissions['viewBookings'] ?? false)
              _buildDrawerItem(Icons.book_online_outlined, 'Bookings', 4),
            if (permissions['viewPayments'] ?? false)
              _buildDrawerItem(Icons.payment_outlined, 'Payments', 5),
            if (permissions['viewAnalytics'] ?? false)
              _buildDrawerItem(Icons.analytics_outlined, 'Analytics', 6),
            if (permissions['sendNotifications'] ?? false)
              _buildDrawerItem(Icons.notifications_outlined, 'Notifications', 7),
            if (permissions['manageCategories'] ?? true)
              _buildDrawerItem(Icons.category_outlined, 'Manage Categories', 8), // Drawer Item
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex]['widget'], // Directly display the selected widget
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.grey.shade300,
      onTap: () => _onItemTapped(index),
    );
  }
}
