import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/database_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../providers/items_provider.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../models/task_log.dart';
import '../providers/date_format_provider.dart';
import 'google_calendar_service.dart';
import 'notification_service.dart';

/// מחיקת משימה עם אישור - משותף לעריכת משימה ולדף ניתוח מעקב משימה (#25).
/// כולל: אירוע ביומן גוגל, התראה, ורענון המסכים. מחזיר true אם המשימה נמחקה
Future<bool> deleteTaskWithConfirm(BuildContext context, WidgetRef ref, Map<String, dynamic> task) async {
  final l10n = AppLocalizations.of(context)!;
  final confirm = await ConfirmDeleteDialog.show(
    context,
    title: l10n.deleteTask,
    content: l10n.deleteTaskConfirm(task['name']),
    onConfirm: () {},
  );
  if (confirm != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  try {
    // מחיקה מהיומן במידה וקיים מזהה גוגל
    bool calendarOk = true; // #54
    if (task['google_event_id'] != null) {
      calendarOk = await GoogleCalendarService.instance.deleteEvent(task['google_event_id']);
    }

    final rawDb = await ref.read(databaseProvider).database;
    await rawDb.delete('tasks', where: 'id = ?', whereArgs: [task['id']]);

    // הגנה מפני קריסה שקטה בשירות ההתראות
    try {
      await NotificationService.instance.cancelReminder(task['id']);
    } catch (e) {
      debugPrint('Failed to cancel reminder: $e');
    }

    // רענון ריאקטיבי מיידי של הממשק
    ref.invalidate(dashboardTasksProvider);
    if (task['category_id'] != null) {
      ref.invalidate(tasksByCategoryProvider(task['category_id']));
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(calendarOk ? l10n.taskDeleted : l10n.calendarDeleteFailed),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.deleteFailed('$e')), backgroundColor: Colors.red),
    );
    return false;
  }
}

/// רענון כל מה שמושפע מביצועים של משימה: היסטוריה, הדשבורד ודף הקבוצה
void _refreshAfterLogChange(WidgetRef ref, Map<String, dynamic> task) {
  ref.invalidate(logsByTaskProvider(task['id']));
  ref.invalidate(dashboardTasksProvider);
  if (task['category_id'] != null) ref.invalidate(tasksByCategoryProvider(task['category_id']));
}

/// תיקון תאריך של ביצוע (#25.9). היעד שהביצוע סגר (due_at) נשאר - כך שתיקון יכול להפוך איחור ל'בזמן'.
/// המונה ו'בוצע לאחרונה' מתעדכנים; היעד הבא, ההתראה והיומן - לא
Future<void> editCompletionDate(BuildContext context, WidgetRef ref, TaskLog log, Map<String, dynamic> task) async {
  final l10n = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: log.completedAt.isAfter(now) ? now : log.completedAt,
    firstDate: DateTime(2020),
    lastDate: now,
    helpText: l10n.fixCompletionDate,
  );
  if (picked == null || !context.mounted) return;

  // שומרים את השעה המקורית - משנים רק את היום
  final newDate = DateTime(picked.year, picked.month, picked.day, log.completedAt.hour, log.completedAt.minute);
  final messenger = ScaffoldMessenger.of(context);
  final db = ref.read(databaseProvider);
  await db.updateTaskLogDate(log.id, newDate);
  await db.recalcTaskFromLogs(task['id']);
  _refreshAfterLogChange(ref, task);

  messenger.showSnackBar(
    SnackBar(content: Text(l10n.completionUpdated), behavior: SnackBarBehavior.floating),
  );
}

/// מחיקת ביצוע עם אישור (#25.9). כמו בתיקון - לא נוגע בתזמון (גם משימה שהסתיימה נשארת 'הסתיימה')
Future<void> deleteCompletionWithConfirm(BuildContext context, WidgetRef ref, TaskLog log, Map<String, dynamic> task) async {
  final l10n = AppLocalizations.of(context)!;
  final confirm = await ConfirmDeleteDialog.show(
    context,
    title: l10n.deleteCompletion,
    content: l10n.deleteCompletionConfirm(DateFormatNotifier.format(log.completedAt)),
    onConfirm: () {},
  );
  if (confirm != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final db = ref.read(databaseProvider);
  await db.deleteTaskLog(log.id);
  await db.recalcTaskFromLogs(task['id']);
  _refreshAfterLogChange(ref, task);

  messenger.showSnackBar(
    SnackBar(content: Text(l10n.completionDeleted), behavior: SnackBarBehavior.floating),
  );
}
