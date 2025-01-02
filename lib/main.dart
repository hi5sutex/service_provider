import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Admin%20Panel/screens/main.dart';
import 'package:service_provider/User Panel/user_login.dart';
import 'package:service_provider/User Panel/main_home.dart'; // User home
import 'package:service_provider/Provider Panel/screens/main.dart'; // Provider home
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
      home: AuthStateHandler(),
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
          return LoginPage();
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
              return LoginPage(); // Redirect to login if user is not found
            }

            final userType = userTypeSnapshot.data!;
            if (userType == 'admin') {
              return MainAdminPanel(); // User panel
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
      final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();

      if (adminDoc.exists && adminDoc.data() != null) {

        return "admin"; // Return userType for "users"
      }

      // Check the "users" collection
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {

        return "user"; // Return userType for "users"
      }

      // Check the "providers" collection
      final providerDoc = await FirebaseFirestore.instance.collection('providers').doc(uid).get();

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
