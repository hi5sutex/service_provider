import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:service_provider/User%20Panel/user_registration.dart';
import 'package:service_provider/User%20Panel/main_home.dart';
import 'package:service_provider/Provider%20Panel/screens/main.dart';
import 'package:service_provider/Provider%20Panel/screens/register_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/main.dart';
import 'package:service_provider/notification_service.dart';
import 'package:service_provider/welcome_screen.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _isObscure = true;
  bool _autoValidate = false;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
    });
  }

  Future<void> loginWithEmailAndPassword() async {
    setState(() {
      _autoValidate = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      await _checkUserRole(uid);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.message}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkUserRole(String uid) async {
    DocumentSnapshot adminDoc =
    await FirebaseFirestore.instance.collection('admins').doc(uid).get();
    if (adminDoc.exists) {
      await NotificationService().registerFCMToken(uid, 'admin');
      _navigateToPage(context, MainAdminPanel(), "Admin");
      return;
    }
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      await NotificationService().registerFCMToken(uid, 'user');
      _navigateToPage(context, MainHome(), "User");
      return;
    }
    DocumentSnapshot providerDoc =
    await FirebaseFirestore.instance.collection('providers').doc(uid).get();
    if (providerDoc.exists) {
      await NotificationService().registerFCMToken(uid, 'provider');
      _navigateToPage(context, Main(), "Provider");
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Error: User role not recognized")),
    );
  }

  Future<bool> _registerFCMToken(String providerId) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await messaging.getToken();
        print('FCM Token: $token');
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('providers')
              .doc(providerId)
              .set({'fcmToken': token}, SetOptions(merge: true));
          print('FCM Token registered for provider: $providerId');
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
            await FirebaseFirestore.instance
                .collection('providers')
                .doc(providerId)
                .set({'fcmToken': newToken}, SetOptions(merge: true));
            print('FCM Token refreshed for provider: $providerId');
          });
          return true;
        } else {
          print('FCM token is null');
          return false;
        }
      } else {
        print('Notification permission denied');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification permission denied")),
        );
        return false;
      }
    } catch (e) {
      print('Error registering FCM token: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error registering notification token: $e")),
      );
      return false;
    }
  }

  void _navigateToPage(BuildContext context, Widget page, String role) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Login Successful as $role!")),
    );
    // Use pushAndRemoveUntil to clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => page),
          (Route<dynamic> route) => false, // Removes all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UserTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: UserTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.all(20.0),
          icon: Icon(
            Icons.arrow_back,
            color: UserTheme.primaryTextColor,
            size: 25,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WelcomeScreen()),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationPage()),
                );
              },
              child: Text(
                "Register",
                style: TextStyle(
                  color: UserTheme.primaryTextColor,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.28,
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign In',
                  style: TextStyle(
                    color: UserTheme.primaryTextColor,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Log in to access your account and explore the services!",
                  style: TextStyle(
                    color: UserTheme.secondaryTextColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: UserTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),
                      _buildTextField(
                        controller: emailController,
                        hintText: "Email",
                        isPassword: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: passwordController,
                        hintText: "Password",
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: isLoading
                            ? Center(
                          child: CircularProgressIndicator(
                            color: UserTheme.onPrimaryTextColor,
                          ),
                        )
                            : ElevatedButton(
                          onPressed: loginWithEmailAndPassword,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: UserTheme.surfaceColor,
                            foregroundColor: UserTheme.primaryColor,
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(fontSize: 19),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RegisterScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: UserTheme.successColor,
                            foregroundColor: UserTheme.onPrimaryTextColor,
                          ),
                          child: const Text(
                            "Become a Provider",
                            style: TextStyle(fontSize: 19),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
        color: UserTheme.primaryTextColor,
        fontSize: 16,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: UserTheme.secondaryTextColor,
        ),
        prefixIcon: Icon(
          isPassword ? Icons.lock_outline : Icons.email_outlined,
          color: UserTheme.secondaryTextColor,
        ),
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
                : UserTheme.onPrimaryTextColor,
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
            color: UserTheme.primaryTextColor,
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
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}