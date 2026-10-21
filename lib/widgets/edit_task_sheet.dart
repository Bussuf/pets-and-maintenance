import 'package:flutter/material.dart';
import 'scroll_fade_hint.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../providers/database_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/items_provider.dart';
import '../services/task_actions.dart';
import '../services/notification_service.dart';
import '../providers/google_auth_provider.dart';
import '../services/google_calendar_service.dart';
import 'quick_add_dialogs.dart';
import '../providers/date_format_provider.dart';
import '../models/task_status.dart';
import '../l10n/app_localizations.dart';

class EditTaskSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> taskMap;

  const EditTaskSheet({super.key, required this.taskMap});

  static Future<void> show(BuildContext context, Map<String, dynamic> task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditTaskSheet(taskMap: task),
    );
  }

  @override
  ConsumerState<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends ConsumerState<EditTaskSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _intervalAmountController;
  late TextEditingController _endConditionCountController;

  late String _selectedUnit;
  late String _selectedEndCondition;
  DateTime? _selectedEndConditionDate;
  DateTime? _nextDueDate;
  late bool _isReminderEnabled;
  late bool _isGoogleSyncEnabled;
  String? _existingGoogleEventId;

  // שיוכים
  late String _selectedCategoryId;
  late String _selectedItemId;

  @override
  void initState() {
    super.initState();
    final t = widget.taskMap;
    _nameController = TextEditingController(text: t['name']);
    _descController = TextEditingController(text: t['description'] ?? '');
    _intervalAmountController = TextEditingController(
      text: '${t['interval_amount'] ?? 7}',
    );
    _endConditionCountController = TextEditingController(
      text: t['end_condition'] == 'count'
          ? (t['end_condition_value'] ?? '')
          : '',
    );

    _selectedUnit = t['interval_unit'] ?? 'days';
    _selectedEndCondition = t['end_condition'] ?? 'always';
    if (_selectedEndCondition == 'until_date' &&
        t['end_condition_value'] != null) {
      _selectedEndConditionDate = DateTime.tryParse(t['end_condition_value']);
    }
    _nextDueDate = t['next_due_date'] != null
        ? DateTime.tryParse(t['next_due_date'])
        : null;
    _isReminderEnabled = (t['is_reminder_enabled'] == 1);

    _existingGoogleEventId = t['google_event_id'];
    _isGoogleSyncEnabled = _existingGoogleEventId != null;

    _selectedCategoryId = t['category_id'] ?? '';
    _selectedItemId = t['item_id'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _intervalAmountController.dispose();
    _endConditionCountController.dispose();
    super.dispose();
  }

  Future<void> _showQuickAddCategory() async {
    final id = await QuickAddDialogs.category(context, ref);
    if (id != null && mounted) {
      setState(() {
        _selectedCategoryId = id;
        _selectedItemId = '';
      });
    }
  }

  Future<void> _showQuickAddItem() async {
    if (_selectedCategoryId.isEmpty) return;
    final id = await QuickAddDialogs.item(context, ref, _selectedCategoryId);
    if (id != null && mounted) setState(() => _selectedItemId = id);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final googleUser = ref.watch(googleAuthProvider);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: media.viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ScrollFadeHint(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.editTask,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: l10n.deleteTask,
                            onPressed: () async {
                              // מחיקה משותפת עם דף הניתוח (lib/services/task_actions.dart)
                              final deleted = await deleteTaskWithConfirm(context, ref, widget.taskMap);
                              if (deleted && mounted) Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.taskNameLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.description,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- אזור שיוך לקבוצה ופריט ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ref
                                      .watch(categoriesProvider)
                                      .when(
                                    data: (cats) {
                                      final displayCats = cats.toList();
                                      if (_selectedCategoryId.isNotEmpty &&
                                          !displayCats.any(
                                                (c) => c.id == _selectedCategoryId,
                                          )) {
                                        displayCats.add(
                                          Category(
                                            id: _selectedCategoryId,
                                            name: '...',
                                            createdAt: DateTime.now(),
                                          ),
                                        );
                                      }
                                      return DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        key: ValueKey('cat_$_selectedCategoryId'),
                                        initialValue: _selectedCategoryId.isEmpty
                                            ? null
                                            : _selectedCategoryId,
                                        decoration: InputDecoration(
                                          labelText: l10n.selectCategory,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        items: displayCats
                                            .map(
                                              (c) => DropdownMenuItem(
                                            value: c.id,
                                            child: Text(c.name),
                                          ),
                                        )
                                            .toList(),
                                        onChanged: (val) => setState(() {
                                          _selectedCategoryId = val ?? '';
                                          _selectedItemId =
                                          ''; // איפוס פריט בעת החלפת קבוצה
                                        }),
                                      );
                                    },
                                    loading: () => const LinearProgressIndicator(),
                                    error: (err, _) =>
                                        Text(l10n.errorLoadingGroups),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.add),
                                  onPressed: _showQuickAddCategory,
                                  tooltip: l10n.newGroup,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _selectedCategoryId.isEmpty
                                      ? Text(
                                    l10n.chooseGroupFirst,
                                    style: const TextStyle(color: Colors.grey),
                                  )
                                      : ref
                                      .watch(
                                    itemsByCategoryProvider(
                                      _selectedCategoryId,
                                    ),
                                  )
                                      .when(
                                    data: (items) {
                                      final displayItems = items.toList();
                                      if (_selectedItemId.isNotEmpty &&
                                          !displayItems.any(
                                                (i) => i.id == _selectedItemId,
                                          )) {
                                        displayItems.add(
                                          Item(
                                            id: _selectedItemId,
                                            categoryId: _selectedCategoryId,
                                            name: '...',
                                          ),
                                        );
                                      }
                                      return DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        key: ValueKey('item_$_selectedItemId'),
                                        initialValue: _selectedItemId.isEmpty
                                            ? null
                                            : _selectedItemId,
                                        decoration: InputDecoration(
                                          labelText: l10n.selectItem,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        items: displayItems
                                            .map(
                                              (i) => DropdownMenuItem(
                                            value: i.id,
                                            child: Text(i.name),
                                          ),
                                        )
                                            .toList(),
                                        onChanged: (val) => setState(
                                              () => _selectedItemId = val ?? '',
                                        ),
                                      );
                                    },
                                    loading: () =>
                                    const LinearProgressIndicator(),
                                    error: (err, _) =>
                                        Text(l10n.errorLoadingItems),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.add),
                                  onPressed: _selectedCategoryId.isEmpty
                                      ? null
                                      : _showQuickAddItem,
                                  tooltip: l10n.newItem,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- אזור תדירות ומשך ---
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _intervalAmountController,
                              // לחיצה מסמנת את כל המספר - בעברית הסמן נכנס בצד הלא נכון של הספרות
                              onTap: () =>
                              _intervalAmountController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _intervalAmountController.text.length,
                              ),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.repeatEvery,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedUnit,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(value: 'days', child: Text(l10n.days)),
                                DropdownMenuItem(
                                  value: 'weeks',
                                  child: Text(l10n.weeks),
                                ),
                                DropdownMenuItem(
                                  value: 'months',
                                  child: Text(l10n.months),
                                ),
                                DropdownMenuItem(
                                  value: 'years',
                                  child: Text(l10n.years),
                                ),
                              ],
                              onChanged: (v) => setState(() => _selectedUnit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: _selectedEndCondition == 'always' ? 1 : 2,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedEndCondition,
                              decoration: InputDecoration(
                                labelText: l10n.endConditionTitle,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'always',
                                  child: Text(l10n.endConditionAlways),
                                ),
                                DropdownMenuItem(
                                  value: 'count',
                                  child: Text(l10n.endConditionCount),
                                ),
                                DropdownMenuItem(
                                  value: 'until_date',
                                  child: Text(l10n.endConditionUntil),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedEndCondition = v!),
                            ),
                          ),
                          if (_selectedEndCondition == 'count') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _endConditionCountController,
                                onTap: () => _endConditionCountController.selection =
                                    TextSelection(
                                      baseOffset: 0,
                                      extentOffset:
                                      _endConditionCountController.text.length,
                                    ),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l10n.quantity,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                          if (_selectedEndCondition == 'until_date') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                onPressed: () async {
                                  final p = await showDatePicker(
                                    context: context,
                                    initialDate:
                                    _selectedEndConditionDate ??
                                        DateTime.now().add(const Duration(days: 30)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2035),
                                  );
                                  if (p != null) {
                                    setState(() => _selectedEndConditionDate = p);
                                  }
                                },
                                icon: const Icon(Icons.calendar_month, size: 16),
                                label: Text(
                                  _selectedEndConditionDate != null
                                      ? DateFormatNotifier.format(
                                    _selectedEndConditionDate!,
                                  )
                                      : l10n.selectDate,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- אזור התראות וסנכרון ---
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: Text(
                                l10n.remindMe,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              secondary: Icon(
                                _isReminderEnabled
                                    ? Icons.notifications_active
                                    : Icons.notifications_off_outlined,
                                color: _isReminderEnabled
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                              ),
                              value: _isReminderEnabled,
                              onChanged: (bool value) =>
                                  setState(() => _isReminderEnabled = value),
                            ),
                            Divider(
                              height: 1,
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                            SwitchListTile(
                              title: Text(
                                l10n.syncGoogleCalendar,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              // הסבר רק כשאין חיבור - כדי שיהיה ברור למה המתג כבוי
                              subtitle: googleUser != null
                                  ? null
                                  : Text(l10n.connectInSettings),
                              secondary: Icon(
                                Icons.calendar_month,
                                color: _isGoogleSyncEnabled
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                              ),
                              value: _isGoogleSyncEnabled,
                              onChanged: googleUser != null
                                  ? (bool value) =>
                                  setState(() => _isGoogleSyncEnabled = value)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // כפתור השמירה מחוץ לגלילה - תמיד גלוי, גם בטופס ארוך ועם מקלדת פתוחה (#58)
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final newName = _nameController.text.trim();
                if (newName.isEmpty || _selectedItemId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.fillNameAndItem),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                String? endVal;
                if (_selectedEndCondition == 'count') {
                  endVal = _endConditionCountController.text.trim();
                } else if (_selectedEndCondition == 'until_date' &&
                    _selectedEndConditionDate != null) {
                  endVal = _selectedEndConditionDate!.toIso8601String();
                }

                try {
                  final db = ref.read(databaseProvider);
                  final rawDb = await db.database;

                  // חישוב מחדש של תאריך היעד אם שונתה התדירות
                  final oldAmount =
                      (widget.taskMap['interval_amount'] as num?)?.toInt() ??
                          7;
                  final oldUnit =
                      widget.taskMap['interval_unit'] as String? ?? 'days';
                  final newAmount =
                      int.tryParse(_intervalAmountController.text) ?? 7;
                  if (newAmount != oldAmount || _selectedUnit != oldUnit) {
                    final lastDone = DateTime.tryParse(
                      widget.taskMap['last_completed_date'] ?? '',
                    );
                    final oldDue = DateTime.tryParse(
                      widget.taskMap['next_due_date'] ?? '',
                    );
                    // טרם בוצעה: משחזרים את נקודת ההתחלה מהיעד הישן פחות התדירות הישנה
                    final base =
                        lastDone ??
                            (oldDue != null
                                ? AppTask.addInterval(oldDue, -oldAmount, oldUnit)
                                : DateTime.now());
                    _nextDueDate = AppTask.addInterval(
                      base,
                      newAmount,
                      _selectedUnit,
                    );
                  }

                  // #51 תנאי סיום: משימה שהסתיימה ונערכה לשימוש חוזר חוזרת לפעילות,
                  // ומשימה פעילה שתנאי הסיום החדש שלה כבר הושג - מסתיימת
                  final doneCount =
                      (widget.taskMap['completed_count'] as num?)?.toInt() ??
                          0;
                  if (_nextDueDate == null) {
                    final lastDone = DateTime.tryParse(
                      widget.taskMap['last_completed_date'] ?? '',
                    );
                    _nextDueDate = AppTask.addInterval(
                      lastDone ?? DateTime.now(),
                      newAmount,
                      _selectedUnit,
                    );
                  }
                  if (doneCount > 0 &&
                      isEndReached(
                        _selectedEndCondition,
                        endVal,
                        doneCount,
                        _nextDueDate,
                      )) {
                    _nextDueDate = null;
                  }

                  String? finalGoogleEventId = _existingGoogleEventId;
                  bool calendarOk = true; // #54: הסנכרון ליומן הצליח

                  // מודל זמני כדי להעביר את הנתונים לשירות גוגל
                  AppTask tempTask = AppTask(
                    id: widget.taskMap['id'],
                    itemId: _selectedItemId,
                    name: newName,
                    description: _descController.text.trim().isEmpty
                        ? null
                        : _descController.text.trim(),
                    intervalAmount:
                    int.tryParse(_intervalAmountController.text) ?? 7,
                    intervalUnit: _selectedUnit,
                    endCondition: _selectedEndCondition,
                    endConditionValue: endVal,
                    nextDueDate: _nextDueDate,
                    isReminderEnabled: _isReminderEnabled,
                    reminderTime: _isReminderEnabled ? '09:00' : null,
                    googleEventId: _existingGoogleEventId,
                  );

                  // לוגיקת סנכרון לגוגל בעת עדכון
                  if (_isGoogleSyncEnabled &&
                      ref.read(googleAuthProvider) != null) {
                    if (_existingGoogleEventId == null) {
                      // המשתמש הדליק את המתג עכשיו - ניצור אירוע חדש
                      finalGoogleEventId = await GoogleCalendarService
                          .instance
                          .createEvent(tempTask, l10n.calendarAddedFromApp);
                      // נכשל: המשימה נשמרת בלי אירוע, והמתג יופיע כבוי - אפשר לנסות שוב
                      calendarOk = finalGoogleEventId != null;
                    } else {
                      // האירוע כבר קיים - רק נעדכן אותו
                      calendarOk = await GoogleCalendarService.instance
                          .updateEvent(tempTask, l10n.calendarUpdatedFromApp);
                    }
                  } else if (!_isGoogleSyncEnabled &&
                      _existingGoogleEventId != null) {
                    // המשתמש כיבה את המתג - נמחק את האירוע מהיומן
                    calendarOk = await GoogleCalendarService.instance
                        .deleteEvent(_existingGoogleEventId!);
                    finalGoogleEventId = null;
                  }

                  // עדכון מסד הנתונים
                  await rawDb.update(
                    'tasks',
                    {
                      'name': newName,
                      'description': _descController.text.trim().isEmpty
                          ? null
                          : _descController.text.trim(),
                      'item_id': _selectedItemId,
                      'interval_amount':
                      int.tryParse(_intervalAmountController.text) ?? 7,
                      'interval_unit': _selectedUnit,
                      'end_condition': _selectedEndCondition,
                      'end_condition_value': endVal,
                      'next_due_date': _nextDueDate?.toIso8601String(),
                      'is_reminder_enabled': _isReminderEnabled ? 1 : 0,
                      'reminder_time': _isReminderEnabled ? '09:00' : null,
                      'google_event_id': finalGoogleEventId,
                    },
                    where: 'id = ?',
                    whereArgs: [widget.taskMap['id']],
                  );

                  // הגנה מפני שגיאת התראות - לא יתקע את הממשק יותר!
                  try {
                    final updatedTask = await db.readTask(
                      widget.taskMap['id'],
                    );
                    if (updatedTask != null) {
                      await NotificationService.instance.scheduleTaskReminder(
                        updatedTask,
                      );
                    }
                  } catch (e) {
                    debugPrint('Failed to schedule reminder: $e');
                  }

                  // רענון כפול - מונע באג שבו הרשימה לא מתעדכנת לאחר שינוי קבוצה או מחיקה
                  ref.invalidate(dashboardTasksProvider);
                  if (_selectedCategoryId.isNotEmpty) {
                    ref.invalidate(
                      tasksByCategoryProvider(_selectedCategoryId),
                    );
                  }
                  if (widget.taskMap['category_id'] != null &&
                      widget.taskMap['category_id'] != _selectedCategoryId) {
                    ref.invalidate(
                      tasksByCategoryProvider(widget.taskMap['category_id']),
                    );
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          calendarOk ? l10n.savedOk : l10n.calendarSyncFailed,
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.saveFailed('$e')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                l10n.saveChanges,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
