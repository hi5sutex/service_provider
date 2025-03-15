import 'package:flutter/material.dart';

class AppTheme {
  // Original palette
  static const Color lightLavender = Color(0xFFF2D7EE);
  static const Color softMauve = Color(0xFFD3BCC0);
  static const Color mutedPlum = Color(0xFFA5668B);
  static const Color deepPurple = Color(0xFF69306D);
  static const Color darkNavy = Color(0xFF0E103D);

  // Primary and secondary colors
  static const Color primaryColorCustom = Color(0xFF060644); // Dark Blue
  static const Color secondaryColorCustom = Color(0xFFFFFFFF); // White
  static const Color secondarytext = Color(0xFFB0B0C0); // White


  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColorCustom,
      primarySwatch: MaterialColor(
        primaryColorCustom.value,
        const {
          50: Color(0xFFE6E6F0),
          100: Color(0xFFB3B3D6),
          200: Color(0xFF8080BB),
          300: Color(0xFF4D4DA0),
          400: Color(0xFF26268C),
          500: primaryColorCustom,
          600: Color(0xFF05053E),
          700: Color(0xFF040435),
          800: Color(0xFF03032C),
          900: Color(0xFF02021C),
        },
      ),

      scaffoldBackgroundColor: lightLavender,
      canvasColor: lightLavender,

      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColorCustom,
        foregroundColor: secondaryColorCustom,
        elevation: 2,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: primaryColorCustom, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: primaryColorCustom),
        bodyLarge: TextStyle(color: primaryColorCustom),
        bodyMedium: TextStyle(color: darkNavy),
        labelLarge: TextStyle(color: secondaryColorCustom),
      ),

      // Updated ElevatedButton theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepPurple, // #69306D for Sign In
          foregroundColor: secondaryColorCustom, // White text/icon
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),

      // Updated OutlinedButton theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: mutedPlum, // #A5668B for Sign Up text
          backgroundColor: secondaryColorCustom, // White background
          side: BorderSide(color: mutedPlum), // #A5668B border
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),

      cardTheme: const CardTheme(
        color: softMauve,
        elevation: 1,
      ),

      iconTheme: const IconThemeData(
        color: primaryColorCustom,
      ),

      colorScheme: ColorScheme.light(
        primary: primaryColorCustom,
        secondary: secondaryColorCustom,
        surface: softMauve,
        background: lightLavender,
        onPrimary: secondaryColorCustom,
        onSecondary: primaryColorCustom,
        onSurface: darkNavy,
        onBackground: darkNavy,
      ).copyWith(secondary: secondaryColorCustom),
    );
  }
}