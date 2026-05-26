import 'package:flutter/material.dart';

extension AppThemeExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Backgrounds
  Color get scaffoldBg => isDarkMode ? const Color(0xFF111214) : const Color(0xFFF2F3F5);
  Color get cardBg => isDarkMode ? const Color(0xFF1A1B1F) : const Color(0xFFFFFFFF);
  Color get headerBg => isDarkMode ? const Color(0xFF111214) : const Color(0xFFFFFFFF);
  Color get border => isDarkMode ? const Color(0xFF2A2B30) : const Color(0xFFE5E6EB);

  // Text
  Color get textColor => isDarkMode ? const Color(0xFFEAEAED) : const Color(0xFF1A1B1F);
  Color get textSecondary => isDarkMode ? const Color(0xFF8A8B93) : const Color(0xFF6B6C75);
  Color get textTertiary => isDarkMode ? const Color(0xFF55565E) : const Color(0xFF9B9CA5);
  Color get textQuaternary => isDarkMode ? const Color(0xFF3A3B42) : const Color(0xFFBBBCC5);

  // Accent — signature green
  Color get accent => isDarkMode ? const Color(0xFF61D47C) : const Color(0xFF3DAE5A);
  Color get accentMuted => isDarkMode
      ? const Color(0xFF61D47C).withOpacity(0.15)
      : const Color(0xFF3DAE5A).withOpacity(0.12);

  // Semantic colors
  Color get liveColor => isDarkMode ? const Color(0xFFE85454) : const Color(0xFFD93636);
  Color get winColor => isDarkMode ? const Color(0xFF61D47C) : const Color(0xFF3DAE5A);
  Color get drawColor => isDarkMode ? const Color(0xFF8A8B93) : const Color(0xFF6B6C75);
  Color get lossColor => isDarkMode ? const Color(0xFFE85454) : const Color(0xFFD93636);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111214),
      cardColor: const Color(0xFF1A1B1F),
      dividerColor: const Color(0xFF2A2B30),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111214),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFEAEAED)),
        titleTextStyle: TextStyle(
          color: Color(0xFFEAEAED),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1B1F),
        selectedItemColor: Color(0xFF61D47C),
        unselectedItemColor: Color(0xFF55565E),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF2F3F5),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFE5E6EB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1A1B1F)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1B1F),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFF3DAE5A),
        unselectedItemColor: Color(0xFF9B9CA5),
      ),
    );
  }
}
