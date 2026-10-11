import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import 'database_provider.dart';

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  FutureOr<List<Category>> build() async {
    final db = ref.watch(databaseProvider);
    return await db.readAllCategories();
  }

  // הוספת קבוצה וריענון
  Future<void> addCategory(Category category) async {
    final db = ref.read(databaseProvider);
    await db.createCategory(category);
    ref.invalidateSelf();
  }

  // עדכון קבוצה (שם, צבע, סמל, תיאור) וריענון כל המסכים
  Future<void> updateCategory(Category category) async {
    final db = ref.read(databaseProvider);
    await db.updateCategory(category);
    ref.invalidateSelf();
  }

  // מחיקת קבוצה וריענון
  Future<void> removeCategory(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteCategory(id);
    ref.invalidateSelf();
  }
}

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(() {
  return CategoriesNotifier();
});