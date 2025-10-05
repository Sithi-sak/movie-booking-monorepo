import 'package:flutter/material.dart';

class AppTheme {
  // Primary Color
  static const Color primaryRed = Color(0xFFCE2029);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF2A2A2A);
  static const Color borderDark = Color(0xFF404040);

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textTertiary = Color(0xFF6E7681);

  // Status Colors
  static const Color success = Color(0xFF238636);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFDA3633);

  // Gradient
  static const LinearGradient redGradient = LinearGradient(
    colors: [primaryRed, Color(0xFFB01E24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Simple dark theme
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primaryRed,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: ColorScheme.dark(
      primary: primaryRed,
      brightness: Brightness.dark,
      surface: surfaceDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundDark,
      surfaceTintColor: Colors.transparent,
      foregroundColor: textPrimary,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );

  // Helper method for status colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'success':
        return success;
      case 'pending':
      case 'warning':
        return warning;
      case 'cancelled':
      case 'error':
        return error;
      default:
        return textSecondary;
    }
  }
}
