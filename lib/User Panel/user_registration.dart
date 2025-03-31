import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:service_provider/User%20Panel/user_verification.dart';
import 'package:service_provider/User%20Panel/user_login.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';
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
      print("Form validation failed");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      print("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    // after this
    // try {
    //   _emailOTP.setConfig(
    //     appEmail: "youremail@example.com",
    //     appName: "Your App Name",
    //     otpLength: 6,
    //     otpType: OTPType.numeric,
    //   );
    //
    //   print("Sending OTP to: ${emailController.text.trim()}");
    //   bool result = await EmailOTP.sendOTP(email: emailController.text.trim());
    //   print("OTP Send Result: $result");
    //
    //   if (result) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text("OTP sent to your email")),
    //     );
    //
    //     await FirebaseFirestore.instance
    //         .collection('user_chatroom')
    //         .doc(emailController.text.trim())
    //         .set({
    //       'name': nameController.text.trim(),
    //       'phone': phoneController.text.trim(),
    //       'email': emailController.text.trim(),
    //       'createdAt': FieldValue.serverTimestamp(),
    //       'role': 'user',
    //     });
    //
    //     Navigator.pushReplacement(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => OtpVerificationPage(
    //           name: nameController.text.trim(),
    //           phone: phoneController.text.trim(),
    //           email: emailController.text.trim(),
    //           password: passwordController.text.trim(),
    //         ),
    //       ),
    //     );
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text("Failed to send OTP")),
    //     );
    //   }
    // } catch (e) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationPage(
            name: nameController.text.trim(),
            phone: phoneController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          ),
        ),
      );
    } catch (e) {ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
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
      resizeToAvoidBottomInset: true,
      backgroundColor: UserTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: UserTheme.surfaceColor,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: UserTheme.primaryColor,
          ),
          onPressed: () {
            Navigator.pop(
              context,
              // MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          },
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.03),
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text(
                "Login",
                style: TextStyle(
                  color: UserTheme.primaryColor,
                  fontSize: screenWidth * 0.045,
                ),
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          color: UserTheme.surfaceColor,
        ),
      ),
      body: SingleChildScrollView(
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
                      color: UserTheme.primaryColor,
                      fontSize: screenWidth * 0.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(
                minHeight: screenHeight * 0.85,
              ),
              decoration: BoxDecoration(
                color: UserTheme.primaryColor,
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
                      icon: Icons.person_outline,
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
                      icon: Icons.phone_android_outlined,
                      isPassword: false,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
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
                      icon: Icons.email_outlined,
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
                      icon: Icons.lock_outline,
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
                      icon: Icons.lock_reset_outlined,
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
                          color: UserTheme.onPrimaryTextColor,
                        ),
                      )
                          : ElevatedButton(
                        onPressed: sendOTPAndNavigate,
                        style: theme.elevatedButtonTheme.style?.copyWith(
                          minimumSize: MaterialStateProperty.all(
                            Size(double.infinity, screenHeight * 0.07),
                          ),
                          backgroundColor: MaterialStateProperty.all(
                            UserTheme.surfaceColor,
                          ),
                          foregroundColor: MaterialStateProperty.all(
                            UserTheme.primaryColor,
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
    required IconData icon,
    required bool isPassword,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _isObscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: UserTheme.primaryTextColor, // Changed to primaryTextColor
        fontSize: MediaQuery.of(context).size.width * 0.04,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: UserTheme.secondaryTextColor,
        ),
        prefixIcon: Icon(icon, color: UserTheme.secondaryTextColor),
        filled: true,
        fillColor: UserTheme.dividerColor,
        errorStyle: TextStyle(
          color: UserTheme.errorTextColor,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(
            color: controller.text.isNotEmpty
                ? UserTheme.successColor
                : UserTheme.secondaryTextColor,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(
            color: UserTheme.successColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(
            color: UserTheme.errorTextColor,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(
            color: UserTheme.errorTextColor,
            width: 2,
          ),
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility : Icons.visibility_off,
            color: UserTheme.secondaryTextColor,
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Text(
          text,
          style: TextStyle(
            color: UserTheme.onPrimaryTextColor,
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