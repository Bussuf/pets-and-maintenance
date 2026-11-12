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
import '../l10n/app_localizations.dart';
import '../providers/date_format_provider.dart';
import '../models/task_status.dart';
import '../utils/duration_text.dart';
import '../screens/task_analysis_screen.dart';
import '../onboarding/onboarding.dart';
import '../providers/settings_provider.dart';
import '../services/task_actions.dart';

class TaskCard extends ConsumerWidget {
  final Map<String, dynamic> task;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final bool showCategoryLabel;
  final DateTime todayStart;

  const TaskCard({
    super.key,
    required this.task,
    required this.isExpanded,
    required this.onToggleExpand,
    this.showCategoryLabel = true,
    required this.todayStart,
  });

  // עיצוב תאריך לפי בחירת המשתמש (הגדרות ← פורמט תאריך)
  String _formatDate(DateTime date) => DateFormatNotifier.format(date);

  // תדירות בשפה הנוכחית, כולל יחיד/זוגי/רבים (כל יום / כל יומיים / כל 3 ימים)
  String _frequencyText(AppLocalizations l10n, int amount, String? unit) {
    switch (unit) {
      case 'weeks':
        return l10n.frequencyWeeks(amount);
      case 'months':
        return l10n.frequencyMonths(amount);
      case 'years':
        return l10n.frequencyYears(amount);
      default:
        return l10n.frequencyDays(amount);
    }
  }

  // #79: ביצוע שהוזן ידנית - מסומן בהערות הביצוע (שדה JSON קיים), לחיווי "ידני" בהיסטוריה
  static const _manualNote = '{"manual":true}';

  Future<void> _completeTaskAtDate(
      BuildContext context,
      WidgetRef ref,
      DateTime completedDate, {
        bool manual = false,
      }) async {
    final l10n = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);
    final rawDb = await db.database;
    final intervalAmount = (task['interval_amount'] as num?)?.toInt() ?? 7;
    final intervalUnit = task['interval_unit'] as String? ?? 'days';

    // #71: בלוח קבוע - התאריך הבא בסדרה; אחרת - מיום הביצוע, כמו תמיד
    final nextDate = nextDueAfterCompletion(
      completedAt: completedDate,
      amount: intervalAmount,
      unit: intervalUnit,
      anchor: DateTime.tryParse(task['schedule_anchor']?.toString() ?? ''),
      currentDue: DateTime.tryParse(task['next_due_date']?.toString() ?? ''),
    );

    final currentCompletedCount =
        (task['completed_count'] as num?)?.toInt() ?? 0;
    // #51 תנאי סיום: האם זו הפעם האחרונה?
    final isLastTime = isEndReached(
      task['end_condition'],
      task['end_condition_value'],
      currentCompletedCount + 1,
      nextDate,
    );
    final uuid = const Uuid();
    final String? googleEventId = task['google_event_id'];
    String? newEventId; // #82: אם האירוע נמחק ביומן ונוצר מחדש

    // אם המשימה מסונכרנת לגוגל יומן, נעדכן את מועד האירוע לתאריך החדש
    bool calendarOk = true; // #54
    if (googleEventId != null && isLastTime) {
      // המשימה הסתיימה - האירוע הבא ביומן כבר לא רלוונטי
      try {
        calendarOk = await GoogleCalendarService.instance.deleteEvent(
          googleEventId,
        );
      } catch (e) {
        debugPrint('Failed to delete Google Calendar event on finish: $e');
      }
    } else if (googleEventId != null) {
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
        final updatedId = await GoogleCalendarService.instance.updateEvent(
          updatedTempTask,
          l10n.calendarUpdatedOnCompletion,
        );
        calendarOk = updatedId != null;
        if (updatedId != null && updatedId != googleEventId) newEventId = updatedId;
      } catch (e) {
        debugPrint('Failed to update Google Calendar event on completion: $e');
      }
    }

    await rawDb.update(
      'tasks',
      {
        'next_due_date': isLastTime ? null : nextDate.toIso8601String(),
        if (isLastTime) 'google_event_id': null,
        if (newEventId != null) 'google_event_id': newEventId,
        'last_completed_date': completedDate.toIso8601String(),
        'completed_count': currentCompletedCount + 1,
      },
      where: 'id = ?',
      whereArgs: [task['id']],
    );

    final logId = uuid.v4(); // #69: "בטל" מוחק בדיוק את הביצוע הזה
    await rawDb.insert('task_logs', {
      'id': logId,
      'task_id': task['id'],
      'completed_at': completedDate.toIso8601String(),
      // תאריך היעד שהביצוע הזה סגר - לחישוב 'בזמן / באיחור' (#25). ריק אם המשימה כבר הסתיימה
      'due_at': task['next_due_date'],
      if (manual) 'notes': _manualNote,
    });

    final updatedTask = await db.readTask(task['id']);
    if (updatedTask != null) {
      await NotificationService.instance.scheduleTaskReminder(updatedTask);
    }

    ref.invalidate(dashboardTasksProvider);
    ref.invalidate(tasksByCategoryProvider(task['category_id']));
    ref.invalidate(logsByTaskProvider(task['id'])); // היסטוריה ודף הניתוח
    Onboarding.notify(OnboardingEvent.completed, task['id']); // הדרכה (#26)

    if (context.mounted) {
      // נלקחים עכשיו: הכרטיס יכול להיבנות מחדש (או להיעלם) לפני שלוחצים "בטל"
      final container = ProviderScope.containerOf(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);
      // האירוע ביומן נמחק רק אם המשימה הסתיימה והמחיקה הצליחה
      final eventDeleted = isLastTime && googleEventId != null && calendarOk;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              (isLastTime
                  ? l10n.extraCompletionLogged
                  : l10n.taskCompletedNext(
                task['name'],
                _formatDate(nextDate),
              )) +
                  (calendarOk ? '' : '\n${l10n.calendarNotUpdated}'),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            persist: false,
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () => _undoCompletion(
                container: container,
                messenger: messenger,
                l10n: l10n,
                logId: logId,
                eventDeleted: eventDeleted,
              ),
            ),
          ),
        );
    }
  }

  /// #69: "בטל" - מחזיר הכל למצב שלפני "בוצע": יעד, מונה, בוצע לאחרונה, הביצוע עצמו, יומן ותזכורת.
  /// `task` הוא עדיין המצב שלפני הביצוע (המפה של הכרטיס ברגע הלחיצה)
  Future<void> _undoCompletion({
    required ProviderContainer container,
    required ScaffoldMessengerState messenger,
    required AppLocalizations l10n,
    required String logId,
    required bool eventDeleted,
  }) async {
    final db = container.read(databaseProvider);
    final rawDb = await db.database;
    String? eventId = task['google_event_id'];
    bool calendarOk = true;

    if (eventId != null && !eventDeleted) {
      // #82: בביצוע ייתכן שנוצר אירוע חדש (הישן נמחק ביומן) - מעדכנים את האירוע הנוכחי, לא את הישן
      eventId = (await db.readTask(task['id']))?.googleEventId ?? eventId;
    }

    if (eventId != null) {
      final restored = AppTask(
        id: task['id'],
        itemId: task['item_id'],
        name: task['name'],
        description: task['description'],
        intervalAmount: (task['interval_amount'] as num?)?.toInt() ?? 7,
        intervalUnit: task['interval_unit'] as String? ?? 'days',
        endCondition: task['end_condition'] ?? 'always',
        endConditionValue: task['end_condition_value'],
        nextDueDate: DateTime.tryParse(task['next_due_date']?.toString() ?? ''),
        googleEventId: eventId,
      );
      if (eventDeleted) {
        // המשימה הסתיימה והאירוע נמחק - יוצרים אירוע חדש בתאריך הקודם
        eventId = await GoogleCalendarService.instance.createEvent(restored, l10n.calendarAddedFromApp);
        calendarOk = eventId != null;
      } else {
        final updatedId = await GoogleCalendarService.instance.updateEvent(restored, l10n.calendarUpdatedFromApp);
        calendarOk = updatedId != null;
        if (updatedId != null) eventId = updatedId;
      }
    }

    await rawDb.update(
      'tasks',
      {
        'next_due_date': task['next_due_date'],
        'last_completed_date': task['last_completed_date'],
        'completed_count': task['completed_count'] ?? 0,
        'google_event_id': eventId,
      },
      where: 'id = ?',
      whereArgs: [task['id']],
    );
    await db.deleteTaskLog(logId);

    final restoredTask = await db.readTask(task['id']);
    if (restoredTask != null) {
      await NotificationService.instance.scheduleTaskReminder(restoredTask);
    }

    container.invalidate(dashboardTasksProvider);
    container.invalidate(tasksByCategoryProvider(task['category_id']));
    container.invalidate(logsByTaskProvider(task['id']));

    messenger.showSnackBar(
      SnackBar(
        content: Text(calendarOk ? l10n.completionUndone : l10n.completionUndoneCalendarFailed),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// #85 "לדחות": גיליון קצר - מחר / בעוד 3 ימים / בעוד שבוע / תאריך אחר. משנה רק את היעד
  Future<void> _showPostponeSheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final today = DateUtils.dateOnly(DateTime.now());
    DateTime inDays(int n) => DateTime(today.year, today.month, today.day + n);

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.postponeTitle(task['name']),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            for (final n in const [1, 3, 7])
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(n == 7 ? l10n.postponeWeek : l10n.postponeInDays(n)),
                trailing: Text(_formatDate(inDays(n))),
                onTap: () => Navigator.pop(ctx, inDays(n)),
              ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(l10n.postponePickDate),
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: inDays(1),
                  firstDate: today,
                  lastDate: DateTime(today.year + 5),
                );
                if (d != null && ctx.mounted) Navigator.pop(ctx, d);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    await _moveDueDate(context, ref, picked, l10n.dueMovedTo(_formatDate(picked)));
  }

  /// #85 "לדלג הפעם": היעד + מרווח אחד, בלי ביצוע. עובר את תאריך הסיום = המשימה מסתיימת
  Future<void> _skipOnce(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final due = DateTime.tryParse(task['next_due_date']?.toString() ?? '');
    if (due == null) return;
    final next = skippedDueDate(
      due,
      (task['interval_amount'] as num?)?.toInt() ?? 7,
      task['interval_unit'] as String? ?? 'days',
      task['end_condition'],
      task['end_condition_value']?.toString(),
      (task['completed_count'] as num?)?.toInt() ?? 0,
      anchor: DateTime.tryParse(task['schedule_anchor']?.toString() ?? ''), // #71
    );
    await _moveDueDate(context, ref, next, next == null ? l10n.skippedFinished : l10n.skippedTo(_formatDate(next)));
  }

  /// #85: מזיז את היעד בלי ביצוע (לדחות / לדלג) - יומן, תזכורת, רענון והודעה עם "בטל".
  /// newDue == null = המשימה מסתיימת (דילוג אחרי תאריך הסיום): האירוע ביומן נמחק, כמו בביצוע האחרון
  Future<void> _moveDueDate(BuildContext context, WidgetRef ref, DateTime? newDue, String message) async {
    final l10n = AppLocalizations.of(context)!;
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    final rawDb = await db.database;
    final String? oldDue = task['next_due_date']?.toString();
    final String? eventId = task['google_event_id'];
    String? newEventId = eventId;
    bool calendarOk = true;

    if (eventId != null) {
      if (newDue == null) {
        calendarOk = await GoogleCalendarService.instance.deleteEvent(eventId);
        newEventId = null;
      } else {
        final current = await db.readTask(task['id']);
        if (current != null) {
          final id = await GoogleCalendarService.instance
              .updateEvent(current.copyWith(nextDueDate: newDue), l10n.calendarUpdatedFromApp);
          calendarOk = id != null;
          if (id != null) newEventId = id;
        }
      }
    }

    await rawDb.update(
      'tasks',
      {'next_due_date': newDue?.toIso8601String(), 'google_event_id': newEventId},
      where: 'id = ?',
      whereArgs: [task['id']],
    );
    final updated = await db.readTask(task['id']);
    if (updated != null) await NotificationService.instance.scheduleTaskReminder(updated);

    container.invalidate(dashboardTasksProvider);
    container.invalidate(tasksByCategoryProvider(task['category_id']));

    final eventDeleted = newDue == null && eventId != null && calendarOk;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message + (calendarOk ? '' : '\n${l10n.calendarNotUpdated}')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          persist: false,
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => _restoreDueDate(
              container: container,
              messenger: messenger,
              l10n: l10n,
              oldDue: oldDue,
              eventDeleted: eventDeleted,
            ),
          ),
        ),
      );
  }

  /// #85: "בטל" אחרי לדחות / לדלג - מחזיר את היעד הקודם, ואת האירוע ביומן ואת התזכורת איתו
  Future<void> _restoreDueDate({
    required ProviderContainer container,
    required ScaffoldMessengerState messenger,
    required AppLocalizations l10n,
    required String? oldDue,
    required bool eventDeleted,
  }) async {
    final db = container.read(databaseProvider);
    final rawDb = await db.database;
    final current = await db.readTask(task['id']);
    if (current == null) return;
    final restored = current.copyWith(nextDueDate: DateTime.tryParse(oldDue ?? ''));

    String? eventId = current.googleEventId;
    bool calendarOk = true;
    if (eventDeleted) {
      // הדילוג סיים את המשימה ומחק את האירוע - יוצרים אותו מחדש בתאריך הקודם
      eventId = await GoogleCalendarService.instance.createEvent(restored, l10n.calendarAddedFromApp);
      calendarOk = eventId != null;
    } else if (eventId != null) {
      final id = await GoogleCalendarService.instance.updateEvent(restored, l10n.calendarUpdatedFromApp);
      calendarOk = id != null;
      if (id != null) eventId = id;
    }

    await rawDb.update(
      'tasks',
      {'next_due_date': oldDue, 'google_event_id': eventId},
      where: 'id = ?',
      whereArgs: [task['id']],
    );
    final restoredTask = await db.readTask(task['id']);
    if (restoredTask != null) await NotificationService.instance.scheduleTaskReminder(restoredTask);

    container.invalidate(dashboardTasksProvider);
    container.invalidate(tasksByCategoryProvider(task['category_id']));

    messenger.showSnackBar(
      SnackBar(
        content: Text(calendarOk ? l10n.dueRestored : '${l10n.dueRestored}\n${l10n.calendarNotUpdated}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickManualCompletionDate(
      BuildContext context,
      WidgetRef ref,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: AppLocalizations.of(context)!.pickActualCompletionDate,
    );
    if (picked == null || !context.mounted) return;

    // #79: כבר יש ביצוע באותו יום - לא מוסיפים כפילות
    final logs = await ref.read(databaseProvider).getLogsByTask(task['id']);
    if (logs.any((l) => DateUtils.isSameDay(l.completedAt, picked))) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.completionSameDayExists),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    if (!context.mounted) return;

    // #79: מוקדם מהביצוע האחרון - או, כשאין ביצועים, מוקדם מיצירת המשימה - רק להיסטוריה.
    // כל השאר: ביצוע רגיל שמזיז את התאריך הבא
    final lastDone = DateTime.tryParse(task['last_completed_date']?.toString() ?? '');
    final created = DateTime.tryParse(task['created_at']?.toString() ?? '');
    final pickedDay = DateUtils.dateOnly(picked);
    final historyOnly = lastDone != null
        ? pickedDay.isBefore(DateUtils.dateOnly(lastDone))
        : (created != null && pickedDay.isBefore(DateUtils.dateOnly(created)));

    if (historyOnly) {
      await _addHistoryCompletion(context, ref, picked);
    } else {
      await _completeTaskAtDate(context, ref, picked, manual: true);
    }
  }

  /// #79: ביצוע עבר - נכנס רק להיסטוריה (ולמונה). התאריך הבא, "בוצע לאחרונה", היומן והתזכורת לא משתנים.
  /// חריג: תנאי סיום "מספר פעמים" שהושג בזכותו - המשימה מסתיימת, כמו בביצוע רגיל
  Future<void> _addHistoryCompletion(BuildContext context, WidgetRef ref, DateTime date) async {
    final l10n = AppLocalizations.of(context)!;
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    final rawDb = await db.database;

    final count = (task['completed_count'] as num?)?.toInt() ?? 0;
    final reachesEnd = task['next_due_date'] != null &&
        isEndReached(
          task['end_condition'],
          task['end_condition_value'],
          count + 1,
          DateTime.tryParse(task['next_due_date'].toString()),
        );
    final String? eventId = task['google_event_id'];
    bool calendarOk = true;
    if (reachesEnd && eventId != null) {
      calendarOk = await GoogleCalendarService.instance.deleteEvent(eventId);
    }

    await rawDb.update(
      'tasks',
      {
        'completed_count': count + 1,
        if (reachesEnd) 'next_due_date': null,
        if (reachesEnd) 'google_event_id': null,
      },
      where: 'id = ?',
      whereArgs: [task['id']],
    );
    final logId = const Uuid().v4();
    await rawDb.insert('task_logs', {
      'id': logId,
      'task_id': task['id'],
      'completed_at': date.toIso8601String(),
      // אין יעד ידוע - מנוע החישובים משחזר אותו (ביצוע קודם + תדירות)
      'due_at': null,
      'notes': _manualNote,
    });

    if (reachesEnd) {
      final updatedTask = await db.readTask(task['id']);
      if (updatedTask != null) await NotificationService.instance.scheduleTaskReminder(updatedTask);
    }

    container.invalidate(dashboardTasksProvider);
    container.invalidate(tasksByCategoryProvider(task['category_id']));
    container.invalidate(logsByTaskProvider(task['id']));

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            (reachesEnd ? l10n.historyCompletionFinished(_formatDate(date)) : l10n.historyCompletionAdded(_formatDate(date))) +
                (calendarOk ? '' : '\n${l10n.calendarNotUpdated}'),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          persist: false,
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => _undoCompletion(
              container: container,
              messenger: messenger,
              l10n: l10n,
              logId: logId,
              eventDeleted: reachesEnd && eventId != null && calendarOk,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    ref.watch(dateFormatProvider); // הכרטיס נבנה מחדש כשמשנים את פורמט התאריך
    final isFinished = isTaskFinished(task);
    final isDark = theme.brightness == Brightness.dark;

    final catColor = task['category_color'] != null
        ? Color(task['category_color'])
        : theme.colorScheme.primary;
    final catIcon = AppIcons.getIcon(task['category_icon']);
    final catName =
        task['category_name'] ?? AppLocalizations.of(context)!.general;
    final itemName = task['item_name'] ?? '';

    final l10n = AppLocalizations.of(context)!;
    bool isOverdue = false;
    int overdueDays = 0;
    String dueDateStr = l10n.notSet;

    if (task['next_due_date'] != null) {
      final due = DateTime.tryParse(task['next_due_date']);
      if (due != null) {
        if (due.isBefore(todayStart)) {
          isOverdue = true;
          // עיגול שעות ל-ימים, כדי שמעבר שעון קיץ/חורף לא יחסיר יום
          overdueDays =
              (todayStart
                  .difference(DateTime(due.year, due.month, due.day))
                  .inHours /
                  24)
                  .round();
        }
        dueDateStr = _formatDate(due);
      }
    }

    String lastCompletedStr = l10n.neverDone;
    if (task['last_completed_date'] != null) {
      final lcDate = DateTime.tryParse(task['last_completed_date']);
      if (lcDate != null) {
        lastCompletedStr = _formatDate(lcDate);
      }
    }

    final intervalStr = _frequencyText(
      l10n,
      (task['interval_amount'] as num?)?.toInt() ?? 7,
      task['interval_unit'],
    );

    final isRemindOn = (task['is_reminder_enabled'] == 1);
    final bool isGoogleSynced = task['google_event_id'] != null;

    // #85: פרטים בכרטיס הפתוח
    final unit = task['interval_unit'] as String?;
    final completedCount = (task['completed_count'] as num?)?.toInt() ?? 0;
    final dueDate = DateTime.tryParse(task['next_due_date']?.toString() ?? '');
    final String relativeDueStr;
    if (isFinished) {
      relativeDueStr = l10n.taskFinishedLabel;
    } else if (dueDate == null) {
      relativeDueStr = l10n.notSet;
    } else if (isOverdue) {
      relativeDueStr = l10n.overdueBy(DurationText.days(l10n, overdueDays, unit));
    } else {
      final daysUntil = (DateTime(dueDate.year, dueDate.month, dueDate.day).difference(todayStart).inHours / 24).round();
      relativeDueStr = daysUntil == 0
          ? l10n.statusDueToday
          : l10n.statusNextIn(DurationText.days(l10n, daysUntil, unit));
    }
    final reminderTimeStr =
        MaterialLocalizations.of(context).formatTimeOfDay(ref.watch(settingsProvider).reminderTime);
    // תנאי סיום (#51) - null = תמיד
    final endValue = task['end_condition_value']?.toString();
    String? endText;
    if (task['end_condition'] == 'count') {
      endText = l10n.endCountProgress(completedCount, int.tryParse(endValue ?? '') ?? 0);
    } else if (task['end_condition'] == 'until_date') {
      final until = DateTime.tryParse(endValue ?? '');
      endText = until != null ? l10n.endUntilDate(_formatDate(until)) : l10n.endConditionUntil;
    }

    // הדרכה (#26): מפתחות רק לכרטיס של משימת הדוגמה, ורק בזמן הדרכה
    GlobalKey? obKey(OnboardingTarget target) => Onboarding.keyFor(target, task['id']);

    return Card(
      key: obKey(OnboardingTarget.taskCard),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: catColor, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          onToggleExpand();
          if (!isExpanded) Onboarding.notify(OnboardingEvent.cardExpanded, task['id']);
        },
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // חיוויים: יומן, תזכורת, תנאי סיום (#85), לוח קבוע (#71) - 8 פיקסלים ביניהם
                      for (final (i, icon) in [
                        if (isGoogleSynced) const Icon(Icons.event_available, size: 18, color: Colors.green),
                        if (isRemindOn) const Icon(Icons.notifications_active, size: 18, color: Colors.blueAccent),
                        if (endText != null) const Icon(Icons.flag_outlined, size: 18, color: Colors.orange),
                        if (task['schedule_anchor'] != null)
                          const Icon(Icons.event_repeat, size: 18, color: Colors.teal),
                      ].indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        icon,
                      ],
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
                              Flexible(
                                child: Text(
                                  '$catName | ',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            Flexible(
                              child: Text(
                                itemName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          key: obKey(OnboardingTarget.nextDue),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? Colors.red.withValues(alpha: isDark ? 0.25 : 0.1)
                                : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: isOverdue
                                ? Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 1,
                            )
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isOverdue) ...[
                                const Icon(
                                  Icons.schedule,
                                  size: 12,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  isFinished
                                      ? '✓ ${l10n.taskFinishedLabel}'
                                      : isOverdue
                                      ? '${l10n.dueDateLabel(dueDateStr)} · ${l10n.overdueBy(DurationText.days(l10n, overdueDays, task['interval_unit']))}'
                                      : l10n.dueDateLabel(dueDateStr),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isOverdue
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isOverdue
                                        ? (isDark
                                        ? Colors.redAccent.shade100
                                        : Colors.red.shade800)
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),

              // --- אזור האקורדיון (נפתח בלחיצה) - #85: תפריט פעולות אנכי מימין, פרטים משמאל ---
              if (isExpanded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(color: catColor.withValues(alpha: 0.4), height: 1),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MenuAction(
                            key: obKey(OnboardingTarget.completeButton),
                            icon: Icons.check,
                            label: l10n.complete,
                            filled: true,
                            onTap: () => _completeTaskAtDate(context, ref, DateTime.now()),
                          ),
                          _MenuAction(
                            key: obKey(OnboardingTarget.analysisButton),
                            icon: Icons.insights,
                            label: l10n.cardAnalysis,
                            // דף ניתוח מעקב משימה (#25)
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TaskAnalysisScreen(taskId: task['id'])),
                            ),
                          ),
                          _MenuAction(
                            key: obKey(OnboardingTarget.manualButton),
                            icon: Icons.history,
                            label: l10n.manualCompletion,
                            onTap: () => _pickManualCompletionDate(context, ref),
                          ),
                          // #85: רק למשימה פעילה עם יעד
                          if (!isFinished && dueDate != null) ...[
                            _MenuAction(
                              key: obKey(OnboardingTarget.postponeButton),
                              icon: Icons.snooze,
                              label: l10n.cardPostpone,
                              onTap: () => _showPostponeSheet(context, ref),
                            ),
                            _MenuAction(
                              key: obKey(OnboardingTarget.skipButton),
                              icon: Icons.skip_next_outlined,
                              label: l10n.cardSkip,
                              onTap: () => _skipOnce(context, ref),
                            ),
                          ],
                          _MenuAction(
                            key: obKey(OnboardingTarget.editButton),
                            icon: Icons.edit_outlined,
                            label: l10n.edit,
                            onTap: () => EditTaskSheet.show(context, task),
                          ),
                          _MenuAction(
                            key: obKey(OnboardingTarget.duplicateButton),
                            icon: Icons.copy_outlined,
                            label: l10n.duplicate,
                            onTap: () => CreateEntityScreen.show(
                              context,
                              type: EntityType.task,
                              categoryId: task['category_id'],
                              itemId: task['item_id'],
                              duplicateData: task,
                            ),
                          ),
                          _MenuAction(
                            key: obKey(OnboardingTarget.deleteButton),
                            icon: Icons.delete_outline,
                            label: l10n.cardDelete,
                            color: theme.colorScheme.error,
                            onTap: () => deleteTaskWithConfirm(context, ref, task), // תמיד באישור
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 11,
                      child: Container(
                        padding: const EdgeInsetsDirectional.only(start: 10),
                        decoration: BoxDecoration(
                          border: BorderDirectional(
                            start: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task['description'] != null && task['description'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(task['description'], style: const TextStyle(fontSize: 14)),
                              ),
                            _DetailLine(
                              icon: Icons.repeat,
                              // #71: "כל 3 חודשים · לוח קבוע"
                              text: task['schedule_anchor'] != null ? '$intervalStr · ${l10n.fixedSchedule}' : intervalStr,
                            ),
                            _DetailLine(
                              icon: Icons.hourglass_empty,
                              text: relativeDueStr,
                              color: isOverdue ? (isDark ? Colors.redAccent.shade100 : Colors.red.shade800) : null,
                            ),
                            _DetailLine(icon: Icons.history_toggle_off, text: l10n.lastDoneLabel(lastCompletedStr)),
                            _DetailLine(icon: Icons.done_all, text: l10n.cardCompletions(completedCount)),
                            if (isRemindOn)
                              _DetailLine(icon: Icons.notifications_outlined, text: l10n.cardReminderAt(reminderTimeStr)),
                            if (isGoogleSynced)
                              _DetailLine(icon: Icons.event_available, text: l10n.calendarSynced),
                            if (endText != null) _DetailLine(icon: Icons.flag_outlined, text: endText),
                          ],
                        ),
                      ),
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

/// #85: שורה בתפריט הפעולות האנכי - אייקון + שם. "השלם" מודגש (filled)
class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color? color;

  const _MenuAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = filled ? scheme.onPrimary : (color ?? scheme.onSurface);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: filled ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 38),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: filled ? fg : (color ?? scheme.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label, style: TextStyle(fontSize: 13, color: fg, fontWeight: filled ? FontWeight.bold : null)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// #85: שורת פרט בטור הפרטים - אייקון קטן + טקסט (נשבר לשורה נוספת אם צריך)
class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _DetailLine({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 14, color: c),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
