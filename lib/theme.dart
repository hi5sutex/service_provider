import 'package:flutter/material.dart';

class AppTheme {
  // Original palette
  // static const Color lightLavender = Color(0xFFFFFFFF);
  static const Color lightLavender = Color(0xFFF2D7EE);
  static const Color softMauve = Color(0xFFFFFFFF);
  // static const Color softMauve = Color(0xFFD3BCC0);
  // static const Color mutedPlum = Color(0xFFA5668B);
  static const Color mutedPlum = Color(0xFFFFFFFF);
  // static const Color deepPurple = Color(0xFF69306D);
  static const Color deepPurple = Color(0xFFFFFFFF);
  static const Color darkNavy = Color(0xFF0E103D);

  // Primary and secondary colors
  static const Color primaryColorCustom = Color(0xFF060644); // Dark Blue
  static const Color secondaryColorCustom = Color(0xFFFFFFFF); // White

  // New colors
  static const Color greyLight = Color(0xFFB0BEC5); // Approx Colors.grey[300]
  static const Color providerGreen = Color(0xFF4CAF50); // Approx Colors.green
  static const Color errorRed = Color(0xFFF44336); // Approx Colors.red

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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(deepPurple),
          foregroundColor: MaterialStateProperty.all(secondaryColorCustom),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(secondaryColorCustom),
          foregroundColor: MaterialStateProperty.all(mutedPlum),
          side: MaterialStateProperty.all(BorderSide(color: mutedPlum)),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
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