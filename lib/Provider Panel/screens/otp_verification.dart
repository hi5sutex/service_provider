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
  EmailOTP myAuth = EmailOTP();
  bool isOtpSent = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    sendOTP();
  }

  void sendOTP() async {
    setState(() {
      isLoading = true;
    });

    final EmailOTP _emailOTP = EmailOTP();
    _emailOTP.setConfig(
      appEmail: "youremail@example.com",
      appName: "Your App Name",
      otpLength: 6,
      otpType: OTPType.numeric,
    );




    try {
      print("Sending OTP to: ${widget.email}");
      bool result = await EmailOTP.sendOTP(email: widget.email);
      print("OTP Send Result: $result");
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent to your email")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
      print("Error occurred while sending OTP: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void verifyOtpAndRegister() async {
    setState(() {
      isLoading = true;
    });

    try {
      bool isVerified = await EmailOTP.verifyOTP(otp: otpController.text);

      if (isVerified) {
        // Create user with Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: widget.email,
          password: widget.password,
        );

        // Save user data to Firestore
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
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP! Please try again.')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the OTP sent to ${widget.email}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: otpController,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : Column(
              children: [
                ElevatedButton(
                  onPressed: verifyOtpAndRegister,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Verify and Register'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: isOtpSent ? sendOTP : null,
                  child: const Text('Resend OTP'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:email_otp/email_otp.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:service_provider/Provider Panel/screens/main.dart';
//
// class OtpVerificationScreen extends StatefulWidget {
//   final String email;
//   final String name;
//   final String phone;
//   final String password;
//
//   OtpVerificationScreen({
//     required this.email,
//     required this.name,
//     required this.phone,
//     required this.password,
//   });
//
//   @override
//   _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
// }
//
// class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
//   final TextEditingController otpController = TextEditingController();
//
//   void verifyOtpAndRegister() async {
//     try {
//       bool isVerified = await EmailOTP.verifyOTP(otp: otpController.text);
//
//       if (isVerified) {
//         UserCredential userCredential = await FirebaseAuth.instance
//             .createUserWithEmailAndPassword(
//           email: widget.email,
//           password: widget.password,
//         );
//
//         await FirebaseFirestore.instance
//             .collection('providers')
//             .doc(userCredential.user!.uid)
//             .set({
//           'name': widget.name,
//           'phone': widget.phone,
//           'email': widget.email,
//           'userType': "provider",
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => Main()),
//               (route) => false,
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Invalid OTP!')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('OTP Verification')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text('Enter the OTP sent to ${widget.email}'),
//             TextFormField(
//               controller: otpController,
//               decoration: const InputDecoration(labelText: 'OTP'),
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: verifyOtpAndRegister,
//               child: const Text('Verify and Register'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


extension on EmailOTP {
  void setConfig({
    required String appEmail,
    required String appName,
    required int otpLength,
    required OTPType otpType,
  }) {}
}