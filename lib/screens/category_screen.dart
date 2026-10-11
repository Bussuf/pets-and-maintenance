import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../providers/database_provider.dart';
import '../providers/items_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../theme/app_icons.dart';
import '../widgets/animated_fab_menu.dart';
import '../widgets/app_drawer.dart';
import 'create_entity_screen.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final Category category;

  const CategoryScreen({Key? key, required this.category}) : super(key: key);

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final _uuid = const Uuid();
  String? _selectedFilterItemId; // null = בועת "הכל"
  late Category _currentCategory;
  final Set<String> _expandedTaskIds = {};

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.indigo,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.category;
  }

  // דיאלוג אישור מחיקה בטוחה
  Future<bool> _confirmDeleteDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ביטול')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('מחק לצמיתות', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ??
        false;
  }

  // בורר סמלים ב-BottomSheet מתוך AppIcons המלא
  void _openIconPickerSheet(Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
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
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('בחר סמל לקבוצה (מלאים וקוויים)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: AppIcons.catalog.length,
                itemBuilder: (_, index) {
                  final key = AppIcons.catalog.keys.elementAt(index);
                  final icon = AppIcons.catalog.values.elementAt(index);
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      onSelect(key);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
    );
  }

  // פתיחת תפריט צף הצמוד ישירות ל-3 הנקודות בבועת הפריט
  void _showItemFloatingMenu(BuildContext anchorContext, Item item) {
    final renderBox = anchorContext.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (renderBox == null || overlay == null) {
      _editItemSheet(item);
      return;
    }

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero, ancestor: overlay),
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('ערוך פריט'),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (val == 'edit') {
        _editItemSheet(item);
      }
    });
  }

  // עריכת קבוצה מלאה
  Future<void> _editCategoryFullDialog() async {
    final nameController = TextEditingController(text: _currentCategory.name);
    final descController = TextEditingController(text: _currentCategory.description ?? '');
    int? selectedColor = _currentCategory.color;
    String? selectedIcon = _currentCategory.icon;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('עריכת קבוצה'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'שם הקבוצה', errorText: errorMessage),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'תיאור'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('סמל קבוצה:', style: TextStyle(fontWeight: FontWeight.w500)),
                    OutlinedButton.icon(
                      onPressed: () {
                        _openIconPickerSheet((newIcon) {
                          setDialogState(() => selectedIcon = newIcon);
                        });
                      },
                      icon: Icon(AppIcons.getIcon(selectedIcon), size: 20),
                      label: const Text('החלף סמל'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('צבע קבוצה:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: _availableColors.map((color) {
                    final isSel = selectedColor == color.value;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color.value),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: color,
                        child: isSel ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                final confirm = await _confirmDeleteDialog(
                  title: 'מחיקת קבוצה',
                  content: 'האם למחוק את הקבוצה "${_currentCategory.name}"? כל הפריטים והמשימות שבה יימחקו לצמיתות.',
                );
                if (confirm) {
                  final db = ref.read(databaseProvider);
                  final rawDb = await db.database;
                  final items = await rawDb.query('items', where: 'category_id = ?', whereArgs: [_currentCategory.id]);
                  for (final item in items) {
                    await rawDb.delete('tasks', where: 'item_id = ?', whereArgs: [item['id']]);
                  }
                  await rawDb.delete('items', where: 'category_id = ?', whereArgs: [_currentCategory.id]);
                  await rawDb.delete('categories', where: 'id = ?', whereArgs: [_currentCategory.id]);

                  ref.invalidate(categoriesProvider);
                  ref.invalidate(dashboardTasksProvider);

                  if (mounted) {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('מחק קבוצה'),
            ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
            FilledButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  setDialogState(() => errorMessage = 'שדה חובה');
                  return;
                }
                final db = ref.read(databaseProvider);
                final isDup = await db.isCategoryNameExists(newName, excludeId: _currentCategory.id);
                if (isDup) {
                  setDialogState(() => errorMessage = 'שם קבוצה זה כבר קיים');
                  return;
                }

                final updated = _currentCategory.copyWith(
                  name: newName,
                  description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                  color: selectedColor,
                  icon: selectedIcon,
                );
                await db.updateCategory(updated);
                ref.invalidate(categoriesProvider);

                setState(() => _currentCategory = updated);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('שמור'),
            ),
          ],
        ),
      ),
    );
  }

  // עריכת פריט ב-BottomSheet מוגן SafeArea
  Future<void> _editItemSheet(Item item) async {
    final nameController = TextEditingController(text: item.name);
    final descController = TextEditingController(text: item.description ?? '');
    String selectedCatId = item.categoryId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final media = MediaQuery.of(sheetContext);
          final categories = ref.watch(categoriesProvider).value ?? [];

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
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
                        Text('עריכת פריט: ${item.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'מחק פריט',
                          onPressed: () async {
                            final confirm = await _confirmDeleteDialog(
                              title: 'מחיקת פריט',
                              content: 'האם למחוק את הפריט "${item.name}" ואת כל המשימות המשויכות אליו?',
                            );
                            if (confirm) {
                              final rawDb = await ref.read(databaseProvider).database;
                              await rawDb.delete('tasks', where: 'item_id = ?', whereArgs: [item.id]);
                              await rawDb.delete('items', where: 'id = ?', whereArgs: [item.id]);

                              ref.invalidate(itemsByCategoryProvider(_currentCategory.id));
                              ref.invalidate(dashboardTasksProvider);

                              setState(() {
                                if (_selectedFilterItemId == item.id) {
                                  _selectedFilterItemId = null;
                                }
                              });

                              if (mounted) Navigator.pop(ctx);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'שם הפריט', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'תיאור', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedCatId,
                            decoration: const InputDecoration(
                              labelText: 'שיוך לקבוצה',
                              border: OutlineInputBorder(),
                            ),
                            items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => selectedCatId = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add),
                          tooltip: 'קבוצה חדשה',
                          onPressed: () async {
                            final newCatNameController = TextEditingController();
                            await showDialog(
                              context: context,
                              builder: (diagCtx) => AlertDialog(
                                title: const Text('קבוצה חדשה'),
                                content: TextField(
                                  controller: newCatNameController,
                                  decoration: const InputDecoration(labelText: 'שם הקבוצה'),
                                  autofocus: true,
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text('ביטול')),
                                  FilledButton(
                                    onPressed: () async {
                                      final catName = newCatNameController.text.trim();
                                      if (catName.isNotEmpty) {
                                        final newCat = Category(
                                          id: _uuid.v4(),
                                          name: catName,
                                          createdAt: DateTime.now(),
                                        );
                                        await ref.read(databaseProvider).createCategory(newCat);
                                        ref.invalidate(categoriesProvider);
                                        setSheetState(() => selectedCatId = newCat.id);
                                      }
                                      if (mounted) Navigator.pop(diagCtx);
                                    },
                                    child: const Text('צור'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        if (newName.isEmpty) return;

                        final rawDb = await ref.read(databaseProvider).database;
                        await rawDb.update(
                          'items',
                          {
                            'name': newName,
                            'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
                            'category_id': selectedCatId,
                          },
                          where: 'id = ?',
                          whereArgs: [item.id],
                        );

                        ref.invalidate(itemsByCategoryProvider(_currentCategory.id));
                        if (selectedCatId != _currentCategory.id) {
                          ref.invalidate(itemsByCategoryProvider(selectedCatId));
                        }
                        setState(() {});
                        if (mounted) Navigator.pop(ctx);
                      },
                      child: const Text('שמור שינויים', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ביצוע משימה בתאריך מסוים
  Future<void> _completeTaskAtDate(Map<String, dynamic> task, DateTime completedDate) async {
    final rawDb = await ref.read(databaseProvider).database;
    final intervalAmount = (task['interval_amount'] as num?)?.toInt() ?? 7;
    final intervalUnit = task['interval_unit'] as String? ?? 'days';

    DateTime nextDate;
    switch (intervalUnit) {
      case 'days':
        nextDate = completedDate.add(Duration(days: intervalAmount));
        break;
      case 'weeks':
        nextDate = completedDate.add(Duration(days: intervalAmount * 7));
        break;
      case 'months':
        nextDate = DateTime(completedDate.year, completedDate.month + intervalAmount, completedDate.day);
        break;
      case 'years':
        nextDate = DateTime(completedDate.year + intervalAmount, completedDate.month, completedDate.day);
        break;
      default:
        nextDate = completedDate.add(Duration(days: intervalAmount));
    }

    final currentCompletedCount = (task['completed_count'] as num?)?.toInt() ?? 0;

    await rawDb.update(
      'tasks',
      {
        'next_due_date': nextDate.toIso8601String(),
        'last_completed_date': completedDate.toIso8601String(),
        'completed_count': currentCompletedCount + 1,
      },
      where: 'id = ?',
      whereArgs: [task['id']],
    );

    await rawDb.insert('task_logs', {
      'id': _uuid.v4(),
      'task_id': task['id'],
      'completed_at': completedDate.toIso8601String(),
    });

    ref.invalidate(dashboardTasksProvider);
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('משימה "${task['name']}" עודכנה! יעד הבא: ${nextDate.toIso8601String().split('T')[0]}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // עריכת משימה מלאה
  Future<void> _editTaskFullDialog(Map<String, dynamic> task) async {
    final nameController = TextEditingController(text: task['name']);
    final descController = TextEditingController(text: task['description'] ?? '');
    final intervalAmountController = TextEditingController(text: '${task['interval_amount'] ?? 7}');
    final endConditionCountController = TextEditingController(
      text: task['end_condition'] == 'count' ? (task['end_condition_value'] ?? '') : '',
    );

    String selectedUnit = task['interval_unit'] ?? 'days';
    String selectedEndCondition = task['end_condition'] ?? 'always';
    DateTime? selectedEndConditionDate = (selectedEndCondition == 'until_date' && task['end_condition_value'] != null)
        ? DateTime.tryParse(task['end_condition_value'])
        : null;

    DateTime? nextDueDate = task['next_due_date'] != null ? DateTime.tryParse(task['next_due_date']) : null;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (diagCtx, setDiagState) => AlertDialog(
          title: const Text('עריכת משימה מלאה'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'שם המשימה', border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'תיאור', border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('הגדרות תזמון וחזרתיות:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: intervalAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'כל', border: UnderlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(border: UnderlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'days', child: Text('ימים')),
                          DropdownMenuItem(value: 'weeks', child: Text('שבועות')),
                          DropdownMenuItem(value: 'months', child: Text('חודשים')),
                          DropdownMenuItem(value: 'years', child: Text('שנים')),
                        ],
                        onChanged: (v) => setDiagState(() => selectedUnit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('תאריך יעד הבא: '),
                    TextButton.icon(
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(nextDueDate != null ? nextDueDate!.toIso8601String().split('T')[0] : 'לא נקבע'),
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: nextDueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (p != null) setDiagState(() => nextDueDate = p);
                      },
                    ),
                  ],
                ),
                const Divider(),
                const Text('תנאי סיום:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                RadioListTile<String>(
                  title: const Text('תמיד (ללא הגבלה)'),
                  value: 'always',
                  groupValue: selectedEndCondition,
                  onChanged: (v) => setDiagState(() => selectedEndCondition = v!),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  title: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('לפי מספר פעמים:'),
                      if (selectedEndCondition == 'count') ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: endConditionCountController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]
                    ],
                  ),
                  value: 'count',
                  groupValue: selectedEndCondition,
                  onChanged: (v) => setDiagState(() => selectedEndCondition = v!),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  title: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('עד תאריך:'),
                      if (selectedEndCondition == 'until_date') ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final p = await showDatePicker(
                              context: context,
                              initialDate: selectedEndConditionDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2035),
                            );
                            if (p != null) setDiagState(() => selectedEndConditionDate = p);
                          },
                          child: Text(selectedEndConditionDate != null
                              ? selectedEndConditionDate!.toIso8601String().split('T')[0]
                              : 'בחר'),
                        )
                      ]
                    ],
                  ),
                  value: 'until_date',
                  groupValue: selectedEndCondition,
                  onChanged: (v) => setDiagState(() => selectedEndCondition = v!),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                final confirm = await _confirmDeleteDialog(
                  title: 'מחיקת משימה',
                  content: 'האם למחוק לצמיתות את המשימה "${task['name']}"?',
                );
                if (confirm) {
                  final rawDb = await ref.read(databaseProvider).database;
                  await rawDb.delete('tasks', where: 'id = ?', whereArgs: [task['id']]);
                  ref.invalidate(dashboardTasksProvider);
                  setState(() {});
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('מחק משימה'),
            ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
            FilledButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) return;

                String? endVal;
                if (selectedEndCondition == 'count') {
                  endVal = endConditionCountController.text.trim();
                } else if (selectedEndCondition == 'until_date' && selectedEndConditionDate != null) {
                  endVal = selectedEndConditionDate!.toIso8601String();
                }

                final rawDb = await ref.read(databaseProvider).database;
                await rawDb.update(
                  'tasks',
                  {
                    'name': newName,
                    'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
                    'interval_amount': int.tryParse(intervalAmountController.text) ?? 7,
                    'interval_unit': selectedUnit,
                    'end_condition': selectedEndCondition,
                    'end_condition_value': endVal,
                    'next_due_date': nextDueDate?.toIso8601String(),
                  },
                  where: 'id = ?',
                  whereArgs: [task['id']],
                );

                ref.invalidate(dashboardTasksProvider);
                setState(() {});
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('שמור'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final itemsAsync = ref.watch(itemsByCategoryProvider(_currentCategory.id));
    final db = ref.watch(databaseProvider);

    final catColor = _currentCategory.color != null ? Color(_currentCategory.color!) : theme.colorScheme.primary;
    final catIcon = AppIcons.getIcon(_currentCategory.icon);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCategory.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'edit') {
                _editCategoryFullDialog();
              } else if (val == 'image') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('הוספת תמונה לקבוצה תוטמע בהמשך'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [Icon(Icons.edit_outlined), SizedBox(width: 12), Text('עריכת קבוצה')]),
              ),
              const PopupMenuItem(
                value: 'image',
                child: Row(children: [Icon(Icons.image_outlined), SizedBox(width: 12), Text('הוספת תמונה')]),
              ),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(currentCategoryId: _currentCategory.id),
      body: Column(
        children: [
          // Header קבוצה
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: catColor.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: catColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: catColor.withOpacity(0.2),
                  child: Icon(catIcon, color: catColor, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentCategory.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : catColor.withOpacity(0.9),
                        ),
                      ),
                      if (_currentCategory.description != null && _currentCategory.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _currentCategory.description!,
                          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // בועות פריטים: ללא V (Checkmark) עם גובה אחיד ו-3 נקודות יציב
          itemsAsync.when(
            data: (items) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    FilterChip(
                      showCheckmark: false, // ביטול ה-V לגובה אחיד
                      label: Text('הכל (${items.length})'),
                      selected: _selectedFilterItemId == null,
                      onSelected: (_) => setState(() => _selectedFilterItemId = null),
                    ),
                    const SizedBox(width: 8),
                    ...items.map((item) {
                      final isSelected = _selectedFilterItemId == item.id;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: GestureDetector(
                          onLongPress: () => _editItemSheet(item),
                          child: FilterChip(
                            showCheckmark: false, // ביטול ה-V לגובה אחיד
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item.name),
                                if (isSelected) ...[
                                  const SizedBox(width: 4),
                                  Builder(
                                    builder: (btnCtx) => InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _showItemFloatingMenu(btnCtx, item),
                                      child: const Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Icon(Icons.more_vert, size: 16),
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedFilterItemId = item.id),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 44, child: Center(child: LinearProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(height: 1),

          // רשימת משימות
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: db.getTasksByCategory(_currentCategory.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data ?? [];
                final filteredTasks = _selectedFilterItemId == null
                    ? tasks
                    : tasks.where((t) => t['item_id'] == _selectedFilterItemId).toList();

                if (filteredTasks.isEmpty) {
                  return const Center(
                    child: Text('אין משימות להצגה בקבוצה זו', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    final taskId = task['id'] as String;
                    final isExpanded = _expandedTaskIds.contains(taskId);

                    final dueDateStr = task['next_due_date'] != null
                        ? task['next_due_date'].toString().split('T')[0]
                        : 'לא נקבע';

                    final intervalStr = 'כל ${task['interval_amount'] ?? 7} ${task['interval_unit'] ?? 'ימים'}';

                    String endConditionDisplay;
                    final endCond = task['end_condition'] ?? 'always';
                    if (endCond == 'count') {
                      endConditionDisplay = 'משך / יעד סיום: ${task['end_condition_value'] ?? 0} פעמים';
                    } else if (endCond == 'until_date') {
                      final dt = task['end_condition_value'] != null
                          ? task['end_condition_value'].toString().split('T')[0]
                          : '';
                      endConditionDisplay = 'משך / יעד סיום: עד $dt';
                    } else {
                      endConditionDisplay = 'משך / יעד סיום: ללא הגבלה (תמיד)';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedTaskIds.remove(taskId);
                            } else {
                              _expandedTaskIds.add(taskId);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task['name'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'פריט: ${task['item_name']} | יעד: $dueDateStr',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                              if (isExpanded) ...[
                                const Divider(height: 20),
                                if (task['description'] != null && task['description'].toString().isNotEmpty) ...[
                                  Text(
                                    task['description'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text(
                                  'תדירות: $intervalStr',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  endConditionDisplay,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      onPressed: () => _completeTaskAtDate(task, DateTime.now()),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('בוצע'),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
                                          helpText: 'בחר תאריך ביצוע בפועל',
                                        );
                                        if (picked != null) {
                                          await _completeTaskAtDate(task, picked);
                                        }
                                      },
                                      icon: const Icon(Icons.history, size: 16),
                                      label: const Text('ביצוע ידני'),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      onPressed: () {
                                        CreateEntityScreen.open(
                                          context,
                                          type: EntityType.task,
                                          categoryId: _currentCategory.id,
                                          itemId: task['item_id'],
                                          duplicateData: task,
                                        );
                                      },
                                      icon: const Icon(Icons.copy_outlined, size: 16),
                                      label: const Text('שכפל'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      tooltip: 'ערוך משימה',
                                      onPressed: () => _editTaskFullDialog(task),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedFabMenu(
        currentCategoryId: _currentCategory.id,
        currentItemId: _selectedFilterItemId,
      ),
    );
  }
}