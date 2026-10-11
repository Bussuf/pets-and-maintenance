import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../providers/database_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../theme/app_icons.dart';
import '../widgets/animated_fab_menu.dart';
import '../widgets/app_drawer.dart';
import '../widgets/global_search_bar.dart';
import 'category_screen.dart';
import 'create_entity_screen.dart';

class AgendaGroup {
  final String title;
  final bool isOverdue;
  final List<Map<String, dynamic>> tasks;

  AgendaGroup({
    required this.title,
    required this.tasks,
    this.isOverdue = false,
  });
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _uuid = const Uuid();
  String? _selectedCategoryId; // null = בועת "הכל"
  final Set<String> _expandedTaskIds = {};

  final Map<String?, GlobalKey> _chipKeys = {};

  final List<Color> _availableColors = [
    Colors.blue, Colors.indigo, Colors.teal, Colors.green, Colors.orange,
    Colors.deepOrange, Colors.red, Colors.purple, Colors.pink, Colors.brown, Colors.blueGrey,
  ];

  void _ensureChipVisible(String? categoryId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _chipKeys[categoryId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _selectCategory(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _ensureChipVisible(categoryId);
  }

  // חלוקת משימות למקטעי אג'נדה לפי תאריכים
  List<AgendaGroup> _buildAgendaGroups(List<Map<String, dynamic>> tasks) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final List<Map<String, dynamic>> overdue = [];
    final List<Map<String, dynamic>> today = [];
    final List<Map<String, dynamic>> tomorrow = [];
    final Map<int, List<Map<String, dynamic>>> upcomingDays = {};
    final List<Map<String, dynamic>> later = [];

    const weekdaysHebrew = {
      DateTime.sunday: 'יום ראשון',
      DateTime.monday: 'יום שני',
      DateTime.tuesday: 'יום שלישי',
      DateTime.wednesday: 'יום רביעי',
      DateTime.thursday: 'יום חמישי',
      DateTime.friday: 'יום שישי',
      DateTime.saturday: 'שבת',
    };

    for (final task in tasks) {
      if (task['next_due_date'] == null) {
        later.add(task);
        continue;
      }
      final due = DateTime.tryParse(task['next_due_date']);
      if (due == null) {
        later.add(task);
        continue;
      }
      final dueStart = DateTime(due.year, due.month, due.day);
      final diffDays = dueStart.difference(todayStart).inDays;

      if (diffDays < 0) {
        overdue.add(task);
      } else if (diffDays == 0) {
        today.add(task);
      } else if (diffDays == 1) {
        tomorrow.add(task);
      } else if (diffDays >= 2 && diffDays <= 6) {
        upcomingDays.putIfAbsent(diffDays, () => []).add(task);
      } else {
        later.add(task);
      }
    }

    final List<AgendaGroup> groups = [];
    if (overdue.isNotEmpty) {
      groups.add(AgendaGroup(title: 'באיחור', tasks: overdue, isOverdue: true));
    }
    if (today.isNotEmpty) {
      groups.add(AgendaGroup(title: 'היום', tasks: today));
    }
    if (tomorrow.isNotEmpty) {
      groups.add(AgendaGroup(title: 'מחר', tasks: tomorrow));
    }

    final sortedDiffs = upcomingDays.keys.toList()..sort();
    for (final diff in sortedDiffs) {
      final targetDate = todayStart.add(Duration(days: diff));
      final dayName = weekdaysHebrew[targetDate.weekday] ?? 'בקרוב';
      groups.add(AgendaGroup(title: dayName, tasks: upcomingDays[diff]!));
    }

    if (later.isNotEmpty) {
      groups.add(AgendaGroup(title: 'מאוחר יותר', tasks: later));
    }

    return groups;
  }

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

  void _openIconPickerSheet(Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
      ),
    );
  }

  Future<void> _editCategoryDialog(Category cat) async {
    final nameController = TextEditingController(text: cat.name);
    final descController = TextEditingController(text: cat.description ?? '');
    int? selectedColor = cat.color;
    String? selectedIcon = cat.icon;
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
                  content: 'האם למחוק את הקבוצה "${cat.name}"? כל הפריטים והמשימות שבה יימחקו לצמיתות.',
                );
                if (confirm) {
                  final db = ref.read(databaseProvider);
                  final rawDb = await db.database;
                  final items = await rawDb.query('items', where: 'category_id = ?', whereArgs: [cat.id]);
                  for (final item in items) {
                    await rawDb.delete('tasks', where: 'item_id = ?', whereArgs: [item['id']]);
                  }
                  await rawDb.delete('items', where: 'category_id = ?', whereArgs: [cat.id]);
                  await rawDb.delete('categories', where: 'id = ?', whereArgs: [cat.id]);

                  ref.invalidate(categoriesProvider);
                  ref.invalidate(dashboardTasksProvider);

                  setState(() {
                    if (_selectedCategoryId == cat.id) {
                      _selectedCategoryId = null;
                    }
                  });

                  if (mounted) Navigator.pop(ctx);
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
                final isDup = await db.isCategoryNameExists(newName, excludeId: cat.id);
                if (isDup) {
                  setDialogState(() => errorMessage = 'שם קבוצה זה כבר קיים');
                  return;
                }

                final updated = cat.copyWith(
                  name: newName,
                  description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                  color: selectedColor,
                  icon: selectedIcon,
                );
                await db.updateCategory(updated);
                ref.invalidate(categoriesProvider);
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

  void _showCategoryChipMenu(Category cat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_forward),
              title: Text('עבור לקבוצה "${cat.name}"'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(category: cat)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('ערוך קבוצה'),
              onTap: () {
                Navigator.pop(ctx);
                _editCategoryDialog(cat);
              },
            ),
          ],
        ),
      ),
    );
  }

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
          content: Text('משימה "${task['name']}" הושלמה! יעד הבא: ${nextDate.toIso8601String().split('T')[0]}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickManualCompletionDate(Map<String, dynamic> task) async {
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
  }

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

  // ווידג'ט כותרת מקטע אג'נדה מעוצב
  Widget _buildSectionHeader(AgendaGroup group, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 6.0, right: 18.0, left: 18.0),
      child: Row(
        children: [
          if (group.isOverdue) ...[
            const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.redAccent),
            const SizedBox(width: 6),
          ],
          Text(
            group.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: group.isOverdue
                  ? (isDark ? Colors.redAccent.shade100 : Colors.red.shade800)
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
            decoration: BoxDecoration(
              color: group.isOverdue
                  ? Colors.red.withOpacity(0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${group.tasks.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: group.isOverdue
                    ? (isDark ? Colors.redAccent.shade100 : Colors.red.shade800)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: group.isOverdue
                  ? Colors.red.withOpacity(0.3)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ווידג'ט כרטיס משימה מלא
  Widget _buildTaskCard(Map<String, dynamic> task, ThemeData theme, bool isDark, DateTime todayStart) {
    final taskId = task['id'] as String;
    final isExpanded = _expandedTaskIds.contains(taskId);

    final catColor = task['category_color'] != null
        ? Color(task['category_color'])
        : theme.colorScheme.primary;
    final catIcon = AppIcons.getIcon(task['category_icon']);
    final catName = task['category_name'] ?? 'כללי';
    final itemName = task['item_name'] ?? '';

    bool isOverdue = false;
    final dueDateStr = task['next_due_date'] != null
        ? task['next_due_date'].toString().split('T')[0]
        : 'לא נקבע';

    if (task['next_due_date'] != null) {
      final due = DateTime.tryParse(task['next_due_date']);
      if (due != null && due.isBefore(todayStart)) {
        isOverdue = true;
      }
    }

    final intervalStr = 'תדירות: כל ${task['interval_amount'] ?? 7} ${task['interval_unit'] ?? 'ימים'}';

    String endConditionDisplay;
    final endCond = task['end_condition'] ?? 'always';
    if (endCond == 'count') {
      endConditionDisplay = 'משך: ${task['end_condition_value'] ?? 0} פעמים';
    } else if (endCond == 'until_date') {
      final dt = task['end_condition_value'] != null
          ? task['end_condition_value'].toString().split('T')[0]
          : '';
      endConditionDisplay = 'משך: עד $dt';
    } else {
      endConditionDisplay = 'משך: ללא הגבלה';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: catColor, width: 1.5),
      ),
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
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(catIcon, size: 16, color: catColor),
                                const SizedBox(width: 4),
                                Text(
                                  '$catName | $itemName',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOverdue
                                    ? Colors.red.withOpacity(isDark ? 0.25 : 0.1)
                                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(6),
                                border: isOverdue
                                    ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isOverdue) ...[
                                    const Icon(Icons.schedule, size: 12, color: Colors.redAccent),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    'יעד: $dueDateStr',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                      color: isOverdue
                                          ? (isDark ? Colors.redAccent.shade100 : Colors.red.shade800)
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(color: catColor.withOpacity(0.4), height: 1),
                ),
                if (task['description'] != null && task['description'].toString().isNotEmpty) ...[
                  Text(
                    task['description'],
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  '$intervalStr , $endConditionDisplay',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => _completeTaskAtDate(task, DateTime.now()),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('השלם'),
                    ),
                    IconButton.outlined(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.insights_outlined, size: 18),
                      tooltip: 'ביצועים וסטטיסטיקה',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('יומן ביצועים וסטטיסטיקה עבור "${task['name']}" יוטמע בהמשך'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    IconButton.outlined(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.history, size: 18),
                      tooltip: 'ביצוע ידני',
                      onPressed: () => _pickManualCompletionDate(task),
                    ),
                    IconButton.outlined(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      tooltip: 'שכפל',
                      onPressed: () {
                        CreateEntityScreen.open(
                          context,
                          type: EntityType.task,
                          categoryId: task['category_id'],
                          itemId: task['item_id'],
                          duplicateData: task,
                        );
                      },
                    ),
                    IconButton.outlined(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'ערוך',
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final tasksAsync = ref.watch(dashboardTasksProvider);

    return Scaffold(
      appBar: GlobalSearchBar(
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('מסך הגדרות יוטמע בהמשך'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(children: [Icon(Icons.settings_outlined), SizedBox(width: 12), Text('הגדרות')]),
              ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: tasksAsync.when(
        data: (tasks) {
          final categories = categoriesAsync.value ?? [];
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);

          int overdueCount = 0;
          for (final t in tasks) {
            if (t['next_due_date'] != null) {
              final due = DateTime.tryParse(t['next_due_date']);
              if (due != null && due.isBefore(todayStart)) {
                overdueCount++;
              }
            }
          }

          final sortedTasks = List<Map<String, dynamic>>.from(tasks)..sort((a, b) {
            final dateA = a['next_due_date'] != null ? DateTime.tryParse(a['next_due_date']) : null;
            final dateB = b['next_due_date'] != null ? DateTime.tryParse(b['next_due_date']) : null;

            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateA.compareTo(dateB);
          });

          final filteredTasks = _selectedCategoryId == null
              ? sortedTasks
              : sortedTasks.where((t) => t['category_id'] == _selectedCategoryId).toList();

          // יצירת קבוצות האג'נדה ושיטוח הרשימה לביצועים מרביים
          final agendaGroups = _buildAgendaGroups(filteredTasks);
          final List<dynamic> flatList = [];
          for (final group in agendaGroups) {
            flatList.add(group); // Section Header
            flatList.addAll(group.tasks); // Task items
          }

          return Column(
            children: [
              // כרטיסיית כותרת מובנית
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                      child: Icon(Icons.grid_view, color: theme.colorScheme.primary, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'כל הקבוצות והמשימות',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            overdueCount > 0
                                ? '${tasks.length} משימות פעילות • $overdueCount באיחור'
                                : '${tasks.length} משימות פעילות • כל המשימות מעודכנות 🎉',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: overdueCount > 0 ? FontWeight.w500 : FontWeight.normal,
                              color: overdueCount > 0
                                  ? (isDark ? Colors.redAccent.shade100 : Colors.red.shade800)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // סרגל בועיות קבוצות
              categoriesAsync.when(
                data: (cats) {
                  _chipKeys.putIfAbsent(null, () => GlobalKey());

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Row(
                      children: [
                        FilterChip(
                          key: _chipKeys[null],
                          showCheckmark: false,
                          label: Text('הכל (${cats.length})'),
                          selected: _selectedCategoryId == null,
                          onSelected: (_) => _selectCategory(null),
                        ),
                        const SizedBox(width: 8),
                        ...cats.map((cat) {
                          final isSelected = _selectedCategoryId == cat.id;
                          final catColor = cat.color != null ? Color(cat.color!) : theme.colorScheme.primary;
                          final catIcon = AppIcons.getIcon(cat.icon);
                          _chipKeys.putIfAbsent(cat.id, () => GlobalKey());

                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: GestureDetector(
                              onLongPress: () => _showCategoryChipMenu(cat),
                              child: InputChip(
                                key: _chipKeys[cat.id],
                                avatar: Icon(catIcon, size: 18, color: catColor),
                                showCheckmark: false,
                                label: Text(cat.name),
                                selected: isSelected,
                                onSelected: (_) => _selectCategory(cat.id),
                                deleteIcon: isSelected ? const Icon(Icons.more_vert, size: 16) : null,
                                onDeleted: isSelected ? () => _showCategoryChipMenu(cat) : null,
                                deleteButtonTooltipMessage: 'אפשרויות קבוצה',
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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

              // רשימת משימות באג'נדה מקובצת
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (details) {
                    if (categories.isEmpty) return;
                    final allCatIds = [null, ...categories.map((c) => c.id)];
                    final currentIndex = allCatIds.indexOf(_selectedCategoryId);
                    if (currentIndex == -1) return;

                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! > 200 && currentIndex < allCatIds.length - 1) {
                        _selectCategory(allCatIds[currentIndex + 1]);
                      } else if (details.primaryVelocity! < -200 && currentIndex > 0) {
                        _selectCategory(allCatIds[currentIndex - 1]);
                      }
                    }
                  },
                  child: flatList.isEmpty
                      ? const Center(
                    child: Text('אין משימות להצגה כרגע', style: TextStyle(color: Colors.grey)),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: flatList.length,
                    itemBuilder: (context, index) {
                      final item = flatList[index];
                      if (item is AgendaGroup) {
                        return _buildSectionHeader(item, theme, isDark);
                      }
                      return _buildTaskCard(item as Map<String, dynamic>, theme, isDark, todayStart);
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('שגיאה: $err')),
      ),
      floatingActionButton: AnimatedFabMenu(
        currentCategoryId: _selectedCategoryId,
      ),
    );
  }
}