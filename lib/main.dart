import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Admin%20Panel/screens/main.dart';
import 'package:service_provider/User Panel/user_login.dart';
import 'package:service_provider/User Panel/main_home.dart'; // User home
import 'package:service_provider/Provider Panel/screens/main.dart'; // Provider home
import 'package:service_provider/welcome_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Service Provider App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Start with the Splash Screen
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthStateHandler()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Color(0xFF060644), // Dark blue background color
        child: Stack(
          children: [
            // Top white circle (now on the right)
            Positioned(
              top: -75, // Adjusted position
              right: -75, // Shifted to the right
              child: Container(
                width: 180, // Reduced size by 50%
                height: 180, // Reduced size by 50%
                decoration: BoxDecoration(
                  color: Colors.white, // White color
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Bottom white circle (now on the left)
            Positioned(
              bottom: -75, // Adjusted position
              left: -75, // Shifted to the left
              child: Container(
                width: 250, // Reduced size by 50%
                height: 250, // Reduced size by 50%
                decoration: BoxDecoration(
                  color: Colors.white, // White color
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Center content (logo and text)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "android/assets/logo.png", // Adjust to your logo path
                    width: 150.0, // Adjust width as needed
                    height: 150.0, // Adjust height as needed
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 5.0), // Add space between logo and text
                  const Text(
                    'Quick Expert', // Adjust text as needed
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return WelcomeScreen();
        }

        // Check user type based on collections
        return FutureBuilder<String?>(
          future: _getUserType(snapshot.data!.uid, context),
          builder: (context, userTypeSnapshot) {
            if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (userTypeSnapshot.hasError || userTypeSnapshot.data == null) {
              return WelcomeScreen(); // Redirect to login if user is not found
            }

            final userType = userTypeSnapshot.data!;
            if (userType == 'admin') {
              return MainAdminPanel(); // Admin panel
            } else if (userType == 'user') {
              return MainHome(); // User panel
            } else if (userType == 'provider') {
              return Main(); // Provider panel
            } else {
              return const Scaffold(
                body: Center(
                  child: Text("Invalid user type!"),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<String?> _getUserType(String uid, BuildContext context) async {
    try {
      // Check the "admins" collection
      final adminDoc =
      await FirebaseFirestore.instance.collection('admins').doc(uid).get();

      if (adminDoc.exists && adminDoc.data() != null) {
        return "admin"; // Return userType for "admins"
      }

      // Check the "users" collection
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        return "user"; // Return userType for "users"
      }

      // Check the "providers" collection
      final providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .get();

      if (providerDoc.exists && providerDoc.data() != null) {
        return "provider"; // Return userType for "providers"
      }

      // If not found in either collection, return null
      return null;
    } catch (e) {
      throw Exception("Error fetching user data: $e");
    }
  }
}
