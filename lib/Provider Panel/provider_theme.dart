import 'package:flutter/material.dart';

class ProviderTheme {
  // Core Colors
  static const Color primaryColor = Color(0xFF060644); // Dark Navy Blue
  static const Color secondaryColor = Color(0xFF8B9EB2); // Steel Blue
  static const Color backgroundColor = Color(0xFFF5F7FA); // Light Grey-Blue
  static const Color surfaceColor = Color(0xFFFFFFFF); // White
  static const Color accentColor = Color(0xFF008CFF); //  Electric Blu

  // Text Colors
  static const Color primaryTextColor = Color(0xFF060644); // Dark Navy Blue
  static const Color secondaryTextColor = Color(0xFF6B7280); // Cool Grey
  static const Color disabledTextColor = Color(0xFFB0B8C4); // Light Grey
  static const Color onPrimaryTextColor = Color(0xFFFFFFFF); // White
  static const Color errorTextColor = Color(0xFFD32F2F); // Red

  // Status Colors
  static const Color pendingColor = Color(0xFF607D8B); // Blue-Grey
  static const Color confirmedColor = Color(0xFF0288D1); // Light Blue (new)
  static const Color ongoingColor = Color(0xFF7B1FA2); // Deep Purple
  static const Color completedColor = Color(0xFF388E3C); // Forest Green
  static const Color canceledColor = Color(0xFFD32F2F);
  static const Color errorColor = Color(0xFFD32F2F);// Red

  // Button Colors
  static const Color defaultButtonColor = Color(0xFF060644); // Dark Navy Blue
  static const Color secondaryButtonColor = Color(0xFF8B9EB2); // Steel Blue
  static const Color disabledButtonColor = Color(0xFFE0E6ED); // Light Grey

  // Additional Colors
  static const Color dividerColor = Color(0xFFD1D9E1); // Light Grey-Blue
  static const Color shadowColor = Color(0x29000000); // Black 16% opacity
  static const Color successColor = Color(0xFF388E3C); // Forest Green
  static const Color warningColor = Color(0xFFFBC02D); // Yellow
  static const Color cardHighlightColor = Color(0xFFF1F4F8); // Very Light Grey-Blue (new)

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF060644), Color(0xFF1E2A78)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFF8B9EB2), Color(0xFFFFD700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient goldenGradient = LinearGradient(
    colors: [Color(0xFFDAA520), Color(0xFFFFD700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme Data
  static ThemeData get themeData => ThemeData(
    primaryColor: primaryColor,
    secondaryHeaderColor: secondaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: surfaceColor,
    dividerColor: dividerColor,
    shadowColor: shadowColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryTextColor,
      elevation: 4,
      titleTextStyle: TextStyle(
        color: onPrimaryTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: primaryTextColor, fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: primaryTextColor, fontSize: 24, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: primaryTextColor, fontSize: 20, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: primaryTextColor, fontSize: 16),
      bodyMedium: TextStyle(color: secondaryTextColor, fontSize: 14),
      labelLarge: TextStyle(color: onPrimaryTextColor, fontSize: 16, fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: defaultButtonColor,
        foregroundColor: onPrimaryTextColor,
        disabledBackgroundColor: disabledButtonColor,
        disabledForegroundColor: disabledTextColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryColor,
        side: const BorderSide(color: secondaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: secondaryTextColor),
      hintStyle: const TextStyle(color: disabledTextColor),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Color(0xFFEAF3EC),
      contentTextStyle: const TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    // snackBarTheme: const SnackBarThemeData(
    //   backgroundColor: primaryColor,
    //   contentTextStyle: TextStyle(color: onPrimaryTextColor),
    //   actionTextColor: accentColor,
    // ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      circularTrackColor: secondaryColor,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryTextColor,
    ),


  );

}