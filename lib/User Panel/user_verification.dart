import 'package:email_otp/email_otp.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_provider/User%20Panel/main_home.dart';
import 'package:service_provider/theme.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String name;
  final String phone;
  final String password;

  OtpVerificationPage({
    required this.email,
    required this.name,
    required this.phone,
    required this.password,
  });

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpController = TextEditingController();

  void _verifyOtpAndRegister() async {
    try {
      // Verify OTP using EmailOTP package method
      bool isVerified = await EmailOTP.verifyOTP(otp: _otpController.text);

      if (isVerified) {
        // Create user in Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: widget.email,
          password: widget.password,
        );

        // Save additional details in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': widget.name,
          'phone': widget.phone,
          'email': widget.email,
          'userType': "user",
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Navigate to Home Page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainHome()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
      appBar: AppBar(
        backgroundColor: ProviderTheme.primaryColor, // Matches #060644 (Primary)
        title: Text(
          'OTP Verification',
          style: TextStyle(
            color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Enter the OTP sent to ${widget.email}',
              style: TextStyle(
                color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'OTP',
                labelStyle: TextStyle(
                  color: ProviderTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: ProviderTheme.dividerColor, // Matches #D1D9E1 (Divider)
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyOtpAndRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: ProviderTheme.primaryColor, // Matches #060644 (Primary)
                foregroundColor: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                'Verify and Register',
                style: TextStyle(
                  color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}