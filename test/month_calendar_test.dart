import 'package:flutter_test/flutter_test.dart';
import 'package:pets_and_maintenance/models/task_log.dart';
import 'package:pets_and_maintenance/widgets/month_calendar.dart';

/// בדיקות לסימונים של הלוח החודשי (#83)
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
  final november = DateTime(2026, 11);

  Map<int, List<CalendarMark>> marks({
    DateTime? month,
    List<Map<String, dynamic>> tasks = const [],
    List<TaskLog> logs = const [],
  }) => buildMonthMarks(month: month ?? november, tasks: tasks, logs: logs, now: now);

  List<CalendarMarkKind> kinds(List<CalendarMark>? day) => day!.map((m) => m.kind).toList();

  test('יעד עתידי מסומן כמתוכנן ביום שלו', () {
    final result = marks(tasks: [task('a', next: DateTime(2026, 11, 20))]);
    expect(result.keys, [20]);
    expect(kinds(result[20]), [CalendarMarkKind.planned]);
  });

  test('יעד היום הוא מתוכנן גם אם השעה כבר עברה', () {
    final result = marks(tasks: [task('a', next: DateTime(2026, 11, 9, 6))]);
    expect(kinds(result[9]), [CalendarMarkKind.planned]);
  });

  test('יעד שעבר מסומן כבאיחור בתאריך המקורי', () {
    final result = marks(tasks: [task('a', next: DateTime(2026, 11, 2))]);
    expect(kinds(result[2]), [CalendarMarkKind.overdue]);
  });

  test('איחור מחודש קודם מופיע רק בחודש שלו', () {
    final tasks = [task('a', next: DateTime(2026, 10, 30))];
    expect(marks(tasks: tasks), isEmpty);
    expect(kinds(marks(month: DateTime(2026, 10), tasks: tasks)[30]), [CalendarMarkKind.overdue]);
  });

  test('אותו יום בחודש אחר או בשנה אחרת לא נספר', () {
    final tasks = [
      task('a', next: DateTime(2026, 12, 20)),
      task('b', next: DateTime(2027, 11, 20)),
    ];
    expect(marks(tasks: tasks), isEmpty);
  });

  test('משימה בלי תאריך לא בלוח', () {
    expect(marks(tasks: [task('a')]), isEmpty);
  });

  test('משימה שהסתיימה: בלי יעד, אבל הביצועים שלה נשארים', () {
    final tasks = [task('a', endCondition: 'count')];
    expect(marks(tasks: tasks), isEmpty);
    final result = marks(tasks: tasks, logs: [log('a', DateTime(2026, 11, 3))]);
    expect(kinds(result[3]), [CalendarMarkKind.done]);
  });

  test('כמה ביצועים באותו יום - כולם מסומנים', () {
    final tasks = [task('a'), task('b')];
    final result = marks(tasks: tasks, logs: [
      log('a', DateTime(2026, 11, 3, 8)),
      log('b', DateTime(2026, 11, 3, 20)),
    ]);
    expect(kinds(result[3]), [CalendarMarkKind.done, CalendarMarkKind.done]);
  });

  test('ביום עם יעד וביצוע - מה שפתוח קודם', () {
    final tasks = [task('a'), task('b', next: DateTime(2026, 11, 12))];
    final result = marks(tasks: tasks, logs: [log('a', DateTime(2026, 11, 12))]);
    expect(kinds(result[12]), [CalendarMarkKind.planned, CalendarMarkKind.done]);
  });

  test('סינון: ביצוע של משימה שלא ברשימה לא מוצג', () {
    final result = marks(tasks: [task('a')], logs: [log('other', DateTime(2026, 11, 3))]);
    expect(result, isEmpty);
  });

  test('קצוות חודש: ה-31 בסוף היום וה-29 בפברואר', () {
    final january = marks(
      month: DateTime(2026, 1),
      tasks: [task('a')],
      logs: [log('a', DateTime(2026, 1, 31, 23, 59)), log('a', DateTime(2026, 2, 1))],
    );
    expect(january.keys, [31]);

    final leapFebruary = marks(
      month: DateTime(2028, 2),
      tasks: [task('b', next: DateTime(2028, 2, 29))],
    );
    expect(leapFebruary.keys, [29]);
  });
}
