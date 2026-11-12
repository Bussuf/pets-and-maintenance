import 'package:flutter_test/flutter_test.dart';
import 'package:pets_and_maintenance/models/task_status.dart';

/// בדיקות לסינון של דף התצוגות (#77)
/// הרצה: flutter test test/task_views_test.dart
void main() {
  Map<String, dynamic> task({
    bool reminder = false,
    bool calendar = false,
    String? end,
    String unit = 'days',
  }) =>
      {
        'is_reminder_enabled': reminder ? 1 : 0,
        'google_event_id': calendar ? 'evt' : null,
        'end_condition': end,
        'interval_unit': unit,
      };

  test('no active chips - nothing matches (the list is empty)', () {
    expect(matchesViews(task(reminder: true, calendar: true), {}), isFalse);
  });

  test('reminder chip keeps only tasks with a reminder', () {
    expect(matchesViews(task(reminder: true), {TaskView.reminder}), isTrue);
    expect(matchesViews(task(), {TaskView.reminder}), isFalse);
  });

  test('calendar chip keeps only synced tasks', () {
    expect(matchesViews(task(calendar: true), {TaskView.calendar}), isTrue);
    expect(matchesViews(task(), {TaskView.calendar}), isFalse);
  });

  test('end condition chip - "always" and none do not count', () {
    expect(matchesViews(task(end: 'count'), {TaskView.endCondition}), isTrue);
    expect(matchesViews(task(end: 'until_date'), {TaskView.endCondition}), isTrue);
    expect(matchesViews(task(end: 'always'), {TaskView.endCondition}), isFalse);
    expect(matchesViews(task(), {TaskView.endCondition}), isFalse);
  });

  test('fixed schedule chip keeps only tasks with an anchor (#71)', () {
    expect(matchesViews({...task(), 'schedule_anchor': '2026-12-01'}, {TaskView.fixedSchedule}), isTrue);
    expect(matchesViews(task(), {TaskView.fixedSchedule}), isFalse);
  });

  test('frequencies combine with OR', () {
    final views = {TaskView.daily, TaskView.weekly};
    expect(matchesViews(task(unit: 'days'), views), isTrue);
    expect(matchesViews(task(unit: 'weeks'), views), isTrue);
    expect(matchesViews(task(unit: 'months'), views), isFalse);
  });

  test('different kinds also combine with OR - each chip only adds', () {
    final views = {TaskView.reminder, TaskView.monthly};
    expect(matchesViews(task(reminder: true, unit: 'months'), views), isTrue);
    expect(matchesViews(task(reminder: true, unit: 'weeks'), views), isTrue);
    expect(matchesViews(task(unit: 'months'), views), isTrue);
    expect(matchesViews(task(unit: 'weeks'), views), isFalse);
  });
}
