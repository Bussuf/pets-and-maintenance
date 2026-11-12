import 'package:flutter_test/flutter_test.dart';
import 'package:pets_and_maintenance/models/task_status.dart';

/// בדיקות ל"לדלג הפעם" (#85)
/// הרצה: flutter test test/skip_due_date_test.dart
void main() {
  test('weekly - one interval forward from the current due date', () {
    final next = skippedDueDate(DateTime(2026, 11, 12), 1, 'weeks', 'always', null, 3);
    expect(next, DateTime(2026, 11, 19));
  });

  test('monthly on the 31st - clamps to the last day of a short month', () {
    final next = skippedDueDate(DateTime(2026, 1, 31), 1, 'months', null, null, 0);
    expect(next, DateTime(2026, 2, 28));
  });

  test('every 3 months - crosses the year', () {
    final next = skippedDueDate(DateTime(2026, 11, 14), 3, 'months', 'always', null, 0);
    expect(next, DateTime(2027, 2, 14));
  });

  test('skipping past the end date finishes the task (null)', () {
    final next = skippedDueDate(DateTime(2026, 11, 20), 1, 'weeks', 'until_date', '2026-11-25', 0);
    expect(next, isNull);
  });

  test('landing exactly on the end date still counts (the end day is included)', () {
    final next = skippedDueDate(DateTime(2026, 11, 18), 1, 'weeks', 'until_date', '2026-11-25', 0);
    expect(next, DateTime(2026, 11, 25));
  });

  test('a count condition is not affected - a skip is not a completion', () {
    final next = skippedDueDate(DateTime(2026, 11, 12), 1, 'days', 'count', '10', 9);
    expect(next, DateTime(2026, 11, 13));
  });
}
