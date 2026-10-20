import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../l10n/app_localizations.dart';
import '../models/task_status.dart';

/// קבוצה ביומן: כותרת (באיחור / היום / מחר / יום בשבוע / מאוחר יותר) והמשימות שבה
class AgendaGroup {
  final String title;
  final bool isOverdue;
  final List<Map<String, dynamic>> tasks;

  AgendaGroup({
    required this.title,
    required this.tasks,
    this.isOverdue = false,
  });
}

/// חלוקת משימות (ממוינות לפי תאריך) לקבוצות יומן - משותף לדשבורד ולדף קבוצה
List<AgendaGroup> buildAgendaGroups(BuildContext context, List<Map<String, dynamic>> tasks) {
  final l10n = AppLocalizations.of(context)!;
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  final List<Map<String, dynamic>> overdue = [];
  final List<Map<String, dynamic>> today = [];
  final List<Map<String, dynamic>> tomorrow = [];
  final Map<int, List<Map<String, dynamic>>> upcomingDays = {};
  final List<Map<String, dynamic>> later = [];
  final List<Map<String, dynamic>> finished = [];

  for (final task in tasks) {
    if (isTaskFinished(task)) {
      finished.add(task);
      continue;
    }
    final due = task['next_due_date'] != null ? DateTime.tryParse(task['next_due_date']) : null;
    if (due == null) {
      later.add(task);
      continue;
    }
    final diffDays = DateTime(due.year, due.month, due.day).difference(todayStart).inDays;

    if (diffDays < 0) {
      overdue.add(task);
    } else if (diffDays == 0) {
      today.add(task);
    } else if (diffDays == 1) {
      tomorrow.add(task);
    } else if (diffDays <= 6) {
      upcomingDays.putIfAbsent(diffDays, () => []).add(task);
    } else {
      later.add(task);
    }
  }

  final List<AgendaGroup> groups = [];
  if (overdue.isNotEmpty) groups.add(AgendaGroup(title: l10n.overdueTasks, tasks: overdue, isOverdue: true));
  if (today.isNotEmpty) groups.add(AgendaGroup(title: l10n.today, tasks: today));
  if (tomorrow.isNotEmpty) groups.add(AgendaGroup(title: l10n.tomorrow, tasks: tomorrow));

  final sortedDiffs = upcomingDays.keys.toList()..sort();
  for (final diff in sortedDiffs) {
    final targetDate = DateTime(todayStart.year, todayStart.month, todayStart.day + diff);
    groups.add(AgendaGroup(title: DateFormat.EEEE(localeTag).format(targetDate), tasks: upcomingDays[diff]!));
  }

  if (later.isNotEmpty) groups.add(AgendaGroup(title: l10n.later, tasks: later));
  if (finished.isNotEmpty) groups.add(AgendaGroup(title: l10n.finishedTasks, tasks: finished));
  return groups;
}

/// כותרת סעיף ביומן: שם הסעיף, מונה משימות וקו מפריד
class AgendaSectionHeader extends StatelessWidget {
  final AgendaGroup group;

  const AgendaSectionHeader({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final overdueColor = isDark ? Colors.redAccent.shade100 : Colors.red.shade800;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Row(
        children: [
          if (group.isOverdue) ...[
            const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.redAccent),
            const SizedBox(width: 6),
          ],
          Text(
            group.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: group.isOverdue ? overdueColor : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
            decoration: BoxDecoration(
              color: group.isOverdue ? Colors.red.withOpacity(0.15) : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${group.tasks.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: group.isOverdue ? overdueColor : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: group.isOverdue ? Colors.red.withOpacity(0.3) : theme.colorScheme.outlineVariant.withOpacity(0.5),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}