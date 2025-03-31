import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
import 'package:flutter/services.dart';
import 'package:service_provider/Provider Panel/screens/otp_verification.dart';

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
  final EmailOTP _emailOTP = EmailOTP();
  bool _autoValidate = false;
  bool isLoading = false;

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
      // Navigate to OTP verification screen
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, // Keeps AppBar color fixed
        elevation: 0,
        bottomOpacity: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white, // Ensures status bar remains white
          statusBarIconBrightness: Brightness.dark, // Keeps icons dark for visibility
        ),
        leading: IconButton(
          padding: const EdgeInsets.all(20.0),
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 25),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: () {
                // Navigate to login page if necessary
              },
              child: Text(
                "Login",
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white, // Keeps background fixed even when scrolling
          ),
        ),
        toolbarHeight: 60, // Fixes the AppBar height
      ),

      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.20,
            padding: const EdgeInsets.only(top: 30, left: 24, right: 24),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Register as a Provider',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF060644),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 30),
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: phoneController,
                        hintText: "Phone Number",
                        isPassword: false,
                        keyboardType: TextInputType.phone,
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
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: emailController,
                        hintText: "Email",
                        isPassword: false,
                        keyboardType: TextInputType.emailAddress,
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
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: isLoading
                            ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                            : ElevatedButton(
                          onPressed: sendOTPAndNavigate,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text("Send OTP", style: TextStyle(fontSize: 19)),
                        ),
                      ),
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
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.black, fontSize: 16),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Colors.black),
        hintStyle: const TextStyle(color: Colors.black),
        errorStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[300],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: BorderSide(color: controller.text.isNotEmpty ? Colors.green : Colors.black, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      keyboardType: keyboardType,
    );
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:email_otp/email_otp.dart';
// import 'package:flutter/services.dart';
// import 'package:service_provider/Provider Panel/screens/otp_verification.dart';
//
// class RegisterScreen extends StatefulWidget {
//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }
//
// class _RegisterScreenState extends State<RegisterScreen> {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController = TextEditingController();
//
//   final EmailOTP _emailOTP = EmailOTP();
//
//   void sendOTPAndNavigate() async {
//     if (passwordController.text != confirmPasswordController.text) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Passwords do not match")),
//       );
//       return;
//     }
//
//     bool result = await EmailOTP.sendOTP(email: emailController.text);
//     if (result) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("OTP sent to your email")),
//       );
//
//       // Save provider information in Firestore
//       await FirebaseFirestore.instance
//           .collection('providers') // Use a separate collection for providers
//           .doc(emailController.text)
//           .set({
//         'name': nameController.text,
//         'phone': phoneController.text,
//         'email': emailController.text,
//         'createdAt': FieldValue.serverTimestamp(),
//         'role': 'provider', // Add a role to distinguish providers
//       });
//
//       // Add the email ID to the user_chatroom collection
//       await FirebaseFirestore.instance
//           .collection('user_chatroom')
//           .doc(emailController.text) // Use email as the document ID
//           .set({
//         'name': nameController.text,
//         'phone': phoneController.text,
//         'email': emailController.text,
//         'createdAt': FieldValue.serverTimestamp(),
//         'role': 'provider',
//       });
//
//       // Navigate to OTP verification screen
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => OtpVerificationScreen(
//             name: nameController.text,
//             phone: phoneController.text,
//             email: emailController.text,
//             password: passwordController.text,
//           ),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Failed to send OTP")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white, // Keeps AppBar color fixed
//         elevation: 0,
//         bottomOpacity: 0,
//         systemOverlayStyle: SystemUiOverlayStyle(
//           statusBarColor: Colors.white, // Ensures status bar remains white
//           statusBarIconBrightness: Brightness.dark, // Keeps icons dark for visibility
//         ),
//         leading: IconButton(
//           padding: const EdgeInsets.all(20.0),
//           icon: Icon(Icons.arrow_back, color: Colors.black, size: 25),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 12.0),
//             child: TextButton(
//               onPressed: () {
//                 // Navigate to login page if necessary
//               },
//               child: Text(
//                 "Login",
//                 style: TextStyle(color: Colors.black, fontSize: 18),
//               ),
//             ),
//           ),
//         ],
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             color: Colors.white, // Keeps background fixed even when scrolling
//           ),
//         ),
//         toolbarHeight: 60, // Fixes the AppBar height
//       ),
//
//       body: Column(
//         children: [
//           Container(
//             height: MediaQuery.of(context).size.height * 0.20,
//             padding: const EdgeInsets.only(top: 30, left: 24, right: 24),
//             alignment: Alignment.centerLeft,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Register as a Provider',
//                   style: TextStyle(
//                     color: Colors.black,
//                     fontSize: 38,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Container(
//               decoration: const BoxDecoration(
//                 color: Color(0xFF060644),
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(50),
//                   topRight: Radius.circular(50),
//                 ),
//               ),
//               padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 30),
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     _buildTextField(
//                       controller: nameController,
//                       hintText: "Full Name",
//                       isPassword: false,
//                     ),
//                     const SizedBox(height: 10),
//                     _buildTextField(
//                       controller: phoneController,
//                       hintText: "Phone Number",
//                       isPassword: false,
//                       keyboardType: TextInputType.phone,
//                     ),
//                     const SizedBox(height: 10),
//                     _buildTextField(
//                       controller: emailController,
//                       hintText: "Email",
//                       isPassword: false,
//                       keyboardType: TextInputType.emailAddress,
//                     ),
//                     const SizedBox(height: 10),
//                     _buildTextField(
//                       controller: passwordController,
//                       hintText: "Password",
//                       isPassword: true,
//                     ),
//                     const SizedBox(height: 10),
//                     _buildTextField(
//                       controller: confirmPasswordController,
//                       hintText: "Confirm Password",
//                       isPassword: true,
//                     ),
//                     const SizedBox(height: 30),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: sendOTPAndNavigate,
//                         style: ElevatedButton.styleFrom(
//                           minimumSize: const Size(double.infinity, 50),
//                           backgroundColor: Colors.white,
//                           foregroundColor: Colors.black,
//                         ),
//                         child: const Text("Send OTP", style: TextStyle(fontSize: 19)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hintText,
//     required bool isPassword,
//     String? prefixText,
//     TextInputType? keyboardType,
//   }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: isPassword,
//       style: const TextStyle(color: Colors.black, fontSize: 16),
//       decoration: InputDecoration(
//         hintText: hintText,
//         prefixText: prefixText,
//         prefixStyle: const TextStyle(color: Colors.black),
//         hintStyle: const TextStyle(color: Colors.black),
//         filled: true,
//         fillColor: Colors.grey[300],
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(23),
//           borderSide: BorderSide(color: controller.text.isNotEmpty ? Colors.green : Colors.black, width: 1.5),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(23),
//           borderSide: const BorderSide(color: Colors.green, width: 2),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(23),
//           borderSide: const BorderSide(color: Colors.red, width: 1.5),
//         ),
//         focusedErrorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(23),
//           borderSide: const BorderSide(color: Colors.red, width: 2),
//         ),
//       ),
//       keyboardType: keyboardType,
//     );
//   }
// }
//
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter/material.dart';
// // import 'package:email_otp/email_otp.dart';
// // import 'package:flutter/services.dart';
// // import 'package:service_provider/Provider Panel/screens/otp_verification.dart';
// //
// // class RegisterScreen extends StatefulWidget {
// //   @override
// //   State<RegisterScreen> createState() => _RegisterScreenState();
// // }
// //
// // class _RegisterScreenState extends State<RegisterScreen> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController phoneController = TextEditingController();
// //   final TextEditingController emailController = TextEditingController();
// //   final TextEditingController passwordController = TextEditingController();
// //   final TextEditingController confirmPasswordController = TextEditingController();
// //
// //   final EmailOTP _emailOTP = EmailOTP();
// //
// //   void sendOTPAndNavigate() async {
// //     if (passwordController.text != confirmPasswordController.text) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Passwords do not match")),
// //       );
// //       return;
// //     }
// //
// //     bool result = await EmailOTP.sendOTP(email: emailController.text);
// //     if (result) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("OTP sent to your email")),
// //       );
// //
// //       // Save provider information in Firestore
// //       await FirebaseFirestore.instance
// //           .collection('providers') // Use a separate collection for providers
// //           .doc(emailController.text)
// //           .set({
// //         'name': nameController.text,
// //         'phone': phoneController.text,
// //         'email': emailController.text,
// //         'createdAt': FieldValue.serverTimestamp(),
// //         'role': 'provider', // Add a role to distinguish providers
// //       });
// //
// //       // Navigate to OTP verification screen
// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //           builder: (context) => OtpVerificationScreen(
// //             name: nameController.text,
// //             phone: phoneController.text,
// //             email: emailController.text,
// //             password: passwordController.text,
// //           ),
// //         ),
// //       );
// //     } else {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Failed to send OTP")),
// //       );
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         backgroundColor: Colors.white, // Keeps AppBar color fixed
// //         elevation: 0,
// //         bottomOpacity: 0,
// //         systemOverlayStyle: SystemUiOverlayStyle(
// //           statusBarColor: Colors.white, // Ensures status bar remains white
// //           statusBarIconBrightness: Brightness.dark, // Keeps icons dark for visibility
// //         ),
// //         leading: IconButton(
// //           padding: const EdgeInsets.all(20.0),
// //           icon: Icon(Icons.arrow_back, color: Colors.black, size: 25),
// //           onPressed: () {
// //             Navigator.pop(context);
// //           },
// //         ),
// //         actions: [
// //           Padding(
// //             padding: const EdgeInsets.only(right: 12.0),
// //             child: TextButton(
// //               onPressed: () {
// //                 // Navigate to login page if necessary
// //               },
// //               child: Text(
// //                 "Login",
// //                 style: TextStyle(color: Colors.black, fontSize: 18),
// //               ),
// //             ),
// //           ),
// //         ],
// //         flexibleSpace: Container(
// //           decoration: BoxDecoration(
// //             color: Colors.white, // Keeps background fixed even when scrolling
// //           ),
// //         ),
// //         toolbarHeight: 60, // Fixes the AppBar height
// //       ),
// //
// //       body: Column(
// //         children: [
// //           Container(
// //             height: MediaQuery.of(context).size.height * 0.20,
// //             padding: const EdgeInsets.only(top: 30, left: 24, right: 24),
// //             alignment: Alignment.centerLeft,
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 const Text(
// //                   'Register as a Provider',
// //                   style: TextStyle(
// //                     color: Colors.black,
// //                     fontSize: 38,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 10),
// //               ],
// //             ),
// //           ),
// //           Expanded(
// //             child: Container(
// //               decoration: const BoxDecoration(
// //                 color: Color(0xFF060644),
// //                 borderRadius: BorderRadius.only(
// //                   topLeft: Radius.circular(50),
// //                   topRight: Radius.circular(50),
// //                 ),
// //               ),
// //               padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 30),
// //               child: SingleChildScrollView(
// //                 child: Column(
// //                   children: [
// //                     _buildTextField(
// //                       controller: nameController,
// //                       hintText: "Full Name",
// //                       isPassword: false,
// //                     ),
// //                     const SizedBox(height: 10),
// //                     _buildTextField(
// //                       controller: phoneController,
// //                       hintText: "Phone Number",
// //                       isPassword: false,
// //                       keyboardType: TextInputType.phone,
// //                     ),
// //                     const SizedBox(height: 10),
// //                     _buildTextField(
// //                       controller: emailController,
// //                       hintText: "Email",
// //                       isPassword: false,
// //                       keyboardType: TextInputType.emailAddress,
// //                     ),
// //                     const SizedBox(height: 10),
// //                     _buildTextField(
// //                       controller: passwordController,
// //                       hintText: "Password",
// //                       isPassword: true,
// //                     ),
// //                     const SizedBox(height: 10),
// //                     _buildTextField(
// //                       controller: confirmPasswordController,
// //                       hintText: "Confirm Password",
// //                       isPassword: true,
// //                     ),
// //                     const SizedBox(height: 30),
// //                     SizedBox(
// //                       width: double.infinity,
// //                       height: 50,
// //                       child: ElevatedButton(
// //                         onPressed: sendOTPAndNavigate,
// //                         style: ElevatedButton.styleFrom(
// //                           minimumSize: const Size(double.infinity, 50),
// //                           backgroundColor: Colors.white,
// //                           foregroundColor: Colors.black,
// //                         ),
// //                         child: const Text("Send OTP", style: TextStyle(fontSize: 19)),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTextField({
// //     required TextEditingController controller,
// //     required String hintText,
// //     required bool isPassword,
// //     String? prefixText,
// //     TextInputType? keyboardType,
// //   }) {
// //     return TextFormField(
// //       controller: controller,
// //       obscureText: isPassword,
// //       style: const TextStyle(color: Colors.black, fontSize: 16),
// //       decoration: InputDecoration(
// //         hintText: hintText,
// //         prefixText: prefixText,
// //         prefixStyle: const TextStyle(color: Colors.black),
// //         hintStyle: const TextStyle(color: Colors.black),
// //         filled: true,
// //         fillColor: Colors.grey[300],
// //         enabledBorder: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(23),
// //           borderSide: BorderSide(color: controller.text.isNotEmpty ? Colors.green : Colors.black, width: 1.5),
// //         ),
// //         focusedBorder: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(23),
// //           borderSide: const BorderSide(color: Colors.green, width: 2),
// //         ),
// //         errorBorder: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(23),
// //           borderSide: const BorderSide(color: Colors.red, width: 1.5),
// //         ),
// //         focusedErrorBorder: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(23),
// //           borderSide: const BorderSide(color: Colors.red, width: 2),
// //         ),
// //       ),
// //       keyboardType: keyboardType,
// //     );
// //   }
// // }