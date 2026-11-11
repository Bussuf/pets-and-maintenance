/// תנאי סיום של משימה (#51)
library;

import 'task.dart';

/// האם תנאי הסיום הושג: מספר פעמים שהושלם, או שהמועד הבא אחרי תאריך הסיום
bool isEndReached(String? condition, String? value, int completedCount, DateTime? nextDate) {
  if (condition == 'count') {
    final target = int.tryParse(value ?? '') ?? 0;
    return target > 0 && completedCount >= target;
  }
  if (condition == 'until_date') {
    final until = DateTime.tryParse(value ?? '');
    if (until == null || nextDate == null) return false;
    // תאריך הסיום כולל את כל היום עצמו
    return nextDate.isAfter(DateTime(until.year, until.month, until.day, 23, 59, 59));
  }
  return false;
}

/// #85 "לדלג הפעם": היעד הבא = היעד הנוכחי + מרווח אחד, בלי ביצוע (המונה לא משתנה).
/// null = הדילוג עובר את תאריך הסיום - המשימה מסתיימת
DateTime? skippedDueDate(
  DateTime due,
  int amount,
  String unit,
  String? condition,
  String? value,
  int completedCount,
) {
  final next = AppTask.addInterval(due, amount, unit);
  return isEndReached(condition, value, completedCount, next) ? null : next;
}

/// #77: התצוגות (צ'יפים בדף התצוגות / שורות בסיידבר)
enum TaskView { reminder, calendar, endCondition, daily, weekly, monthly, yearly }

const _frequencyViews = {
  TaskView.daily: 'days',
  TaskView.weekly: 'weeks',
  TaskView.monthly: 'months',
  TaskView.yearly: 'years',
};

/// #77: האם המשימה עונה על הסינון. כל הצ'יפים ב"או": משימה מוצגת אם היא עונה על
/// לפחות צ'יפ פעיל אחד. בלי צ'יפים פעילים - הרשימה ריקה (כל צ'יפ רק מוסיף)
bool matchesViews(Map<String, dynamic> task, Set<TaskView> views) {
  for (final view in views) {
    final matches = switch (view) {
      TaskView.reminder => task['is_reminder_enabled'] == 1,
      TaskView.calendar => task['google_event_id'] != null,
      TaskView.endCondition => task['end_condition'] != null && task['end_condition'] != 'always',
      _ => (task['interval_unit'] ?? 'days') == _frequencyViews[view],
    };
    if (matches) return true;
  }
  return false;
}

/// משימה שהסתיימה: יש לה תנאי סיום, ואין לה מועד הבא
bool isTaskFinished(Map<String, dynamic> task) =>
    task['end_condition'] != null &&
        task['end_condition'] != 'always' &&
        task['next_due_date'] == null;