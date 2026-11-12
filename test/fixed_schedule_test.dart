import 'package:flutter_test/flutter_test.dart';
import 'package:pets_and_maintenance/models/task_status.dart';

/// בדיקות ללוח זמנים קבוע (#71)
/// הרצה: flutter test test/fixed_schedule_test.dart
void main() {
  group('nextDueAfterCompletion', () {
    test('no anchor - from the completion day, exactly as before', () {
      final next = nextDueAfterCompletion(
        completedAt: DateTime(2026, 10, 21),
        amount: 3,
        unit: 'months',
        currentDue: DateTime(2026, 12, 1),
      );
      expect(next, DateTime(2027, 1, 21));
    });

    test('the backlog case: quarterly payment due in December, paid early on 21/10 - March', () {
      final next = nextDueAfterCompletion(
        completedAt: DateTime(2026, 10, 21),
        amount: 3,
        unit: 'months',
        anchor: DateTime(2026, 12, 1),
        currentDue: DateTime(2026, 12, 1),
      );
      expect(next, DateTime(2027, 3, 1));
    });

    test('paid on the due date - the next date in the series', () {
      final next = nextDueAfterCompletion(
        completedAt: DateTime(2026, 12, 1),
        amount: 3,
        unit: 'months',
        anchor: DateTime(2026, 12, 1),
        currentDue: DateTime(2026, 12, 1),
      );
      expect(next, DateTime(2027, 3, 1));
    });

    test('late by more than one interval - missed dates are skipped, not stacked', () {
      final next = nextDueAfterCompletion(
        completedAt: DateTime(2027, 5, 10),
        amount: 3,
        unit: 'months',
        anchor: DateTime(2026, 12, 1),
        currentDue: DateTime(2026, 12, 1),
      );
      expect(next, DateTime(2027, 6, 1));
    });

    test('postponed: due moved to the 5th, done then - the schedule does not drift', () {
      final next = nextDueAfterCompletion(
        completedAt: DateTime(2026, 12, 5),
        amount: 3,
        unit: 'months',
        anchor: DateTime(2026, 12, 1),
        currentDue: DateTime(2026, 12, 5),
      );
      expect(next, DateTime(2027, 3, 1));
    });
  });

  group('nextFixedDue', () {
    test('monthly on the 31st - back to the 31st after February', () {
      final anchor = DateTime(2027, 1, 31);
      final feb = nextFixedDue(anchor, 1, 'months', DateTime(2027, 1, 31));
      expect(feb, DateTime(2027, 2, 28));
      final mar = nextFixedDue(anchor, 1, 'months', feb);
      expect(mar, DateTime(2027, 3, 31));
      final apr = nextFixedDue(anchor, 1, 'months', mar);
      expect(apr, DateTime(2027, 4, 30));
    });

    test('weekly - one week after the given date', () {
      expect(nextFixedDue(DateTime(2026, 11, 2), 1, 'weeks', DateTime(2026, 11, 12)), DateTime(2026, 11, 16));
    });
  });

  group('skippedDueDate with an anchor', () {
    test('skip moves to the next date in the series', () {
      final next = skippedDueDate(DateTime(2026, 12, 5), 3, 'months', 'always', null, 0, anchor: DateTime(2026, 12, 1));
      expect(next, DateTime(2027, 3, 1));
    });

    test('skip past the end date finishes the task', () {
      final next = skippedDueDate(DateTime(2026, 12, 1), 3, 'months', 'until_date', '2027-01-31', 0,
          anchor: DateTime(2026, 12, 1));
      expect(next, isNull);
    });
  });
}
