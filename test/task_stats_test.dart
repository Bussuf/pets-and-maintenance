import 'package:flutter_test/flutter_test.dart';
import 'package:pets_and_maintenance/models/task_log.dart';
import 'package:pets_and_maintenance/models/task_stats.dart';

/// בדיקות למנוע החישובים של דף 'ניתוח מעקב משימה' (#25)
/// הרצה: flutter test test/task_stats_test.dart

Map<String, dynamic> task({
  int amount = 7,
  String unit = 'days',
  DateTime? next,
  String endCondition = 'always',
}) => {
  'id': 't1',
  'interval_amount': amount,
  'interval_unit': unit,
  'end_condition': endCondition,
  'next_due_date': next?.toIso8601String(),
};

TaskLog log(DateTime completed, {DateTime? due}) =>
    TaskLog(id: completed.toIso8601String(), taskId: 't1', completedAt: completed, dueAt: due);

void main() {
  final now = DateTime(2026, 10, 20, 12);

  test('משימה בלי ביצועים: אפסים ובלי מספרים מומצאים', () {
    final s = TaskStats.compute(task(next: DateTime(2026, 10, 25)), [], now: now);
    expect(s.completions, 0);
    expect(s.onTimePercent, isNull);
    expect(s.avgIntervalDays, isNull);
    expect(s.onTimeStreak, 0);
    expect(s.health, TaskHealth.onTrack);
    expect(s.daysUntilDue, 5);
  });

  test('בזמן = עד סוף יום היעד (כולל), עם due_at שמור', () {
    final s = TaskStats.compute(task(next: DateTime(2026, 10, 30)), [
      log(DateTime(2026, 10, 1, 23, 50), due: DateTime(2026, 10, 1)), // באותו יום, מאוחר בערב - בזמן
      log(DateTime(2026, 10, 11, 9), due: DateTime(2026, 10, 8)), // 3 ימים אחרי
    ], now: now);
    expect(s.logs[0].onTime, isTrue);
    expect(s.logs[1].onTime, isFalse);
    expect(s.logs[1].lateDays, 3);
    expect(s.onTimePercent, 50);
  });

  test('ביצועים ישנים בלי due_at: משחזרים מביצוע קודם + תדירות', () {
    final s = TaskStats.compute(task(amount: 7, next: DateTime(2026, 10, 30)), [
      log(DateTime(2026, 9, 1)), // ראשון - אין על מה להשוות, נחשב בזמן
      log(DateTime(2026, 9, 8)), // בדיוק שבוע - בזמן
      log(DateTime(2026, 9, 18)), // 10 ימים - באיחור 3
    ], now: now);
    expect(s.logs.map((l) => l.onTime).toList(), [true, true, false]);
    expect(s.logs[2].lateDays, 3);
    expect(s.logs[0].due, isNull);
  });

  test('רצף בזמן נספר מהביצוע האחרון אחורה, ונעצר באיחור', () {
    final s = TaskStats.compute(task(next: DateTime(2026, 10, 30)), [
      log(DateTime(2026, 9, 1)),
      log(DateTime(2026, 9, 12)), // באיחור (11 ימים)
      log(DateTime(2026, 9, 19)),
      log(DateTime(2026, 9, 26)),
    ], now: now);
    expect(s.onTimeStreak, 2);
  });

  test('מרווחים: ממוצע, הכי מהר, הכי לאט', () {
    final s = TaskStats.compute(task(next: DateTime(2026, 10, 30)), [
      log(DateTime(2026, 9, 1)),
      log(DateTime(2026, 9, 7)), // 6
      log(DateTime(2026, 9, 15)), // 8
      log(DateTime(2026, 9, 25)), // 10
    ], now: now);
    expect(s.intervals.map((p) => p.days).toList(), [6, 8, 10]);
    expect(s.avgIntervalDays, 8);
    expect(s.fastestDays, 6);
    expect(s.slowestDays, 10);
    expect(s.targetDays, 7);
  });

  test('מרווח שחוצה מעבר לשעון חורף נשאר 7 ימים', () {
    final s = TaskStats.compute(task(next: DateTime(2026, 11, 3)), [
      log(DateTime(2026, 10, 20, 9)),
      log(DateTime(2026, 10, 27, 9)),
    ], now: now);
    expect(s.intervals.single.days, 7);
  });

  test('סטטוס: באיחור כשתאריך היעד עבר', () {
    final s = TaskStats.compute(task(next: DateTime(2026, 10, 18)), [log(DateTime(2026, 10, 11))], now: now);
    expect(s.health, TaskHealth.overdue);
    expect(s.daysUntilDue, -2);
  });

  test('סטטוס: צריך תשומת לב כש-3 מתוך 5 האחרונים באיחור', () {
    final s = TaskStats.compute(task(next: DateTime(2026, 10, 30)), [
      log(DateTime(2026, 8, 1)),
      log(DateTime(2026, 8, 12)), // איחור
      log(DateTime(2026, 8, 19)),
      log(DateTime(2026, 8, 30)), // איחור
      log(DateTime(2026, 9, 10)), // איחור
    ], now: now);
    expect(s.health, TaskHealth.needsAttention);
  });

  test('סטטוס: הסתיימה גוברת על הכול', () {
    final s = TaskStats.compute(task(endCondition: 'count', next: null), [log(DateTime(2026, 9, 1))], now: now);
    expect(s.health, TaskHealth.finished);
    expect(s.daysUntilDue, isNull);
  });

  test('מתי: ימים בשבוע וחלק בחודש', () {
    final s = TaskStats.compute(task(next: DateTime(2026, 10, 30)), [
      log(DateTime(2026, 1, 1)), // יום חמישי, תחילת חודש
      log(DateTime(2026, 1, 15)), // יום חמישי, אמצע חודש
      log(DateTime(2026, 1, 25)), // יום ראשון, סוף חודש
    ], now: now);
    expect(s.weekdayCounts[DateTime.thursday], 2);
    expect(s.weekdayCounts[DateTime.sunday], 1);
    expect(s.monthPartCounts, [1, 1, 1]);
  });

  test('משימה חודשית: קו היעד בימים', () {
    final s = TaskStats.compute(task(amount: 6, unit: 'months', next: DateTime(2027, 3, 1)), [], now: now);
    expect(s.targetDays, closeTo(182.6, 0.1));
  });
}
