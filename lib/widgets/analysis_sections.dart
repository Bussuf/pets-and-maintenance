import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/task_actions.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../l10n/app_localizations.dart';
import '../models/task_stats.dart';
import 'analysis_widgets.dart';
import '../utils/duration_text.dart';
import '../providers/date_format_provider.dart';

/// הסקשנים המתקפלים של דף ניתוח מעקב משימה (#25), כל אחד בווידג'ט משלו

/// שם יום בשבוע לפי מספר (DateTime.monday..sunday), בשפה הנוכחית
String _weekdayName(BuildContext context, int weekday, {bool short = false}) {
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  final date = DateTime(2026, 1, 4 + (weekday % 7)); // 4/1/2026 הוא יום ראשון
  if (!short) return DateFormat.EEEE(localeTag).format(date);
  // בעברית האות הבודדת ברורה ('א׳'), באנגלית צריך 3 אותיות ('Sun') כי S/T חוזרות
  final narrow = Localizations.localeOf(context).languageCode == 'he';
  return narrow ? DateFormat('EEEEE', localeTag).format(date) : DateFormat.E(localeTag).format(date);
}

/// הודעה כשאין עדיין ביצועים
class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        AppLocalizations.of(context)!.noCompletionsYet,
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// כותרת משנה קטנה בתוך סקשן
class _SubTitle extends StatelessWidget {
  final String text;

  const _SubTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

// ---------------- מתי אתה עושה את זה ----------------

class WhenSection extends StatelessWidget {
  final TaskStats stats;

  const WhenSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // היום והחלק בחודש הכי נפוצים (בתיקו - הראשון)
    int? topDay;
    stats.weekdayCounts.forEach((day, count) {
      if (count > 0 && (topDay == null || count > stats.weekdayCounts[topDay]!)) topDay = day;
    });
    int topPart = 0;
    for (int i = 1; i < 3; i++) {
      if (stats.monthPartCounts[i] > stats.monthPartCounts[topPart]) topPart = i;
    }
    final partNames = [l10n.monthPartStart, l10n.monthPartMiddle, l10n.monthPartEnd];
    final partShort = [l10n.monthPartStartShort, l10n.monthPartMiddleShort, l10n.monthPartEndShort];

    final hasData = stats.completions > 0 && topDay != null;
    final dayName = hasData ? _weekdayName(context, topDay!) : '';

    return AnalysisSection(
      id: 'when',
      title: Text(l10n.whenTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
      chip: hasData ? '$dayName · ${partNames[topPart]}' : null,
      child: !hasData
          ? const _NoData()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            // התובנה - עם אייקון, בלי קווים מפרידים
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.whenSentence(dayName, partNames[topPart]),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          _SubTitle(l10n.whenWeekdays),
          _WeekdayBars(stats: stats, topDay: topDay!),
          _SubTitle(l10n.whenMonthPart),
          _MonthPartBar(counts: stats.monthPartCounts, top: topPart, labels: partShort),
        ],
      ),
    );
  }
}

/// עמודה לכל יום בשבוע, מסודרות לפי היום הראשון בשבוע של השפה (בעברית - ראשון).
/// גובה העמודות יחסי לשטח שנשאר - כך שגם גופן גדול לא יחרוג מהגבולות
class _WeekdayBars extends StatelessWidget {
  final TaskStats stats;
  final int topDay;

  const _WeekdayBars({required this.stats, required this.topDay});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = ראשון
    final order = [for (int i = 0; i < 7; i++) ((first + i) % 7 == 0 ? DateTime.sunday : (first + i) % 7)];
    final maxCount = stats.weekdayCounts.values.fold<int>(1, (a, b) => a > b ? a : b);
    final labelStyle = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final day in order)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    // מספר מעל העמודה (ריק ב-0, כדי שכל העמודות יתחילו באותו גובה)
                    Text(stats.weekdayCounts[day]! > 0 ? '${stats.weekdayCounts[day]}' : '', style: labelStyle),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: (stats.weekdayCounts[day]! / maxCount).clamp(0.06, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: day == topDay ? scheme.primary : scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_weekdayName(context, day, short: true), maxLines: 1, style: labelStyle),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// שלושה אריחים: תחילת / אמצע / סוף חודש - האחוז ומתחתיו המילה, והנפוץ מודגש.
/// הרוחב יחסי לאחוזים, אבל כל אריח מקבל קודם את הרוחב שהתוכן שלו צריך - כך שום מילה לא נחתכת.
/// אם אין מקום אפילו למינימום של שלושתם (מסך צר מאוד / גופן ענק) - שלושה אריחים שווים
class _MonthPartBar extends StatelessWidget {
  final List<int> counts;
  final int top;
  final List<String> labels;

  const _MonthPartBar({required this.counts, required this.top, required this.labels});

  static const double _gap = 6;
  static const double _hPad = 8;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = counts.fold<int>(0, (a, b) => a + b);
    final percents = [for (final c in counts) total == 0 ? 0 : (c * 100 / total).round()];

    final base = DefaultTextStyle.of(context).style;
    const percentStyle = TextStyle(fontWeight: FontWeight.bold);
    const labelStyle = TextStyle(fontSize: 12);
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    double textWidth(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: base.merge(style)),
        textDirection: direction,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      return painter.width;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - _gap * 2;
        // מינימום אחיד לשלושת האריחים: התוכן הרחב ביותר בשפה הנוכחית (המילה הארוכה, או '100%')
        // כך שאריחים עם אותו אחוז תמיד באותו רוחב, והמילה תמיד נכנסת
        double widest = textWidth('100%', percentStyle);
        for (final label in labels) {
          final w = textWidth(label, labelStyle);
          if (w > widest) widest = w;
        }
        final mins = List<double>.filled(3, widest + _hPad * 2 + 2);
        final sumMin = mins.fold<double>(0, (a, b) => a + b);

        final List<double> widths;
        if (sumMin > available) {
          widths = List.filled(3, available / 3);
        } else {
          final extra = available - sumMin;
          widths = [
            for (int i = 0; i < 3; i++) mins[i] + (total == 0 ? extra / 3 : extra * percents[i] / 100),
          ];
        }

        return Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              SizedBox(
                width: widths[i],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 8),
                  decoration: BoxDecoration(
                    color: i == top ? scheme.primary : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${percents[i]}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: percentStyle.copyWith(color: i == top ? scheme.onPrimary : scheme.onPrimaryContainer),
                      ),
                      Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle.copyWith(color: i == top ? scheme.onPrimary : scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ---------------- הקצב שלך ----------------

class PaceSection extends StatelessWidget {
  final TaskStats stats;
  final String? unit; // יחידת התדירות של המשימה - קובעת ימים או חודשים

  const PaceSection({super.key, required this.stats, required this.unit});

  /// הסטייה מהיעד ביחידה של המשימה: ימים שלמים, או חודשים בעיגול לעשירית.
  /// חיובי = איחור (מעל הקו), שלילי = הקדמה (מתחת לקו)
  double _deviation(int days) {
    final diff = days - stats.targetDays;
    if (!DurationText.usesMonths(unit)) return diff.roundToDouble();
    return ((diff / 30.44) * 10).round() / 10;
  }

  /// היעד ביחידה של המשימה (לכותרת)
  String _targetText() {
    if (!DurationText.usesMonths(unit)) return stats.targetDays.round().toString();
    final months = ((stats.targetDays / 30.44) * 10).round() / 10;
    return months == months.roundToDouble() ? months.toInt().toString() : months.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final points = stats.intervals;
    final n = points.length;
    final deviations = [for (final p in points) _deviation(p.days)];
    // איחור = מעל הקו - אותה הגדרה כמו הצבע בגרף
    final late = deviations.where((d) => d > 0).length;

    String? chip;
    if (n == 1) {
      chip = late > 0 ? l10n.paceLastLate : l10n.paceLastOnTime;
    } else if (n > 1) {
      chip = late > 0 ? l10n.paceLateInLast(late, n) : l10n.paceAllOnTime(n);
    }

    return AnalysisSection(
      id: 'pace',
      title: Text(l10n.paceTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
      chip: chip,
      child: n == 0
          ? Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(l10n.paceNeedTwo, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Text(
              DurationText.usesMonths(unit) ? l10n.paceCaptionMonths(_targetText()) : l10n.paceCaptionDays(_targetText()),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          _PaceChart(points: points, deviations: deviations, yearLabels: DurationText.usesMonths(unit)),
          if (stats.fastestDays != null && stats.slowestDays != null) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            DetailRow(
              icon: Icons.directions_run,
              label: l10n.paceFastest,
              value: DurationText.days(l10n, stats.fastestDays!, unit),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            DetailRow(
              icon: Icons.directions_walk,
              label: l10n.paceSlowest,
              value: DurationText.days(l10n, stats.slowestDays!, unit),
            ),
            if (stats.paceAvgDays != null) ...[
              Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              DetailRow(
                icon: Icons.speed,
                label: l10n.paceAverage,
                value: DurationText.days(l10n, stats.paceAvgDays!.round(), unit),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// גרף סטייה מהיעד: הקו המקווקו באמצע הוא היעד. עמודה למעלה (כתומה) = איחור, למטה (כחולה) = הקדמה.
/// המספר ליד כל עמודה הוא ההפרש ('+3', '−1', '0'). תווית זמן רק כשהחודש (או השנה) מתחלפים
class _PaceChart extends StatelessWidget {
  final List<IntervalPoint> points;
  final List<double> deviations;
  final bool yearLabels; // משימות חודשים/שנים - תוויות שנה במקום חודש

  const _PaceChart({required this.points, required this.deviations, required this.yearLabels});

  static String _signed(double d) {
    if (d == 0) return '0';
    final abs = d.abs();
    final text = abs == abs.roundToDouble() ? abs.toInt().toString() : abs.toStringAsFixed(1);
    return d > 0 ? '+$text' : '−$text';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final lateColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    final labelStyle = TextStyle(fontSize: 10, color: scheme.onSurfaceVariant);
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    final maxAbs = deviations.fold<double>(0, (a, d) => d.abs() > a ? d.abs() : a);
    final scale = maxAbs == 0 ? 1.0 : maxAbs * 1.15;
    final valueRowHeight = MediaQuery.textScalerOf(context).scale(10) + 6;

    // תווית זמן רק כשהתקופה מתחלפת (ובראשונה), ולא בשתי עמודות צמודות
    bool samePeriod(DateTime a, DateTime b) => yearLabels ? a.year == b.year : (a.year == b.year && a.month == b.month);
    final labelAt = <int>{};
    int lastLabel = -2;
    for (int i = 0; i < points.length; i++) {
      final changed = i == 0 || !samePeriod(points[i].completedAt, points[i - 1].completedAt);
      if (changed && i - lastLabel > 1) {
        labelAt.add(i);
        lastLabel = i;
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final half = constraints.maxHeight / 2;
              final barMax = half - valueRowHeight; // גובה מקסימלי לעמודה בכל חצי
              return Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final d in deviations)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // חצי עליון: איחור
                                SizedBox(
                                  height: half,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: d < 0
                                        ? null
                                        : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(_signed(d), maxLines: 1, textAlign: TextAlign.center, style: labelStyle),
                                        const SizedBox(height: 2),
                                        Container(
                                          height: d == 0 ? 3 : barMax * (d / scale).clamp(0.06, 1.0),
                                          decoration: BoxDecoration(
                                            color: d == 0 ? scheme.primary.withValues(alpha: 0.35) : lateColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // חצי תחתון: הקדמה
                                SizedBox(
                                  height: half,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: d >= 0
                                        ? null
                                        : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          height: barMax * (-d / scale).clamp(0.06, 1.0),
                                          decoration: BoxDecoration(
                                            color: scheme.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(_signed(d), maxLines: 1, textAlign: TextAlign.center, style: labelStyle),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  // קו היעד המקווקו - באמצע
                  Positioned(
                    left: 0,
                    right: 0,
                    top: half,
                    child: CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: _DashedLinePainter(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (int i = 0; i < points.length; i++)
              Expanded(
                child: labelAt.contains(i)
                    ? Text(
                  yearLabels
                      ? '${points[i].completedAt.year}'
                      : DateFormat.MMM(localeTag).format(points[i].completedAt),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                  style: labelStyle,
                )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 5.0, gap = 4.0;
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, 0), Offset((x + dash).clamp(0, size.width), 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}

// ---------------- לוח ביצועים ----------------

/// לוח חודשי (ימים) או שנתי (חודשים), עם בורר תצוגה. ברירת המחדל לפי יחידת המשימה:
/// ימים/שבועות - חודשי, חודשים/שנים - שנתי. ביצוע בזמן = צבע ראשי, באיחור = כתום,
/// היום = מסגרת, יעד הבא = מסגרת מקווקוות. דפדוף מהביצוע הראשון ועד היעד הבא
class CalendarSection extends StatefulWidget {
  final TaskStats stats;
  final String? unit;
  final DateTime? nextDue;

  const CalendarSection({super.key, required this.stats, required this.unit, required this.nextDue});

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  // התצוגה נקבעת לפי סוג המשימה בלבד: ימים/שבועות - חודשי, חודשים/שנים - שנתי
  late final bool _yearly = DurationText.usesMonths(widget.unit);
  late DateTime _month; // החודש המוצג (היום הראשון בו)
  late int _year; // השנה המוצגת

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _year = now.year;
  }

  /// גבולות הדפדוף: מהביצוע הראשון (או החודש הנוכחי) ועד היעד הבא (או החודש הנוכחי)
  DateTime get _minMonth {
    final now = DateTime.now();
    final first = widget.stats.logs.isNotEmpty ? widget.stats.logs.first.log.completedAt : now;
    final d = first.isBefore(now) ? first : now;
    return DateTime(d.year, d.month);
  }

  DateTime get _maxMonth {
    final now = DateTime.now();
    final last = widget.nextDue != null && widget.nextDue!.isAfter(now) ? widget.nextDue! : now;
    return DateTime(last.year, last.month);
  }

  /// ביצועים בטווח תאריכים [from, to)
  List<LogStat> _logsBetween(DateTime from, DateTime to) => widget.stats.logs
      .where((s) => !s.log.completedAt.isBefore(from) && s.log.completedAt.isBefore(to))
      .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();

    // הצ'יפ - תמיד לפי התקופה הנוכחית (לא משתנה בדפדוף), ביחידה של ברירת המחדל
    final String chip;
    if (DurationText.usesMonths(widget.unit)) {
      final n = _logsBetween(DateTime(now.year), DateTime(now.year + 1)).length;
      chip = l10n.calChip('${now.year}', n);
    } else {
      final n = _logsBetween(DateTime(now.year, now.month), DateTime(now.year, now.month + 1)).length;
      chip = l10n.calChip(DateFormat.MMMM(localeTag).format(now), n);
    }

    return AnalysisSection(
      id: 'calendar',
      title: Text(l10n.calTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
      chip: chip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 0),

          _yearly ? _buildYear(context, localeTag) : _buildMonth(context, localeTag),
          const SizedBox(height: 20),
          const _CalendarLegend(),
          if (widget.stats.completions > 0) ...[
            const SizedBox(height: 10),
            _CalendarRecords(stats: widget.stats, unit: widget.unit),
          ],
        ],
      ),
    );
  }

  /// שורת ניווט: חץ אחורה, כותרת, חץ קדימה (החצים מתהפכים לבד ב-RTL)
  Widget _navRow(String title, {required bool canBack, required bool canForward, required VoidCallback onBack, required VoidCallback onForward}) {
    // אין לאן לדפדף - בלי חיצים בכלל, רק הכותרת
    if (!canBack && !canForward) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    // יש לאן לדפדף - שני החיצים תמיד (החץ שאין לאן להמשיך בכיוונו - מעומעם), כדי שהכותרת לא תזוז
    return Row(
      children: [
        IconButton(onPressed: canBack ? onBack : null, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        IconButton(onPressed: canForward ? onForward : null, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }

  // --- חודשי ---
  Widget _buildMonth(BuildContext context, String localeTag) {
    final scheme = Theme.of(context).colorScheme;
    final first = MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = ראשון
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = (_month.weekday % 7 - first + 7) % 7; // תאים ריקים לפני היום הראשון
    final today = DateTime.now();

    // ביצועים לפי יום בחודש
    final byDay = <int, List<LogStat>>{};
    for (final s in _logsBetween(_month, DateTime(_month.year, _month.month + 1))) {
      byDay.putIfAbsent(s.log.completedAt.day, () => []).add(s);
    }

    final headerStyle = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);
    final weekdayOrder = [for (int i = 0; i < 7; i++) ((first + i) % 7 == 0 ? DateTime.sunday : (first + i) % 7)];

    return Column(
      children: [
        _navRow(
          DateFormat.yMMMM(localeTag).format(_month),
          canBack: _month.isAfter(_minMonth),
          canForward: _month.isBefore(_maxMonth),
          onBack: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
          onForward: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
        ),
        Row(
          children: [
            for (final d in weekdayOrder)
              Expanded(
                child: Text(_weekdayName(context, d, short: true), textAlign: TextAlign.center, style: headerStyle),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          padding: EdgeInsets.zero, // בלי ריפוד אוטומטי של שטח המערכת (שורה ריקה בסוף)
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (int i = 0; i < leading; i++) const SizedBox.shrink(),
            for (int day = 1; day <= daysInMonth; day++)
              _CalendarCell(
                label: '$day',
                logs: byDay[day] ?? const [],
                isToday: today.year == _month.year && today.month == _month.month && today.day == day,
                isNextDue: widget.nextDue != null &&
                    widget.nextDue!.year == _month.year &&
                    widget.nextDue!.month == _month.month &&
                    widget.nextDue!.day == day,
              ),
          ],
        ),
      ],
    );
  }

  // --- שנתי ---
  Widget _buildYear(BuildContext context, String localeTag) {
    final today = DateTime.now();
    return Column(
      children: [
        _navRow(
          '$_year',
          canBack: _year > _minMonth.year,
          canForward: _year < _maxMonth.year,
          onBack: () => setState(() => _year--),
          onForward: () => setState(() => _year++),
        ),
        GridView.count(
          padding: EdgeInsets.zero, // בלי ריפוד אוטומטי של שטח המערכת (שורה ריקה בסוף)
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.6,
          children: [
            for (int m = 1; m <= 12; m++)
              _CalendarCell(
                label: DateFormat.MMM(localeTag).format(DateTime(_year, m)),
                logs: _logsBetween(DateTime(_year, m), DateTime(_year, m + 1)),
                showCount: true,
                isToday: today.year == _year && today.month == m,
                isNextDue: widget.nextDue != null && widget.nextDue!.year == _year && widget.nextDue!.month == m,
              ),
          ],
        ),
      ],
    );
  }
}

/// תא בלוח (יום או חודש): מלא אם היה ביצוע - כתום אם אחד מהם באיחור.
/// מספר קטן בפינה כשיש יותר מביצוע אחד (בלוח השנתי - תמיד, כשיש ביצועים)
class _CalendarCell extends StatelessWidget {
  final String label;
  final List<LogStat> logs;
  final bool isToday;
  final bool isNextDue;
  final bool showCount;

  const _CalendarCell({
    required this.label,
    required this.logs,
    required this.isToday,
    required this.isNextDue,
    this.showCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final lateColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;

    final done = logs.isNotEmpty;
    final anyLate = logs.any((s) => !s.onTime);
    final fill = !done ? scheme.surfaceContainerHighest.withValues(alpha: 0.4) : (anyLate ? lateColor : scheme.primary);
    final textColor = !done ? scheme.onSurfaceVariant : (anyLate ? Colors.black87 : scheme.onPrimary);
    final count = logs.length;

    Widget cell = Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: isToday ? Border.all(color: scheme.primary, width: 2) : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: textColor, fontWeight: done ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          if (done && (showCount || count > 1))
            PositionedDirectional(
              top: 1,
              end: 3,
              child: Text('$count', style: TextStyle(fontSize: 9, color: textColor)),
            ),
        ],
      ),
    );

    if (isNextDue && !isToday) {
      cell = CustomPaint(
        foregroundPainter: _DashedRectPainter(color: scheme.onSurfaceVariant),
        child: cell,
      );
    }
    return cell;
  }
}

/// מקרא: בזמן / באיחור / היום / יעד הבא
class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final lateColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    final style = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);

    Widget item(Widget box, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [box, const SizedBox(width: 4), Text(text, style: style)],
    );
    Widget box({Color? fill, Border? border}) => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: fill, border: border, borderRadius: BorderRadius.circular(3)),
    );

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        item(box(fill: scheme.primary), l10n.statOnTime),
        item(box(fill: lateColor), l10n.overdueTasks),
        item(box(border: Border.all(color: scheme.primary, width: 2)), l10n.today),
        item(
          CustomPaint(foregroundPainter: _DashedRectPainter(color: scheme.onSurfaceVariant), child: box()),
          l10n.detailNextDue,
        ),
      ],
    );
  }
}

/// מסגרת מקווקוות מעוגלת (ל'יעד הבא')
class _DashedRectPainter extends CustomPainter {
  final Color color;

  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) => oldDelegate.color != color;
}

/// שיאים לאורך כל ההיסטוריה (לא רק התקופה המוצגת): הרצף הכי ארוך בזמן, והאיחור הכי גדול
class _CalendarRecords extends StatelessWidget {
  final TaskStats stats;
  final String? unit;

  const _CalendarRecords({required this.stats, required this.unit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final late = stats.biggestLate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        DetailRow(
          icon: Icons.local_fire_department_outlined,
          label: l10n.recordLongestStreak,
          value: l10n.recordStreakValue(stats.longestOnTimeStreak),
          muted: stats.longestOnTimeStreak == 0,
        ),
        Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        DetailRow(
          icon: Icons.schedule,
          label: l10n.recordBiggestLate,
          value: late == null
              ? l10n.recordNoLate
              : '${DurationText.days(l10n, late.lateDays, unit)} · ${DateFormatNotifier.format(late.log.completedAt)}',
          muted: late == null,
        ),
      ],
    );
  }
}

// ---------------- היסטוריה ----------------

/// רשימת הביצועים מהחדש לישן: 5 אחרונים, ו'הצג הכול' מרחיב באותו סקשן.
/// ⋮ לכל שורה: תיקון תאריך / מחיקה (משותף - lib/services/task_actions.dart)
class HistorySection extends StatefulWidget {
  final TaskStats stats;
  final Map<String, dynamic> task;

  const HistorySection({super.key, required this.stats, required this.task});

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  static const _collapsedCount = 5;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final logs = widget.stats.logs.reversed.toList(); // מהחדש לישן
    final visible = _showAll ? logs : logs.take(_collapsedCount).toList();

    return AnalysisSection(
      id: 'history',
      title: Text(l10n.historyTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
      chip: logs.isEmpty
          ? null
          : l10n.historyChip(logs.length, DateFormatNotifier.format(logs.first.log.completedAt)),
      child: logs.isEmpty
          ? const _NoData()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < visible.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            _HistoryRow(entry: visible[i], task: widget.task),
          ],
          if (logs.length > _collapsedCount)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(_showAll ? l10n.historyShowLess : l10n.historyShowAll(logs.length)),
              ),
            ),
        ],
      ),
    );
  }
}

/// שורה בהיסטוריה: אייקון, תאריך + יום, תגית בזמן/באיחור, ו-⋮
class _HistoryRow extends ConsumerWidget {
  final LogStat entry;
  final Map<String, dynamic> task;

  const _HistoryRow({required this.entry, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final okColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
    final lateColor = isDark ? Colors.orange.shade300 : Colors.orange.shade800;
    final color = entry.onTime ? okColor : lateColor;
    final date = entry.log.completedAt;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(entry.onTime ? Icons.check : Icons.schedule, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${DateFormatNotifier.format(date)} · ${_weekdayName(context, date.weekday)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // #79: ביצוע שהוזן ידנית - חיווי בלבד, בלי השפעה על החישובים
          if (entry.log.parsedNotes?['manual'] == true) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.historyManualChip,
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Text(
              entry.onTime
                  ? l10n.statOnTime
                  : l10n.overdueBy(DurationText.days(l10n, entry.lateDays, task['interval_unit'])),
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            position: PopupMenuPosition.under,
            onSelected: (value) {
              if (value == 'date') {
                editCompletionDate(context, ref, entry.log, task);
              } else if (value == 'delete') {
                deleteCompletionWithConfirm(context, ref, entry.log, task);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Row(children: [
                  const Icon(Icons.edit_calendar_outlined, size: 20),
                  const SizedBox(width: 12),
                  Flexible(child: Text(l10n.fixCompletionDate)),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  const SizedBox(width: 12),
                  Flexible(child: Text(l10n.deleteCompletion, style: const TextStyle(color: Colors.red))),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
