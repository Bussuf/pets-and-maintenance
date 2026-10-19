import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// שפת האפליקציה. null = לפי שפת המערכת
class LocaleNotifier extends Notifier<Locale?> {
  static const String _localeKey = 'app_locale';
  static Locale? _initial;

  /// נטען לפני runApp - כדי שלא יהיה "הבהוב" של שפה אחרת בפתיחת האפליקציה
  static Future<void> preload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_localeKey);
      if (code != null) _initial = Locale(code);
    } catch (e) {
      debugPrint('Failed to load locale: $e');
    }
  }

  @override
  Locale? build() => _initial;

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_localeKey);
      } else {
        await prefs.setString(_localeKey, locale.languageCode);
      }
    } catch (e) {
      debugPrint('Failed to save locale: $e');
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(() {
  return LocaleNotifier();
});