import 'package:flutter/material.dart';
import 'package:service_provider/User Panel/user_home.dart';
import 'package:service_provider/User Panel/user_profile.dart';
import 'package:service_provider/User Panel/user_booking.dart';
import 'chat_funtionality/all_users_screen.dart';

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
    AllUsersScreen(),
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
      backgroundColor: Color(0xFFf5f5f5), // Set the background color of the page here
      body: Stack(
        children: [
          _pages[_selectedIndex], // Main content
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Color(0xFF060644), // Black background color for navigation bar
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home,
                    label: 'Home',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.book_online,
                    label: 'Booking',
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.message_outlined,
                    label: 'Message',
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.account_circle,
                    label: 'Profile',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
          color: Color(0xFF7C4DFF), // Purple background for selected item
          borderRadius: BorderRadius.circular(25),
        )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey, // Icon color
              size: 24,
            ),
            if (isSelected)
              SizedBox(width: 8), // Spacing between icon and label
            if (isSelected)
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
