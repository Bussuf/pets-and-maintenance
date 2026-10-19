import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/task.dart';
import '../providers/database_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/items_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../theme/app_icons.dart';
import '../services/notification_service.dart';
import '../providers/google_auth_provider.dart';
import '../services/google_calendar_service.dart';

enum EntityType { task, item, category }

class CreateEntityScreen extends ConsumerStatefulWidget {
  final EntityType initialType;
  final List<EntityType> allowedTypes;
  final String? preselectedCategoryId;
  final String? preselectedItemId;
  final Map<String, dynamic>? initialDuplicateData;

  const CreateEntityScreen({
    Key? key,
    this.initialType = EntityType.task,
    this.allowedTypes = const [EntityType.task, EntityType.item, EntityType.category],
    this.preselectedCategoryId,
    this.preselectedItemId,
    this.initialDuplicateData,
  }) : super(key: key);

  static Future<void> show(
      BuildContext context, {
        EntityType type = EntityType.task,
        List<EntityType> allowedTypes = const [EntityType.task, EntityType.item, EntityType.category],
        String? categoryId,
        String? itemId,
        Map<String, dynamic>? duplicateData,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CreateEntityScreen(
        initialType: type,
        allowedTypes: allowedTypes,
        preselectedCategoryId: categoryId,
        preselectedItemId: itemId,
        initialDuplicateData: duplicateData,
      ),
    );
  }

  @override
  ConsumerState<CreateEntityScreen> createState() => _CreateEntityScreenState();
}

class _CreateEntityScreenState extends ConsumerState<CreateEntityScreen> {
  late EntityType _currentType;
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _intervalAmountController;
  late final TextEditingController _endConditionCountController;

  String? _selectedCategoryId;
  String? _selectedItemId;
  String _selectedIntervalUnit = 'days';

  int? _selectedColor;
  String? _selectedIcon;

  String _endCondition = 'always';
  DateTime? _endConditionDate;
  bool _isReminderEnabled = false;
  bool _isGoogleSyncEnabled = false;

  final List<Color> _availableColors = [
    Colors.blue, Colors.indigo, Colors.teal, Colors.green, Colors.orange, Colors.deepOrange, Colors.red, Colors.purple, Colors.pink, Colors.brown, Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _currentType = widget.allowedTypes.contains(widget.initialType) ? widget.initialType : widget.allowedTypes.first;
    _selectedCategoryId = widget.preselectedCategoryId;
    _selectedItemId = widget.preselectedItemId;

    final dup = widget.initialDuplicateData;
    _nameController = TextEditingController(text: dup?['name'] ?? '');
    _descController = TextEditingController(text: dup?['description'] ?? '');
    _intervalAmountController = TextEditingController(text: dup != null ? '${dup['interval_amount'] ?? 7}' : '7');
    _endConditionCountController = TextEditingController(
      text: (dup != null && dup['end_condition'] == 'count') ? (dup['end_condition_value'] ?? '') : '',
    );

    if (dup != null) {
      _selectedIntervalUnit = dup['interval_unit'] ?? 'days';
      _endCondition = dup['end_condition'] ?? 'always';
      if (_endCondition == 'until_date' && dup['end_condition_value'] != null) {
        _endConditionDate = DateTime.tryParse(dup['end_condition_value']);
      }
      _isReminderEnabled = (dup['is_reminder_enabled'] == 1);
      _isGoogleSyncEnabled = (dup['google_event_id'] != null);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _intervalAmountController.dispose();
    _endConditionCountController.dispose();
    super.dispose();
  }

  void _openIconPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.65, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              const Text('בחר סמל לקבוצה (מלאים וקוויים)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  controller: scrollController, padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: AppIcons.catalog.length,
                  itemBuilder: (_, index) {
                    final key = AppIcons.catalog.keys.elementAt(index);
                    final icon = AppIcons.catalog.values.elementAt(index);
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _selectedIcon = key);
                        Navigator.pop(ctx);
                      },
                      child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 28)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showQuickAddCategory(AppLocalizations l10n) async {
    final quickNameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addCategoryTitleHint),
        content: TextField(controller: quickNameController, decoration: InputDecoration(hintText: l10n.name), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () async {
              if (quickNameController.text.trim().isNotEmpty) {
                final newCat = Category(id: _uuid.v4(), name: quickNameController.text.trim(), createdAt: DateTime.now());
                await ref.read(databaseProvider).createCategory(newCat);
                ref.invalidate(categoriesProvider);
                setState(() => _selectedCategoryId = newCat.id);
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickAddItem(AppLocalizations l10n) async {
    if (_selectedCategoryId == null) return;
    final quickNameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addItemTitleHint),
        content: TextField(controller: quickNameController, decoration: InputDecoration(hintText: l10n.name), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () async {
              if (quickNameController.text.trim().isNotEmpty) {
                final newItem = Item(id: _uuid.v4(), categoryId: _selectedCategoryId!, name: quickNameController.text.trim());
                await ref.read(databaseProvider).createItem(newItem);
                ref.invalidate(itemsByCategoryProvider(_selectedCategoryId!));
                setState(() => _selectedItemId = newItem.id);
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime(2035));
    if (picked != null) setState(() => _endConditionDate = picked);
  }

  DateTime _calculateInitialDueDate(int amount, String unit) {
    return AppTask.addInterval(DateTime.now(), amount, unit);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final db = ref.read(databaseProvider);
      final entityName = _nameController.text.trim();
      String repositoryName = '';

      if (_currentType == EntityType.category) {
        repositoryName = l10n.myGroups;
        final category = Category(
          id: _uuid.v4(), name: entityName, description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          createdAt: DateTime.now(), color: _selectedColor, icon: _selectedIcon,
        );
        await ref.read(categoriesProvider.notifier).addCategory(category);
      }
      else if (_currentType == EntityType.item) {
        if (_selectedCategoryId == null) return;
        final cats = ref.read(categoriesProvider).value ?? [];
        final parentCat = cats.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => Category(id: '', name: 'קבוצה', createdAt: DateTime.now()));
        repositoryName = parentCat.name;

        final item = Item(
          id: _uuid.v4(), categoryId: _selectedCategoryId!, name: entityName, description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        );
        await db.createItem(item);
        ref.invalidate(itemsByCategoryProvider(_selectedCategoryId!));
      }
      else if (_currentType == EntityType.task) {
        if (_selectedItemId == null) return;
        final items = ref.read(itemsByCategoryProvider(_selectedCategoryId!)).value ?? [];
        final parentItem = items.firstWhere((i) => i.id == _selectedItemId, orElse: () => Item(id: '', categoryId: '', name: 'פריט'));
        repositoryName = parentItem.name;

        final amount = int.tryParse(_intervalAmountController.text) ?? 7;
        final initialDueDate = _calculateInitialDueDate(amount, _selectedIntervalUnit);

        String? endVal;
        if (_endCondition == 'count') endVal = _endConditionCountController.text.trim();
        else if (_endCondition == 'until_date' && _endConditionDate != null) endVal = _endConditionDate!.toIso8601String();

        AppTask task = AppTask(
          id: _uuid.v4(), itemId: _selectedItemId!, name: entityName, description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          intervalAmount: amount, intervalUnit: _selectedIntervalUnit, endCondition: _endCondition, endConditionValue: endVal,
          nextDueDate: initialDueDate, isReminderEnabled: _isReminderEnabled, reminderTime: _isReminderEnabled ? '09:00' : null,
        );

        // -- יצירת סנכרון ליומן גוגל במידה ואושר --
        if (_isGoogleSyncEnabled && ref.read(googleAuthProvider) != null) {
          final googleEventId = await GoogleCalendarService.instance.createEvent(task, 'קבוצה: $repositoryName');
          if (googleEventId != null) {
            task = task.copyWith(googleEventId: googleEventId);
          }
        }

        await db.createTask(task);
        await NotificationService.instance.scheduleTaskReminder(task);

        ref.invalidate(dashboardTasksProvider);
        ref.invalidate(tasksByCategoryProvider(_selectedCategoryId!));
      }

      if (mounted) Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.savedSuccessfully(entityName, repositoryName), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFF2E2F33), duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('שגיאה בשמירה: $e'), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final googleUser = ref.watch(googleAuthProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: media.viewInsets.bottom + 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('יצירת חדש', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),

                // --- הצגת צ'יפים של סוגי ישויות באופן דינמי ---
                if (widget.allowedTypes.length > 1) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.allowedTypes.map((type) {
                        String label = '';
                        if (type == EntityType.task) label = l10n.task;
                        if (type == EntityType.item) label = l10n.item;
                        if (type == EntityType.category) label = l10n.category;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _buildTypeChip(label, type),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _currentType == EntityType.category ? l10n.addCategoryTitleHint : _currentType == EntityType.item ? l10n.addItemTitleHint : l10n.addTaskTitleHint,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? l10n.requiredField : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.description, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                if (_currentType == EntityType.item || _currentType == EntityType.task) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: categoriesAsync.when(
                                data: (cats) {
                                  final displayCats = cats.toList();
                                  if (_selectedCategoryId != null && !displayCats.any((c) => c.id == _selectedCategoryId)) {
                                    displayCats.add(Category(id: _selectedCategoryId!, name: '...', createdAt: DateTime.now()));
                                  }
                                  return DropdownButtonFormField<String>(
                                    value: _selectedCategoryId,
                                    decoration: InputDecoration(labelText: l10n.selectCategory, border: const OutlineInputBorder(), isDense: true),
                                    items: displayCats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                    onChanged: (val) => setState(() { _selectedCategoryId = val; _selectedItemId = null; }),
                                    validator: (val) => val == null ? l10n.requiredField : null,
                                  );
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (err, _) => Text('שגיאה: $err'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(icon: const Icon(Icons.add), onPressed: () => _showQuickAddCategory(l10n), tooltip: l10n.addQuick)
                          ],
                        ),
                        if (_currentType == EntityType.task) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ref.watch(itemsByCategoryProvider(_selectedCategoryId ?? '')).when(
                                  data: (items) {
                                    final displayItems = items.toList();
                                    if (_selectedItemId != null && !displayItems.any((i) => i.id == _selectedItemId)) {
                                      displayItems.add(Item(id: _selectedItemId!, categoryId: _selectedCategoryId!, name: '...'));
                                    }
                                    return DropdownButtonFormField<String>(
                                      value: _selectedItemId,
                                      decoration: InputDecoration(labelText: l10n.selectItem, border: const OutlineInputBorder(), isDense: true),
                                      items: displayItems.map((i) => DropdownMenuItem(value: i.id, child: Text(i.name))).toList(),
                                      onChanged: (val) => setState(() => _selectedItemId = val),
                                      validator: (val) => val == null ? l10n.requiredField : null,
                                    );
                                  },
                                  loading: () => const LinearProgressIndicator(),
                                  error: (err, _) => Text('שגיאה: $err'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(icon: const Icon(Icons.add), onPressed: _selectedCategoryId == null ? null : () => _showQuickAddItem(l10n), tooltip: l10n.addQuick)
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_currentType == EntityType.category) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.icon, style: const TextStyle(fontWeight: FontWeight.bold)),
                      OutlinedButton.icon(onPressed: _openIconPickerSheet, icon: Icon(AppIcons.getIcon(_selectedIcon), size: 20), label: Text(_selectedIcon != null ? 'החלף סמל' : 'בחר סמל')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.color, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    children: _availableColors.map((color) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = color.value),
                      child: CircleAvatar(backgroundColor: color, child: _selectedColor == color.value ? const Icon(Icons.check, color: Colors.white) : null),
                    )).toList(),
                  ),
                ],

                if (_currentType == EntityType.task) ...[
                  Row(
                    children: [
                      Expanded(flex: 2, child: TextFormField(controller: _intervalAmountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.repeatEvery, border: const OutlineInputBorder()), validator: (val) => (val == null || int.tryParse(val) == null) ? l10n.requiredField : null)),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _selectedIntervalUnit, decoration: const InputDecoration(border: OutlineInputBorder()),
                          items: [
                            DropdownMenuItem(value: 'days', child: Text(l10n.days)), DropdownMenuItem(value: 'weeks', child: Text(l10n.weeks)),
                            DropdownMenuItem(value: 'months', child: Text(l10n.months)), DropdownMenuItem(value: 'years', child: Text(l10n.years)),
                          ],
                          onChanged: (val) => setState(() => _selectedIntervalUnit = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: _endCondition == 'always' ? 1 : 2,
                          child: DropdownButtonFormField<String>(
                            value: _endCondition,
                            decoration: const InputDecoration(labelText: 'משך משימה', border: OutlineInputBorder(), isDense: true),
                            items: [
                              DropdownMenuItem(value: 'always', child: Text(l10n.endConditionAlways)),
                              DropdownMenuItem(value: 'count', child: Text(l10n.endConditionCount)),
                              DropdownMenuItem(value: 'until_date', child: Text(l10n.endConditionUntil)),
                            ],
                            onChanged: (v) => setState(() => _endCondition = v!),
                          ),
                        ),
                        if (_endCondition == 'count') ...[
                          const SizedBox(width: 12),
                          Expanded(flex: 1, child: TextFormField(controller: _endConditionCountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'כמות', border: OutlineInputBorder(), isDense: true))),
                        ],
                        if (_endCondition == 'until_date') ...[
                          const SizedBox(width: 12),
                          Expanded(flex: 1, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))), onPressed: _pickEndDate, icon: const Icon(Icons.calendar_month, size: 16), label: Text(_endConditionDate != null ? _endConditionDate!.toIso8601String().split('T')[0] : l10n.selectDate, style: const TextStyle(fontSize: 12)))),
                        ],
                      ]
                  ),
                  const SizedBox(height: 16),

                  // --- אזור התראות וסנכרון ---
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('קבל תזכורת למכשיר', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('התראה תופיע בהתאם להגדרות המערכת'),
                          secondary: Icon(_isReminderEnabled ? Icons.notifications_active : Icons.notifications_off_outlined, color: _isReminderEnabled ? theme.colorScheme.primary : Colors.grey),
                          value: _isReminderEnabled,
                          onChanged: (bool value) => setState(() => _isReminderEnabled = value),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                        SwitchListTile(
                          title: const Text('סנכרן ליומן גוגל', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(googleUser != null ? 'ייווצר אירוע יום שלם' : 'יש להתחבר דרך מסך ההגדרות'),
                          secondary: Icon(Icons.calendar_month, color: _isGoogleSyncEnabled ? theme.colorScheme.primary : Colors.grey),
                          value: _isGoogleSyncEnabled,
                          onChanged: googleUser != null ? (bool value) => setState(() => _isGoogleSyncEnabled = value) : null,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _save,
                  child: Text(l10n.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, EntityType type) {
    final theme = Theme.of(context);
    final isSelected = _currentType == type;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() {
        _currentType = type;
        _formKey.currentState?.reset();
      }),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      showCheckmark: false,
    );
  }
}