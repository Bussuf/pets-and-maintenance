import 'task.dart';
import 'task_log.dart';
import 'task_status.dart';

/// מצב משימה בדף הניתוח (#25) - 4 מצבים קבועים בלבד
enum TaskHealth { onTrack, needsAttention, overdue, finished }

/// ביצוע אחד, אחרי חישוב: מתי היה היעד, והאם בוצע בזמן
class LogStat {
  final TaskLog log;
  final DateTime? due; // null = אין על מה להשוות (ביצוע ראשון ישן)
  final bool onTime;
  final int lateDays; // 0 אם בזמן

  const LogStat({required this.log, required this.due, required this.onTime, required this.lateDays});
}

/// מרווח בין שני ביצועים רצופים - לגרף 'הקצב שלך'
class IntervalPoint {
  final DateTime completedAt; // סוף המרווח
  final int days;
  final bool isLate;

  const IntervalPoint({required this.completedAt, required this.days, required this.isLate});
}

/// מנוע החישובים של דף 'ניתוח מעקב משימה' (#25).
/// בלי תצוגה ובלי מסד נתונים - מקבל משימה וביצועים, מחזיר מספרים. נבדק ב-test/task_stats_test.dart
class TaskStats {
  /// כמה מהביצועים האחרונים נבדקים לסטטוס 'צריך תשומת לב', וכמה איחורים מפעילים אותו
  static const int attentionWindow = 5;
  static const int attentionLateThreshold = 3;

  /// כמה מרווחים אחרונים מוצגים בגרף הקצב
  static const int chartIntervals = 12;

  final TaskHealth health;
  final List<LogStat> logs; // מהישן לחדש
  final int completions;
  final int? onTimePercent; // null אם אין ביצועים
  final double? avgIntervalDays; // null אם פחות מ-2 ביצועים
  final List<IntervalPoint> intervals; // עד chartIntervals אחרונים
  final int? fastestDays;
  final int? slowestDays;
  final int onTimeStreak; // ביצועים רצופים בזמן, מהאחרון אחורה
  final int? daysUntilDue; // שלילי = באיחור; null = אין יעד (הסתיימה)
  final double targetDays; // התדירות בימים - קו היעד בגרף
  final Map<int, int> weekdayCounts; // DateTime.monday..sunday → כמות
  final List<int> monthPartCounts; // [תחילת (1-10), אמצע (11-20), סוף (21+)]

  const TaskStats._({
    required this.health,
    required this.logs,
    required this.completions,
    required this.onTimePercent,
    required this.avgIntervalDays,
    required this.intervals,
    required this.fastestDays,
    required this.slowestDays,
    required this.onTimeStreak,
    required this.daysUntilDue,
    required this.targetDays,
    required this.weekdayCounts,
    required this.monthPartCounts,
  });

  /// מספר יום קלנדרי (ב-UTC) - הפרש ימים בלי השפעה של שעון קיץ/חורף
  static int _day(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  static double _unitDays(int amount, String unit) {
    switch (unit) {
      case 'weeks':
        return amount * 7.0;
      case 'months':
        return amount * 30.44;
      case 'years':
        return amount * 365.25;
      default:
        return amount.toDouble();
    }
  }

  /// task: שורה מטבלת המשימות (כמו בכרטיס). logs: כל הביצועים של המשימה, בכל סדר
  static TaskStats compute(Map<String, dynamic> task, List<TaskLog> logs, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final amount = (task['interval_amount'] as num?)?.toInt() ?? 7;
    final unit = task['interval_unit'] as String? ?? 'days';

    final sorted = [...logs]..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    // --- בזמן / באיחור לכל ביצוע. ביצוע בלי due_at (לפני גרסה 7) - משחזרים: ביצוע קודם + תדירות ---
    final stats = <LogStat>[];
    for (int i = 0; i < sorted.length; i++) {
      final log = sorted[i];
      final due = log.dueAt ?? (i > 0 ? AppTask.addInterval(sorted[i - 1].completedAt, amount, unit) : null);
      final late = due == null ? 0 : _day(log.completedAt) - _day(due);
      stats.add(LogStat(log: log, due: due, onTime: late <= 0, lateDays: late > 0 ? late : 0));
    }

    // --- מרווחים בין ביצועים ---
    final allIntervals = <IntervalPoint>[];
    for (int i = 1; i < stats.length; i++) {
      allIntervals.add(IntervalPoint(
        completedAt: stats[i].log.completedAt,
        days: _day(stats[i].log.completedAt) - _day(stats[i - 1].log.completedAt),
        isLate: !stats[i].onTime,
      ));
    }
    final intervalDays = allIntervals.map((p) => p.days).toList();

    // --- רצף בזמן, מהאחרון אחורה ---
    int streak = 0;
    for (final s in stats.reversed) {
      if (!s.onTime) break;
      streak++;
    }

    // --- מתי: ימים בשבוע וחלק בחודש ---
    final weekdays = {for (int d = DateTime.monday; d <= DateTime.sunday; d++) d: 0};
    final monthParts = [0, 0, 0];
    for (final s in stats) {
      final c = s.log.completedAt;
      weekdays[c.weekday] = weekdays[c.weekday]! + 1;
      monthParts[c.day <= 10 ? 0 : (c.day <= 20 ? 1 : 2)]++;
    }

    // --- יעד הבא ---
    final next = task['next_due_date'] != null ? DateTime.tryParse(task['next_due_date'].toString()) : null;
    final daysUntilDue = next == null ? null : _day(next) - _day(today);

    // --- סטטוס: הסתיימה > באיחור > צריך תשומת לב > בקצב טוב ---
    final recent = stats.length > attentionWindow ? stats.sublist(stats.length - attentionWindow) : stats;
    final recentLate = recent.where((s) => !s.onTime).length;
    final TaskHealth health;
    if (isTaskFinished(task)) {
      health = TaskHealth.finished;
    } else if (daysUntilDue != null && daysUntilDue < 0) {
      health = TaskHealth.overdue;
    } else if (recentLate >= attentionLateThreshold) {
      health = TaskHealth.needsAttention;
    } else {
      health = TaskHealth.onTrack;
    }

    return TaskStats._(
      health: health,
      logs: stats,
      completions: stats.length,
      onTimePercent: stats.isEmpty ? null : (stats.where((s) => s.onTime).length * 100 / stats.length).round(),
      avgIntervalDays: intervalDays.isEmpty ? null : intervalDays.reduce((a, b) => a + b) / intervalDays.length,
      intervals: allIntervals.length > chartIntervals ? allIntervals.sublist(allIntervals.length - chartIntervals) : allIntervals,
      fastestDays: intervalDays.isEmpty ? null : intervalDays.reduce((a, b) => a < b ? a : b),
      slowestDays: intervalDays.isEmpty ? null : intervalDays.reduce((a, b) => a > b ? a : b),
      onTimeStreak: streak,
      daysUntilDue: daysUntilDue,
      targetDays: _unitDays(amount, unit),
      weekdayCounts: weekdays,
      monthPartCounts: monthParts,
    );
  }
}
