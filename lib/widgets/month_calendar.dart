import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../l10n/app_localizations.dart';
import '../models/task_log.dart';
import '../models/task_status.dart';
import '../providers/items_provider.dart';

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

/// כותרת ברשימת היום: שם ומונה
class _DayListHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final bool isOverdue;

  const _DayListHeader({required this.title, required this.count, required this.color, this.isOverdue = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        children: [
          if (isOverdue) ...[
            const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.redAccent),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
            decoration: BoxDecoration(
              color: isOverdue ? Colors.red.withValues(alpha: 0.15) : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isOverdue ? color : scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// שורת "בוצע" ברשימת היום - לתצוגה בלבד
class _DoneRow extends StatelessWidget {
  final Map<String, dynamic> task;

  const _DoneRow({required this.task});

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

/// מיקוד יום (#83): רצועת 7 ימים נעוצה למעלה, והמשימות של היום הנבחר נגללות מתחתיה.
/// הרצועה מתחילה מהיום (ולא מתחילת שבוע), כדי שתמיד יראו את מה שלפנינו.
/// כרטיס המשימה מגיע מבחוץ, כדי שמצב ההרחבה יישאר משותף עם היומן
class WeekFocusView extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> tasks; // כבר מסוננות לפי הצ'יפ
  final Color accent;
  final Widget Function(Map<String, dynamic> task) taskCardBuilder;

  const WeekFocusView({
    super.key,
    required this.tasks,
    required this.accent,
    required this.taskCardBuilder,
  });

  @override
  ConsumerState<WeekFocusView> createState() => _WeekFocusViewState();
}

class _WeekFocusViewState extends ConsumerState<WeekFocusView> {
  int _page = 0; // כמה שבועות מהיום
  late DateTime _selected = _today;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _pageStart(int page) {
    final today = _today;
    return DateTime(today.year, today.month, today.day + page * weekLength);
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
      _selected = _pageStart(page); // בעמוד הנוכחי זה היום עצמו
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final accent = widget.accent;
    final today = _today;
    final from = _pageStart(_page);
    final lastDay = DateTime(from.year, from.month, from.day + weekLength - 1);

    final logs = ref.watch(weekLogsProvider(from)).valueOrNull ?? const <TaskLog>[];
    final marks = buildWeekMarks(from: from, tasks: widget.tasks, logs: logs, now: DateTime.now());

    final dayMarks = marks[_selected] ?? const <CalendarMark>[];
    final overdue = dayMarks.where((m) => m.kind == CalendarMarkKind.overdue).toList();
    final rest = dayMarks.where((m) => m.kind != CalendarMarkKind.overdue).toList();
    final dayLabel = DateFormat.MMMMd(localeTag).format(_selected);
    final iconStyle = IconButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        // כמו בצ'יפים: ב-RTL החלקה ימינה = הבא; ב-LTR הכיוון מתהפך
        final velocity = details.primaryVelocity! * (Directionality.of(context) == TextDirection.rtl ? 1 : -1);
        if (velocity > 200) {
          _goToPage(_page + 1);
        } else if (velocity < -200) {
          _goToPage(_page - 1);
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      style: iconStyle,
                      onPressed: () => _goToPage(_page - 1),
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
                    if (_page != 0)
                      IconButton(
                        style: iconStyle,
                        tooltip: l10n.today,
                        onPressed: () => _goToPage(0),
                        icon: Icon(Icons.today, size: 20, color: accent),
                      ),
                    IconButton(
                      style: iconStyle,
                      onPressed: () => _goToPage(_page + 1),
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
                            final date = DateTime(from.year, from.month, from.day + i);
                            return _DayCell(
                              date: date,
                              marks: marks[date] ?? const [],
                              isToday: date == today,
                              isSelected: date == _selected,
                              isPast: date.isBefore(today),
                              accent: accent,
                              onTap: () => setState(() => _selected = date),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: 80 + MediaQuery.paddingOf(context).bottom),
              children: [
                if (overdue.isNotEmpty) ...[
                  _DayListHeader(
                    title: l10n.overdueTasks,
                    count: overdue.length,
                    color: _overdueColor(context),
                    isOverdue: true,
                  ),
                  for (final mark in overdue) widget.taskCardBuilder(mark.task),
                ],
                _DayListHeader(
                  title: _selected == today ? '${l10n.today} · $dayLabel' : dayLabel,
                  count: rest.length,
                  color: accent,
                ),
                if (dayMarks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(l10n.calEmptyDay, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  ),
                for (final mark in rest)
                  if (mark.kind == CalendarMarkKind.done) _DoneRow(task: mark.task) else widget.taskCardBuilder(mark.task),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
