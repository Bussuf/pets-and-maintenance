import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/database_provider.dart';
import '../screens/category_screen.dart';
import '../theme/app_icons.dart';

class GlobalSearchBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const GlobalSearchBar({Key? key, this.actions}) : super(key: key);

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
    // 1. סגירת חלונית החיפוש ואיפוס הטקסט
    controller.closeView('');

    // 2. הכנת מסך היעד לפי סוג הרשומה
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
      // משימה (task)
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

    // 3. ניווט מתוך הקונטקסט של המסך הראשי מיד עם סגירת החלונית
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

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: SearchAnchor(
          // חיבור מפורש של הקונטרולר לסגירה אמינה
          searchController: _searchController,
          builder: (context, controller) {
            return SearchBar(
              controller: controller,
              elevation: const WidgetStatePropertyAll(1),
              backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainerHigh),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'תפריט צד',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              hintText: 'חיפוש משימות, פריטים או קבוצות...',
              trailing: widget.actions,
              onTap: () => controller.openView(),
              onChanged: (_) => controller.openView(),
            );
          },
          suggestionsBuilder: (context, controller) async {
            final query = controller.text.trim();
            if (query.isEmpty) {
              return [
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'הקלד כדי לחפש משימות, פריטים או קבוצות...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
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
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text('לא נמצאו תוצאות', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                )
              ];
            }

            final List<Widget> tiles = [];

            // 1. משימות (אייקון task_alt)
            if (tasks.isNotEmpty) {
              tiles.add(
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('משימות', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              );
              for (final task in tasks) {
                tiles.add(
                  ListTile(
                    leading: Icon(Icons.task_alt, color: theme.colorScheme.primary),
                    title: Text(task['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'משימה • ${task['item_name']} • ${task['category_name']}',
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    onTap: () => _navigateToTarget(controller, task),
                  ),
                );
              }
            }

            // 2. פריטים (אייקון inventory_2_outlined)
            if (items.isNotEmpty) {
              tiles.add(
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('פריטים', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              );
              for (final item in items) {
                tiles.add(
                  ListTile(
                    leading: Icon(Icons.inventory_2_outlined, color: theme.colorScheme.secondary),
                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'פריט • שייך לקבוצה: ${item['category_name']}',
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    onTap: () => _navigateToTarget(controller, item),
                  ),
                );
              }
            }

            // 3. קבוצות (סמל וצבע מקוריים)
            if (categories.isNotEmpty) {
              tiles.add(
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('קבוצות', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
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
                    subtitle: const Text('קבוצה ראשית', style: TextStyle(fontSize: 13, color: Colors.grey)),
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