import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/database_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../theme/app_icons.dart';
import 'confirm_delete_dialog.dart';
import '../l10n/app_localizations.dart';

class EditCategorySheet extends ConsumerStatefulWidget {
  final Category category;

  const EditCategorySheet({super.key, required this.category});

  static Future<void> show(BuildContext context, Category category) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditCategorySheet(category: category),
    );
  }

  @override
  ConsumerState<EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends ConsumerState<EditCategorySheet> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  int? _selectedColor;
  String? _selectedIcon;
  String? _errorMessage;

  final List<Color> _availableColors = [
    Colors.blue, Colors.indigo, Colors.teal, Colors.green, Colors.orange,
    Colors.deepOrange, Colors.red, Colors.purple, Colors.pink, Colors.brown, Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _descController = TextEditingController(text: widget.category.description ?? '');
    _selectedColor = widget.category.color;
    _selectedIcon = widget.category.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _openIconPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
              Text(AppLocalizations.of(context)!.chooseGroupIcon, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  ),
                  itemCount: AppIcons.catalog.length,
                  itemBuilder: (_, index) {
                    final key = AppIcons.catalog.keys.elementAt(index);
                    final icon = AppIcons.catalog.values.elementAt(index);
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _selectedIcon = key);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 28),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: media.viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.editGroup, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: l10n.deleteGroup,
                          onPressed: () async {
                            final confirm = await ConfirmDeleteDialog.show(
                              context,
                              title: l10n.deleteGroup,
                              content: l10n.deleteGroupConfirm(widget.category.name),
                              onConfirm: () {}, // <--- הוספנו את הפרמטר החסר
                            );
                            if (confirm == true) {
                              final db = ref.read(databaseProvider);
                              final rawDb = await db.database;
                              final items = await rawDb.query('items', where: 'category_id = ?', whereArgs: [widget.category.id]);
                              for (final item in items) {
                                await rawDb.delete('tasks', where: 'item_id = ?', whereArgs: [item['id']]);
                              }
                              await rawDb.delete('items', where: 'category_id = ?', whereArgs: [widget.category.id]);
                              await rawDb.delete('categories', where: 'id = ?', whereArgs: [widget.category.id]);

                              ref.invalidate(categoriesProvider);
                              ref.invalidate(dashboardTasksProvider);

                              if (context.mounted) {
                                Navigator.pop(context); // סוגר את חלונית העריכה
                                // אם אנחנו לא בדאשבורד אלא בתוך מסך הקבוצה עצמו, סגור גם אותו
                                if (Navigator.canPop(context)) Navigator.pop(context);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: l10n.addCategoryTitleHint, border: const OutlineInputBorder(), errorText: _errorMessage),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      decoration: InputDecoration(labelText: l10n.description, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(l10n.groupIconLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                        OutlinedButton.icon(
                          onPressed: _openIconPickerSheet,
                          icon: Icon(AppIcons.getIcon(_selectedIcon), size: 20),
                          label: Text(l10n.changeIcon),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.groupColorLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableColors.map((color) {
                        final isSel = _selectedColor == color.toARGB32();
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color.toARGB32()),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: color,
                            child: isSel ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // כפתור השמירה מחוץ לגלילה - תמיד גלוי, גם בטופס ארוך ועם מקלדת פתוחה (#58)
            FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                final newName = _nameController.text.trim();
                if (newName.isEmpty) {
                  setState(() => _errorMessage = l10n.requiredField);
                  return;
                }
                final db = ref.read(databaseProvider);
                final isDup = await db.isCategoryNameExists(newName, excludeId: widget.category.id);
                if (isDup) {
                  setState(() => _errorMessage = l10n.groupNameExists);
                  return;
                }

                final updated = widget.category.copyWith(
                  name: newName,
                  description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                  color: _selectedColor,
                  icon: _selectedIcon,
                );

                await db.updateCategory(updated);
                ref.invalidate(categoriesProvider);
                ref.invalidate(dashboardTasksProvider);

                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l10n.saveChanges, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}