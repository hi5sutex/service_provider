import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_provider/Admin Panel/screens/dashboard_screen.dart';
import 'package:service_provider/Admin Panel/screens/users_screen.dart';
import 'package:service_provider/Admin Panel/screens/providers_screen.dart';
import 'package:service_provider/Admin Panel/screens/services_screen.dart';
import 'package:service_provider/Admin Panel/screens/bookings_screen.dart';
import 'package:service_provider/Admin Panel/screens/payments_screen.dart';
import 'package:service_provider/Admin Panel/screens/analytics_screen.dart';
import 'package:service_provider/Admin Panel/screens/notifications_screen.dart';

class MainAdminPanel extends StatefulWidget {
  @override
  _MainAdminPanelState createState() => _MainAdminPanelState();
}

class _MainAdminPanelState extends State<MainAdminPanel> {
  int _selectedIndex = 0;
  String _headerTitle = 'Dashboard';
  String? adminName;
  String? adminEmail;
  String? adminProfileUrl;

  bool viewUsers = false;
  bool viewProviders = false;
  bool viewServices = false;
  bool viewBookings = false;
  bool viewPayments = false;
  bool viewAnalytics = false;
  bool sendNotifications = false;

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
          viewUsers = data['permissions']['viewUsers'] ?? false;
          viewProviders = data['permissions']['viewProviders'] ?? false;
          viewServices = data['permissions']['viewServices'] ?? false;
          viewBookings = data['permissions']['viewBookings'] ?? false;
          viewPayments = data['permissions']['viewPayments'] ?? false;
          viewAnalytics = data['permissions']['viewAnalytics'] ?? false;
          sendNotifications = data['permissions']['sendNotifications'] ?? false;
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
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _headerTitle = _pages[index]['title'];
    });
    Navigator.pop(context); // Close drawer on selection
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Redirect to login page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_headerTitle),
        centerTitle: false,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            if (adminName != null && adminEmail != null)
              UserAccountsDrawerHeader(
                accountName: Text(adminName!),
                accountEmail: Text(adminEmail!),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  backgroundImage: NetworkImage(
                    adminProfileUrl ??
                        'https://avatar.iran.liara.run/public',
                  ),
                ),
                // currentAccountPictureSize: Size(80, 80),
              ),
            _buildDrawerItem(Icons.dashboard_outlined, 'Dashboard', 0),
            if (viewUsers) _buildDrawerItem(Icons.people_outline, 'Users', 1),
            if (viewProviders)
              _buildDrawerItem(Icons.business_outlined, 'Providers', 2),
            if (viewServices)
              _buildDrawerItem(Icons.design_services_outlined, 'Services', 3),
            if (viewBookings)
              _buildDrawerItem(Icons.book_online_outlined, 'Bookings', 4),
            if (viewPayments)
              _buildDrawerItem(Icons.payment_outlined, 'Payments', 5),
            if (viewAnalytics)
              _buildDrawerItem(Icons.analytics_outlined, 'Analytics', 6),
            if (sendNotifications)
              _buildDrawerItem(
                  Icons.notifications_outlined, 'Notifications', 7),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        child: _pages[_selectedIndex]['widget'],
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => _onItemTapped(index),
    );
  }
}

class ProvidersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Providers Screen'));
  }
}

class ServicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Services Screen'));
  }
}

class BookingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Bookings Screen'));
  }
}

class PaymentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Payments Screen'));
  }
}

class AnalyticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Analytics Screen'));
  }
}

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Notifications Screen'));
  }
}
