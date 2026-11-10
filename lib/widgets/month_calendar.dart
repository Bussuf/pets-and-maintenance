import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../l10n/app_localizations.dart';
import '../models/task_log.dart';
import '../models/task_status.dart';
import 'agenda.dart';

/// שם יום בשבוע לפי מספר (DateTime.monday..sunday), בשפה הנוכחית
String weekdayName(BuildContext context, int weekday, {bool short = false}) {
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  final date = DateTime(2026, 1, 4 + (weekday % 7)); // 4/1/2026 הוא יום ראשון
  if (!short) return DateFormat.EEEE(localeTag).format(date);
  // בעברית האות הבודדת ברורה ('א׳'), באנגלית צריך 3 אותיות ('Sun') כי S/T חוזרות
  final narrow = Localizations.localeOf(context).languageCode == 'he';
  return narrow ? DateFormat('EEEEE', localeTag).format(date) : DateFormat.E(localeTag).format(date);
}

/// גוון למילוי שעליו טקסט לבן: צבע בהיר מדי מוכהה עד שהלבן קריא
Color calendarFillColor(Color color) {
  var hsl = HSLColor.fromColor(color);
  var result = color;
  while (result.computeLuminance() > 0.3 && hsl.lightness > 0) {
    hsl = hsl.withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0));
    result = hsl.toColor();
  }
  return result;
}

/// מספר הימים ברצועה
const int weekLength = 7;

/// יום לפני/אחרי - בחישוב קלנדרי, לא ב-Duration (שעון קיץ/חורף, #37)
DateTime shiftDay(DateTime day, int days) => DateTime(day.year, day.month, day.day + days);

/// הפרש בימים שלמים בין שני תאריכים.
/// חישוב ב-UTC: ביום של מעבר לשעון קיץ/חורף הפרש השעות המקומי לא שווה לימים שלמים
int _daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// באיזה עמוד של הרצועה נמצא יום: 0 = היום + 6 הבאים, 1- = 7 הימים שלפני
int weekPageOf(DateTime day, DateTime today) => (_daysBetween(today, day) / weekLength).floor();

/// היום הראשון בעמוד של הרצועה שבו נמצא [day]
DateTime weekPageStart(DateTime day, DateTime today) => shiftDay(today, weekPageOf(day, today) * weekLength);

/// סוג הסעיף של יום ברצועה - אותו סוג שהיה לו ביומן, כדי שזיכרון הקיפול יהיה אחד (#90)
AgendaKind dayKind(DateTime day, DateTime today) {
  final diff = _daysBetween(today, day);
  if (diff < 0) return AgendaKind.past;
  if (diff == 0) return AgendaKind.today;
  if (diff == 1) return AgendaKind.tomorrow;
  if (diff < weekLength) return AgendaKind.week;
  return AgendaKind.later;
}

/// סוג סימון ביום ברצועת השבוע (#83)
enum CalendarMarkKind { overdue, planned, done }

/// סימון אחד ביום: המשימה ומה קרה איתה באותו יום
class CalendarMark {
  final Map<String, dynamic> task;
  final CalendarMarkKind kind;

  const CalendarMark(this.task, this.kind);
}

/// הסימונים של 7 ימים החל מ-[from] (חצות), לפי תאריך. בכל יום: באיחור, מתוכנן, בוצע.
/// משימות באיחור מוצגות על היום הנוכחי ולא על התאריך המקורי - שם צריך לטפל בהן.
/// [tasks] כבר מסוננות לפי הצ'יפ - ביצוע של משימה שלא ברשימה לא מוצג.
/// יעדים עתידיים מעבר ליעד הבא לא מוקרנים: היעד מחושב מיום הביצוע, אז הקרנה הייתה מטעה
Map<DateTime, List<CalendarMark>> buildWeekMarks({
  required DateTime from,
  required List<Map<String, dynamic>> tasks,
  required List<TaskLog> logs,
  required DateTime now,
}) {
  DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
  final today = dayOf(now);
  final to = DateTime(from.year, from.month, from.day + weekLength);
  bool inRange(DateTime day) => !day.isBefore(from) && day.isBefore(to);

  final tasksById = {for (final t in tasks) t['id']: t};
  final marks = <DateTime, List<CalendarMark>>{};
  final overdue = <CalendarMark>[];

  for (final task in tasks) {
    if (isTaskFinished(task)) continue;
    final due = task['next_due_date'] != null ? DateTime.tryParse(task['next_due_date']) : null;
    if (due == null) continue;
    final day = dayOf(due);
    if (day.isBefore(today)) {
      overdue.add(CalendarMark(task, CalendarMarkKind.overdue));
    } else if (inRange(day)) {
      marks.putIfAbsent(day, () => []).add(CalendarMark(task, CalendarMarkKind.planned));
    }
  }
  if (overdue.isNotEmpty && inRange(today)) marks[today] = [...overdue, ...?marks[today]];

  for (final log in logs) {
    final task = tasksById[log.taskId];
    final day = dayOf(log.completedAt);
    if (task == null || !inRange(day)) continue;
    marks.putIfAbsent(day, () => []).add(CalendarMark(task, CalendarMarkKind.done));
  }

  return marks;
}

/// הרשימה כשהרצועה פתוחה (#90): אותם סעיפים כמו ביומן, מסוננים ליום הנבחר.
/// היום - "באיחור" ו"היום"; מחר - "מחר"; עוד השבוע - שם היום; הלאה ובעבר - התאריך
List<AgendaGroup> buildDayGroups(BuildContext context, DateTime day, List<CalendarMark> marks, DateTime today) {
  final l10n = AppLocalizations.of(context)!;
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  List<Map<String, dynamic>> of(CalendarMarkKind kind) => [
    for (final mark in marks)
      if (mark.kind == kind) mark.task,
  ];
  final overdue = of(CalendarMarkKind.overdue);
  final planned = of(CalendarMarkKind.planned);
  final done = of(CalendarMarkKind.done);

  final kind = dayKind(day, today);
  final title = switch (kind) {
    AgendaKind.today => l10n.today,
    AgendaKind.tomorrow => l10n.tomorrow,
    AgendaKind.week => DateFormat.EEEE(localeTag).format(day),
    _ => DateFormat.MMMMd(localeTag).format(day),
  };

  return [
    if (overdue.isNotEmpty)
      AgendaGroup(title: l10n.overdueTasks, kind: AgendaKind.overdue, tasks: overdue, isOverdue: true),
    if (planned.isNotEmpty || done.isNotEmpty) AgendaGroup(title: title, kind: kind, tasks: planned, doneTasks: done),
  ];
}

/// רשת חודש: שורת ימים בשבוע ותאים לפי התחלת השבוע של השפה (הלוח בדף הניתוח)
class MonthGrid extends StatelessWidget {
  final DateTime month; // היום הראשון בחודש
  final Widget Function(int day) dayBuilder;

  const MonthGrid({
    super.key,
    required this.month,
    required this.dayBuilder,
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
          children: [
            for (int i = 0; i < leading; i++) const SizedBox.shrink(),
            for (int day = 1; day <= daysInMonth; day++) dayBuilder(day),
          ],
        ),
      ],
    );
  }
}

Color _taskColor(BuildContext context, Map<String, dynamic> task) => task['category_color'] != null
    ? Color(task['category_color'] as int)
    : Theme.of(context).colorScheme.primary;

Color _overdueColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.redAccent.shade100 : Colors.red.shade800;

/// עיגול סימון: בוצע = מלא עם ✓, מתוכנן = מסגרת, באיחור = מסגרת אדומה
class _MarkDot extends StatelessWidget {
  final CalendarMarkKind kind;
  final Color color;

  const _MarkDot({required this.kind, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDone = kind == CalendarMarkKind.done;
    final isOverdue = kind == CalendarMarkKind.overdue;
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black87;
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? color : null,
        border: isDone ? null : Border.all(color: isOverdue ? _overdueColor(context) : color, width: isOverdue ? 2 : 1.5),
      ),
      child: isDone ? Icon(Icons.check, size: 9, color: checkColor) : null,
    );
  }
}

/// יום ברצועה: יום בשבוע, מספר, ושורת סימונים ממורכזת
class _DayCell extends StatelessWidget {
  final DateTime date;
  final List<CalendarMark> marks;
  final bool isToday;
  final bool isSelected;
  final bool isPast;
  final Color accent;
  final VoidCallback onTap;

  static const _maxMarks = 3;

  const _DayCell({
    required this.date,
    required this.marks,
    required this.isToday,
    required this.isSelected,
    required this.isPast,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final numberColor = isSelected
        ? Colors.white
        : (isToday ? accent : (isPast ? scheme.onSurfaceVariant : scheme.onSurface));

    // יותר מדי סימונים: ה-"+N" תופס את המקום של השלישי
    final overflow = marks.length > _maxMarks;
    final shown = overflow ? marks.take(_maxMarks - 1) : marks;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weekdayName(context, date.weekday, short: true),
                maxLines: 1,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? calendarFillColor(accent) : null,
                  border: isToday && !isSelected ? Border.all(color: accent, width: 1.5) : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 13,
                      color: numberColor,
                      fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 13,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final mark in shown)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: _MarkDot(kind: mark.kind, color: _taskColor(context, mark.task)),
                        ),
                      if (overflow)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Text(
                            '+${marks.length - shown.length}',
                            textDirection: TextDirection.ltr, // אחרת ב-RTL זה נראה "2+"
                            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// שורת "בוצע" ברשימה המסוננת ליום - לתצוגה בלבד
class CompletedTaskRow extends StatelessWidget {
  final Map<String, dynamic> task;

  const CompletedTaskRow({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _MarkDot(kind: CalendarMarkKind.done, color: _taskColor(context, task)),
          const SizedBox(width: 8),
          Expanded(child: Text(task['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.calDone,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// רצועת 7 הימים (#83), נעוצה מעל הרשימה. היא רק בוחרת יום - הרשימה שמתחת
/// היא היומן הרגיל, מסונן ליום הזה (#90). מתחילה מהיום (ולא מתחילת שבוע),
/// כדי שתמיד יראו את מה שלפנינו
class WeekStrip extends StatelessWidget {
  final DateTime selected; // היום הנבחר (חצות)
  final Map<DateTime, List<CalendarMark>> marks; // הסימונים של העמוד המוצג
  final Color accent;
  final ValueChanged<DateTime> onSelectDay;

  const WeekStrip({
    super.key,
    required this.selected,
    required this.marks,
    required this.accent,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final page = weekPageOf(selected, today);
    final from = weekPageStart(selected, today);
    final lastDay = shiftDay(from, weekLength - 1);
    void goToPage(int p) => onSelectDay(shiftDay(today, p * weekLength)); // בעמוד הנוכחי זה היום עצמו
    final iconStyle = IconButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // החלקה על הרצועה (#89): יום אחד קדימה/אחורה; העמוד עוקב אחרי היום הנבחר
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            // כמו בצ'יפים: ב-RTL החלקה ימינה = הבא; ב-LTR הכיוון מתהפך
            final velocity = details.primaryVelocity! * (Directionality.of(context) == TextDirection.rtl ? 1 : -1);
            if (velocity > 200) {
              onSelectDay(shiftDay(selected, 1));
            } else if (velocity < -200) {
              onSelectDay(shiftDay(selected, -1));
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      style: iconStyle,
                      onPressed: () => goToPage(page - 1),
                      icon: Icon(Icons.chevron_left, size: 22, color: accent),
                    ),
                    Expanded(
                      child: Text(
                        '${DateFormat.MMMd(localeTag).format(from)} – ${DateFormat.MMMd(localeTag).format(lastDay)}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (page != 0 || selected != today)
                      IconButton(
                        style: iconStyle,
                        tooltip: l10n.today,
                        onPressed: () => goToPage(0),
                        icon: Icon(Icons.today, size: 20, color: accent),
                      ),
                    IconButton(
                      style: iconStyle,
                      onPressed: () => goToPage(page + 1),
                      icon: Icon(Icons.chevron_right, size: 22, color: accent),
                    ),
                  ],
                ),
                Row(
                  children: [
                    for (int i = 0; i < weekLength; i++)
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final date = shiftDay(from, i);
                            return _DayCell(
                              date: date,
                              marks: marks[date] ?? const [],
                              isToday: date == today,
                              isSelected: date == selected,
                              isPast: date.isBefore(today),
                              accent: accent,
                              onTap: () => onSelectDay(date),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
