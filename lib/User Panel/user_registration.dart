import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:service_provider/User%20Panel/user_verification.dart';
import 'package:service_provider/User%20Panel/user_login.dart';
import 'package:service_provider/theme.dart';
import 'package:service_provider/welcome_screen.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final EmailOTP _emailOTP = EmailOTP();
  bool isLoading = false;
  bool _isObscure = true;
  bool _autoValidate = false;

  void sendOTPAndNavigate() async {
    setState(() {
      _autoValidate = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      _emailOTP.setConfig(
        appEmail: "youremail@example.com",
        appName: "Your App Name",
        otpLength: 6,
        otpType: OTPType.numeric,
      );

      bool result = await EmailOTP.sendOTP(email: emailController.text);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent to your email")),
        );

        await FirebaseFirestore.instance
            .collection('user_chatroom')
            .doc(emailController.text)
            .set({
          'name': nameController.text,
          'phone': phoneController.text,
          'email': emailController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'user',
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              name: nameController.text,
              phone: phoneController.text,
              email: emailController.text,
              password: passwordController.text,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send OTP")),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow resizing when keyboard appears
      backgroundColor: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          },
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.03),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text(
                "Login",
                style: TextStyle(
                  color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
                  fontSize: screenWidth * 0.045,
                ),
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          color: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
        ),
      ),
      body: SingleChildScrollView( // Wrap entire body in SingleChildScrollView
        child: Column(
          children: [
            SizedBox(
              height: screenHeight * 0.15,
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.02, left: screenWidth * 0.06),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
                      fontSize: screenWidth * 0.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(
                minHeight: screenHeight * 0.85, // Ensure enough height for content
              ),
              decoration: BoxDecoration(
                color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              padding: EdgeInsets.all(screenWidth * 0.075),
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.025),
                    _buildTextField(
                      controller: nameController,
                      hintText: "Full Name",
                      isPassword: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    _buildTextField(
                      controller: phoneController,
                      hintText: "Phone Number",
                      isPassword: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    _buildTextField(
                      controller: emailController,
                      hintText: "Email",
                      isPassword: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    _buildTextField(
                      controller: passwordController,
                      hintText: "Password",
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    _buildTextField(
                      controller: confirmPasswordController,
                      hintText: "Confirm Password",
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.07,
                      child: isLoading
                          ? Center(
                        child: CircularProgressIndicator(
                          color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                        ),
                      )
                          : ElevatedButton(
                        onPressed: sendOTPAndNavigate,
                        style: theme.elevatedButtonTheme.style?.copyWith(
                          minimumSize: MaterialStateProperty.all(
                            Size(double.infinity, screenHeight * 0.07),
                          ),
                          backgroundColor: MaterialStateProperty.all(
                            ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
                          ),
                          foregroundColor: MaterialStateProperty.all(
                            ProviderTheme.primaryColor, // Matches #060644 (Primary)
                          ),
                        ),
                        child: Text(
                          "Send OTP",
                          style: TextStyle(fontSize: screenWidth * 0.045),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    _buildRedirectLink(
                      "Already have an account? Login here",
                      LoginPage(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool isPassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _isObscure,
      style: TextStyle(
        color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
        fontSize: MediaQuery.of(context).size.width * 0.04,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: ProviderTheme.onPrimaryTextColor.withOpacity(0.7), // Matches #FFFFFF with opacity
        ),
        filled: true,
        fillColor: ProviderTheme.dividerColor, // Matches #D1D9E1 (Divider)
        errorStyle: TextStyle(
          color: ProviderTheme.errorTextColor, // Matches #D32F2F (Error Text)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(
            color: controller.text.isNotEmpty
                ? ProviderTheme.successColor // Matches #388E3C (Success Text)
                : ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(
            color: ProviderTheme.successColor, // Matches #388E3C (Success Text)
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(
            color: ProviderTheme.errorTextColor, // Matches #D32F2F (Error Text)
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(
            color: ProviderTheme.errorTextColor, // Matches #D32F2F (Error Text)
            width: 2,
          ),
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility : Icons.visibility_off,
            color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        )
            : null,
      ),
    );
  }

  Widget _buildRedirectLink(String text, Widget page) {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Text(
          text,
          style: TextStyle(
            color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
            fontSize: MediaQuery.of(context).size.width * 0.04,
          ),
        ),
      ),
    );
  }
}

extension on EmailOTP {
  void setConfig({
    required String appEmail,
    required String appName,
    required int otpLength,
    required OTPType otpType,
  }) {}
}