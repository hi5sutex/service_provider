import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:service_provider/User Panel/user_home.dart';
import 'package:service_provider/Ak Provider Panel/screens/main.dart'; // Replace with actual provider home
import 'package:service_provider/User Panel/user_login.dart';
import 'package:service_provider/User%20Panel/main_home.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app
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
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If still connecting to Firebase, show a loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // If the user is not logged in, navigate to the LoginPage
          if (!snapshot.hasData || snapshot.data == null) {
            return LoginPage();
          }

          // If the user is logged in, fetch user details from Firestore
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // If user details not found or error occurs
              if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                return LoginPage(); // Redirect to login if details are missing
              }

              // Check the user type (e.g., 'user' or 'provider') and navigate accordingly
              final userType = userSnapshot.data!.get('userType');
              if (userType == 'user') {
                return MainHome(); // Replace with actual user home page widget
              } else if (userType == 'provider') {
                return Main(); // Replace with actual provider home page widget
              }

              // Default case: Navigate to LoginPage
              return LoginPage();
            },
          );
        },
      ),
    );
  }
}
