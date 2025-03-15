import 'package:flutter/material.dart';
import 'package:service_provider/User%20Panel/user_login.dart';
import 'package:service_provider/User%20Panel/user_registration.dart';
import 'theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryColorCustom,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              color: AppTheme.primaryColorCustom,
              height: screenHeight * 0.65,
              width: double.infinity,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "android/assets/logo.png",
                      width: screenWidth * 0.35,
                      height: screenHeight * 0.2,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Quick Expert',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: screenWidth * 0.08,
                        color: AppTheme.secondaryColorCustom,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenHeight * 0.35,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColorCustom,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.015,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Welcome',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: screenWidth * 0.09,
                        color: AppTheme.primaryColorCustom,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Welcome to Quick Expert! Log in to start offering your services and make an impact!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: screenWidth * 0.045,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => LoginPage()),
                              );
                            },
                            style: theme.elevatedButtonTheme.style?.copyWith(
                              padding: MaterialStateProperty.all(
                                EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                              ),
                            ),
                            child: Text(
                              'Sign In',
                              style: TextStyle(fontSize: screenWidth * 0.045),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => RegistrationPage()),
                              );
                            },
                            style: theme.outlinedButtonTheme.style?.copyWith(
                              padding: MaterialStateProperty.all(
                                EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                              ),
                            ),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(fontSize: screenWidth * 0.045),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}