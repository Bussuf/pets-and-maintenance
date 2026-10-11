import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import 'database_provider.dart';

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  FutureOr<List<Category>> build() async {
    // שליפה ראשונית של כל הקטגוריות
    final db = ref.watch(databaseProvider);
    return await db.readAllCategories();
  }

  // פונקציית עזר להוספת קטגוריה וריענון המסך
  Future<void> addCategory(Category category) async {
    final db = ref.read(databaseProvider);
    await db.createCategory(category);
    // פקודה זו אומרת ל-Riverpod לטעון את הנתונים מחדש ולעדכן את ה-UI
    ref.invalidateSelf(); 
  }

  // פונקציית עזר למחיקת קטגוריה
  Future<void> removeCategory(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteCategory(id);
    ref.invalidateSelf();
  }
}

// ה-Provider שאליו ה-UI יאזין
final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(() {
  return CategoriesNotifier();
});