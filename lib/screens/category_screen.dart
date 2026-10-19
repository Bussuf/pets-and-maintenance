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
import '../widgets/global_search_bar.dart';
import '../widgets/task_card.dart';
import '../widgets/edit_category_sheet.dart';
import '../widgets/confirm_delete_dialog.dart';

class CategoryAgendaGroup {
  final String title;
  final bool isOverdue;
  final List<Map<String, dynamic>> tasks;

  CategoryAgendaGroup({
    required this.title,
    required this.tasks,
    this.isOverdue = false,
  });
}

class CategoryScreen extends ConsumerStatefulWidget {
  final Category category;
  final String? initialItemId;
  final String? initialTaskId;

  const CategoryScreen({
    Key? key,
    required this.category,
    this.initialItemId,
    this.initialTaskId,
  }) : super(key: key);

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final _uuid = const Uuid();
  String? _selectedFilterItemId;
  final Set<String> _expandedTaskIds = {};

  final Map<String?, GlobalKey> _chipKeys = {};
  final Map<String, GlobalKey> _taskKeys = {};

  @override
  void initState() {
    super.initState();
    _selectedFilterItemId = widget.initialItemId;

    if (widget.initialTaskId != null) {
      _expandedTaskIds.add(widget.initialTaskId!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialItemId != null) {
        _ensureChipVisible(widget.initialItemId);
      }
      if (widget.initialTaskId != null) {
        final taskKey = _taskKeys[widget.initialTaskId];
        if (taskKey?.currentContext != null) {
          Scrollable.ensureVisible(
            taskKey!.currentContext!,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _ensureChipVisible(String? itemId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _chipKeys[itemId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _selectFilterItem(String? itemId) {
    setState(() => _selectedFilterItemId = itemId);
    _ensureChipVisible(itemId);
  }

  List<CategoryAgendaGroup> _buildAgendaGroups(List<Map<String, dynamic>> tasks) {
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

    final List<CategoryAgendaGroup> groups = [];
    if (overdue.isNotEmpty) {
      groups.add(CategoryAgendaGroup(title: 'באיחור', tasks: overdue, isOverdue: true));
    }
    if (today.isNotEmpty) {
      groups.add(CategoryAgendaGroup(title: 'היום', tasks: today));
    }
    if (tomorrow.isNotEmpty) {
      groups.add(CategoryAgendaGroup(title: 'מחר', tasks: tomorrow));
    }

    final sortedDiffs = upcomingDays.keys.toList()..sort();
    for (final diff in sortedDiffs) {
      final targetDate = todayStart.add(Duration(days: diff));
      final dayName = weekdaysHebrew[targetDate.weekday] ?? 'בקרוב';
      groups.add(CategoryAgendaGroup(title: dayName, tasks: upcomingDays[diff]!));
    }

    if (later.isNotEmpty) {
      groups.add(CategoryAgendaGroup(title: 'מאוחר יותר', tasks: later));
    }

    return groups;
  }

  Future<void> _editItemSheet(Item item, String catId) async {
    final nameController = TextEditingController(text: item.name);
    final descController = TextEditingController(text: item.description ?? '');
    String selectedCatId = item.categoryId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                            final confirm = await ConfirmDeleteDialog.show(
                              context,
                              title: 'מחיקת פריט',
                              content: 'האם למחוק את הפריט "${item.name}" ואת כל המשימות המשויכות אליו?',
                              onConfirm: () {},
                            );
                            if (confirm == true) {
                              final rawDb = await ref.read(databaseProvider).database;
                              await rawDb.delete('tasks', where: 'item_id = ?', whereArgs: [item.id]);
                              await rawDb.delete('items', where: 'id = ?', whereArgs: [item.id]);

                              ref.invalidate(itemsByCategoryProvider(catId));
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
                                        await ref.read(categoriesProvider.notifier).addCategory(newCat);
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

                        ref.invalidate(itemsByCategoryProvider(catId));
                        if (selectedCatId != catId) {
                          ref.invalidate(itemsByCategoryProvider(selectedCatId));
                        }
                        ref.invalidate(dashboardTasksProvider);

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

  Widget _buildSectionHeader(CategoryAgendaGroup group, ThemeData theme, bool isDark) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categoriesList = ref.watch(categoriesProvider).value ?? [];
    final currentCategory = categoriesList.firstWhere(
          (c) => c.id == widget.category.id,
      orElse: () => widget.category,
    );

    final itemsAsync = ref.watch(itemsByCategoryProvider(currentCategory.id));

    // --- השינוי הגדול: שימוש ב-dashboardTasksProvider במקום ב-tasksByCategoryProvider ---
    final allTasksAsync = ref.watch(dashboardTasksProvider);

    final catColor = currentCategory.color != null ? Color(currentCategory.color!) : theme.colorScheme.primary;
    final catIcon = AppIcons.getIcon(currentCategory.icon);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: GlobalSearchBar(
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'edit') {
                EditCategorySheet.show(context, currentCategory);
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
      drawer: AppDrawer(currentCategoryId: currentCategory.id),
      body: Column(
        children: [
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
                        currentCategory.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : catColor.withOpacity(0.9),
                        ),
                      ),
                      if (currentCategory.description != null && currentCategory.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          currentCategory.description!,
                          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          itemsAsync.when(
            data: (items) {
              _chipKeys.putIfAbsent(null, () => GlobalKey());

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    FilterChip(
                      key: _chipKeys[null],
                      showCheckmark: false,
                      label: Text('הכל (${items.length})'),
                      selected: _selectedFilterItemId == null,
                      onSelected: (_) => _selectFilterItem(null),
                    ),
                    const SizedBox(width: 8),
                    ...items.map((item) {
                      final isSelected = _selectedFilterItemId == item.id;
                      _chipKeys.putIfAbsent(item.id, () => GlobalKey());

                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: GestureDetector(
                          onLongPress: () => _editItemSheet(item, currentCategory.id),
                          child: InputChip(
                            key: _chipKeys[item.id],
                            showCheckmark: false,
                            label: Text(item.name),
                            selected: isSelected,
                            onSelected: (_) => _selectFilterItem(item.id),
                            deleteIcon: isSelected ? const Icon(Icons.more_vert, size: 16) : null,
                            onDeleted: isSelected ? () => _editItemSheet(item, currentCategory.id) : null,
                            deleteButtonTooltipMessage: 'ערוך פריט',
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

          Expanded(
            child: itemsAsync.when(
              data: (items) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (details) {
                    if (items.isEmpty) return;
                    final allFilterIds = [null, ...items.map((e) => e.id)];
                    final currentIndex = allFilterIds.indexOf(_selectedFilterItemId);
                    if (currentIndex == -1) return;

                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! > 200 && currentIndex < allFilterIds.length - 1) {
                        _selectFilterItem(allFilterIds[currentIndex + 1]);
                      } else if (details.primaryVelocity! < -200 && currentIndex > 0) {
                        _selectFilterItem(allFilterIds[currentIndex - 1]);
                      }
                    }
                  },
                  child: allTasksAsync.when(
                    data: (allTasks) {
                      // --- סינון מקומי של המשימות לפי הקבוצה הנוכחית ---
                      final tasks = allTasks.where((t) => t['category_id'] == currentCategory.id).toList();

                      final sortedTasks = List<Map<String, dynamic>>.from(tasks)..sort((a, b) {
                        final dateA = a['next_due_date'] != null ? DateTime.tryParse(a['next_due_date']) : null;
                        final dateB = b['next_due_date'] != null ? DateTime.tryParse(b['next_due_date']) : null;

                        if (dateA == null && dateB == null) return 0;
                        if (dateA == null) return 1;
                        if (dateB == null) return -1;
                        return dateA.compareTo(dateB);
                      });

                      final filteredTasks = _selectedFilterItemId == null
                          ? sortedTasks
                          : sortedTasks.where((t) => t['item_id'] == _selectedFilterItemId).toList();

                      if (filteredTasks.isEmpty) {
                        return const Center(
                          child: Text('אין משימות להצגה בקבוצה זו', style: TextStyle(color: Colors.grey)),
                        );
                      }

                      final agendaGroups = _buildAgendaGroups(filteredTasks);
                      final List<dynamic> flatList = [];
                      for (final group in agendaGroups) {
                        flatList.add(group);
                        flatList.addAll(group.tasks);
                      }

                      return ListView.builder(
                        padding: EdgeInsets.only(bottom: 80 + MediaQuery.paddingOf(context).bottom),
                        itemCount: flatList.length,
                        itemBuilder: (context, index) {
                          final entry = flatList[index];
                          if (entry is CategoryAgendaGroup) {
                            return _buildSectionHeader(entry, theme, isDark);
                          }
                          final taskItem = entry as Map<String, dynamic>;
                          return TaskCard(
                            task: taskItem,
                            isExpanded: _expandedTaskIds.contains(taskItem['id']),
                            onToggleExpand: () {
                              setState(() {
                                if (_expandedTaskIds.contains(taskItem['id'])) {
                                  _expandedTaskIds.remove(taskItem['id']);
                                } else {
                                  _expandedTaskIds.add(taskItem['id']);
                                }
                              });
                            },
                            showCategoryLabel: false,
                            todayStart: todayStart,
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('שגיאה: $err')),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('שגיאה: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedFabMenu(
        currentCategoryId: currentCategory.id,
        currentItemId: _selectedFilterItemId,
      ),
    );
  }
}