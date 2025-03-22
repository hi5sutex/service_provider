import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:service_provider/Admin%20Panel/screens/PendingServicesScreen.dart';
import 'package:service_provider/Admin%20Panel/screens/main.dart';
import 'package:service_provider/Provider%20Panel/screens/booking_screen.dart';
import 'package:service_provider/Provider%20Panel/screens/chat/provider_chat_list.dart';
import 'package:service_provider/User%20Panel/main_home.dart'; // User home
import 'package:service_provider/Provider%20Panel/screens/main.dart'; // Provider home
import 'package:service_provider/welcome_screen.dart';
import 'package:service_provider/notification_service.dart';
// import 'package:service_provider/Provider%20Panel/screens/bookings/provider_booking.dart'; // For navigation
// import 'package:service_provider/Provider%20Panel/screens/chat/provider_chat_list.dart'; // For navigation
import 'firebase_options.dart';
import 'theme.dart'; // Import the theme file

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background notification: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
  await NotificationService.showBackgroundNotification(message);  // Use NotificationService
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global navigator key for navigation from NotificationService
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Service Provider App',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      navigatorKey: navigatorKey, // Assign the navigator key
      routes: {
        '/providerBooking': (context) => ProviderBooking(),
        //     ProviderBooking(
        //   bookingId: ModalRoute.of(context)?.settings.arguments as String?,
        // ),

        '/chat': (context) => ProviderChatListScreen(),
        '/serviceRequests': (context) => PendingServicesScreen(), // Placeholder; replace with actual screen
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize NotificationService
    NotificationService().initialize(context);
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthStateHandler()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.primaryColorCustom,
        child: Stack(
          children: [
            Positioned(
              top: -75,
              right: -75,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColorCustom,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -75,
              left: -75,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColorCustom,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "android/assets/logo.png",
                    width: 150.0,
                    height: 150.0,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 5.0),
                  Text(
                    'Quick Expert',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 30.0,
                      color: AppTheme.secondaryColorCustom,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const WelcomeScreen();
        }

        return FutureBuilder<String?>(
          future: _getUserType(snapshot.data!.uid),
          builder: (context, userTypeSnapshot) {
            if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userTypeSnapshot.hasError || userTypeSnapshot.data == null) {
              return const WelcomeScreen();
            }

            final userType = userTypeSnapshot.data!;
            if (userType == 'admin') {
              return MainAdminPanel();
            } else if (userType == 'user') {
              return MainHome();
            } else if (userType == 'provider') {
              return Main();
            } else {
              return const Scaffold(
                body: Center(child: Text("Invalid user type!")),
              );
            }
          },
        );
      },
    );
  }

  Future<String?> _getUserType(String uid) async {
    try {
      final adminDoc =
      await FirebaseFirestore.instance.collection('admins').doc(uid).get();
      if (adminDoc.exists && adminDoc.data() != null) {
        return "admin";
      }

      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return "user";
      }

      final providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .get();
      if (providerDoc.exists && providerDoc.data() != null) {
        return "provider";
      }

      return null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }
}