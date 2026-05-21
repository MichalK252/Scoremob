import 'package:flutter/material.dart';

extension AppThemeExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Theme-aware color getters
  Color get scaffoldBg => isDarkMode ? const Color(0xFF0C0C0E) : const Color(0xFFF5F5F7);
  Color get cardBg => isDarkMode ? const Color(0xFF16161A) : const Color(0xFFFFFFFF);
  Color get headerBg => isDarkMode ? const Color(0xFF0E0E10) : const Color(0xFFEBEBF0);
  Color get border => isDarkMode ? const Color(0xFF24242A) : const Color(0xFFE2E2E7);
  
  Color get textColor => isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
  Color get textSecondary => isDarkMode ? Colors.white70 : const Color(0xFF636366);
  Color get textTertiary => isDarkMode ? Colors.white54 : const Color(0xFF8E8E93);
  Color get textQuaternary => isDarkMode ? Colors.white30 : const Color(0xFFAEAEB2);

  // Gradient helper
  List<Color> get containerGradient => isDarkMode
      ? [const Color(0xFF16161A), const Color(0xFF0D0D10)]
      : [const Color(0xFFFFFFFF), const Color(0xFFF9F9FB)];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0C0C0E),
      cardColor: const Color(0xFF16161A),
      dividerColor: const Color(0xFF24242A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0C0C0E),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0C0C0E),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFE2E2E7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F7),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1C1C1E)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1C1C1E),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Color(0xFF8E8E93),
      ),
    );
  }
}
