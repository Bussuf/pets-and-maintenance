import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../models/task.dart';
import '../models/task_log.dart';
import 'dashboard_tasks_provider.dart';
import 'database_provider.dart';

// מאפשר שליפת רשימת פריטים לפי מזהה קבוצה
final itemsByCategoryProvider = FutureProvider.family<List<Item>, String>((ref, categoryId) async {
  if (categoryId.isEmpty) return [];
  final db = ref.watch(databaseProvider);
  return await db.getItemsByCategory(categoryId);
});

// שליפת כל המשימות השייכות לקבוצה מסוימת (ריאקטיבי ומסונכרן מלא)
final tasksByCategoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, categoryId) async {
  if (categoryId.isEmpty) return [];
  final db = ref.watch(databaseProvider);
  return await db.getTasksByCategory(categoryId);
});

// שליפת כל המשימות השייכות לפריט מסוים
final tasksByItemProvider = FutureProvider.family<List<AppTask>, String>((ref, itemId) async {
  if (itemId.isEmpty) return [];
  final db = ref.watch(databaseProvider);
  return await db.getTasksByItem(itemId);
});

// שליפת היסטוריית הלוגים של משימה מסוימת
final logsByTaskProvider = FutureProvider.family<List<TaskLog>, String>((ref, taskId) async {
  if (taskId.isEmpty) return [];
  final db = ref.watch(databaseProvider);
  return await db.getLogsByTask(taskId);
});

// הביצועים של 7 ימים לרצועת השבוע (#83; המפתח: היום הראשון ברצועה).
// תלוי במשימות כדי להתרענן אחרי כל שינוי - כל מסלולי ההשלמה, הביטול והמחיקה כבר מרעננים אותן
final weekLogsProvider = FutureProvider.autoDispose.family<List<TaskLog>, DateTime>((ref, from) async {
  await ref.watch(dashboardTasksProvider.future);
  final db = ref.watch(databaseProvider);
  return await db.getLogsBetween(from, DateTime(from.year, from.month, from.day + 7));
});