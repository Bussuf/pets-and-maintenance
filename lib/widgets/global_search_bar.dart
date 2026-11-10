import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../theme/app_icons.dart';
import '../screens/settings_screen.dart';
import '../screens/organization_screen.dart';
import '../l10n/app_localizations.dart';

/// הפס העליון (#89): ☰, כותרת דינמית, 🔍 (חיפוש מלא), פעולות נוספות ו-⋮ - הכל בשורה אחת
class GlobalSearchBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final Widget? title; // הכותרת שבאמצע - נבנית במסך (נתיב, סיכום)
  final Color? backgroundColor; // גוון הקבוצה המסומנת
  final List<Widget>? actions; // לפני ה-⋮ (למשל כפתור רצועת השבוע)
  final bool showSettingsMenu;
  final VoidCallback? onAddItem; // אם קיים - מוצג 'הוסף פריט לקבוצה' בתפריט
  final VoidCallback? onEditGroup; // אם קיים - מוצג 'עריכת קבוצה' בתפריט
  final void Function({required String categoryId, String? itemId, String? taskId})? onOpenTarget; // בחירת תוצאת חיפוש
  final Key? menuKey; // מפתח לתפריט ⋮ - בשביל ההדרכה (#26)
  final Key? drawerKey; // מפתח לכפתור התפריט הצדדי - בשביל ההדרכה (#26)

  const GlobalSearchBar({
    super.key,
    this.title,
    this.backgroundColor,
    this.actions,
    this.showSettingsMenu = false,
    this.onAddItem,
    this.onEditGroup,
    this.onOpenTarget,
    this.menuKey,
    this.drawerKey,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  final SearchController _searchController = SearchController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToTarget(SearchController controller, Map<String, dynamic> itemData) {
    controller.closeView('');

    final type = itemData['type'];
    final String categoryId = type == 'category' ? itemData['id'] : itemData['category_id'];
    final String? itemId = type == 'category' ? null : (type == 'item' ? itemData['id'] : itemData['item_id']);
    final String? taskId = type == 'category' || type == 'item' ? null : itemData['id'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onOpenTarget?.call(categoryId: categoryId, itemId: itemId, taskId: taskId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: widget.backgroundColor ?? Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: SearchAnchor(
            searchController: _searchController,
            viewHintText: l10n.searchHint,
            builder: (context, controller) {
              return Row(
                children: [
                  IconButton(
                    key: widget.drawerKey,
                    icon: const Icon(Icons.menu),
                    tooltip: l10n.openMenu,
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  Expanded(child: widget.title ?? const SizedBox.shrink()),
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: l10n.searchHint,
                    onPressed: () => controller.openView(),
                  ),
                  if (widget.actions != null) ...widget.actions!,
                  if (widget.showSettingsMenu)
                    PopupMenuButton<String>(
                      key: widget.menuKey,
                      icon: const Icon(Icons.more_vert),
                      // נפתח מתחת לפס - הכפתור נשאר גלוי ולחיצה נוספת עליו סוגרת
                      position: PopupMenuPosition.under,
                      offset: const Offset(0, 8),
                      tooltip: l10n.settingsTitle,
                      onSelected: (value) {
                        if (value == 'add_item') {
                          widget.onAddItem?.call();
                          return;
                        }
                        if (value == 'edit_group') {
                          widget.onEditGroup?.call();
                          return;
                        }
                        if (value == 'organize') {
                          if (controller.isOpen) controller.closeView('');
                          // נפתח מעל המסך הנוכחי - 'חזור' מחזיר לכאן ולא להגדרות
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OrganizationScreen()),
                          );
                          return;
                        }
                        if (value == 'settings') {
                          // סוגרים את החיפוש אך ורק אם הוא פתוח כרגע
                          if (controller.isOpen) {
                            controller.closeView('');
                          }

                          // ניווט טבעי ובטוח
                          Navigator.push(
                            context, // שימוש בקונטקסט המקומי של הפס המבטיח שמירה על היסטוריית הניווט
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        if (widget.onAddItem != null)
                          PopupMenuItem(
                            value: 'add_item',
                            child: Row(
                              children: [
                                const Icon(Icons.add_box_outlined, size: 20),
                                const SizedBox(width: 12),
                                Flexible(child: Text(AppLocalizations.of(context)!.addItemToGroup)),
                              ],
                            ),
                          ),
                        if (widget.onEditGroup != null)
                          PopupMenuItem(
                            value: 'edit_group',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 20),
                                const SizedBox(width: 12),
                                Flexible(child: Text(l10n.editGroup)),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'organize',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_note, size: 20),
                              const SizedBox(width: 12),
                              Flexible(child: Text(l10n.organizeGroupsItems)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              const Icon(Icons.settings_outlined, size: 20),
                              const SizedBox(width: 12),
                              Flexible(child: Text(l10n.settingsTitle)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
            suggestionsBuilder: (context, controller) async {
              final query = controller.text.trim();
              if (query.isEmpty) {
                return [
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        l10n.searchPrompt,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                ];
              }

              final db = ref.read(databaseProvider);
              final results = await db.searchAll(query);

              final categories = results['categories'] ?? [];
              final items = results['items'] ?? [];
              final tasks = results['tasks'] ?? [];

              if (categories.isEmpty && items.isEmpty && tasks.isEmpty) {
                return [
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(l10n.noResults, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  )
                ];
              }

              final List<Widget> tiles = [];

              if (tasks.isNotEmpty) {
                tiles.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(l10n.tasksHeader, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                );
                for (final task in tasks) {
                  tiles.add(
                    ListTile(
                      leading: Icon(Icons.task_alt, color: theme.colorScheme.primary),
                      title: Text(task['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        l10n.searchTaskSubtitle('${task['item_name']}', '${task['category_name']}'),
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      onTap: () => _navigateToTarget(controller, task),
                    ),
                  );
                }
              }

              if (items.isNotEmpty) {
                tiles.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(l10n.itemsHeader, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                );
                for (final item in items) {
                  tiles.add(
                    ListTile(
                      leading: Icon(Icons.inventory_2_outlined, color: theme.colorScheme.secondary),
                      title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        l10n.searchItemSubtitle('${item['category_name']}'),
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      onTap: () => _navigateToTarget(controller, item),
                    ),
                  );
                }
              }

              if (categories.isNotEmpty) {
                tiles.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(l10n.groupsHeader, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                );
                for (final cat in categories) {
                  final catColor = cat['color'] != null ? Color(cat['color']) : theme.colorScheme.primary;
                  final catIcon = AppIcons.getIcon(cat['icon']);

                  tiles.add(
                    ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: catColor.withValues(alpha: 0.2),
                        child: Icon(catIcon, color: catColor, size: 20),
                      ),
                      title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(l10n.mainGroup, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      onTap: () => _navigateToTarget(controller, cat),
                    ),
                  );
                }
              }

              return tiles;
            },
          ),
        ),
      ),
    );
  }
}
