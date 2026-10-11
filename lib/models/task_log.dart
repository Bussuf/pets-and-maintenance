import 'dart:convert';

class TaskLog {
  final String id;
  final String taskId;
  final DateTime completedAt;
  final String? notes; // For future JSON payload

  TaskLog({
    required this.id,
    required this.taskId,
    required this.completedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'completed_at': completedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory TaskLog.fromMap(Map<String, dynamic> map) {
    return TaskLog(
      id: map['id'],
      taskId: map['task_id'],
      completedAt: DateTime.parse(map['completed_at']),
      notes: map['notes'],
    );
  }

  // Helper method to parse notes if they are stored as JSON string
  Map<String, dynamic>? get parsedNotes {
    if (notes == null || notes!.isEmpty) return null;
    try {
      return jsonDecode(notes!);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'TaskLog{id: $id, taskId: $taskId, completedAt: $completedAt}';
  }
}
