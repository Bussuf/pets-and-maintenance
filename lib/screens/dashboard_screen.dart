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

import '../widgets/agenda.dart';

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

            final agendaGroups = buildAgendaGroups(context, filteredTasks);
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
                              padding: const EdgeInsetsDirectional.only(end: 8.0),
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
                          return AgendaSectionHeader(group: item);
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
