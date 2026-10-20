import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_provider.dart';

/// פורמט התאריך שהמשתמש בחר: 'auto' (לפי השפה), 'dmy', 'mdy', 'ymd'
class DateFormatNotifier extends Notifier<String> {
  static const String _key = 'date_format';
  static const List<String> options = ['auto', 'dmy', 'mdy', 'ymd'];
  static String _current = 'auto';

  /// נטען לפני runApp - כדי שהתאריכים יוצגו נכון כבר במסך הראשון
  static Future<void> preload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null && options.contains(saved)) _current = saved;
    } catch (e) {
      debugPrint('Failed to load date format: $e');
    }
  }

  /// עיצוב תאריך לפי בחירת המשתמש - פונקציה אחת לכל האפליקציה.
  /// pattern מאפשר להציג דוגמה של פורמט מסוים (בגיליון הבחירה)
  static String format(DateTime date, {String? pattern}) {
    var p = pattern ?? _current;
    if (p == 'auto') {
      // לפי שפת האפליקציה: באנגלית חודש/יום, בשאר השפות יום/חודש
      p = LocaleNotifier.l10n.localeName.startsWith('en') ? 'mdy' : 'dmy';
    }
    switch (p) {
      case 'mdy':
        return DateFormat('MM/dd/yy').format(date);
      case 'ymd':
        return DateFormat('yyyy-MM-dd').format(date);
      default:
        return DateFormat('dd/MM/yy').format(date);
    }
  }

  @override
  String build() => _current;

  Future<void> setFormat(String pattern) async {
    state = pattern;
    _current = pattern;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, pattern);
    } catch (e) {
      debugPrint('Failed to save date format: $e');
    }
  }
}

final dateFormatProvider = NotifierProvider<DateFormatNotifier, String>(() {
  return DateFormatNotifier();
});
