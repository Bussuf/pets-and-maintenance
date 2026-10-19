import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/categories_provider.dart';
import '../screens/category_screen.dart';
import '../theme/app_icons.dart';

class AppDrawer extends ConsumerWidget {
  final String? currentCategoryId;

  const AppDrawer({Key? key, this.currentCategoryId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final isDashboardActive = currentCategoryId == null;

    return Drawer(
      width: 270,
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.pets, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  l10n.appTitle,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                    Navigator.of(context).popUntil((route) => route.isFirst);
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
                        selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        onTap: () {
                          Navigator.pop(context);
                          if (isSelected) return;

                          if (currentCategoryId == null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CategoryScreen(category: cat)),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => CategoryScreen(category: cat)),
                            );
                          }
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