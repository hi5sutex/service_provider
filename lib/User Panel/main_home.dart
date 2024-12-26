import 'package:flutter/material.dart';
import 'package:service_provider/User Panel/user_home.dart';
import 'package:service_provider/User Panel/user_chat.dart';
import 'package:service_provider/User Panel/user_profile.dart';
import 'package:service_provider/User Panel/user_booking.dart';

class MainHome extends StatefulWidget {
  @override
  _MainHomeState createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int _selectedIndex = 0;

  // List of pages for navigation
  final List<Widget> _pages = [
    UserHome(),
    UserBooking(),
    UserChat(),
    UserProfile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: [
          _buildBottomNavItem(icon: Icons.home, label: 'Home', index: 0),
          _buildBottomNavItem(icon: Icons.book_online, label: 'Booking', index: 1),
          _buildBottomNavItem(icon: Icons.chat, label: 'Chat', index: 2),
          _buildBottomNavItem(icon: Icons.account_circle, label: 'Account', index: 3),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem({required IconData icon, required String label, required int index}) {
    return BottomNavigationBarItem(
      icon: MouseRegion(
        onEnter: (_) {
          setState(() {
            // Optionally, you can add a hover effect here
          });
        },
        onExit: (_) {
          setState(() {
            // Reset hover effect if necessary
          });
        },
        child: Icon(
          icon,
          size: _selectedIndex == index ? 30 : 22, // Slightly larger for selected item
        ),
      ),
      label: _selectedIndex == index ? label : '', // Show label only for selected item
    );
  }
}
