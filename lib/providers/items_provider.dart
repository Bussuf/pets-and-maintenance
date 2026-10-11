import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../models/task.dart';
import '../models/task_log.dart';
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