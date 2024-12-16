import 'package:email_otp/email_otp.dart';
import 'package:flutter/material.dart';

void main() {
  // Configuring the OTP package
  EmailOTP.config(
    appName: 'MyApp',              // App Name
    otpType: OTPType.numeric,      // OTP type (numeric, alpha, alphaNumeric)
    emailTheme: EmailTheme.v1,     // Email theme
    otpLength: 6,                  // OTP length
    expiry: 30000,                 // OTP expiry time (in milliseconds)
    appEmail: 'youremail@example.com', // Email address from which OTP will be sent
  );

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OTPServicePage(),
    ),
  );
}

class OTPServicePage extends StatelessWidget {
  const OTPServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    TextEditingController otpController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('OTP Service')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email Address'),
          ),
          ElevatedButton(
            onPressed: () async {
              bool result = await EmailOTP.sendOTP(email: emailController.text);
              if (result) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("OTP has been sent")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to send OTP")),
                );
              }
            },
            child: const Text('Send OTP'),
          ),
          TextFormField(
            controller: otpController,
            decoration: const InputDecoration(labelText: 'Enter OTP'),
          ),
          ElevatedButton(
            onPressed: () async {
              bool isVerified = await EmailOTP.verifyOTP(otp: otpController.text);
              if (isVerified) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("OTP Verified Successfully")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid OTP")),
                );
              }
            },
            child: const Text('Verify OTP'),
          ),
        ],
      ),
    );
  }
}
