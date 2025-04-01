import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/user_login.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'providers_screen.dart';
import 'services_screen.dart';
import 'bookings_screen.dart';
import 'payments_screen.dart';
import 'analytics_screen.dart';
import 'notifications_screen.dart';
import 'manage_categories.dart';
import 'admin_theme.dart'; // Import your theme file

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
    //{'title': 'Payments', 'widget': PaymentsScreen()},
    //{'title': 'Analytics', 'widget': AnalyticsScreen()},
    //{'title': 'Notifications', 'widget': NotificationsScreen()},
    {'title': 'Manage Categories', 'widget': ManageCategoriesScreen()},
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
    Navigator.pop(context); // Close the drawer
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pages[_selectedIndex]['title'],
          style: AdminTheme.themeData.textTheme.titleLarge?.copyWith(
            color: AdminTheme.onPrimaryTextColor,
          ),
        ),
        backgroundColor: AdminTheme.primaryColor,
        iconTheme: IconThemeData(color: AdminTheme.onPrimaryTextColor),
      ),
      drawer: _buildDrawer(context),
      body: _pages[_selectedIndex]['widget'],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: AdminTheme.primaryGradient,
        ),
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AdminTheme.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(Icons.dashboard_outlined, 'Dashboard', 0),
                    if (permissions['viewUsers'] ?? false)
                      _buildDrawerItem(Icons.people_outlined, 'Users', 1),
                    if (permissions['viewProviders'] ?? false)
                      _buildDrawerItem(Icons.business_outlined, 'Providers', 2),
                    if (permissions['viewServices'] ?? false)
                      _buildDrawerItem(Icons.design_services_outlined, 'Services', 3),
                    if (permissions['viewBookings'] ?? false)
                      _buildDrawerItem(Icons.book_online_outlined, 'Bookings', 4),
                    //if (permissions['viewPayments'] ?? false)
                      //_buildDrawerItem(Icons.payment_outlined, 'Payments', 5),
                   // if (permissions['viewAnalytics'] ?? false)
                     // _buildDrawerItem(Icons.analytics_outlined, 'Analytics', 6),
                   // if (permissions['sendNotifications'] ?? false)
                      //_buildDrawerItem(Icons.notifications_outlined, 'Notifications', 7),
                    if (permissions['manageCategories'] ?? true)
                      _buildDrawerItem(Icons.category_outlined, 'Manage Categories', 8),
                    const Divider(
                      color: AdminTheme.dividerColor,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildLogoutItem(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.primaryColor.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AdminTheme.secondaryColor,
              backgroundImage: NetworkImage(
                adminProfileUrl ?? 'https://avatar.iran.liara.run/public',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              adminName ?? 'Admin',
              style: AdminTheme.themeData.textTheme.titleLarge?.copyWith(
                color: AdminTheme.onPrimaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              adminEmail ?? 'admin@example.com',
              style: AdminTheme.themeData.textTheme.bodyMedium?.copyWith(
                color: AdminTheme.onPrimaryTextColor.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _selectedIndex == index
            ? AdminTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: _selectedIndex == index
              ? AdminTheme.primaryColor
              : AdminTheme.secondaryTextColor,
        ),
        title: Text(
          title,
          style: AdminTheme.themeData.textTheme.bodyLarge?.copyWith(
            color: _selectedIndex == index
                ? AdminTheme.primaryTextColor
                : AdminTheme.secondaryTextColor,
            fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: _selectedIndex == index
            ? Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AdminTheme.primaryColor,
        )
            : null,
        onTap: () => _onItemTapped(index),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildLogoutItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AdminTheme.errorTextColor.withOpacity(0.1),
      ),
      child: ListTile(
        leading: Icon(
          Icons.logout,
          color: AdminTheme.errorTextColor,
        ),
        title: Text(
          'Logout',
          style: AdminTheme.themeData.textTheme.bodyLarge?.copyWith(
            color: AdminTheme.errorTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: _logout,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}