import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';

// שימוש ב-FutureProvider כי מדובר בשליפה לקריאה בלבד עבור מסך הבית
final dashboardTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getDashboardTasks();
});