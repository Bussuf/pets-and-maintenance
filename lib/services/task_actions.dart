import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/database_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../providers/items_provider.dart';
import '../widgets/confirm_delete_dialog.dart';
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
