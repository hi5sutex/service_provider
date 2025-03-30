import 'package:flutter/material.dart';
import 'package:service_provider/User%20Panel/user_home.dart';
import 'package:service_provider/User%20Panel/user_profile.dart';
import 'package:service_provider/User%20Panel/user_booking.dart';
import 'package:service_provider/User%20Panel/chat_funtionality/ChatListScreen.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart'; // Ensure ProviderTheme is imported

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
    ChatListScreen(),
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
      body: Stack(
        children: [
          _pages[_selectedIndex], // Main content
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // White background for professional look
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent, // Use Container's color
                  elevation: 0, // Custom shadow from Container
                  type: BottomNavigationBarType.fixed,
                  showUnselectedLabels: true, // Always show labels
                  showSelectedLabels: true,
                  items: [
                    _buildNavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'Home',
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.book_online_outlined,
                      selectedIcon: Icons.book_online,
                      label: 'Booking',
                      index: 1,
                    ),
                    _buildNavItem(
                      icon: Icons.message_outlined,
                      selectedIcon: Icons.message,
                      label: 'Message',
                      index: 2,
                    ),
                    _buildNavItem(
                      icon: Icons.account_circle_outlined,
                      selectedIcon: Icons.account_circle,
                      label: 'Profile',
                      index: 3,
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: UserTheme.primaryColor, // #060644
                  unselectedItemColor: UserTheme.disabledTextColor, // #B0B8C4
                  onTap: _onItemTapped,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isSelected ? selectedIcon : icon,
          key: ValueKey(isSelected),
          size: isSelected ? 26 : 20, // Selected: 26, Unselected: 20
        ),
      ),
      label: label,
    );
  }
}