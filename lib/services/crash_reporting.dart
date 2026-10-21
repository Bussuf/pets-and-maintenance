import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// דוחות שגיאה אנונימיים ל-Firebase Crashlytics (#64).
/// נשלח רק מידע טכני (השגיאה, דגם, גרסת מערכת וגרסת אפליקציה) - אף פעם לא תוכן המאגר.
class CrashReporting {
  CrashReporting._();

  static const _prefKey = 'crashReportsEnabled';

  // --- דגלי בדיקה זמניים (שלב 2 של #64). להחזיר ל-false אחרי שהדוח הופיע בלוח! ---
  // בזמן פיתוח לא שולחים כלום, כדי שהבדיקות מהסטודיו לא ימלאו את הלוח
  static const _collectInDebug = false;
  // שולח דוח בדיקה אחד בכל פתיחה של האפליקציה
  static const _sendTestReport = false;

  static bool _enabled = true;

  /// האם המשתמש מאפשר דוחות (ברירת מחדל: כן). להצגה במסך ההגדרות
  static bool get enabled => _enabled;

  /// אתחול לפני runApp: Firebase, הגדרת השליחה, ותפיסת כל השגיאות שלא נתפסו
  static Future<void> init() async {
    await Firebase.initializeApp();

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? true;
    await _applyCollection();

    // שגיאות של Flutter (בנייה וציור מסכים)
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // שגיאות אסינכרוניות שלא נתפסו בשום מקום
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    if (_sendTestReport) {
      await recordError(Exception('PETS test report'), StackTrace.current, reason: 'test');
    }
  }

  /// שינוי מההגדרות - נשמר ומופעל מיד
  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    await _applyCollection();
  }

  /// שגיאה "שקטה" שנתפסה ב-catch: האפליקציה ממשיכה, אבל הדוח מגיע ללוח.
  /// במצב פיתוח היא גם מודפסת לקונסולה (כמו debugPrint)
  static Future<void> recordError(Object error, StackTrace? stack, {String? reason}) {
    return FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
  }

  static Future<void> _applyCollection() {
    return FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      _enabled && (_collectInDebug || !kDebugMode),
    );
  }
}
