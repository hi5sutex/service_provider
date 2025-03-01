import 'package:flutter/material.dart';
import 'package:service_provider/Provider Panel/screens/home_screen.dart';
import 'package:service_provider/Provider Panel/screens/booking_screen.dart';
import 'package:service_provider/Provider Panel/screens/chat_screen.dart';
import 'package:service_provider/Provider Panel/screens/profile_screen.dart';
import 'package:service_provider/Provider Panel/screens/add_dummy_bookings.dart';

import '../../User Panel/chat_funtionality/all_users_screen.dart';

class Main extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // List of pages for navigation
  final List<Widget> _pages = [
    ProviderHome(),
    ProviderBooking(),
    AllUsersScreen(),
    ProviderProfile(),
    // AddDummyBookings(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
        showSelectedLabels: true,
        items: [
          _buildBottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            index: 0,
          ),
          _buildBottomNavItem(
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_note,
            label: 'Booking',
            index: 1,
          ),
          _buildBottomNavItem(
            icon: Icons.chat_outlined,
            selectedIcon: Icons.chat,
            label: 'Chat',
            index: 2,
          ),
          _buildBottomNavItem(
            icon: Icons.account_circle_outlined,
            selectedIcon: Icons.account_circle,
            label: 'Account',
            index: 3,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF060644),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _selectedIndex == index ? selectedIcon : icon,
          key: ValueKey(_selectedIndex == index), // Ensure smooth animation when switching icons
          size: _selectedIndex == index ? 22 : 24, // Larger size for the selected icon
        ),
      ),
      label: _selectedIndex == index ? label : '', // Show label only for the selected item
    );
  }
}
