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

  test('הכי מהר / הכי לאט / קצב ממוצע - רק על החלון של הגרף (12 אחרונים)', () {
    // מרווח ראשון של 30 יום, ואחריו 12 מרווחים של 7 - הישן יוצא מהחלון
    final dates = [DateTime(2026, 1, 1), DateTime(2026, 1, 31)];
    for (int i = 0; i < 12; i++) {
      dates.add(dates.last.add(const Duration(days: 7)));
    }
    final s = TaskStats.compute(task(next: DateTime(2026, 6, 1)), [for (final d in dates) log(d)], now: now);
    expect(s.intervals.length, 12);
    expect(s.slowestDays, 7);
    expect(s.fastestDays, 7);
    expect(s.paceAvgDays, 7);
    // הממוצע הכללי (אריח בראש הדף) - על כל ההיסטוריה, כולל ה-30
    expect(s.avgIntervalDays, closeTo((30 + 12 * 7) / 13, 0.001));
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

  test('הרצף הכי ארוך בזמן והאיחור הכי גדול', () {
    final s = TaskStats.compute(task(amount: 7, next: DateTime(2026, 10, 30)), [
      log(DateTime(2026, 9, 1)), // בזמן (ראשון)
      log(DateTime(2026, 9, 8)), // בזמן
      log(DateTime(2026, 9, 15)), // בזמן - רצף של 3
      log(DateTime(2026, 9, 26)), // באיחור 4 (יעד 22/9)
      log(DateTime(2026, 10, 3)), // בזמן
      log(DateTime(2026, 10, 12)), // באיחור 2 (יעד 10/10)
    ], now: now);
    expect(s.longestOnTimeStreak, 3);
    expect(s.biggestLate!.lateDays, 4);
    expect(s.biggestLate!.log.completedAt, DateTime(2026, 9, 26));
  });

  test('בלי איחורים - אין איחור הכי גדול, והרצף הוא כל הביצועים', () {
    final s = TaskStats.compute(task(next: DateTime(2026, 10, 30)), [
      log(DateTime(2026, 10, 1)),
      log(DateTime(2026, 10, 8)),
    ], now: now);
    expect(s.biggestLate, isNull);
    expect(s.longestOnTimeStreak, 2);
  });

  test('משימה חודשית: קו היעד בימים', () {
    final s = TaskStats.compute(task(amount: 6, unit: 'months', next: DateTime(2027, 3, 1)), [], now: now);
    expect(s.targetDays, closeTo(182.6, 0.1));
  });
}
