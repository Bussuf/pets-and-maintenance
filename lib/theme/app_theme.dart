import 'package:flutter/material.dart';

class AppTheme {
  // צבעי Google Stock ראשיים
  static const Color googleBlue = Color(0xFF1A73E8);
  static const Color googleBlueLight = Color(0xFF4C8DFF);
  static const Color dangerRed = Color(0xFFD93025);

  // תאימות לאחור לווידג'טים שמשתמשים בשמות הקודמים
  static const Color primaryColor = googleBlue;
  static const Color accentPurple = Color(0xFF8AB4F8);
  static const Color dangerColor = dangerRed;

  // ערכת נושא בהירה (Light Mode)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: googleBlue,
        brightness: Brightness.light,
        surface: const Color(0xFFF8F9FA),
        error: dangerRed,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1F1F1F)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1F1F1F),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      // שימוש ב-CardThemeData לפי הגרסאות העדכניות של Flutter
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E2EC), width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: googleBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  // ערכת נושא כהה (Dark Mode)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: googleBlueLight,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1F22),
        error: dangerRed,
      ),
      scaffoldBackgroundColor: const Color(0xFF131314),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF131314),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      // שימוש ב-CardThemeData לפי הגרסאות העדכניות של Flutter
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1F22),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2E2F33), width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: googleBlueLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}