import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../providers/database_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/items_provider.dart';
import '../l10n/app_localizations.dart';

/// דיאלוגים מהירים ליצירת קבוצה/פריט מתוך טפסים (טופס יצירה ועריכת משימה)
class QuickAddDialogs {
  static const _uuid = Uuid();

  /// יוצר קבוצה חדשה. מחזיר את המזהה שלה, או null אם בוטל
  static Future<String?> category(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _askName(context, l10n.newGroup, l10n.addCategoryTitleHint);
    if (name == null) return null;

    final newCat = Category(id: _uuid.v4(), name: name, createdAt: DateTime.now());
    await ref.read(databaseProvider).createCategory(newCat);
    ref.invalidate(categoriesProvider);
    return newCat.id;
  }

  /// יוצר פריט חדש בקבוצה. מחזיר את המזהה שלו, או null אם בוטל
  static Future<String?> item(BuildContext context, WidgetRef ref, String categoryId) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _askName(context, l10n.newItem, l10n.addItemTitleHint);
    if (name == null) return null;

    final newItem = Item(id: _uuid.v4(), categoryId: categoryId, name: name);
    await ref.read(databaseProvider).createItem(newItem);
    ref.invalidate(itemsByCategoryProvider(categoryId));
    return newItem.id;
  }

  /// דיאלוג עם שדה שם אחד. מחזיר את השם, או null אם בוטל או נשאר ריק
  static Future<String?> _askName(BuildContext context, String title, String hint) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(l10n.save)),
        ],
      ),
    );
    return (result == null || result.isEmpty) ? null : result;
  }
}