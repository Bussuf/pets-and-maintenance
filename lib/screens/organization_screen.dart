import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../providers/database_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/items_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../theme/app_icons.dart';
import 'create_entity_screen.dart';
import '../widgets/edit_category_sheet.dart';
import '../widgets/edit_item_sheet.dart';
import '../l10n/app_localizations.dart';

class OrganizationScreen extends ConsumerStatefulWidget {
  final Category? parentCategory;

  const OrganizationScreen({Key? key, this.parentCategory}) : super(key: key);

  @override
  ConsumerState<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends ConsumerState<OrganizationScreen> {
  bool _isReordering = false;
  List<Category> _categories = [];
  List<Item> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);

    if (widget.parentCategory == null) {
      _categories = await db.getCategories();
    } else {
      _items = await db.getItemsByCategory(widget.parentCategory!.id);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveOrder() async {
    final db = ref.read(databaseProvider);
    if (widget.parentCategory == null) {
      final ids = _categories.map((c) => c.id).toList();
      await db.reorderCategories(ids);
      ref.invalidate(categoriesProvider);
    } else {
      final ids = _items.map((i) => i.id).toList();
      await db.reorderItems(ids);
      ref.invalidate(itemsByCategoryProvider(widget.parentCategory!.id));
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      if (widget.parentCategory == null) {
        final item = _categories.removeAt(oldIndex);
        _categories.insert(newIndex, item);
      } else {
        final item = _items.removeAt(oldIndex);
        _items.insert(newIndex, item);
      }
    });
    _saveOrder();
  }

  void _confirmDelete(String id, String title) {
    final l10n = AppLocalizations.of(context)!;
    final warningText = widget.parentCategory == null
        ? l10n.deleteGroupWarning
        : l10n.deleteItemWarning;

    ConfirmDeleteDialog.show(
      context,
      title: l10n.deleteNamed(title),
      content: warningText,
      onConfirm: () async {
        final db = ref.read(databaseProvider);
        if (widget.parentCategory == null) {
          await db.deleteCategory(id);
          ref.invalidate(categoriesProvider);
        } else {
          await db.deleteItem(id);
          ref.invalidate(itemsByCategoryProvider(widget.parentCategory!.id));
          ref.invalidate(tasksByCategoryProvider(widget.parentCategory!.id));
          ref.invalidate(dashboardTasksProvider);
        }
        _loadData();
      },
    );
  }

  void _navigateToEdit({Category? categoryToEdit, Item? itemToEdit}) async {
    if (categoryToEdit != null) {
      await EditCategorySheet.show(context, categoryToEdit);
      _loadData();
    } else if (itemToEdit != null) {
      await EditItemSheet.show(context, itemToEdit, widget.parentCategory!.id);
      _loadData();
    } else {
      // פתיחת טופס ליצירת קבוצה/פריט חדש בלבד (ללא משימה)
      await CreateEntityScreen.show(
        context,
        type: widget.parentCategory == null ? EntityType.category : EntityType.item,
        allowedTypes: const [EntityType.category, EntityType.item],
        categoryId: widget.parentCategory?.id,
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCategoryMode = widget.parentCategory == null;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCategoryMode ? l10n.organizeGroups : l10n.organizeNamed(widget.parentCategory!.name)),
        actions: [
          IconButton(
            icon: Icon(_isReordering ? Icons.check : Icons.reorder),
            tooltip: _isReordering ? l10n.doneReordering : l10n.reorder,
            onPressed: () => setState(() => _isReordering = !_isReordering),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addNew,
            onPressed: () => _navigateToEdit(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isReordering
          ? _buildReorderableList()
          : _buildStandardList(theme),
    );
  }

  Widget _buildStandardList(ThemeData theme) {
    final itemCount = widget.parentCategory == null ? _categories.length : _items.length;
    if (itemCount == 0) {
      return Center(child: Text(AppLocalizations.of(context)!.noData));
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 8 + MediaQuery.paddingOf(context).bottom),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (widget.parentCategory == null) {
          final cat = _categories[index];
          final catColor = cat.color != null ? Color(cat.color!) : theme.colorScheme.primary;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: catColor.withOpacity(0.2),
              child: Icon(AppIcons.getIcon(cat.icon), color: catColor),
            ),
            title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: cat.description != null ? Text(cat.description!, maxLines: 1) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _navigateToEdit(categoryToEdit: cat)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(cat.id, cat.name)),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrganizationScreen(parentCategory: cat)),
              );
            },
            onLongPress: () => setState(() => _isReordering = true),
          );
        } else {
          final item = _items[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: item.description != null ? Text(item.description!, maxLines: 1) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _navigateToEdit(itemToEdit: item)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(item.id, item.name)),
              ],
            ),
            onLongPress: () => setState(() => _isReordering = true),
          );
        }
      },
    );
  }

  Widget _buildReorderableList() {
    final itemCount = widget.parentCategory == null ? _categories.length : _items.length;

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        if (widget.parentCategory == null) {
          final cat = _categories[index];
          return ListTile(
            key: ValueKey(cat.id),
            leading: const Icon(Icons.drag_handle, color: Colors.grey),
            title: Text(cat.name),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          );
        } else {
          final item = _items[index];
          return ListTile(
            key: ValueKey(item.id),
            leading: const Icon(Icons.drag_handle, color: Colors.grey),
            title: Text(item.name),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          );
        }
      },
    );
  }
}