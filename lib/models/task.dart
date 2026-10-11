// מודל משימה מעודכן הכולל תנאי סיום, ערך סיום ומונה ביצועים
class AppTask {
  final String id;
  final String itemId;
  final String name;
  final String? description;
  final int intervalAmount;
  final String intervalUnit; // 'days', 'weeks', 'months', 'years'
  final String endCondition; // 'always', 'count', 'until_date'
  final String? endConditionValue; // תאריך ISO8601 או כמות מספר פעמים
  final int completedCount; // כמה פעמים בוצעה בפועל
  final DateTime? lastCompletedDate;
  final DateTime? nextDueDate;

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
    );
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
    );
  }
}