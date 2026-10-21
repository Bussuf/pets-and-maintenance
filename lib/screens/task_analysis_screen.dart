import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../l10n/app_localizations.dart';
import '../models/task_stats.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../providers/date_format_provider.dart';
import '../providers/items_provider.dart';
import '../theme/app_icons.dart';
import '../utils/duration_text.dart';
import '../widgets/analysis_widgets.dart';
import '../widgets/analysis_sections.dart';
import '../widgets/edit_task_sheet.dart';

/// דף 'ניתוח מעקב משימה' (#25). נפתח מכפתור 'סטטיסטיקות' בכרטיס המשימה.
/// הנתונים נשאבים חיים מהספקים - עריכה, השלמה או מחיקה מתעדכנות מיד
class TaskAnalysisScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskAnalysisScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  ConsumerState<TaskAnalysisScreen> createState() => _TaskAnalysisScreenState();
}

class _TaskAnalysisScreenState extends ConsumerState<TaskAnalysisScreen> {
  bool _closing = false;

  /// המשימה נמחקה (מהתפריט או מעריכה) - סוגרים את הדף הזה בלבד
  void _closeBecauseDeleted() {
    if (_closing) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null) Navigator.of(context).removeRoute(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(dateFormatProvider); // תאריכים מתעדכנים כשמשנים פורמט
    final tasksAsync = ref.watch(dashboardTasksProvider);
    final logsAsync = ref.watch(logsByTaskProvider(widget.taskId));

    Map<String, dynamic>? task;
    for (final t in tasksAsync.value ?? const <Map<String, dynamic>>[]) {
      if (t['id'] == widget.taskId) task = t;
    }

    if (tasksAsync.hasValue && task == null) {
      _closeBecauseDeleted();
      return const Scaffold();
    }
    if (task == null || !logsAsync.hasValue) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.taskAnalysisTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final stats = TaskStats.compute(task, logsAsync.value!);
    final currentTask = task;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.taskAnalysisTitle),
        actions: [
          // עריכה בלבד - טופס העריכה הקיים כולל גם מחיקה. אם המשימה נמחקת, הדף נסגר לבד
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editTask,
            onPressed: () => EditTaskSheet.show(context, currentTask),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          _buildHeader(context, l10n, currentTask, stats),
          const SizedBox(height: 10),
          _buildStatusCard(context, l10n, currentTask, stats),
          const SizedBox(height: 10),
          _buildTiles(l10n, currentTask, stats),
          WhenSection(stats: stats),
          PaceSection(stats: stats, unit: currentTask['interval_unit']),
          CalendarSection(
            stats: stats,
            unit: currentTask['interval_unit'],
            nextDue: DateTime.tryParse(currentTask['next_due_date']?.toString() ?? ''),
          ),
          HistorySection(stats: stats, task: currentTask),
        ],
      ),
    );
  }

  // ---------------- ראש הדף: מתקפל, עם כל פרטי המשימה ----------------

  String _dateWithWeekday(DateTime d) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    return '${DateFormatNotifier.format(d)} · ${DateFormat.EEEE(localeTag).format(d)}';
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, Map<String, dynamic> task, TaskStats stats) {
    final theme = Theme.of(context);
    final unit = task['interval_unit'] as String?;
    final amount = (task['interval_amount'] as num?)?.toInt() ?? 7;
    final every = DurationText.every(l10n, amount, unit);
    final description = task['description']?.toString() ?? '';

    final catColor = task['category_color'] != null ? Color(task['category_color']) : theme.colorScheme.primary;

    // משך / תנאי סיום
    final endValue = task['end_condition_value']?.toString();
    String endText;
    switch (task['end_condition']) {
      case 'count':
        endText = l10n.endCountProgress(stats.completions, int.tryParse(endValue ?? '') ?? 0);
        break;
      case 'until_date':
        final until = DateTime.tryParse(endValue ?? '');
        endText = until != null ? l10n.endUntilDate(DateFormatNotifier.format(until)) : l10n.endConditionUntil;
        break;
      default:
        endText = l10n.endConditionAlways;
    }

    // תזכורת ואירוע - לפי הגדרת המשימה עצמה בלבד
    final reminderOn = task['is_reminder_enabled'] == 1;
    final synced = task['google_event_id'] != null;

    final next = DateTime.tryParse(task['next_due_date']?.toString() ?? '');
    final lastDone = DateTime.tryParse(task['last_completed_date']?.toString() ?? '');
    // 'פעילה מאז': תאריך יצירה, ובמשימות ישנות (לפני גרסה 7) - הביצוע הראשון
    final since = DateTime.tryParse(task['created_at']?.toString() ?? '') ??
        (stats.logs.isNotEmpty ? stats.logs.first.log.completedAt : null);
    final sinceDays = since == null
        ? 0
        : DateTime.now().difference(DateTime(since.year, since.month, since.day)).inHours ~/ 24;

    final rows = <Widget>[
      DetailRow(icon: Icons.flag_outlined, label: l10n.endConditionTitle, value: endText),
      DetailRow(
        icon: Icons.notifications_outlined,
        label: l10n.detailReminder,
        value: reminderOn ? l10n.reminderActive : l10n.reminderOff,
        muted: !reminderOn,
      ),
      DetailRow(
        icon: Icons.calendar_month_outlined,
        label: l10n.detailCalendar,
        value: synced ? l10n.calendarSynced : l10n.calendarNotSynced,
        muted: !synced,
      ),
      DetailRow(
        icon: Icons.event_outlined,
        label: l10n.detailNextDue,
        value: next != null ? _dateWithWeekday(next) : '—',
        muted: next == null,
      ),
      DetailRow(
        icon: Icons.history,
        label: l10n.detailLastDone,
        value: lastDone != null ? _dateWithWeekday(lastDone) : l10n.neverDone,
        muted: lastDone == null,
      ),
      DetailRow(
        icon: Icons.eco_outlined,
        label: l10n.detailActiveSince,
        value: since != null ? '${DateFormatNotifier.format(since)} · ${DurationText.days(l10n, sinceDays, unit)}' : '—',
        muted: since == null,
      ),
    ];

    return AnalysisSection(
      id: 'header',
      // הצ'יפ בשורה השנייה (ליד הקבוצה) - כדי שהשם יקבל את כל הרוחב ולא יישבר
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task['name'] ?? '', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(AppIcons.getIcon(task['category_icon']), size: 14, color: catColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${task['category_name'] ?? ''} · ${task['item_name'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              SummaryChip(text: every),
            ],
          ),
          // התיאור ככותרת משנה - גלוי גם כשהראש מקופל
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(description, style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            rows[i],
          ],
        ],
      ),
    );
  }

  // ---------------- חלונית סטטוס: 4 מצבים קבועים ----------------

  Widget _buildStatusCard(BuildContext context, AppLocalizations l10n, Map<String, dynamic> task, TaskStats stats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unit = task['interval_unit'] as String?;
    final days = stats.daysUntilDue;

    final IconData icon;
    final Color color;
    final String title;
    switch (stats.health) {
      case TaskHealth.onTrack:
        icon = Icons.check_circle_outline;
        color = isDark ? Colors.green.shade300 : Colors.green.shade700;
        title = l10n.healthOnTrack;
        break;
      case TaskHealth.needsAttention:
        icon = Icons.error_outline;
        color = isDark ? Colors.orange.shade300 : Colors.orange.shade800;
        title = l10n.healthAttention;
        break;
      case TaskHealth.overdue:
        icon = Icons.schedule;
        color = isDark ? Colors.redAccent.shade100 : Colors.red.shade700;
        title = l10n.overdueTasks;
        break;
      case TaskHealth.finished:
        icon = Icons.flag_outlined;
        color = theme.colorScheme.onSurfaceVariant;
        title = l10n.taskFinishedLabel;
        break;
    }

    // המשפט מתחת לכותרת - תמיד באותו מבנה לכל מצב
    final String subtitle;
    if (stats.health == TaskHealth.finished) {
      subtitle = l10n.statusFinishedAfter(stats.completions);
    } else if (stats.health == TaskHealth.overdue) {
      subtitle = l10n.overdueBy(DurationText.days(l10n, -(days ?? 0), unit));
    } else {
      final nextPart = days == 0 ? l10n.statusDueToday : l10n.statusNextIn(DurationText.days(l10n, days ?? 0, unit));
      final extra = stats.health == TaskHealth.needsAttention
          ? l10n.statusTendsLate
          : (stats.onTimeStreak > 0 ? l10n.statusStreak(stats.onTimeStreak) : null);
      subtitle = extra == null ? nextPart : '$nextPart · $extra';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- 3 מספרים ----------------

  Widget _buildTiles(AppLocalizations l10n, Map<String, dynamic> task, TaskStats stats) {
    final unit = task['interval_unit'] as String?;
    final months = DurationText.usesMonths(unit);

    String avgValue = '—';
    if (stats.avgIntervalDays != null) {
      final v = months ? stats.avgIntervalDays! / 30.44 : stats.avgIntervalDays!;
      final rounded = (v * 10).round() / 10;
      avgValue = rounded == rounded.roundToDouble() ? rounded.toInt().toString() : rounded.toStringAsFixed(1);
    }

    return Row(
      children: [
        Expanded(child: StatTile(label: l10n.statCompletions, value: '${stats.completions}')),
        const SizedBox(width: 8),
        Expanded(
          child: StatTile(
            label: l10n.statOnTime,
            value: stats.onTimePercent != null ? '${stats.onTimePercent}%' : '—',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatTile(
            label: l10n.statActualEvery,
            value: avgValue,
            unit: stats.avgIntervalDays == null
                ? null
                : avgValue == '1'
                ? (months ? l10n.unitMonth : l10n.unitDay)
                : (months ? l10n.months : l10n.days),
          ),
        ),
      ],
    );
  }
}
