class AppTask {
  final String id;
  final String itemId;
  final String name;
  final String? description;
  final int intervalAmount;
  final String intervalUnit;
  final String endCondition;
  final String? endConditionValue;
  final int completedCount;
  final DateTime? lastCompletedDate;
  final DateTime? nextDueDate;

  // -- שדות התראות --
  final bool isReminderEnabled;
  final String? reminderTime;

  // -- סנכרון יומן גוגל --
  final String? googleEventId;

  // -- מעקב (#25) --
  final DateTime? createdAt; // תאריך יצירת המשימה (ריק במשימות שנוצרו לפני גרסה 7)

  AppTask({
    required this.id,
    required this.itemId,
    required this.name,
    this.description,
    required this.intervalAmount,
    required this.intervalUnit,
    required this.endCondition,
    this.endConditionValue,
    this.completedCount = 0,
    this.lastCompletedDate,
    this.nextDueDate,
    this.isReminderEnabled = false,
    this.reminderTime,
    this.googleEventId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'name': name,
      'description': description,
      'interval_amount': intervalAmount,
      'interval_unit': intervalUnit,
      'end_condition': endCondition,
      'end_condition_value': endConditionValue,
      'completed_count': completedCount,
      'last_completed_date': lastCompletedDate?.toIso8601String(),
      'next_due_date': nextDueDate?.toIso8601String(),
      'is_reminder_enabled': isReminderEnabled ? 1 : 0,
      'reminder_time': reminderTime,
      'google_event_id': googleEventId,
      // רק אם קיים - כדי ששמירה של משימה ישנה לא תמחק ערך קיים
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  factory AppTask.fromMap(Map<String, dynamic> map) {
    return AppTask(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      intervalAmount: map['interval_amount'] as int,
      intervalUnit: map['interval_unit'] as String,
      endCondition: map['end_condition'] as String? ?? 'always',
      endConditionValue: map['end_condition_value'] as String?,
      completedCount: (map['completed_count'] as int?) ?? 0,
      lastCompletedDate: map['last_completed_date'] != null
          ? DateTime.parse(map['last_completed_date'] as String)
          : null,
      nextDueDate: map['next_due_date'] != null
          ? DateTime.parse(map['next_due_date'] as String)
          : null,
      isReminderEnabled: (map['is_reminder_enabled'] as int?) == 1,
      reminderTime: map['reminder_time'] as String?,
      googleEventId: map['google_event_id'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  /// מצמיד את היום לסוף החודש אם הוא לא קיים בו (31/01 + חודש = 28/02, ולא 03/03)
  static DateTime _clampDay(int year, int month, DateTime from) {
    final lastDay = DateTime(year, month + 1, 0).day; // יום 0 של החודש הבא = היום האחרון של החודש
    final day = from.day > lastDay ? lastDay : from.day;
    return DateTime(year, month, day, from.hour, from.minute, from.second);
  }

  /// מוסיף תדירות לתאריך (כמות שלילית = מחסיר)
  static DateTime addInterval(DateTime from, int amount, String unit) {
    // חשבון קלנדרי (ולא Duration) - כדי שמעבר שעון קיץ/חורף לא יזיז את התאריך ביום
    switch (unit) {
      case 'weeks': return DateTime(from.year, from.month, from.day + amount * 7, from.hour, from.minute, from.second);
      case 'months': return _clampDay(from.year, from.month + amount, from);
      case 'years': return _clampDay(from.year + amount, from.month, from);
      default: return DateTime(from.year, from.month, from.day + amount, from.hour, from.minute, from.second);
    }
  }

  AppTask copyWith({
    String? id,
    String? itemId,
    String? name,
    String? description,
    int? intervalAmount,
    String? intervalUnit,
    String? endCondition,
    String? endConditionValue,
    int? completedCount,
    DateTime? lastCompletedDate,
    DateTime? nextDueDate,
    bool? isReminderEnabled,
    String? reminderTime,
    String? googleEventId,
    DateTime? createdAt,
  }) {
    return AppTask(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      description: description ?? this.description,
      intervalAmount: intervalAmount ?? this.intervalAmount,
      intervalUnit: intervalUnit ?? this.intervalUnit,
      endCondition: endCondition ?? this.endCondition,
      endConditionValue: endConditionValue ?? this.endConditionValue,
      completedCount: completedCount ?? this.completedCount,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      googleEventId: googleEventId ?? this.googleEventId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}