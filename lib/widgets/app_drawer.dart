import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/categories_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../theme/app_icons.dart';
import '../models/task_status.dart';

/// #77: שם ואייקון של כל תצוגה - משותף לסיידבר ולצ'יפים בדף התצוגות
String taskViewLabel(AppLocalizations l10n, TaskView view) => switch (view) {
      TaskView.reminder => l10n.viewReminder,
      TaskView.calendar => l10n.viewCalendar,
      TaskView.endCondition => l10n.viewEndCondition,
      TaskView.fixedSchedule => l10n.fixedSchedule,
      TaskView.daily => l10n.viewDaily,
      TaskView.weekly => l10n.viewWeekly,
      TaskView.monthly => l10n.viewMonthly,
      TaskView.yearly => l10n.viewYearly,
    };

IconData taskViewIcon(TaskView view) => switch (view) {
      TaskView.reminder => Icons.notifications_outlined,
      TaskView.calendar => Icons.event_available,
      TaskView.endCondition => Icons.flag_outlined,
      TaskView.fixedSchedule => Icons.event_repeat,
      _ => Icons.repeat,
    };

const _frequencyViews = [TaskView.daily, TaskView.weekly, TaskView.monthly, TaskView.yearly];

class AppDrawer extends ConsumerStatefulWidget {
  final String? currentCategoryId;
  final void Function(String? categoryId) onSelectCategory;
  final Set<TaskView>? currentViews; // #77: null = לא בדף התצוגות
  final void Function(TaskView view) onSelectView;

  const AppDrawer({
    super.key,
    this.currentCategoryId,
    required this.onSelectCategory,
    this.currentViews,
    required this.onSelectView,
  });

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  // "לפי תדירות" פתוח מראש אם התצוגה הנוכחית היא תדירות
  late bool _frequencyOpen = widget.currentViews?.any(_frequencyViews.contains) ?? false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final views = widget.currentViews;
    final isDashboardActive = widget.currentCategoryId == null && views == null;

    // #77: מספר המשימות הפעילות ליד כל שורה (משימות שהסתיימו לא נספרות - כמו בכותרת)
    final active = (ref.watch(dashboardTasksProvider).valueOrNull ?? const <Map<String, dynamic>>[])
        .where((t) => !isTaskFinished(t))
        .toList();
    int countView(TaskView v) => active.where((t) => matchesViews(t, {v})).length;
    int countCategory(String id) => active.where((t) => t['category_id'] == id).length;
    bool isOnlyView(TaskView v) => views != null && views.length == 1 && views.contains(v);

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

    // שורה בסיידבר. המספר בתיבה ברוחב קבוע בצד השמאלי - כל המספרים על קו אנכי אחד,
    // גם בתתי-השורות של האקורדיון (ההזחה רק בצד ההתחלה)
    Widget row({
      Widget? leading,
      required Widget title,
      required int count,
      required bool selected,
      required VoidCallback onTap,
      bool indent = false,
      Color? selectedTileColor,
    }) =>
        Material(
          type: MaterialType.transparency,
          child: ListTile(
            leading: leading,
            title: title,
            contentPadding: EdgeInsetsDirectional.only(start: indent ? 56 : 16, end: 16),
            trailing: SizedBox(
              width: 28,
              child: Text(
                '$count',
                textAlign: TextAlign.left,
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            selected: selected,
            focusColor: Colors.transparent,
            selectedTileColor: selectedTileColor ?? theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            onTap: onTap,
          ),
        );

    void pick(VoidCallback action) {
      Navigator.pop(context);
      action();
    }

    return Drawer(
      width: 270,
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.pets, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                // שורה אחת שמתכווצת אם צריך - לכותרת הסיידבר יש גובה קבוע
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.appTitle,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.paddingOf(context).bottom),
              children: [
                // יעד ראשי: כל הקבוצות (אייקון מלא)
                // Material שקוף - כדי שצבע הבחירה ייצבע על הפריט ויזוז עם הגלילה
                row(
                  leading: Icon(Icons.grid_view, color: isDashboardActive ? theme.colorScheme.primary : null),
                  title: Text(l10n.allGroups, style: const TextStyle(fontWeight: FontWeight.bold)),
                  count: active.length,
                  selected: isDashboardActive,
                  selectedTileColor: theme.colorScheme.primaryContainer,
                  onTap: () => pick(() => widget.onSelectCategory(null)),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Divider(),
                ),

                // #77: משימות לפי סוג - כל שורה פותחת את דף התצוגות עם הצ'יפ שלה בלבד
                sectionTitle(l10n.drawerTasksSection),
                for (final view in const [
                  TaskView.reminder,
                  TaskView.calendar,
                  TaskView.endCondition,
                  TaskView.fixedSchedule,
                ])
                  row(
                    leading: Icon(taskViewIcon(view)),
                    title: Text(taskViewLabel(l10n, view)),
                    count: countView(view),
                    selected: isOnlyView(view),
                    onTap: () => pick(() => widget.onSelectView(view)),
                  ),
                // "לפי תדירות" - אקורדיון עם 4 תתי-שורות; המספר שלו = סך כל המשימות הפעילות
                row(
                  leading: const Icon(Icons.repeat),
                  title: Row(
                    children: [
                      Flexible(child: Text(l10n.viewByFrequency)),
                      const SizedBox(width: 4),
                      Icon(_frequencyOpen ? Icons.expand_less : Icons.expand_more, size: 18),
                    ],
                  ),
                  count: active.length,
                  selected: false,
                  onTap: () => setState(() => _frequencyOpen = !_frequencyOpen),
                ),
                if (_frequencyOpen)
                  for (final view in _frequencyViews)
                    row(
                      indent: true,
                      title: Text(taskViewLabel(l10n, view)),
                      count: countView(view),
                      selected: isOnlyView(view),
                      onTap: () => pick(() => widget.onSelectView(view)),
                    ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Divider(),
                ),

                sectionTitle(l10n.myGroups),

                ...categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) {
                      return [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(l10n.noGroupsYet, style: const TextStyle(color: Colors.grey)),
                        )
                      ];
                    }
                    return categories.map((cat) {
                      final isSelected = widget.currentCategoryId == cat.id;
                      final catColor = cat.color != null ? Color(cat.color!) : theme.colorScheme.primary;
                      return row(
                        leading: Icon(AppIcons.getIcon(cat.icon), color: isSelected ? theme.colorScheme.primary : catColor),
                        title: Text(
                          cat.name,
                          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        ),
                        count: countCategory(cat.id),
                        selected: isSelected,
                        onTap: () => pick(() {
                          if (!isSelected) widget.onSelectCategory(cat.id);
                        }),
                      );
                    }).toList();
                  },
                  loading: () => [const Center(child: CircularProgressIndicator())],
                  error: (err, _) => [Text(l10n.errorWithDetails('$err'))],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
