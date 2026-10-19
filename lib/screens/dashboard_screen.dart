import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'create_entity_screen.dart';
import 'category_screen.dart';
import '../widgets/task_card.dart';
import '../widgets/edit_category_sheet.dart';
import '../l10n/app_localizations.dart';

import 'package:intl/intl.dart' show DateFormat;

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _uuid = const Uuid();
  DateTime? _lastBackPressTime;
  String? _selectedCategoryId;
  final Set<String> _expandedTaskIds = {};

  final Map<String?, GlobalKey> _chipKeys = {};

  void _ensureChipVisible(String? categoryId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _chipKeys[categoryId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          alignment: 0.5,
          // הצ'יפ המסומן נגלל למרכז; בקצוות הגלילה נעצרת והריפוד נשמר
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

  List<AgendaGroup> _buildAgendaGroups(List<Map<String, dynamic>> tasks) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final List<Map<String, dynamic>> overdue = [];
    final List<Map<String, dynamic>> today = [];
    final List<Map<String, dynamic>> tomorrow = [];
    final Map<int, List<Map<String, dynamic>>> upcomingDays = {};
    final List<Map<String, dynamic>> later = [];

    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();

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
      groups.add(
        AgendaGroup(title: l10n.overdueTasks, tasks: overdue, isOverdue: true),
      );
    }
    if (today.isNotEmpty) {
      groups.add(AgendaGroup(title: l10n.today, tasks: today));
    }
    if (tomorrow.isNotEmpty) {
      groups.add(AgendaGroup(title: l10n.tomorrow, tasks: tomorrow));
    }

    final sortedDiffs = upcomingDays.keys.toList()..sort();
    for (final diff in sortedDiffs) {
      final targetDate = todayStart.add(Duration(days: diff));
      final dayName = DateFormat.EEEE(localeTag).format(targetDate);
      groups.add(AgendaGroup(title: dayName, tasks: upcomingDays[diff]!));
    }

    if (later.isNotEmpty) {
      groups.add(AgendaGroup(title: l10n.later, tasks: later));
    }

    return groups;
  }

  void _showCategoryChipMenu(Category cat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_forward),
              title: Text(
                AppLocalizations.of(context)!.goToGroupNamed(cat.name),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryScreen(category: cat),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(AppLocalizations.of(context)!.editGroup),
              onTap: () {
                Navigator.pop(ctx);
                EditCategorySheet.show(context, cat);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(AgendaGroup group, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 16.0,
        bottom: 6.0,
        right: 18.0,
        left: 18.0,
      ),
      child: Row(
        children: [
          if (group.isOverdue) ...[
            const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: Colors.redAccent,
            ),
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final tasksAsync = ref.watch(dashboardTasksProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }

        final now = DateTime.now();
        final isWarningActive =
            _lastBackPressTime != null &&
            now.difference(_lastBackPressTime!) < const Duration(seconds: 2);

        if (isWarningActive) {
          await SystemNavigator.pop();
        } else {
          _lastBackPressTime = now;
          HapticFeedback.lightImpact();

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.pressAgainToExit,
                textAlign: TextAlign.center,
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              width: 200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }
      },

      child: Scaffold(
        key: _scaffoldKey,
        appBar: GlobalSearchBar(
          showSettingsMenu: true,
          // ברירת מחדל: הקבוצה של הצ'יפ המסומן (ללא קבוצה כשמסומן 'הכל')
          onAddItem: () => CreateEntityScreen.show(
            context,
            type: EntityType.item,
            categoryId: _selectedCategoryId,
          ),
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

            final sortedTasks = List<Map<String, dynamic>>.from(tasks)
              ..sort((a, b) {
                final dateA = a['next_due_date'] != null
                    ? DateTime.tryParse(a['next_due_date'])
                    : null;
                final dateB = b['next_due_date'] != null
                    ? DateTime.tryParse(b['next_due_date'])
                    : null;

                if (dateA == null && dateB == null) return 0;
                if (dateA == null) return 1;
                if (dateB == null) return -1;
                return dateA.compareTo(dateB);
              });

            final filteredTasks = _selectedCategoryId == null
                ? sortedTasks
                : sortedTasks
                      .where((t) => t['category_id'] == _selectedCategoryId)
                      .toList();

            final agendaGroups = _buildAgendaGroups(filteredTasks);
            final List<dynamic> flatList = [];
            for (final group in agendaGroups) {
              flatList.add(group);
              flatList.addAll(group.tasks);
            }

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(
                      isDark ? 0.2 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.2,
                        ),
                        child: Icon(
                          Icons.grid_view,
                          color: theme.colorScheme.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.allGroupsAndTasks,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              overdueCount > 0
                                  ? AppLocalizations.of(context)!
                                        .summaryWithOverdue(
                                          tasks.length,
                                          overdueCount,
                                        )
                                  : AppLocalizations.of(context)!
                                        .summaryAllClear(tasks.length),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: overdueCount > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                                color: overdueCount > 0
                                    ? (isDark
                                          ? Colors.redAccent.shade100
                                          : Colors.red.shade800)
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                categoriesAsync.when(
                  data: (cats) {
                    _chipKeys.putIfAbsent(null, () => GlobalKey());

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          FilterChip(
                            key: _chipKeys[null],
                            showCheckmark: false,
                            label: Text(
                              AppLocalizations.of(context)!
                                  .allWithCount(cats.length),
                            ),
                            selected: _selectedCategoryId == null,
                            onSelected: (_) => _selectCategory(null),
                          ),
                          const SizedBox(width: 8),
                          ...cats.map((cat) {
                            final isSelected = _selectedCategoryId == cat.id;
                            final catColor = cat.color != null
                                ? Color(cat.color!)
                                : theme.colorScheme.primary;
                            final catIcon = AppIcons.getIcon(cat.icon);
                            _chipKeys.putIfAbsent(cat.id, () => GlobalKey());

                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: GestureDetector(
                                onLongPress: () => _showCategoryChipMenu(cat),
                                child: InputChip(
                                  key: _chipKeys[cat.id],
                                  avatar: Icon(
                                    catIcon,
                                    size: 18,
                                    color: catColor,
                                  ),
                                  showCheckmark: false,
                                  label: Text(cat.name),
                                  selected: isSelected,
                                  onSelected: (_) => _selectCategory(cat.id),
                                  deleteIcon: isSelected
                                      ? const Icon(Icons.more_vert, size: 16)
                                      : null,
                                  onDeleted: isSelected
                                      ? () => _showCategoryChipMenu(cat)
                                      : null,
                                  deleteButtonTooltipMessage:
                                      AppLocalizations.of(context)!
                                          .groupOptions,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 44,
                    child: Center(child: LinearProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const Divider(height: 1),

                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (details) {
                      if (categories.isEmpty) return;
                      final allCatIds = [null, ...categories.map((c) => c.id)];
                      final currentIndex = allCatIds.indexOf(
                        _selectedCategoryId,
                      );
                      if (currentIndex == -1) return;

                      if (details.primaryVelocity != null) {
                        // ב-RTL החלקה ימינה = הצ'יפ הבא (כמו היום); ב-LTR הכיוון מתהפך
                        final velocity =
                            details.primaryVelocity! *
                            (Directionality.of(context) == TextDirection.rtl
                                ? 1
                                : -1);
                        if (velocity > 200 &&
                            currentIndex < allCatIds.length - 1) {
                          _selectCategory(allCatIds[currentIndex + 1]);
                        } else if (velocity < -200 && currentIndex > 0) {
                          _selectCategory(allCatIds[currentIndex - 1]);
                        }
                      }
                    },
                    child: flatList.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)!.noTasksNow,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              bottom: 80 + MediaQuery.paddingOf(context).bottom,
                            ),
                            itemCount: flatList.length,
                            itemBuilder: (context, index) {
                              final item = flatList[index];
                              if (item is AgendaGroup) {
                                return _buildSectionHeader(item, theme, isDark);
                              }

                              final taskItem = item as Map<String, dynamic>;
                              return TaskCard(
                                task: taskItem,
                                isExpanded: _expandedTaskIds.contains(
                                  taskItem['id'],
                                ),
                                onToggleExpand: () {
                                  setState(() {
                                    if (_expandedTaskIds.contains(
                                      taskItem['id'],
                                    )) {
                                      _expandedTaskIds.remove(taskItem['id']);
                                    } else {
                                      _expandedTaskIds.add(taskItem['id']);
                                    }
                                  });
                                },
                                showCategoryLabel: true,
                                todayStart: todayStart,
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(AppLocalizations.of(context)!.errorWithDetails('$err')),
          ),
        ),
        floatingActionButton: AnimatedFabMenu(
          currentCategoryId: _selectedCategoryId,
        ),
      ),
    );
  }
}
