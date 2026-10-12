import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/database_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../models/task.dart';
import '../providers/items_provider.dart';
import '../theme/app_icons.dart';
import '../screens/create_entity_screen.dart';
import '../widgets/edit_task_sheet.dart';
import '../services/notification_service.dart';
import '../services/google_calendar_service.dart';

class TaskCard extends ConsumerWidget {
  final Map<String, dynamic> task;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final bool showCategoryLabel;
  final DateTime todayStart;

  const TaskCard({
    Key? key,
    required this.task,
    required this.isExpanded,
    required this.onToggleExpand,
    this.showCategoryLabel = true,
    required this.todayStart,
  }) : super(key: key);

  Future<void> _completeTaskAtDate(BuildContext context, WidgetRef ref, DateTime completedDate) async {
    final db = ref.read(databaseProvider);
    final rawDb = await db.database;
    final intervalAmount = (task['interval_amount'] as num?)?.toInt() ?? 7;
    final intervalUnit = task['interval_unit'] as String? ?? 'days';

    DateTime nextDate;
    switch (intervalUnit) {
      case 'days': nextDate = completedDate.add(Duration(days: intervalAmount)); break;
      case 'weeks': nextDate = completedDate.add(Duration(days: intervalAmount * 7)); break;
      case 'months': nextDate = DateTime(completedDate.year, completedDate.month + intervalAmount, completedDate.day); break;
      case 'years': nextDate = DateTime(completedDate.year + intervalAmount, completedDate.month, completedDate.day); break;
      default: nextDate = completedDate.add(Duration(days: intervalAmount));
    }

    final currentCompletedCount = (task['completed_count'] as num?)?.toInt() ?? 0;
    final uuid = const Uuid();
    final String? googleEventId = task['google_event_id'];

    // אם המשימה מסונכרנת לגוגל יומן, נעדכן את מועד האירוע לתאריך החדש
    if (googleEventId != null) {
      try {
        final updatedTempTask = AppTask(
          id: task['id'],
          itemId: task['item_id'],
          name: task['name'],
          description: task['description'],
          intervalAmount: intervalAmount,
          intervalUnit: intervalUnit,
          endCondition: task['end_condition'] ?? 'always',
          endConditionValue: task['end_condition_value'],
          nextDueDate: nextDate,
          googleEventId: googleEventId,
        );
        await GoogleCalendarService.instance.updateEvent(updatedTempTask, 'עודכן עקב השלמת משימה');
      } catch (e) {
        debugPrint('Failed to update Google Calendar event on completion: $e');
      }
    }

    await rawDb.update(
      'tasks',
      {
        'next_due_date': nextDate.toIso8601String(),
        'last_completed_date': completedDate.toIso8601String(),
        'completed_count': currentCompletedCount + 1,
      },
      where: 'id = ?',
      whereArgs: [task['id']],
    );

    await rawDb.insert('task_logs', {
      'id': uuid.v4(),
      'task_id': task['id'],
      'completed_at': completedDate.toIso8601String(),
    });

    final updatedTask = await db.readTask(task['id']);
    if (updatedTask != null) {
      await NotificationService.instance.scheduleTaskReminder(updatedTask);
    }

    ref.invalidate(dashboardTasksProvider);
    ref.invalidate(tasksByCategoryProvider(task['category_id']));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('משימה "${task['name']}" הושלמה! יעד הבא: ${nextDate.toIso8601String().split('T')[0]}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickManualCompletionDate(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'בחר תאריך ביצוע בפועל',
    );
    if (picked != null) {
      await _completeTaskAtDate(context, ref, picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final catColor = task['category_color'] != null ? Color(task['category_color']) : theme.colorScheme.primary;
    final catIcon = AppIcons.getIcon(task['category_icon']);
    final catName = task['category_name'] ?? 'כללי';
    final itemName = task['item_name'] ?? '';

    bool isOverdue = false;
    final dueDateStr = task['next_due_date'] != null ? task['next_due_date'].toString().split('T')[0] : 'לא נקבע';

    if (task['next_due_date'] != null) {
      final due = DateTime.tryParse(task['next_due_date']);
      if (due != null && due.isBefore(todayStart)) isOverdue = true;
    }

    String lastCompletedStr = 'טרם בוצע';
    if (task['last_completed_date'] != null) {
      final lcDate = DateTime.tryParse(task['last_completed_date']);
      if (lcDate != null) {
        lastCompletedStr = '${lcDate.day.toString().padLeft(2, '0')}/${lcDate.month.toString().padLeft(2, '0')}/${lcDate.year.toString().substring(2)}';
      }
    }

    final intervalStr = 'תדירות: كل ${task['interval_amount'] ?? 7} ${task['interval_unit'] ?? 'ימים'}';
    final isRemindOn = (task['is_reminder_enabled'] == 1);
    final bool isGoogleSynced = task['google_event_id'] != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: catColor, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggleExpand,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // --- שורה 1: כותרת ואייקוני סטטוס מסודרים בצד שמאל ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isGoogleSynced) ...[
                        const Icon(Icons.event_available, size: 18, color: Colors.green),
                        if (isRemindOn) const SizedBox(width: 8),
                      ],
                      if (isRemindOn)
                        const Icon(Icons.notifications_active, size: 18, color: Colors.blueAccent),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // --- שורה 2: תגיות סיווג וחץ אקורדיון ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showCategoryLabel) ...[
                              Icon(catIcon, size: 16, color: catColor),
                              const SizedBox(width: 4),
                              Text('$catName | ', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                            Text(itemName, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOverdue ? Colors.red.withOpacity(isDark ? 0.25 : 0.1) : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: isOverdue ? Border.all(color: Colors.red.withOpacity(0.3), width: 1) : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isOverdue) ...[const Icon(Icons.schedule, size: 12, color: Colors.redAccent), const SizedBox(width: 4)],
                              Text('תאריך הבא לביצוע: $dueDateStr', style: TextStyle(fontSize: 12, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal, color: isOverdue ? (isDark ? Colors.redAccent.shade100 : Colors.red.shade800) : theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),

              // --- אזור האקורדיון (נפתח בלחיצה) ---
              if (isExpanded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(color: catColor.withOpacity(0.4), height: 1),
                ),
                if (task['description'] != null && task['description'].toString().isNotEmpty) ...[
                  Text(task['description'], style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                ],
                Text(intervalStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.history_toggle_off, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('בוצע לאחרונה: $lastCompletedStr', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                      onPressed: () => _completeTaskAtDate(context, ref, DateTime.now()),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('השלם'),
                    ),
                    IconButton.outlined(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.history, size: 18),
                      tooltip: 'ביצוע ידני',
                      onPressed: () => _pickManualCompletionDate(context, ref),
                    ),
                    IconButton.outlined(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      tooltip: 'שכפל',
                      onPressed: () => CreateEntityScreen.show(context, type: EntityType.task, categoryId: task['category_id'], itemId: task['item_id'], duplicateData: task),
                    ),
                    IconButton.outlined(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'ערוך',
                      onPressed: () => EditTaskSheet.show(context, task),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}