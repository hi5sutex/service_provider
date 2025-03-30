import 'dart:async';
import 'package:email_otp/email_otp.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_provider/User%20Panel/main_home.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';

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
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _secondsRemaining = 60;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _resendOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("Resending OTP to: ${widget.email}");
      bool result = await EmailOTP.sendOTP(email: widget.email);
      print("OTP Resend Result: $result");

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP resent to your email")),
        );
        // Clear the OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        // Restart the timer
        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to resend OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
      print("Error occurred while resending OTP: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _verifyOtpAndRegister() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Combine the OTP digits from the six controllers
      String otp = _otpControllers.map((controller) => controller.text).join();
      bool isVerified = await EmailOTP.verifyOTP(otp: otp);

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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String timerText =
        "00:${_secondsRemaining.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: UserTheme.surfaceColor, // Matches #FFFFFF (Surface)
      appBar: AppBar(
        backgroundColor: UserTheme.surfaceColor, // Matches #FFFFFF (Surface)
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // OTP Icon Image
              Container(
                margin: EdgeInsets.only(bottom: 30),
                height: 150,  // Adjust height as needed
                child: Image.asset(
                  'android/assets/otp_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              // Title
              Text(
                'We sent you a code to verify your number',
                style: TextStyle(
                  color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Display Email
              Text(
                'Enter the OTP sent to ${widget.email}',
                style: TextStyle(
                  color: UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // OTP Input Boxes (6 digits)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 50,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: TextStyle(
                        color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '', // Hide the counter for maxLength
                        filled: true,
                        fillColor: UserTheme.dividerColor, // Matches #D1D9E1 (Divider)
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: UserTheme.dividerColor, // Matches #D1D9E1 (Divider)
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: UserTheme.primaryColor, // Matches #060644 (Primary)
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.length == 1 && index < 5) {
                          _focusNodes[index].unfocus();
                          FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index].unfocus();
                          FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              // Resend Timer or Resend Link
              _canResend
                  ? TextButton(
                onPressed: _resendOtp,
                child: Text(
                  "Resend OTP",
                  style: TextStyle(
                    color: UserTheme.primaryColor, // Matches #060644 (Primary)
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : Text(
                "Didn't receive? Resend in $timerText",
                style: TextStyle(
                  color: UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: UserTheme.primaryColor, // Matches #060644 (Primary)
                  ),
                )
                    : ElevatedButton(
                  onPressed: _verifyOtpAndRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UserTheme.primaryColor, // Matches #060644 (Primary)
                    foregroundColor: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}