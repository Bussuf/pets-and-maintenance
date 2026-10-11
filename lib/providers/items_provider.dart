import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import 'database_provider.dart';
import '../models/task.dart';
import '../models/task_log.dart';

// מאפשר שליפת רשימת פריטים לפי מזהה קטגוריה נתונה
final itemsByCategoryProvider = FutureProvider.family<List<Item>, String>((ref, categoryId) async {
  if (categoryId.isEmpty) return [];
  final db = ref.watch(databaseProvider);
  return await db.getItemsByCategory(categoryId);
});

// שליפת כל המשימות השייכות לפריט מסוים
final tasksByItemProvider = FutureProvider.family<List<AppTask>, String>((ref, itemId) async {
  final db = ref.watch(databaseProvider);
  return await db.getTasksByItem(itemId);
});

// שליפת היסטוריית הלוגים של משימה מסוימת
final logsByTaskProvider = FutureProvider.family<List<TaskLog>, String>((ref, taskId) async {
  final db = ref.watch(databaseProvider);
  return await db.getLogsByTask(taskId);
});