import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // ברירת המחדל היא לפי הגדרות המערכת של המשתמש
    return ThemeMode.system;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    // בעתיד נוסיף כאן קוד ששומר את הבחירה ל-SharedPreferences (משימה #17)
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});