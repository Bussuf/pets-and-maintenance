import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../l10n/app_localizations.dart';
import '../models/task_stats.dart';
import 'analysis_widgets.dart';

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

  const WhenSection({Key? key, required this.stats}) : super(key: key);

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
            child: Text(
              l10n.whenSentence(dayName, partNames[topPart]),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
