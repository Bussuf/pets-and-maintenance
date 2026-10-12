import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../providers/database_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/items_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import 'confirm_delete_dialog.dart';

class EditItemSheet extends ConsumerStatefulWidget {
  final Item item;
  final String currentCategoryId;

  const EditItemSheet({Key? key, required this.item, required this.currentCategoryId}) : super(key: key);

  static Future<void> show(BuildContext context, Item item, String currentCategoryId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => EditItemSheet(item: item, currentCategoryId: currentCategoryId),
    );
  }

  @override
  ConsumerState<EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends ConsumerState<EditItemSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedCatId;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _descController = TextEditingController(text: widget.item.description ?? '');
    _selectedCatId = widget.item.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final categories = ref.watch(categoriesProvider).value ?? [];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: media.viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('עריכת פריט: ${widget.item.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'מחק פריט',
                    onPressed: () async {
                      final confirm = await ConfirmDeleteDialog.show(
                        context,
                        title: 'מחיקת פריט',
                        content: 'האם למחוק את הפריט "${widget.item.name}" ואת כל המשימות המשויכות אליו?',
                        onConfirm: () {}, 
                      );
                      if (confirm == true) {
                        final rawDb = await ref.read(databaseProvider).database;
                        await rawDb.delete('tasks', where: 'item_id = ?', whereArgs: [widget.item.id]);
                        await rawDb.delete('items', where: 'id = ?', whereArgs: [widget.item.id]);

                        ref.invalidate(itemsByCategoryProvider(widget.currentCategoryId));
                        ref.invalidate(tasksByCategoryProvider(widget.currentCategoryId));
                        ref.invalidate(dashboardTasksProvider);

                        if (mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'שם הפריט', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'תיאור', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCatId,
                decoration: const InputDecoration(labelText: 'שיוך לקבוצה', border: OutlineInputBorder()),
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCatId = val);
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  final newName = _nameController.text.trim();
                  if (newName.isEmpty) return;

                  final rawDb = await ref.read(databaseProvider).database;
                  await rawDb.update(
                    'items',
                    {
                      'name': newName,
                      'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                      'category_id': _selectedCatId,
                    },
                    where: 'id = ?',
                    whereArgs: [widget.item.id],
                  );

                  ref.invalidate(itemsByCategoryProvider(widget.currentCategoryId));
                  ref.invalidate(tasksByCategoryProvider(widget.currentCategoryId));
                  if (_selectedCatId != widget.currentCategoryId) {
                    ref.invalidate(itemsByCategoryProvider(_selectedCatId));
                    ref.invalidate(tasksByCategoryProvider(_selectedCatId));
                  }
                  ref.invalidate(dashboardTasksProvider);

                  if (mounted) Navigator.pop(context);
                },
                child: const Text('שמור שינויים', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}