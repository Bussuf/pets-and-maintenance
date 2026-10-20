import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../providers/locale_provider.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    // הגדרות לאנדרואיד בלבד
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> requestPermissions() async {
    // בקשת הרשאה חיונית באנדרואיד 13 ומעלה
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> scheduleTaskReminder(AppTask task) async {
    // 1. אם המשימה ללא תאריך יעד, או שההתראה כבויה למשימה זו - בטל התראה קיימת וצא
    if (task.nextDueDate == null || task.isReminderEnabled == false) {
      await cancelReminder(task.id);
      return;
    }

    // 2. קריאת ההגדרות הגלובליות שנשמרו (שעה וסגנון)
    final prefs = await SharedPreferences.getInstance();
    final style = prefs.getString('notificationStyle') ?? 'grouped';

    if (style == 'none') {
      await cancelReminder(task.id);
      return;
    }

    final timeStr = prefs.getString('reminderTime') ?? '09:00';
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;

    // 3. מיזוג תאריך המשימה עם השעה שהמשתמש הגדיר במסך ההגדרות
    var scheduledDate = DateTime(
      task.nextDueDate!.year,
      task.nextDueDate!.month,
      task.nextDueDate!.day,
      hour,
      minute,
    );

    // הגנה: לא נתזמן התראות לתאריך או שעה שכבר עברו
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final l10n = LocaleNotifier.l10n;
    final androidDetails = AndroidNotificationDetails(
      'tasks_maintenance_channel',
      l10n.notifChannelName,
      channelDescription: l10n.notifChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
    );
    final details = NotificationDetails(android: androidDetails);

    // 4. תזמון ההתראה לפי הסגנון הנבחר
    if (style == 'separated') {
      // מצב נפרד: משתמש במזהה המשימה. עריכת משימה קיימת תדרוס את ההתראה הקודמת שלה!
      final int id = task.id.hashCode;
      await _notificationsPlugin.zonedSchedule(
        id,
        l10n.notifTaskTitle(task.name),
        task.description != null && task.description!.isNotEmpty
            ? task.description
            : l10n.notifTaskDefaultBody,
        tzDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else if (style == 'grouped') {
      // מצב מרוכז: המזהה הוא התאריך. כל המשימות לאותו יום יידרסו להתראה אחת מאוגדת.
      final int dateId = scheduledDate.year * 10000 + scheduledDate.month * 100 + scheduledDate.day;

      await _notificationsPlugin.zonedSchedule(
        dateId,
        l10n.notifGroupedTitle,
        l10n.notifGroupedBody,
        tzDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelReminder(String taskId) async {
    // ביטול נקודתי של התראה נפרדת במידה והמשתמש מוחק/מכבה משימה
    await _notificationsPlugin.cancel(taskId.hashCode);
  }
}