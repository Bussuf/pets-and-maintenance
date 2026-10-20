import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';

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

  /// תרגום לשימוש מחוץ למסכים (התראות, יומן גוגל) - לפי השפה שנבחרה, או שפת המכשיר
  static AppLocalizations get l10n {
    final code = (_initial ?? WidgetsBinding.instance.platformDispatcher.locale).languageCode;
    final isSupported = AppLocalizations.supportedLocales.any((l) => l.languageCode == code);
    // שפה שלא נתמכת - נופלים לאנגלית, בדיוק כמו האפליקציה עצמה
    return lookupAppLocalizations(Locale(isSupported ? code : 'en'));
  }

  @override
  Locale? build() => _initial;

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    _initial = locale; // כדי ש-l10n (של ההתראות/היומן) יכיר את הבחירה החדשה
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
    // טקסטי ההתראות שכבר תוזמנו - לשפה החדשה
    await NotificationService.instance.rescheduleAll();
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(() {
  return LocaleNotifier();
});