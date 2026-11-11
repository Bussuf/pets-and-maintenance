import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/task_status.dart';
import '../onboarding/onboarding.dart';

/// סוג סעיף ביומן - המפתח לזכירת קיפול (#84).
/// כל ימי השבוע הם סוג אחד, כי "שלישי" של היום הוא "שני" של מחר.
/// past - יום שעבר ברצועת השבוע (רק ביצועים). אותם סוגים ביומן וברצועה, עם זיכרון קיפול אחד (#90)
enum AgendaKind { overdue, today, tomorrow, week, later, finished, past }

/// המפתח של צ'יפ "הכל". לקבוצה ולפריט המפתח הוא המזהה שלהם
const String agendaAllScope = 'all';

/// #77: זיכרון קיפול אחד לדף התצוגות
const String agendaViewsScope = 'views';
const String _agendaPrefPrefix = 'agenda_collapsed_';

/// האם כל הסעיפים המוצגים מקופלים (חץ הצ'יפ, וכיוון הלחיצה עליו)
bool allSectionsCollapsed(Set<AgendaKind> collapsed, Iterable<AgendaKind> shown) =>
    shown.isNotEmpty && shown.every(collapsed.contains);

/// לחיצה חוזרת על צ'יפ מסומן (#87): יש סעיף מוצג פתוח - מקפלים; כולם מקופלים - פותחים
Set<AgendaKind> toggledSections(Set<AgendaKind> collapsed, Iterable<AgendaKind> shown) =>
    allSectionsCollapsed(collapsed, shown) ? collapsed.difference(shown.toSet()) : {...collapsed, ...shown};

/// מיקום בקרוסלה (#89): אחרי האחרון חוזרים לראשון, ולפני הראשון - לאחרון
int wrapIndex(int index, int length) => ((index % length) + length) % length;

/// מחיקת הזיכרון של קבוצות/פריטים שנמחקו
Future<void> clearAgendaCollapse(Iterable<String> scopes) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    for (final scope in scopes) {
      await prefs.remove('$_agendaPrefPrefix$scope');
    }
  } catch (e) {
    debugPrint('Failed to clear agenda state: $e');
  }
}

/// אילו סוגי סעיפים מקופלים - לכל צ'יפ זיכרון משלו (#88), נשמר בין הפעלות
class AgendaCollapseNotifier extends StateNotifier<Set<AgendaKind>> {
  final String _scope;

  String get _prefKey => '$_agendaPrefPrefix$_scope';

  AgendaCollapseNotifier(this._scope) : super(const {AgendaKind.later, AgendaKind.finished}) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefKey);
      if (saved == null || !mounted) return;
      state = AgendaKind.values.where((k) => saved.contains(k.name)).toSet();
    } catch (e) {
      debugPrint('Failed to load agenda state: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, state.map((k) => k.name).toList());
    } catch (e) {
      debugPrint('Failed to save agenda state: $e');
    }
  }

  void toggle(AgendaKind kind) {
    state = state.contains(kind) ? ({...state}..remove(kind)) : {...state, kind};
    _save();
  }

  void expand(AgendaKind kind) {
    state = {...state}..remove(kind);
    _save();
  }

  void expandAll() {
    state = <AgendaKind>{};
    _save();
  }

  /// בזמן הדרכה בלי השפעה - קיפול היה מעלים את מה שההדרכה מצביעה עליו
  void toggleAll(Iterable<AgendaKind> shown) {
    if (Onboarding.isActive) return;
    state = toggledSections(state, shown);
    _save();
  }
}

/// המפתח: agendaAllScope, או מזהה הקבוצה/הפריט של הצ'יפ המסומן
final agendaCollapseProvider =
    StateNotifierProvider.family<AgendaCollapseNotifier, Set<AgendaKind>, String>((ref, scope) {
  return AgendaCollapseNotifier(scope);
});

/// קבוצה ביומן: כותרת (באיחור / היום / מחר / יום בשבוע / מאוחר יותר) והמשימות שבה
class AgendaGroup {
  final String title;
  final AgendaKind kind;
  final bool isOverdue;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> doneTasks; // ביצועים באותו יום - רק כשהרשימה מסוננת ליום (#90)

  AgendaGroup({
    required this.title,
    required this.kind,
    required this.tasks,
    this.doneTasks = const [],
    this.isOverdue = false,
  });

  int get count => tasks.length + doneTasks.length;
}

/// שורת "בוצע" ברשימה השטוחה (לעומת משימה, שמוצגת ככרטיס)
class AgendaDoneEntry {
  final Map<String, dynamic> task;

  const AgendaDoneEntry(this.task);
}

/// הרשימה השטוחה של היומן: כותרות, ומשימות של סעיפים פתוחים בלבד
List<dynamic> flattenAgenda(List<AgendaGroup> groups, Set<AgendaKind> collapsed) {
  return [
    for (final group in groups) ...[
      group,
      if (!collapsed.contains(group.kind)) ...[
        ...group.tasks,
        for (final task in group.doneTasks) AgendaDoneEntry(task),
      ],
    ],
  ];
}

/// חלוקת משימות (ממוינות לפי תאריך) לקבוצות יומן - משותף לדשבורד ולדף קבוצה
List<AgendaGroup> buildAgendaGroups(BuildContext context, List<Map<String, dynamic>> tasks) {
  final l10n = AppLocalizations.of(context)!;
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  final List<Map<String, dynamic>> overdue = [];
  final List<Map<String, dynamic>> today = [];
  final List<Map<String, dynamic>> tomorrow = [];
  final Map<int, List<Map<String, dynamic>>> upcomingDays = {};
  final List<Map<String, dynamic>> later = [];
  final List<Map<String, dynamic>> finished = [];

  for (final task in tasks) {
    if (isTaskFinished(task)) {
      finished.add(task);
      continue;
    }
    final due = task['next_due_date'] != null ? DateTime.tryParse(task['next_due_date']) : null;
    if (due == null) {
      later.add(task);
      continue;
    }
    final diffDays = DateTime(due.year, due.month, due.day).difference(todayStart).inDays;

    if (diffDays < 0) {
      overdue.add(task);
    } else if (diffDays == 0) {
      today.add(task);
    } else if (diffDays == 1) {
      tomorrow.add(task);
    } else if (diffDays <= 6) {
      upcomingDays.putIfAbsent(diffDays, () => []).add(task);
    } else {
      later.add(task);
    }
  }

  final List<AgendaGroup> groups = [];
  if (overdue.isNotEmpty) groups.add(AgendaGroup(title: l10n.overdueTasks, kind: AgendaKind.overdue, tasks: overdue, isOverdue: true));
  if (today.isNotEmpty) groups.add(AgendaGroup(title: l10n.today, kind: AgendaKind.today, tasks: today));
  if (tomorrow.isNotEmpty) groups.add(AgendaGroup(title: l10n.tomorrow, kind: AgendaKind.tomorrow, tasks: tomorrow));

  final sortedDiffs = upcomingDays.keys.toList()..sort();
  for (final diff in sortedDiffs) {
    final targetDate = DateTime(todayStart.year, todayStart.month, todayStart.day + diff);
    groups.add(AgendaGroup(title: DateFormat.EEEE(localeTag).format(targetDate), kind: AgendaKind.week, tasks: upcomingDays[diff]!));
  }

  if (later.isNotEmpty) groups.add(AgendaGroup(title: l10n.later, kind: AgendaKind.later, tasks: later));
  if (finished.isNotEmpty) groups.add(AgendaGroup(title: l10n.finishedTasks, kind: AgendaKind.finished, tasks: finished));
  return groups;
}

/// כותרת סעיף ביומן: שם הסעיף, מונה משימות וקו מפריד. לחיצה מקפלת (#84);
/// סעיף מקופל מציג נקודות בצבעי הקבוצות של המשימות שבו
class AgendaSectionHeader extends ConsumerWidget {
  final AgendaGroup group;
  final String scope; // הצ'יפ שהזיכרון שלו חל כאן

  static const _maxDots = 5;

  const AgendaSectionHeader({super.key, required this.group, required this.scope});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final overdueColor = isDark ? Colors.redAccent.shade100 : Colors.red.shade800;
    final isCollapsed = ref.watch(agendaCollapseProvider(scope)).contains(group.kind);

    return Semantics(
      expanded: !isCollapsed,
      child: InkWell(
        // בזמן הדרכה הכותרת נמצאת בתוך האזור המואר - קיפול היה מעלים את הכרטיס שההדרכה מצביעה עליו
        onTap: () {
          if (Onboarding.isActive) return;
          ref.read(agendaCollapseProvider(scope).notifier).toggle(group.kind);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
          child: Row(
            children: [
              if (group.isOverdue) ...[
                const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.redAccent),
                const SizedBox(width: 6),
              ],
              Text(
                group.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: group.isOverdue ? overdueColor : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: group.isOverdue ? Colors.red.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${group.count}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: group.isOverdue ? overdueColor : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isCollapsed)
                for (final task in [...group.tasks, ...group.doneTasks].take(_maxDots))
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsetsDirectional.only(start: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task['category_color'] != null
                          ? Color(task['category_color'] as int)
                          : theme.colorScheme.primary,
                    ),
                  ),
              const SizedBox(width: 10),
              Expanded(
                child: Divider(
                  color: group.isOverdue ? Colors.red.withValues(alpha: 0.3) : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: isCollapsed ? 0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.expand_more, size: 20, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}