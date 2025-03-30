import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:service_provider/User%20Panel/user_login.dart';
import 'package:service_provider/User%20Panel/user_registration.dart';
import 'package:service_provider/User Panel/Usertheme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            return Stack(
              children: [
                // Top Section with Logo
                Container(
                  height: screenHeight * 0.70,
                  decoration: BoxDecoration(
                    gradient: UserTheme.primaryGradient,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: screenHeight * 0.05),
                        Image.asset(
                          "android/assets/logo.png",
                          width: screenWidth * 0.35,
                          fit: BoxFit.contain,
                        ),
                        Text(
                          'Quick Expert',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: UserTheme.onPrimaryTextColor,
                            fontSize: screenWidth * 0.08,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Section with Buttons
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: screenHeight * 0.35,
                    decoration: BoxDecoration(
                      color: UserTheme.surfaceColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: UserTheme.shadowColor,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.03,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Welcome',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: screenWidth * 0.09,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Welcome to Quick Expert! Log in to start offering your services and make an impact!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: screenWidth * 0.045,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // const Spacer(),
                        SizedBox(height: 50,),
                        Row(
                          children: [
                            // Sign In Button (Primary)
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: UserTheme.primaryColor,
                                  foregroundColor: UserTheme.onPrimaryTextColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.02,
                                  ),
                                  elevation: 2,
                                  shadowColor: UserTheme.shadowColor,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => LoginPage()),
                                  );
                                },
                                child: Text(
                                  'Sign In',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: screenWidth * 0.045,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            // Sign Up Button (Enhanced Secondary)
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    colors: [
                                      UserTheme.surfaceColor,
                                      UserTheme.backgroundColor,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: UserTheme.shadowColor.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: UserTheme.secondaryColor.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: UserTheme.secondaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.02,
                                    ),
                                    side: BorderSide.none, // Remove default border
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => RegistrationPage()),
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: screenWidth * 0.045,
                                      color: UserTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}