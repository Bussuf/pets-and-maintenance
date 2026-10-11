import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../providers/database_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/items_provider.dart';
import 'confirm_delete_dialog.dart';
import '../services/notification_service.dart';

class EditTaskSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> taskMap;

  const EditTaskSheet({Key? key, required this.taskMap}) : super(key: key);

  static Future<void> show(BuildContext context, Map<String, dynamic> task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditTaskSheet(taskMap: task),
    );
  }

  @override
  ConsumerState<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends ConsumerState<EditTaskSheet> {
  final _uuid = const Uuid();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _intervalAmountController;
  late TextEditingController _endConditionCountController;

  late String _selectedUnit;
  late String _selectedEndCondition;
  DateTime? _selectedEndConditionDate;
  DateTime? _nextDueDate;
  late bool _isReminderEnabled;

  // שיוכים
  late String _selectedCategoryId;
  late String _selectedItemId;

  @override
  void initState() {
    super.initState();
    final t = widget.taskMap;
    _nameController = TextEditingController(text: t['name']);
    _descController = TextEditingController(text: t['description'] ?? '');
    _intervalAmountController = TextEditingController(text: '${t['interval_amount'] ?? 7}');
    _endConditionCountController = TextEditingController(
      text: t['end_condition'] == 'count' ? (t['end_condition_value'] ?? '') : '',
    );

    _selectedUnit = t['interval_unit'] ?? 'days';
    _selectedEndCondition = t['end_condition'] ?? 'always';
    if (_selectedEndCondition == 'until_date' && t['end_condition_value'] != null) {
      _selectedEndConditionDate = DateTime.tryParse(t['end_condition_value']);
    }
    _nextDueDate = t['next_due_date'] != null ? DateTime.tryParse(t['next_due_date']) : null;
    _isReminderEnabled = (t['is_reminder_enabled'] == 1);

    _selectedCategoryId = t['category_id'] ?? '';
    _selectedItemId = t['item_id'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _intervalAmountController.dispose();
    _endConditionCountController.dispose();
    super.dispose();
  }

  Future<void> _showQuickAddCategory() async {
    final quickNameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('קבוצה חדשה'),
        content: TextField(
          controller: quickNameController,
          decoration: const InputDecoration(hintText: 'שם הקבוצה'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          FilledButton(
            onPressed: () async {
              if (quickNameController.text.trim().isNotEmpty) {
                final newCat = Category(
                  id: _uuid.v4(),
                  name: quickNameController.text.trim(),
                  createdAt: DateTime.now(),
                );
                await ref.read(databaseProvider).createCategory(newCat);
                ref.invalidate(categoriesProvider);
                setState(() => _selectedCategoryId = newCat.id);
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickAddItem() async {
    if (_selectedCategoryId.isEmpty) return;
    final quickNameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('פריט חדש'),
        content: TextField(
          controller: quickNameController,
          decoration: const InputDecoration(hintText: 'שם הפריט'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          FilledButton(
            onPressed: () async {
              if (quickNameController.text.trim().isNotEmpty) {
                final newItem = Item(
                  id: _uuid.v4(),
                  categoryId: _selectedCategoryId,
                  name: quickNameController.text.trim(),
                );
                await ref.read(databaseProvider).createItem(newItem);
                ref.invalidate(itemsByCategoryProvider(_selectedCategoryId));
                setState(() => _selectedItemId = newItem.id);
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);

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
                  const Text('עריכת משימה', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'מחק משימה',
                    onPressed: () async {
                      final confirm = await ConfirmDeleteDialog.show(
                        context,
                        title: 'מחיקת משימה',
                        content: 'האם למחוק לצמיתות את המשימה "${widget.taskMap['name']}"?',
                        onConfirm: () {},
                      );

                      if (confirm == true) {
                        try {
                          final rawDb = await ref.read(databaseProvider).database;
                          await rawDb.delete('tasks', where: 'id = ?', whereArgs: [widget.taskMap['id']]);

                          // הגנה מפני קריסה שקטה בשירות ההתראות
                          try {
                            await NotificationService.instance.cancelReminder(widget.taskMap['id']);
                          } catch (e) {
                            debugPrint('Failed to cancel reminder: $e');
                          }

                          // רענון ריאקטיבי מיידי של הממשק
                          ref.invalidate(dashboardTasksProvider);
                          if (_selectedCategoryId.isNotEmpty) {
                            ref.invalidate(tasksByCategoryProvider(_selectedCategoryId));
                          }
                          if (widget.taskMap['category_id'] != null && widget.taskMap['category_id'] != _selectedCategoryId) {
                            ref.invalidate(tasksByCategoryProvider(widget.taskMap['category_id']));
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('המשימה נמחקה בהצלחה'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('שגיאה במחיקה: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'שם המשימה', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'תיאור', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // --- אזור שיוך לקבוצה ופריט ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ref.watch(categoriesProvider).when(
                            data: (cats) {
                              final displayCats = cats.toList();
                              if (_selectedCategoryId.isNotEmpty && !displayCats.any((c) => c.id == _selectedCategoryId)) {
                                displayCats.add(Category(id: _selectedCategoryId, name: '...', createdAt: DateTime.now()));
                              }
                              return DropdownButtonFormField<String>(
                                value: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
                                decoration: const InputDecoration(labelText: 'שיוך לקבוצה', border: OutlineInputBorder(), isDense: true),
                                items: displayCats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                onChanged: (val) => setState(() {
                                  _selectedCategoryId = val ?? '';
                                  _selectedItemId = ''; // איפוס פריט בעת החלפת קבוצה
                                }),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (err, _) => const Text('שגיאה בטעינת קבוצות'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add),
                          onPressed: _showQuickAddCategory,
                          tooltip: 'הוסף קבוצה',
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _selectedCategoryId.isEmpty
                              ? const Text('בחר קבוצה קודם', style: TextStyle(color: Colors.grey))
                              : ref.watch(itemsByCategoryProvider(_selectedCategoryId)).when(
                            data: (items) {
                              final displayItems = items.toList();
                              if (_selectedItemId.isNotEmpty && !displayItems.any((i) => i.id == _selectedItemId)) {
                                displayItems.add(Item(id: _selectedItemId, categoryId: _selectedCategoryId, name: '...'));
                              }
                              return DropdownButtonFormField<String>(
                                value: _selectedItemId.isEmpty ? null : _selectedItemId,
                                decoration: const InputDecoration(labelText: 'שיוך לפריט', border: OutlineInputBorder(), isDense: true),
                                items: displayItems.map((i) => DropdownMenuItem(value: i.id, child: Text(i.name))).toList(),
                                onChanged: (val) => setState(() => _selectedItemId = val ?? ''),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (err, _) => const Text('שגיאה בטעינת פריטים'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add),
                          onPressed: _selectedCategoryId.isEmpty ? null : _showQuickAddItem,
                          tooltip: 'הוסף פריט',
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- אזור תדירות ומשך ---
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _intervalAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'תדירות: כל', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'days', child: Text('ימים')),
                        DropdownMenuItem(value: 'weeks', child: Text('שבועות')),
                        DropdownMenuItem(value: 'months', child: Text('חודשים')),
                        DropdownMenuItem(value: 'years', child: Text('שנים')),
                      ],
                      onChanged: (v) => setState(() => _selectedUnit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: _selectedEndCondition == 'always' ? 1 : 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedEndCondition,
                      decoration: const InputDecoration(labelText: 'משך משימה', border: OutlineInputBorder(), isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'always', child: Text('לנצח (תמיד)')),
                        DropdownMenuItem(value: 'count', child: Text('לפי מספר פעמים')),
                        DropdownMenuItem(value: 'until_date', child: Text('עד תאריך יעד')),
                      ],
                      onChanged: (v) => setState(() => _selectedEndCondition = v!),
                    ),
                  ),
                  if (_selectedEndCondition == 'count') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _endConditionCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'כמות', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                  ],
                  if (_selectedEndCondition == 'until_date') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        onPressed: () async {
                          final p = await showDatePicker(
                            context: context,
                            initialDate: _selectedEndConditionDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2035),
                          );
                          if (p != null) setState(() => _selectedEndConditionDate = p);
                        },
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: Text(_selectedEndConditionDate != null ? _selectedEndConditionDate!.toIso8601String().split('T')[0] : 'בחר תאריך', style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // --- אזור התראות וסנכרון ---
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('קבל תזכורת למכשיר', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('התראה תופיע בהתאם להגדרות המערכת'),
                      secondary: Icon(
                        _isReminderEnabled ? Icons.notifications_active : Icons.notifications_off_outlined,
                        color: _isReminderEnabled ? theme.colorScheme.primary : Colors.grey,
                      ),
                      value: _isReminderEnabled,
                      onChanged: (bool value) => setState(() => _isReminderEnabled = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              FilledButton(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  final newName = _nameController.text.trim();
                  if (newName.isEmpty || _selectedItemId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('נא למלא שם משימה ולשייך לפריט'), backgroundColor: Colors.orange),
                    );
                    return;
                  }

                  String? endVal;
                  if (_selectedEndCondition == 'count') {
                    endVal = _endConditionCountController.text.trim();
                  } else if (_selectedEndCondition == 'until_date' && _selectedEndConditionDate != null) {
                    endVal = _selectedEndConditionDate!.toIso8601String();
                  }

                  try {
                    final db = ref.read(databaseProvider);
                    final rawDb = await db.database;

                    await rawDb.update(
                      'tasks',
                      {
                        'name': newName,
                        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                        'item_id': _selectedItemId,
                        'interval_amount': int.tryParse(_intervalAmountController.text) ?? 7,
                        'interval_unit': _selectedUnit,
                        'end_condition': _selectedEndCondition,
                        'end_condition_value': endVal,
                        'next_due_date': _nextDueDate?.toIso8601String(),
                        'is_reminder_enabled': _isReminderEnabled ? 1 : 0,
                        'reminder_time': _isReminderEnabled ? '09:00' : null,
                      },
                      where: 'id = ?',
                      whereArgs: [widget.taskMap['id']],
                    );

                    // הגנה מפני שגיאת התראות - לא יתקע את הממשק יותר!
                    try {
                      final updatedTask = await db.readTask(widget.taskMap['id']);
                      if (updatedTask != null) {
                        await NotificationService.instance.scheduleTaskReminder(updatedTask);
                      }
                    } catch (e) {
                      debugPrint('Failed to schedule reminder: $e');
                    }

                    // רענון כפול - מונע באג שבו הרשימה לא מתעדכנת לאחר שינוי קבוצה או מחיקה
                    ref.invalidate(dashboardTasksProvider);
                    if (_selectedCategoryId.isNotEmpty) {
                      ref.invalidate(tasksByCategoryProvider(_selectedCategoryId));
                    }
                    if (widget.taskMap['category_id'] != null && widget.taskMap['category_id'] != _selectedCategoryId) {
                      ref.invalidate(tasksByCategoryProvider(widget.taskMap['category_id']));
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('נשמר בהצלחה!'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('שגיאה בשמירה: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
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