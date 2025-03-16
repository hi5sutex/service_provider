import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:service_provider/Provider%20Panel/screens/home_screen.dart';
import 'package:service_provider/Provider%20Panel/screens/bookings/provider_booking.dart';
import 'package:service_provider/Provider%20Panel/screens/chat/provider_chat_list.dart';
import 'package:service_provider/Provider%20Panel/screens/profile_screen.dart';
import 'package:service_provider/main.dart';

class Main extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ProviderHome(),
    ProviderBooking(),
    ProviderChatListScreen(),
    ProviderProfile(),
  ];

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  void _setupNotifications() {
    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${message.notification?.title}: ${message.notification?.body}'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              String? bookingId = message.data['bookingId'];
              if (bookingId != null) {
                _navigateToBookingDetails(bookingId);
              }
            },
          ),
        ),
      );
    });

    // Background/terminated notifications when app is opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened: ${message.notification?.title}');
      String? bookingId = message.data['bookingId'];
      if (bookingId != null) {
        _navigateToBookingDetails(bookingId);
      }
    });

    // Check if app was opened from a terminated state
    _checkInitialMessage();

    // Handle local notification tap
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _navigateToBookingDetails(response.payload!);
        }
      },
    );
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state: ${initialMessage.notification?.title}');
      String? bookingId = initialMessage.data['bookingId'];
      if (bookingId != null) {
        _navigateToBookingDetails(bookingId);
      }
    }
  }

  void _navigateToBookingDetails(String bookingId) {
    setState(() {
      _selectedIndex = 1; // Switch to ProviderBooking page
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderBooking(), // Pass bookingId if supported
      ),
    );
  }

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
        selectedItemColor: const Color(0xFF060644),
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
          key: ValueKey(_selectedIndex == index),
          size: _selectedIndex == index ? 22 : 24,
        ),
      ),
      label: _selectedIndex == index ? label : '',
    );
  }
}