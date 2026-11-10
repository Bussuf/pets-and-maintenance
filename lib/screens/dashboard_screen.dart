import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/task_log.dart';
import '../providers/categories_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../providers/items_provider.dart';
import '../theme/app_icons.dart';
import '../widgets/animated_fab_menu.dart';
import '../widgets/app_drawer.dart';
import '../widgets/global_search_bar.dart';
import 'create_entity_screen.dart';
import '../widgets/task_card.dart';
import '../widgets/edit_category_sheet.dart';
import '../widgets/edit_item_sheet.dart';
import '../l10n/app_localizations.dart';
import '../widgets/agenda.dart';
import '../widgets/month_calendar.dart';
import '../models/task_status.dart';
import '../onboarding/onboarding.dart';
import '../onboarding/onboarding_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastBackPressTime;
  String? _selectedCategoryId;
  String? _selectedItemId; // צ'יפ פריט, כשמסומנת קבוצה (#88)
  bool _weekOpen = false; // מיקוד יום (#83) - תמיד מתחילים ביומן
  DateTime _focusDay = DateTime.now(); // היום הנבחר ברצועה; מתאפס להיום בכל פתיחה
  final Set<String> _expandedTaskIds = {};

  final Map<String?, GlobalKey> _itemChipKeys = {};

  @override
  void initState() {
    super.initState();
    // הדרכה התחילה/הסתיימה - בנייה מחדש, כדי שהכרטיס של משימת הדוגמה יקבל (או יאבד) את המפתחות שלו
    Onboarding.changes.addListener(_onOnboardingChanged);
    Onboarding.beforeStart = _resetForOnboarding;
    // התקנה חדשה (#26): מסך "שלום" - אחרי שהמשימות נטענו (וגם המסד נוצר)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(dashboardTasksProvider.future);
      if (!mounted) return;
      await Onboarding.maybeWelcome(context);
    });
  }

  void _onOnboardingChanged() {
    if (mounted) setState(() {});
  }

  /// לפני הדרכה: חוזרים ליומן ול"הכל", סוגרים כרטיסים פתוחים ופותחים את כל הסעיפים (הכותרת והכרטיס צריכים להיראות)
  void _resetForOnboarding() {
    if (!mounted) return;
    setState(() {
      _expandedTaskIds.clear();
      _weekOpen = false;
    });
    _selectCategory(null);
    ref.read(agendaCollapseProvider(agendaAllScope).notifier).expandAll();
  }

  @override
  void dispose() {
    Onboarding.changes.removeListener(_onOnboardingChanged);
    if (Onboarding.beforeStart == _resetForOnboarding) Onboarding.beforeStart = null;
    super.dispose();
  }

  void _ensureChipVisible(String? itemId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemChipKeys[itemId];
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
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedItemId = null;
    });
  }

  void _selectItem(String? itemId) {
    setState(() => _selectedItemId = itemId);
    _ensureChipVisible(itemId);
  }

  /// לחיצה על צ'יפ פריט: בחירה, ואם הוא כבר מסומן - קיפול/פתיחה של הסעיפים המוצגים (#87)
  void _onItemChipTap(String? itemId, List<AgendaKind> shown) {
    if (itemId != _selectedItemId) {
      _selectItem(itemId);
      return;
    }
    ref.read(agendaCollapseProvider(_collapseScope).notifier).toggleAll(shown);
  }

  /// המשימות של הצ'יפ המסומן: הכל, קבוצה, או פריט בתוכה
  List<Map<String, dynamic>> _inScope(List<Map<String, dynamic>> tasks) {
    if (_selectedCategoryId == null) return tasks;
    return tasks
        .where((t) =>
            t['category_id'] == _selectedCategoryId &&
            (_selectedItemId == null || t['item_id'] == _selectedItemId))
        .toList();
  }

  /// הכותרת המוגדלת (#90): אייקון, שם מלא, תיאור, סיכום ונקודות מיקום בין הקבוצות.
  /// החלקה עליה עוברת בין הקבוצות; ^ מקפל/פותח את כל הסעיפים המוצגים; לחיצה ארוכה בקבוצה - עריכה
  Widget _buildHeader({
    required List<Category> categories,
    required Category? category,
    required String? itemName,
    required int activeCount,
    required int overdueCount,
    required Color accent,
    required Color background,
    required List<AgendaKind> shown,
    required bool allCollapsed,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final title = category == null
        ? l10n.allGroupsAndTasks
        : (itemName == null ? category.name : '${category.name} › $itemName');
    final description = category?.description;
    final positions = <String?>[null, ...categories.map((c) => c.id)];

    return GestureDetector(
      key: Onboarding.key(OnboardingTarget.groupChips),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) => _onHeaderSwipe(details, positions),
      onLongPress: category == null ? null : () => EditCategorySheet.show(context, category),
      child: Container(
        width: double.infinity,
        color: background,
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: accent.withValues(alpha: 0.2),
                  child: Icon(
                    category == null ? Icons.grid_view : AppIcons.getIcon(category.icon),
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 21,
                          height: 1.25,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : accent,
                        ),
                      ),
                      if (description?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        overdueCount > 0
                            ? l10n.summaryWithOverdue(activeCount, overdueCount)
                            : l10n.summaryAllClear(activeCount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: overdueCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          color: overdueCount > 0
                              ? (isDark ? Colors.redAccent.shade100 : Colors.red.shade800)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (shown.isNotEmpty)
                  IconButton(
                    tooltip: allCollapsed ? l10n.sectionsExpandAll : l10n.sectionsCollapseAll,
                    style: IconButton.styleFrom(backgroundColor: scheme.onSurface.withValues(alpha: 0.08)),
                    onPressed: () => ref.read(agendaCollapseProvider(_collapseScope).notifier).toggleAll(shown),
                    // ^ יש מה לקפל, v הכל מקופל
                    icon: AnimatedRotation(
                      turns: allCollapsed ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_less),
                    ),
                  ),
              ],
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              // נקודות מיקום: כמה קבוצות יש, ואיפה אנחנו. אפשר גם ללחוץ עליהן
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final id in positions)
                    GestureDetector(
                      onTap: () => _selectCategory(id),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: id == _selectedCategoryId ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: id == _selectedCategoryId ? 0.9 : 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// כיוון החלקה: 1 = הבא, 1- = הקודם, 0 = לא החלקה. ב-RTL החלקה ימינה = הבא; ב-LTR הכיוון מתהפך
  int _swipeDelta(DragEndDetails details) {
    final velocity = details.primaryVelocity;
    if (velocity == null || velocity.abs() < 200) return 0;
    return (velocity > 0) == (Directionality.of(context) == TextDirection.rtl) ? 1 : -1;
  }

  /// החלקה על הכותרת (#90): הקבוצה הבאה, בקרוסלה ("הכל" ← הקבוצות ← "הכל")
  void _onHeaderSwipe(DragEndDetails details, List<String?> positions) {
    final delta = _swipeDelta(details);
    final index = positions.indexOf(_selectedCategoryId);
    if (delta == 0 || positions.length < 2 || index == -1) return;
    _selectCategory(positions[wrapIndex(index + delta, positions.length)]);
  }

  /// החלקה על הרשימה (#90): רק בין הפריטים של הקבוצה, בקרוסלה.
  /// ב"הכל" אין שורת צ'יפים - קבוצות מחליפים בכותרת, כדי שאי אפשר "להיתקע" בתוך קבוצה
  void _onListSwipe(DragEndDetails details, List<Item>? items) {
    final delta = _swipeDelta(details);
    if (delta == 0 || _selectedCategoryId == null) return;
    final ids = <String?>[null, ...?items?.map((i) => i.id)];
    final index = ids.indexOf(_selectedItemId);
    if (ids.length < 2 || index == -1) return;
    _selectItem(ids[wrapIndex(index + delta, ids.length)]);
  }

  /// הצ'יפ שזיכרון הקיפול שלו חל עכשיו (#88): הפריט, הקבוצה, או "הכל"
  String get _collapseScope => _selectedItemId ?? _selectedCategoryId ?? agendaAllScope;

  /// תוצאת חיפוש: מסמנים את הקבוצה והפריט, ופותחים את המשימה ואת הסעיף שלה ביומן
  void _openSearchTarget({required String categoryId, String? itemId, String? taskId}) {
    setState(() {
      _weekOpen = false;
      if (taskId != null) _expandedTaskIds.add(taskId);
    });
    _selectCategory(categoryId);
    if (itemId != null) _selectItem(itemId);
    if (taskId == null) return;
    final tasks = ref.read(dashboardTasksProvider).valueOrNull ?? const <Map<String, dynamic>>[];
    final task = tasks.where((t) => t['id'] == taskId).firstOrNull;
    if (task == null) return;
    ref.read(agendaCollapseProvider(itemId ?? categoryId).notifier).expand(buildAgendaGroups(context, [task]).first.kind);
  }

  /// שורת צ'יפי הפריטים של הקבוצה המסומנת
  Widget _buildItemChips(List<Item> items, String categoryId, List<AgendaKind> shown) {
    _itemChipKeys.putIfAbsent(null, () => GlobalKey());
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          FilterChip(
            key: _itemChipKeys[null],
            showCheckmark: false,
            label: Text(l10n.allWithCount(items.length)),
            selected: _selectedItemId == null,
            onSelected: (_) => _onItemChipTap(null, shown),
          ),
          const SizedBox(width: 8),
          ...items.map((item) {
            final isSelected = _selectedItemId == item.id;
            _itemChipKeys.putIfAbsent(item.id, () => GlobalKey());

            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8.0),
              child: GestureDetector(
                onLongPress: () => EditItemSheet.show(context, item, categoryId),
                child: InputChip(
                  key: _itemChipKeys[item.id],
                  showCheckmark: false,
                  label: Text(item.name),
                  selected: isSelected,
                  onSelected: (_) => _onItemChipTap(item.id, shown),
                  deleteIcon: isSelected ? const Icon(Icons.more_vert, size: 16) : null,
                  onDeleted: isSelected ? () => EditItemSheet.show(context, item, categoryId) : null,
                  deleteButtonTooltipMessage: l10n.editItem,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
              ),
            );
          }),
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
    final collapsedKinds = ref.watch(agendaCollapseProvider(_collapseScope));
    final selectedCategory = (categoriesAsync.valueOrNull ?? const <Category>[])
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;
    final itemsAsync = selectedCategory != null ? ref.watch(itemsByCategoryProvider(selectedCategory.id)) : null;
    final selectedItemName =
        itemsAsync?.valueOrNull?.where((i) => i.id == _selectedItemId).firstOrNull?.name;
    final calendarAccent = selectedCategory?.color != null
        ? Color(selectedCategory!.color!)
        : theme.colorScheme.primary;
    // הפס העליון והכותרת שמתחתיו באותו גוון - נראים כמשטח אחד
    final headerColor = calendarAccent.withValues(alpha: isDark ? 0.18 : 0.08);

    // הסיכום בכותרת - על מה שמוצג עכשיו (הכל / קבוצה / פריט)
    final nowTime = DateTime.now();
    final today = DateTime(nowTime.year, nowTime.month, nowTime.day);
    final allTasks = tasksAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final scopedTasks = _inScope(allTasks);
    // משימות שהסתיימו לא נספרות כפעילות (#51)
    final activeCount = scopedTasks.where((t) => !isTaskFinished(t)).length;
    final overdueCount = scopedTasks.where((t) {
      final due = t['next_due_date'] != null ? DateTime.tryParse(t['next_due_date']) : null;
      return due != null && due.isBefore(today);
    }).length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }

        // רמה אחת למעלה בכל פעם: פריט ← קבוצה ← "הכל" (#89)
        if (_selectedItemId != null) {
          _selectItem(null);
          return;
        }
        if (_selectedCategoryId != null) {
          _selectCategory(null);
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
          backgroundColor: headerColor,
          actions: [
            // רצועת השבוע (#89) - כפתור גלוי במקום לחיצה על כרטיס הכותרת
            IconButton(
              tooltip: AppLocalizations.of(context)!.switchView,
              isSelected: _weekOpen,
              icon: const Icon(Icons.view_week_outlined),
              selectedIcon: Icon(Icons.view_week, color: calendarAccent),
              onPressed: allTasks.isEmpty
                  ? null
                  : () => setState(() {
                        _weekOpen = !_weekOpen;
                        _focusDay = today;
                      }),
            ),
          ],
          showSettingsMenu: true,
          menuKey: Onboarding.key(OnboardingTarget.menu),
          drawerKey: Onboarding.key(OnboardingTarget.drawer),
          // ברירת מחדל: הקבוצה של הצ'יפ המסומן (ללא קבוצה כשמסומן 'הכל')
          onAddItem: () => CreateEntityScreen.show(
            context,
            type: EntityType.item,
            categoryId: _selectedCategoryId,
          ),
          onEditGroup: selectedCategory == null ? null : () => EditCategorySheet.show(context, selectedCategory),
          onOpenTarget: _openSearchTarget,
        ),
        drawer: AppDrawer(currentCategoryId: _selectedCategoryId, onSelectCategory: _selectCategory),
        body: tasksAsync.when(
          data: (tasks) {
            final categories = categoriesAsync.value ?? [];

            // #67: הקבוצה המסומנת נמחקה (מכל מסלול) - חוזרים ל'הכל'.
            // רק אחרי שהרשימה סיימה להיטען, כדי לא לאפס בטעות קבוצה חדשה
            if (_selectedCategoryId != null &&
                !categoriesAsync.isLoading &&
                !categories.any((c) => c.id == _selectedCategoryId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _selectCategory(null);
              });
            }

            // אותו דבר לפריט המסומן: נמחק או הועבר לקבוצה אחרת - חוזרים ל'הכל' של הקבוצה
            if (_selectedItemId != null &&
                itemsAsync != null &&
                itemsAsync.hasValue &&
                !itemsAsync.isLoading &&
                !itemsAsync.value!.any((i) => i.id == _selectedItemId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _selectItem(null);
              });
            }
            final todayStart = today;

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

            final filteredTasks = _inScope(sortedTasks);

            // במסד ריק נשארים ביומן - שם ההסבר והקישור למדריך (#26)
            final showWeek = _weekOpen && tasks.isNotEmpty;

            // רשימה אחת (#90): הרצועה רק מסננת את היומן ליום הנבחר - אותם סעיפים ואותו זיכרון קיפול
            final weekFrom = weekPageStart(_focusDay, todayStart);
            final weekLogs = showWeek
                ? ref.watch(weekLogsProvider(weekFrom)).valueOrNull ?? const <TaskLog>[]
                : const <TaskLog>[];
            final weekMarks = showWeek
                ? buildWeekMarks(from: weekFrom, tasks: filteredTasks, logs: weekLogs, now: DateTime.now())
                : const <DateTime, List<CalendarMark>>{};
            final agendaGroups = showWeek
                ? buildDayGroups(context, _focusDay, weekMarks[_focusDay] ?? const [], todayStart)
                : buildAgendaGroups(context, filteredTasks);
            final flatList = flattenAgenda(agendaGroups, collapsedKinds);

            // הסעיפים שמוצגים עכשיו - על אלה פועלת לחיצה חוזרת על הצ'יפ, ומהם נקבע החץ שלו
            final shownKinds = agendaGroups.map((g) => g.kind).toList();
            final allCollapsed = allSectionsCollapsed(collapsedKinds, shownKinds);

            Widget buildTaskCard(Map<String, dynamic> taskItem) => TaskCard(
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
              showCategoryLabel: _selectedCategoryId == null,
              todayStart: todayStart,
            );

            return Column(
              children: [
                _buildHeader(
                  categories: categories,
                  category: selectedCategory,
                  itemName: selectedItemName,
                  activeCount: activeCount,
                  overdueCount: overdueCount,
                  accent: calendarAccent,
                  background: headerColor,
                  shown: shownKinds,
                  allCollapsed: allCollapsed,
                ),
                // צ'יפים רק לפריטים בתוך קבוצה (#90); קבוצות מחליפים בהחלקה על הכותרת או מהתפריט הצדדי
                if (selectedCategory != null)
                  _buildItemChips(itemsAsync?.valueOrNull ?? const <Item>[], selectedCategory.id, shownKinds),
                const Divider(height: 1),

                // הזמנה להדרכה עם נתוני דוגמה (#26) - רק כשאין עדיין נתונים של המשתמש
                const OnboardingStartCard(),

                if (showWeek)
                  WeekStrip(
                    selected: _focusDay,
                    marks: weekMarks,
                    accent: calendarAccent,
                    onSelectDay: (day) => setState(() => _focusDay = day),
                  ),

                Expanded(
                  // החלקה על הרשימה (#89) - גם כשהרצועה פתוחה; על הרצועה עצמה היא מזיזה יום
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (details) =>
                        _onListSwipe(details, itemsAsync?.valueOrNull),
                    child: flatList.isEmpty
                    // אין במסד כלום (#26) - הסבר + קישור למדריך. אחרת (למשל קבוצה מסוננת בלי משימות) - הטקסט הרגיל
                        ? (tasks.isEmpty && categories.isEmpty
                        ? const OnboardingEmptyState()
                        : Center(
                      child: Text(
                        showWeek
                            ? AppLocalizations.of(context)!.calEmptyDay
                            : _selectedCategoryId != null
                            ? AppLocalizations.of(context)!.noTasksInGroup
                            : AppLocalizations.of(context)!.noTasksNow,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ))
                        : ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: 80 + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: flatList.length,
                      itemBuilder: (context, index) {
                        final item = flatList[index];
                        if (item is AgendaDoneEntry) return CompletedTaskRow(task: item.task);
                        if (item is AgendaGroup) {
                          return AgendaSectionHeader(
                            // הדרכה (#26): הכותרת של הקבוצה שבה משימת הדוגמה ("היום")
                            key: item.tasks.any((t) => t['id'] == Onboarding.taskId)
                                ? Onboarding.keyFor(OnboardingTarget.todayHeader, Onboarding.taskId)
                                : null,
                            scope: _collapseScope,
                            group: item,
                          );
                        }

                        return buildTaskCard(item as Map<String, dynamic>);
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
          key: Onboarding.key(OnboardingTarget.fab),
          currentCategoryId: _selectedCategoryId,
          currentItemId: _selectedItemId,
        ),
      ),
    );
  }
}
