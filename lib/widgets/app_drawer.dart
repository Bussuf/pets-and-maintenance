import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/categories_provider.dart';
import '../theme/app_icons.dart';
import '../models/task_status.dart';

/// #77: שם ואייקון של כל תצוגה - משותף לסיידבר ולצ'יפים בדף התצוגות
String taskViewLabel(AppLocalizations l10n, TaskView view) => switch (view) {
      TaskView.reminder => l10n.viewReminder,
      TaskView.calendar => l10n.viewCalendar,
      TaskView.endCondition => l10n.viewEndCondition,
      TaskView.daily => l10n.viewDaily,
      TaskView.weekly => l10n.viewWeekly,
      TaskView.monthly => l10n.viewMonthly,
      TaskView.yearly => l10n.viewYearly,
    };

IconData taskViewIcon(TaskView view) => switch (view) {
      TaskView.reminder => Icons.notifications_outlined,
      TaskView.calendar => Icons.event_available,
      TaskView.endCondition => Icons.flag_outlined,
      _ => Icons.repeat,
    };

class AppDrawer extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final isDashboardActive = currentCategoryId == null && currentViews == null;

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
                Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                  leading: Icon(
                    Icons.grid_view,
                    color: isDashboardActive ? theme.colorScheme.primary : null,
                  ),
                  title: Text(l10n.allGroups, style: const TextStyle(fontWeight: FontWeight.bold)),
                  selected: isDashboardActive,
                  focusColor: Colors.transparent,
                  selectedColor: theme.colorScheme.onPrimaryContainer,
                  selectedTileColor: theme.colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  onTap: () {
                    Navigator.pop(context);
                    onSelectCategory(null);
                  },
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Divider(),
                ),

                // #77: תצוגות - כל תצוגה פותחת את דף התצוגות עם הצ'יפ שלה בלבד
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    l10n.viewsTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (final view in TaskView.values)
                  Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      leading: Icon(taskViewIcon(view)),
                      title: Text(taskViewLabel(l10n, view)),
                      selected: currentViews != null && currentViews!.length == 1 && currentViews!.contains(view),
                      focusColor: Colors.transparent,
                      selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      onTap: () {
                        Navigator.pop(context);
                        onSelectView(view);
                      },
                    ),
                  ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Divider(),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    l10n.myGroups,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

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
                      final isSelected = currentCategoryId == cat.id;
                      final catColor = cat.color != null ? Color(cat.color!) : theme.colorScheme.primary;
                      final catIcon = AppIcons.getIcon(cat.icon);

                      return Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                        leading: Icon(catIcon, color: isSelected ? theme.colorScheme.primary : catColor),
                        title: Text(
                          cat.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        focusColor: Colors.transparent,
                        selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        onTap: () {
                          Navigator.pop(context);
                          if (!isSelected) onSelectCategory(cat.id);
                        },
                      ));
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