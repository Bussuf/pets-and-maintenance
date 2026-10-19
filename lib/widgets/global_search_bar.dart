import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/database_provider.dart';
import '../screens/category_screen.dart';
import '../theme/app_icons.dart';
import '../screens/settings_screen.dart';
import '../l10n/app_localizations.dart';

class GlobalSearchBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final bool showSettingsMenu;
  final VoidCallback? onAddItem; // אם קיים - מוצג 'הוסף פריט לקבוצה' בתפריט

  const GlobalSearchBar({
    Key? key,
    this.actions,
    this.showSettingsMenu = false,
    this.onAddItem,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(68);

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
    Widget destination;

    if (type == 'category') {
      destination = CategoryScreen(
        category: Category(
          id: itemData['id'],
          name: itemData['name'],
          description: itemData['description'],
          color: itemData['color'],
          icon: itemData['icon'],
          createdAt: DateTime.now(),
        ),
      );
    } else if (type == 'item') {
      destination = CategoryScreen(
        category: Category(
          id: itemData['category_id'],
          name: itemData['category_name'],
          color: itemData['category_color'],
          icon: itemData['category_icon'],
          createdAt: DateTime.now(),
        ),
        initialItemId: itemData['id'],
      );
    } else {
      destination = CategoryScreen(
        category: Category(
          id: itemData['category_id'],
          name: itemData['category_name'],
          color: itemData['category_color'],
          icon: itemData['category_icon'],
          createdAt: DateTime.now(),
        ),
        initialItemId: itemData['item_id'],
        initialTaskId: itemData['id'],
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(this.context).push(
          MaterialPageRoute(builder: (_) => destination),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: SearchAnchor(
          searchController: _searchController,
          builder: (context, controller) {
            return SearchBar(
              controller: controller,
              elevation: const WidgetStatePropertyAll(1),
              backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainerHigh),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                tooltip: l10n.openMenu,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              hintText: l10n.searchHint,
              trailing: [
                if (widget.actions != null) ...widget.actions!,
                if (widget.showSettingsMenu)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: l10n.settingsTitle,
                    onSelected: (value) {
                      if (value == 'add_item') {
                        widget.onAddItem?.call();
                        return;
                      }
                      if (value == 'settings') {
                        // סוגרים את החיפוש אך ורק אם הוא פתוח כרגע
                        if (controller.isOpen) {
                          controller.closeView('');
                        }

                        // ניווט טבעי ובטוח
                        Navigator.push(
                          context, // שימוש בקונטקסט המקומי של ה-SearchBar המבטיח שמירה על היסטוריית הניווט
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
                              Text(AppLocalizations.of(context)!.addItemToGroup),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            const Icon(Icons.settings_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.settingsTitle),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
              onTap: () => controller.openView(),
              onChanged: (_) => controller.openView(),
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
                      backgroundColor: catColor.withOpacity(0.2),
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
    );
  }
}