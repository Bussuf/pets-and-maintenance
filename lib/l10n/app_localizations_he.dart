// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'ניהול משימות חוזרות';

  @override
  String get save => 'שמירה';

  @override
  String get cancel => 'ביטול';

  @override
  String get delete => 'מחק';

  @override
  String get deletePermanently => 'מחק לצמיתות';

  @override
  String get newAction => 'חדש';

  @override
  String get task => 'משימה';

  @override
  String get item => 'פריט';

  @override
  String get category => 'קבוצה';

  @override
  String get all => 'הכל';

  @override
  String get noTasks => 'אין משימות דחופות כרגע!';

  @override
  String get activeTasks => 'משימות פעילות';

  @override
  String get overdueTasks => 'באיחור';

  @override
  String get doneNow => 'בוצע עכשיו';

  @override
  String get myGroups => 'הקבוצות שלי';

  @override
  String get name => 'שם';

  @override
  String get description => 'תיאור (אופציונלי)';

  @override
  String get repeatEvery => 'כל כמה זמן?';

  @override
  String get days => 'ימים';

  @override
  String get weeks => 'שבועות';

  @override
  String get months => 'חודשים';

  @override
  String get years => 'שנים';

  @override
  String get requiredField => 'שדה חובה';

  @override
  String get selectCategory => 'שייך לקבוצה';

  @override
  String get selectItem => 'שייך לפריט';

  @override
  String get addTaskTitleHint => 'הוספת שם למשימה';

  @override
  String get addItemTitleHint => 'שם הפריט';

  @override
  String get addCategoryTitleHint => 'שם הקבוצה';

  @override
  String get color => 'צבע (אופציונלי)';

  @override
  String get icon => 'סמל (אופציונלי)';

  @override
  String get addQuick => '+ חדש';

  @override
  String get endConditionTitle => 'משך';

  @override
  String get endConditionAlways => 'תמיד';

  @override
  String get endConditionCount => 'מספר פעמים ספציפי';

  @override
  String get endConditionUntil => 'עד תאריך';

  @override
  String get selectDate => 'בחר תאריך';

  @override
  String get times => 'פעמים';

  @override
  String savedSuccessfully(String entityName, String repositoryName) {
    return '$entityName נשמר בהצלחה ב$repositoryName';
  }

  @override
  String get lightMode => 'מצב בהיר';

  @override
  String get darkMode => 'מצב כהה';

  @override
  String get systemMode => 'הגדרות מערכת';

  @override
  String dueDateLabel(String date) {
    return 'תאריך לביצוע: $date';
  }

  @override
  String overdueDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ימי איחור',
      two: 'יומיים באיחור',
      one: 'יום אחד באיחור',
    );
    return '$_temp0';
  }

  @override
  String get backupSection => 'גיבוי ושחזור';

  @override
  String get backupExport => 'ייצוא גיבוי';

  @override
  String get backupExportSubtitle =>
      'שמירת כל הנתונים לקובץ (Drive, וואטסאפ, קבצים...)';

  @override
  String get backupImport => 'שחזור מגיבוי';

  @override
  String get backupImportSubtitle => 'טעינת קובץ גיבוי במקום הנתונים הנוכחיים';

  @override
  String get backupImportConfirmTitle => 'לשחזר מגיבוי?';

  @override
  String get backupImportConfirmBody =>
      'כל הקבוצות, הפריטים והמשימות הנוכחיים יוחלפו בתוכן הקובץ. מומלץ לייצא קודם גיבוי של המצב הנוכחי.';

  @override
  String get backupImportConfirmAction => 'בחר קובץ';

  @override
  String get backupImportSuccess => 'הנתונים שוחזרו בהצלחה';

  @override
  String backupFailed(String error) {
    return 'הפעולה נכשלה: $error';
  }
}
