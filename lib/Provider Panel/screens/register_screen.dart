import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:service_provider/Provider Panel/screens/otp_verification.dart';

class ProviderTheme {
  static Color primaryColor = const Color(0xFF060644);
  static Color surfaceColor = Colors.white;
  static Color onPrimaryTextColor = Colors.white;
  static Color primaryTextColor = Colors.black;
  static Color secondaryTextColor = Colors.grey;
  static Color dividerColor = Colors.grey[200]!;
  static Color errorTextColor = Colors.red[400]!;
  static Color successColor = Colors.green;
}

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  //final EmailOTP _emailOTP = EmailOTP();
  bool _autoValidate = false;
  bool isLoading = false;
  bool _isObscure = true;

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

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            name: nameController.text.trim(),
            phone: phoneController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ProviderTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: ProviderTheme.surfaceColor,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ProviderTheme.primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.03),
            child: TextButton(
              onPressed: () {
                // Navigate to provider login page if needed
              },
              child: Text(
                "Login",
                style: TextStyle(
                  color: ProviderTheme.primaryColor,
                  fontSize: screenWidth * 0.045,
                ),
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          color: ProviderTheme.surfaceColor,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: screenHeight * 0.15,
              child: Padding(
                padding: EdgeInsets.only(
                    top: screenHeight * 0.02, left: screenWidth * 0.06),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Register as Provider',
                    style: TextStyle(
                      color: ProviderTheme.primaryColor,
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
                color: ProviderTheme.primaryColor,
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
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
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
                          color: ProviderTheme.onPrimaryTextColor,
                        ),
                      )
                          : ElevatedButton(
                        onPressed: sendOTPAndNavigate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ProviderTheme.surfaceColor,
                          foregroundColor: ProviderTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          minimumSize: Size(double.infinity, screenHeight * 0.07),
                        ),
                        child: Text(
                          "Send OTP",
                          style: TextStyle(fontSize: screenWidth * 0.045),
                        ),
                      ),
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
        color: ProviderTheme.primaryTextColor,  // Changed to match user registration
        fontSize: MediaQuery.of(context).size.width * 0.04,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: ProviderTheme.secondaryTextColor,
        ),
        prefixIcon: Icon(icon, color: ProviderTheme.secondaryTextColor),
        filled: true,
        fillColor: ProviderTheme.dividerColor,
        errorStyle: TextStyle(
          color: ProviderTheme.errorTextColor,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(
            color: controller.text.isNotEmpty
                ? ProviderTheme.successColor
                : ProviderTheme.secondaryTextColor,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(
            color: ProviderTheme.successColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(
            color: ProviderTheme.errorTextColor,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(
            color: ProviderTheme.errorTextColor,
            width: 2,
          ),
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility : Icons.visibility_off,
            color: ProviderTheme.secondaryTextColor,
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
}