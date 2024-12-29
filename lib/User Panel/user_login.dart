import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User Panel/user_registration.dart';
import 'package:service_provider/User Panel/main_home.dart';
import 'package:service_provider/Provider Panel/screens/main.dart';
import 'package:service_provider/Provider Panel/screens/register_screen.dart';
import 'package:service_provider/Admin Panel/screens/main.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;

  // Method to log in with email and password
  Future<void> loginWithEmailAndPassword() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Log in user with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // Check if the user is in the 'admins' collection
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (adminDoc.exists) {
        // User is an admin
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Successful as Admin!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainAdminPanel(), // Navigate to Admin's Main Panel
          ),
        );
      } else {
        // Check if the user is in the 'users' collection
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          // User is a normal user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Successful as User!")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainHome(), // Navigate to User's Main Home
            ),
          );
        } else {
          // Check if the user is in the 'providers' collection
          DocumentSnapshot providerDoc = await FirebaseFirestore.instance
              .collection('providers')
              .doc(uid)
              .get();

          if (providerDoc.exists) {
            // User is a provider
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Login Successful as Provider!")),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Main(), // Replace with Provider's Main Panel
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("User not found in database.")),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Invalid password.";
      } else {
        errorMessage = "Login failed. Please try again.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Page")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loginWithEmailAndPassword,
              child: const Text("Login"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // Navigate to registration page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationPage(), // Replace with your registration page
                  ),
                );
              },
              child: const Text("Don't have an account? Register here"),
            ),
            TextButton(
              onPressed: () {
                // Navigate to registration page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterScreen(), // Replace with your registration page
                  ),
                );
              },
              child: const Text("Wanna become Provider? Register here"),
            ),
          ],
        ),
      ),
    );
  }
}

