import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../models/task_log.dart';
import '../models/task_status.dart';

/// שם יום בשבוע לפי מספר (DateTime.monday..sunday), בשפה הנוכחית
String weekdayName(BuildContext context, int weekday, {bool short = false}) {
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  final date = DateTime(2026, 1, 4 + (weekday % 7)); // 4/1/2026 הוא יום ראשון
  if (!short) return DateFormat.EEEE(localeTag).format(date);
  // בעברית האות הבודדת ברורה ('א׳'), באנגלית צריך 3 אותיות ('Sun') כי S/T חוזרות
  final narrow = Localizations.localeOf(context).languageCode == 'he';
  return narrow ? DateFormat('EEEEE', localeTag).format(date) : DateFormat.E(localeTag).format(date);
}

/// סוג סימון ביום בלוח החודשי (#83)
enum CalendarMarkKind { overdue, planned, done }

/// סימון אחד ביום: המשימה ומה קרה איתה באותו יום
class CalendarMark {
  final Map<String, dynamic> task;
  final CalendarMarkKind kind;

  const CalendarMark(this.task, this.kind);
}

/// הסימונים של חודש אחד, לפי יום בחודש. בכל יום קודם מה שעוד פתוח, אחר כך מה שבוצע.
/// [tasks] כבר מסוננות לפי הצ'יפ - ביצוע של משימה שלא ברשימה לא מוצג.
/// יעדים עתידיים מעבר ליעד הבא לא מוקרנים: היעד מחושב מיום הביצוע, אז הקרנה הייתה מטעה
Map<int, List<CalendarMark>> buildMonthMarks({
  required DateTime month,
  required List<Map<String, dynamic>> tasks,
  required List<TaskLog> logs,
  required DateTime now,
}) {
  final todayStart = DateTime(now.year, now.month, now.day);
  final tasksById = {for (final t in tasks) t['id']: t};
  final marks = <int, List<CalendarMark>>{};
  bool inMonth(DateTime d) => d.year == month.year && d.month == month.month;

  for (final task in tasks) {
    if (isTaskFinished(task)) continue;
    final due = task['next_due_date'] != null ? DateTime.tryParse(task['next_due_date']) : null;
    if (due == null || !inMonth(due)) continue;
    final isOverdue = DateTime(due.year, due.month, due.day).isBefore(todayStart);
    marks.putIfAbsent(due.day, () => []).add(
      CalendarMark(task, isOverdue ? CalendarMarkKind.overdue : CalendarMarkKind.planned),
    );
  }

  for (final log in logs) {
    final task = tasksById[log.taskId];
    if (task == null || !inMonth(log.completedAt)) continue;
    marks.putIfAbsent(log.completedAt.day, () => []).add(CalendarMark(task, CalendarMarkKind.done));
  }

  return marks;
}

/// רשת חודש: שורת ימים בשבוע ותאים לפי התחלת השבוע של השפה.
/// התוכן של כל תא מגיע מבחוץ - משותף ללוח בדף הניתוח וללוח החודשי
class MonthGrid extends StatelessWidget {
  final DateTime month; // היום הראשון בחודש
  final Widget Function(int day) dayBuilder;
  final double childAspectRatio;

  const MonthGrid({
    super.key,
    required this.month,
    required this.dayBuilder,
    this.childAspectRatio = 1,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = ראשון
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = (month.weekday % 7 - first + 7) % 7; // תאים ריקים לפני היום הראשון

    final headerStyle = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);
    final weekdayOrder = [for (int i = 0; i < 7; i++) ((first + i) % 7 == 0 ? DateTime.sunday : (first + i) % 7)];

    return Column(
      children: [
        Row(
          children: [
            for (final d in weekdayOrder)
              Expanded(
                child: Text(weekdayName(context, d, short: true), textAlign: TextAlign.center, style: headerStyle),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          padding: EdgeInsets.zero, // בלי ריפוד אוטומטי של שטח המערכת (שורה ריקה בסוף)
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: childAspectRatio,
          children: [
            for (int i = 0; i < leading; i++) const SizedBox.shrink(),
            for (int day = 1; day <= daysInMonth; day++) dayBuilder(day),
          ],
        ),
      ],
    );
  }
}
