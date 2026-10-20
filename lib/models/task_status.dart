/// תנאי סיום של משימה (#51)

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

/// משימה שהסתיימה: יש לה תנאי סיום, ואין לה מועד הבא
bool isTaskFinished(Map<String, dynamic> task) =>
    task['end_condition'] != null &&
        task['end_condition'] != 'always' &&
        task['next_due_date'] == null;