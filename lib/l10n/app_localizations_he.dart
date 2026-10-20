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

  @override
  String get addItemToGroup => 'הוסף פריט לקבוצה';

  @override
  String get languageSection => 'שפה';

  @override
  String get languageSystem => 'מערכת';

  @override
  String get allGroups => 'כל הקבוצות';

  @override
  String get noGroupsYet => 'אין קבוצות עדיין';

  @override
  String errorWithDetails(String error) {
    return 'שגיאה: $error';
  }

  @override
  String get deleteGroupWarning =>
      'מחיקת הקבוצה תמחוק גם את כל הפריטים והמשימות שבתוכה (מחיקת שרשרת). האם להמשיך?';

  @override
  String get deleteItemWarning =>
      'מחיקת הפריט תמחוק גם את כל המשימות המשויכות אליו. האם להמשיך?';

  @override
  String deleteNamed(String name) {
    return 'מחיקת $name';
  }

  @override
  String get organizeGroups => 'ארגון קבוצות';

  @override
  String organizeNamed(String name) {
    return 'ארגון: $name';
  }

  @override
  String get doneReordering => 'סיום סידור';

  @override
  String get reorder => 'ארגון מחדש';

  @override
  String get addNew => 'הוסף חדש';

  @override
  String get noData => 'אין נתונים להצגה.';

  @override
  String editItemNamed(String name) {
    return 'עריכת פריט: $name';
  }

  @override
  String get deleteItem => 'מחיקת פריט';

  @override
  String deleteItemConfirm(String name) {
    return 'האם למחוק את הפריט \"$name\" ואת כל המשימות המשויכות אליו?';
  }

  @override
  String get saveChanges => 'שמור שינויים';

  @override
  String get chooseGroupIcon => 'בחר סמל לקבוצה';

  @override
  String get editGroup => 'עריכת קבוצה';

  @override
  String get deleteGroup => 'מחיקת קבוצה';

  @override
  String deleteGroupConfirm(String name) {
    return 'האם למחוק את הקבוצה \"$name\"? כל הפריטים והמשימות שבה יימחקו לצמיתות.';
  }

  @override
  String get groupIconLabel => 'סמל קבוצה:';

  @override
  String get changeIcon => 'החלף סמל';

  @override
  String get groupColorLabel => 'צבע קבוצה:';

  @override
  String get groupNameExists => 'שם קבוצה זה כבר קיים';

  @override
  String get openMenu => 'תפריט צד';

  @override
  String get searchHint => 'חיפוש משימות, פריטים או קבוצות...';

  @override
  String get settingsTitle => 'הגדרות מערכת';

  @override
  String get searchPrompt => 'הקלד כדי לחפש משימות, פריטים או קבוצות...';

  @override
  String get noResults => 'לא נמצאו תוצאות';

  @override
  String get tasksHeader => 'משימות';

  @override
  String get itemsHeader => 'פריטים';

  @override
  String get groupsHeader => 'קבוצות';

  @override
  String searchTaskSubtitle(String item, String group) {
    return 'משימה • $item • $group';
  }

  @override
  String searchItemSubtitle(String group) {
    return 'פריט • שייך לקבוצה: $group';
  }

  @override
  String get mainGroup => 'קבוצה ראשית';

  @override
  String get today => 'היום';

  @override
  String get tomorrow => 'מחר';

  @override
  String get later => 'מאוחר יותר';

  @override
  String allWithCount(int count) {
    return 'הכל ($count)';
  }

  @override
  String get editItem => 'עריכת פריט';

  @override
  String get noTasksInGroup => 'אין משימות להצגה בקבוצה זו';

  @override
  String goToGroupNamed(String name) {
    return 'עבור לקבוצה \"$name\"';
  }

  @override
  String get pressAgainToExit => 'לחץ שוב ליציאה';

  @override
  String get allGroupsAndTasks => 'כל הקבוצות והמשימות';

  @override
  String summaryWithOverdue(int active, int overdue) {
    String _temp0 = intl.Intl.pluralLogic(
      active,
      locale: localeName,
      other: '$active משימות פעילות',
      one: 'משימה פעילה אחת',
    );
    return '$_temp0 • $overdue באיחור';
  }

  @override
  String summaryAllClear(int active) {
    String _temp0 = intl.Intl.pluralLogic(
      active,
      locale: localeName,
      other: '$active משימות פעילות',
      one: 'משימה פעילה אחת',
    );
    return '$_temp0 • כל המשימות מעודכנות 🎉';
  }

  @override
  String get groupOptions => 'אפשרויות קבוצה';

  @override
  String get noTasksNow => 'אין משימות להצגה כרגע';

  @override
  String frequencyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'תדירות: כל $n ימים',
      two: 'תדירות: כל יומיים',
      one: 'תדירות: כל יום',
    );
    return '$_temp0';
  }

  @override
  String frequencyWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'תדירות: כל $n שבועות',
      two: 'תדירות: כל שבועיים',
      one: 'תדירות: כל שבוע',
    );
    return '$_temp0';
  }

  @override
  String frequencyMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'תדירות: כל $n חודשים',
      two: 'תדירות: כל חודשיים',
      one: 'תדירות: כל חודש',
    );
    return '$_temp0';
  }

  @override
  String frequencyYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'תדירות: כל $n שנים',
      two: 'תדירות: כל שנתיים',
      one: 'תדירות: כל שנה',
    );
    return '$_temp0';
  }

  @override
  String get calendarUpdatedOnCompletion => 'עודכן עקב השלמת משימה';

  @override
  String taskCompletedNext(String name, String date) {
    return 'משימה \"$name\" הושלמה! יעד הבא: $date';
  }

  @override
  String get pickActualCompletionDate => 'בחר תאריך ביצוע בפועל';

  @override
  String get general => 'כללי';

  @override
  String get notSet => 'לא נקבע';

  @override
  String get neverDone => 'טרם בוצע';

  @override
  String lastDoneLabel(String date) {
    return 'בוצע לאחרונה: $date';
  }

  @override
  String get complete => 'השלם';

  @override
  String get statistics => 'סטטיסטיקות';

  @override
  String get comingSoon => 'יוטמע בהמשך';

  @override
  String get manualCompletion => 'ביצוע ידני';

  @override
  String get duplicate => 'שכפל';

  @override
  String get edit => 'ערוך';

  @override
  String get newGroup => 'קבוצה חדשה';

  @override
  String get newItem => 'פריט חדש';

  @override
  String calendarGroupLabel(String name) {
    return 'קבוצה: $name';
  }

  @override
  String saveFailed(String error) {
    return 'שגיאה בשמירה: $error';
  }

  @override
  String get createNew => 'יצירת חדש';

  @override
  String get chooseIcon => 'בחר סמל';

  @override
  String get quantity => 'כמות';

  @override
  String get remindMe => 'קבל תזכורת למכשיר';

  @override
  String get reminderSubtitle => 'התראה תופיע בהתאם להגדרות המערכת';

  @override
  String get syncGoogleCalendar => 'סנכרן ליומן גוגל';

  @override
  String get willCreateAllDayEvent => 'ייווצר אירוע יום שלם';

  @override
  String get connectInSettings => 'יש להתחבר דרך מסך ההגדרות';

  @override
  String get editTask => 'עריכת משימה';

  @override
  String get deleteTask => 'מחיקת משימה';

  @override
  String deleteTaskConfirm(String name) {
    return 'האם למחוק לצמיתות את המשימה \"$name\"?';
  }

  @override
  String get taskDeleted => 'המשימה נמחקה בהצלחה';

  @override
  String deleteFailed(String error) {
    return 'שגיאה במחיקה: $error';
  }

  @override
  String get taskNameLabel => 'שם המשימה';

  @override
  String get errorLoadingGroups => 'שגיאה בטעינת קבוצות';

  @override
  String get errorLoadingItems => 'שגיאה בטעינת פריטים';

  @override
  String get chooseGroupFirst => 'בחר קבוצה קודם';

  @override
  String get eventWillUpdate => 'האירוע יעודכן ביומן';

  @override
  String get fillNameAndItem => 'נא למלא שם משימה ולשייך לפריט';

  @override
  String get calendarAddedFromApp => 'נוסף מאפליקציית Pets & Maintenance';

  @override
  String get calendarUpdatedFromApp => 'עודכן מהאפליקציה';

  @override
  String get savedOk => 'נשמר בהצלחה!';

  @override
  String get appearanceSection => 'מראה ותצוגה';

  @override
  String get themeLight => 'בהיר';

  @override
  String get themeDark => 'כהה';

  @override
  String get notificationsSection => 'התראות ותזכורות';

  @override
  String get notifSeparated => 'נפרד';

  @override
  String get notifGrouped => 'מרוכז';

  @override
  String get notifNone => 'ללא';

  @override
  String get notifGroupedDesc =>
      'התראה אחת ביום המאגדת את כל המשימות לאותו יום';

  @override
  String get notifSeparatedDesc => 'קבלת התראה נפרדת לכל משימה';

  @override
  String get notifNoneDesc => 'התראות האפליקציה כבויות';

  @override
  String get dailyReminderTime => 'שעת תזכורת יומית';

  @override
  String get notificationsOff => 'התראות כבויות';

  @override
  String reminderAt(String time) {
    return 'בשעה $time (לחץ לשינוי)';
  }

  @override
  String get pickReminderTime => 'בחר שעת תזכורת';

  @override
  String get ok => 'אישור';

  @override
  String get reminderTimeUpdated => 'שעת ההתראות עודכנה בהצלחה';

  @override
  String get syncSection => 'סנכרון ושירותים';

  @override
  String get googleCalendarSync => 'סנכרון יומן גוגל';

  @override
  String connectedAs(String email) {
    return 'מחובר:\n$email';
  }

  @override
  String get notConnectedGoogle => 'לא מחובר ליומן גוגל';

  @override
  String get disconnect => 'ניתוק';

  @override
  String get connect => 'התחבר';

  @override
  String get contentSection => 'ניהול תוכן';

  @override
  String get organizeGroupsItems => 'ארגון קבוצות ופריטים';

  @override
  String get organizeSubtitle => 'עריכה, מחיקה וסידור מחדש של התוכן';

  @override
  String get notifChannelName => 'משימות ותחזוקה';

  @override
  String get notifChannelDesc => 'התראות עבור משימות הבית';

  @override
  String notifTaskTitle(String name) {
    return 'תזכורת: $name';
  }

  @override
  String get notifTaskDefaultBody => 'הגיע הזמן לבצע את המשימה';

  @override
  String get notifGroupedTitle => '🏠 משימות להיום';

  @override
  String get notifGroupedBody =>
      'יש לך משימות תחזוקה שנקבעו להיום. היכנס לאפליקציה לצפייה בפירוט.';

  @override
  String calendarEventTitle(String name) {
    return '🏠 תחזוקה: $name';
  }

  @override
  String get calendarAutoCreated =>
      'נוצר אוטומטית מאפליקציית Pets & Maintenance';

  @override
  String get generalSection => 'כללי';

  @override
  String get themeTitle => 'ערכת נושא';

  @override
  String get followSystem => 'לפי המערכת';

  @override
  String get notificationStyleTitle => 'סגנון התראות';

  @override
  String get aboutSection => 'אודות';

  @override
  String get versionTitle => 'גרסה';

  @override
  String get dateFormatTitle => 'פורמט תאריך';

  @override
  String get dateFormatAuto => 'לפי השפה';

  @override
  String get dateFormatDmy => 'יום/חודש/שנה';

  @override
  String get dateFormatMdy => 'חודש/יום/שנה';

  @override
  String get dateFormatYmd => 'שנה-חודש-יום';

  @override
  String get googleSignInFailed =>
      'ההתחברות לגוגל נכשלה. בדוק את החיבור לאינטרנט ונסה שוב.';

  @override
  String get googleConnected => 'מחובר ליומן גוגל';

  @override
  String get googleDisconnected => 'נותקת מיומן גוגל';

  @override
  String get finishedTasks => 'הסתיימו';

  @override
  String get taskFinishedLabel => 'הסתיימה';

  @override
  String get extraCompletionLogged => 'ביצוע נוסף נרשם ✓';

  @override
  String get calendarCreateFailed =>
      'נשמר, אבל לא נוסף ליומן גוגל. אפשר לנסות שוב בעריכת המשימה.';

  @override
  String get calendarSyncFailed =>
      'השינויים נשמרו, אבל יומן גוגל לא עודכן. בדוק את החיבור לאינטרנט ונסה שוב.';

  @override
  String get calendarDeleteFailed =>
      'המשימה נמחקה, אבל האירוע נשאר ביומן גוגל. אפשר למחוק אותו ידנית.';

  @override
  String get calendarNotUpdated => 'יומן גוגל לא עודכן (אין חיבור?)';

  @override
  String durationDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ימים',
      two: 'יומיים',
      one: 'יום אחד',
    );
    return '$_temp0';
  }

  @override
  String get monthsApproxOne => 'כחודש';

  @override
  String get monthsApproxTwo => 'כחודשיים';

  @override
  String monthsApproxMany(String n) {
    return 'כ-$n חודשים';
  }

  @override
  String overdueBy(String duration) {
    return 'באיחור $duration';
  }
}
