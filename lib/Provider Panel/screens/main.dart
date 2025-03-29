import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:service_provider/Provider%20Panel/screens/home_screen.dart';
import 'package:service_provider/Provider%20Panel/screens/bookings/provider_booking.dart';
import 'package:service_provider/Provider%20Panel/screens/chat/provider_chat_list.dart';
import 'package:service_provider/Provider%20Panel/screens/profile_screen.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'package:service_provider/main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Main extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      ProviderHome(),
      ProviderBooking(),
      ProviderChatListScreen(),
      ProviderProfile(),
    ];
    _setupNotifications();
  }

  void _setupNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');

      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${message.notification?.title}: ${message.notification?.body}'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              String? bookingId = message.data['bookingId'];
              if (bookingId != null) _navigateToBookingDetails(bookingId);
            },
          ),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened: ${message.notification?.title}');
      String? bookingId = message.data['bookingId'];
      if (bookingId != null) _navigateToBookingDetails(bookingId);
    });

    _checkInitialMessage();

    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) _navigateToBookingDetails(response.payload!);
      },
    );
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state: ${initialMessage.notification?.title}');
      String? bookingId = initialMessage.data['bookingId'];
      if (bookingId != null) _navigateToBookingDetails(bookingId);
    }
  }

  void _navigateToBookingDetails(String bookingId) {
    setState(() => _selectedIndex = 1);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProviderBooking()),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<bool> _onWillPop() async {
    // Show the exit confirmation dialog
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ProviderTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Exit App',
          style: ProviderTheme.themeData.textTheme.titleLarge?.copyWith(
            color: ProviderTheme.primaryTextColor,
          ),
        ),
        content: Text(
          'Are you sure you want to exit the app?',
          style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
            color: ProviderTheme.secondaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cancel, don't exit
            child: Text(
              'No',
              style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                color: ProviderTheme.secondaryTextColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirm, exit
            child: Text(
              'Yes',
              style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                color: ProviderTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    ) ??
        false; // Return false if the dialog is dismissed (e.g., by tapping outside)
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ProviderTheme.themeData,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: WillPopScope(
        onWillPop: _onWillPop, // Intercept back button press
        child: Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: ProviderTheme.surfaceColor,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: false,
            showSelectedLabels: true,
            selectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ProviderTheme.primaryColor,
              shadows: [
                Shadow(
                  color: ProviderTheme.primaryColor.withOpacity(0.3),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: ProviderTheme.secondaryTextColor,
            ),
            items: [
              _buildBottomNavItem(
                icon: FontAwesomeIcons.house,
                selectedIcon: FontAwesomeIcons.house,
                label: 'Home',
                index: 0,
              ),
              _buildBottomNavItem(
                icon: FontAwesomeIcons.calendar,
                selectedIcon: FontAwesomeIcons.calendarCheck,
                label: 'Booking',
                index: 1,
              ),
              _buildBottomNavItem(
                icon: FontAwesomeIcons.comment,
                selectedIcon: FontAwesomeIcons.solidComment,
                label: 'Chat',
                index: 2,
              ),
              _buildBottomNavItem(
                icon: FontAwesomeIcons.user,
                selectedIcon: FontAwesomeIcons.solidUser,
                label: 'Account',
                index: 3,
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: ProviderTheme.primaryColor,
            unselectedItemColor: ProviderTheme.secondaryTextColor,
            onTap: _onItemTapped,
          ),
        ),
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
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              _selectedIndex == index ? selectedIcon : icon,
              key: ValueKey(_selectedIndex == index),
              size: _selectedIndex == index ? 20 : 24,
              color: _selectedIndex == index
                  ? ProviderTheme.primaryColor
                  : ProviderTheme.secondaryTextColor,
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}