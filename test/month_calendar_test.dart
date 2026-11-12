import 'dart:ui' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:pets_and_maintenance/models/task_log.dart';
import 'package:pets_and_maintenance/widgets/month_calendar.dart';

/// בדיקות לסימונים של רצועת השבוע (#83)
/// הרצה: flutter test test/month_calendar_test.dart

Map<String, dynamic> task(String id, {DateTime? next, String endCondition = 'always'}) => {
  'id': id,
  'end_condition': endCondition,
  'next_due_date': next?.toIso8601String(),
};

TaskLog log(String taskId, DateTime completed) =>
    TaskLog(id: '$taskId-${completed.toIso8601String()}', taskId: taskId, completedAt: completed);

void main() {
  final now = DateTime(2026, 11, 9, 12);
  final today = DateTime(2026, 11, 9);

  Map<DateTime, List<CalendarMark>> marks({
    DateTime? from,
    List<Map<String, dynamic>> tasks = const [],
    List<TaskLog> logs = const [],
  }) => buildWeekMarks(from: from ?? today, tasks: tasks, logs: logs, now: now);

  List<CalendarMarkKind> kinds(List<CalendarMark>? day) => day!.map((m) => m.kind).toList();

  test('יעד בשבוע מסומן כמתוכנן ביום שלו', () {
    final result = marks(tasks: [task('a', next: DateTime(2026, 11, 12))]);
    expect(result.keys, [DateTime(2026, 11, 12)]);
    expect(kinds(result[DateTime(2026, 11, 12)]), [CalendarMarkKind.planned]);
  });

  test('יעד היום הוא מתוכנן גם אם השעה כבר עברה', () {
    final result = marks(tasks: [task('a', next: DateTime(2026, 11, 9, 6))]);
    expect(kinds(result[today]), [CalendarMarkKind.planned]);
  });

  test('באיחור מופיע על היום, לא על התאריך המקורי', () {
    final result = marks(tasks: [task('a', next: DateTime(2026, 11, 2))]);
    expect(result.keys, [today]);
    expect(kinds(result[today]), [CalendarMarkKind.overdue]);
  });

  test('בשבוע שעבר אין סימון של באיחור', () {
    final result = marks(from: DateTime(2026, 11, 2), tasks: [task('a', next: DateTime(2026, 11, 3))]);
    expect(result, isEmpty);
  });

  test('ביום הנוכחי: באיחור קודם, אחר כך מתוכנן, ובסוף בוצע', () {
    final tasks = [
      task('planned', next: today),
      task('late', next: DateTime(2026, 11, 2)),
      task('done'),
    ];
    final result = marks(tasks: tasks, logs: [log('done', DateTime(2026, 11, 9, 8))]);
    expect(kinds(result[today]), [CalendarMarkKind.overdue, CalendarMarkKind.planned, CalendarMarkKind.done]);
  });

  test('מחוץ ל-7 הימים לא נספר', () {
    final tasks = [task('a', next: DateTime(2026, 11, 16))];
    expect(marks(tasks: tasks), isEmpty);
    expect(marks(from: DateTime(2026, 11, 16), tasks: tasks).keys, [DateTime(2026, 11, 16)]);
  });

  test('קצה הטווח: היום השביעי עד סופו, והיום השמיני בחוץ', () {
    final result = marks(tasks: [task('a')], logs: [
      log('a', DateTime(2026, 11, 15, 23, 59)),
      log('a', DateTime(2026, 11, 16)),
    ]);
    expect(result.keys, [DateTime(2026, 11, 15)]);
  });

  test('טווח שחוצה חודש', () {
    final result = marks(
      from: DateTime(2026, 11, 28),
      tasks: [task('a', next: DateTime(2026, 12, 2))],
    );
    expect(result.keys, [DateTime(2026, 12, 2)]);
  });

  test('משימה בלי תאריך לא ברצועה', () {
    expect(marks(tasks: [task('a')]), isEmpty);
  });

  test('משימה שהסתיימה: בלי יעד, אבל הביצועים שלה נשארים', () {
    final tasks = [task('a', endCondition: 'count')];
    expect(marks(tasks: tasks), isEmpty);
    final result = marks(tasks: tasks, logs: [log('a', DateTime(2026, 11, 10))]);
    expect(kinds(result[DateTime(2026, 11, 10)]), [CalendarMarkKind.done]);
  });

  test('כמה ביצועים באותו יום - כולם מסומנים', () {
    final tasks = [task('a'), task('b')];
    final result = marks(tasks: tasks, logs: [
      log('a', DateTime(2026, 11, 10, 8)),
      log('b', DateTime(2026, 11, 10, 20)),
    ]);
    expect(kinds(result[DateTime(2026, 11, 10)]), [CalendarMarkKind.done, CalendarMarkKind.done]);
  });

  test('סינון: ביצוע של משימה שלא ברשימה לא מוצג', () {
    final result = marks(tasks: [task('a')], logs: [log('other', DateTime(2026, 11, 10))]);
    expect(result, isEmpty);
  });

  test('צבע בהיר מוכהה למילוי, צבע כהה נשאר', () {
    expect(calendarFillColor(const Color(0xFFFFEB3B)).computeLuminance(), lessThanOrEqualTo(0.3));
    const dark = Color(0xFF1F3A5F);
    expect(calendarFillColor(dark), dark);
  });
}
