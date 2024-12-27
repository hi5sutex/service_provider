import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_provider/Provider Panel/screens/main.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String name;
  final String phone;
  final String password;

  OtpVerificationScreen({
    required this.email,
    required this.name,
    required this.phone,
    required this.password,
  });

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController otpController = TextEditingController();

  void verifyOtpAndRegister() async {
    try {
      bool isVerified = await EmailOTP.verifyOTP(otp: otpController.text);

      if (isVerified) {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: widget.email,
          password: widget.password,
        );

        await FirebaseFirestore.instance
            .collection('providers')
            .doc(userCredential.user!.uid)
            .set({
          'name': widget.name,
          'phone': widget.phone,
          'email': widget.email,
          'userType': "provider",
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Main()),
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
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Enter the OTP sent to ${widget.email}'),
            TextFormField(
              controller: otpController,
              decoration: const InputDecoration(labelText: 'OTP'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: verifyOtpAndRegister,
              child: const Text('Verify and Register'),
            ),
          ],
        ),
      ),
    );
  }
}
