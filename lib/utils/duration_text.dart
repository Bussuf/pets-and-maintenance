import 'package:intl/intl.dart' show DateFormat;
import '../l10n/app_localizations.dart';
import '../providers/date_format_provider.dart';

/// #71: ניסוח הכלל של לוח קבוע מתוך תאריך העוגן - "כל יום ראשון", "ב-1 לכל חודש", "כל שנה ב-1 בדצמבר"
String fixedScheduleRule(AppLocalizations l10n, String localeTag, DateTime anchor, int amount, String unit) {
  switch (unit) {
    case 'weeks':
      return l10n.fixedRuleWeekly(amount, DateFormat.EEEE(localeTag).format(anchor));
    case 'months':
      final rule = l10n.fixedRuleMonthly(amount, anchor.day);
      return anchor.day > 28 ? '$rule ${l10n.fixedRuleLastDayNote}' : rule;
    case 'years':
      return l10n.fixedRuleYearly(amount, DateFormat.MMMMd(localeTag).format(anchor));
    default:
      return l10n.fixedRuleDaily(amount, DateFormatNotifier.format(anchor));
  }
}

/// ניסוח אנושי של משכים (#25, #55) - לפי יחידת התדירות של המשימה:
/// משימות ימים/שבועות - תמיד בימים ('22 ימים');
/// משימות חודשים/שנים - פחות מ-30 יום בימים, ומעל בחודשים בעיגול לחצי ('כ-5.5 חודשים')
class DurationText {
  static bool usesMonths(String? unit) => unit == 'months' || unit == 'years';

  /// תדירות בלי קידומת: 'כל שבוע', 'כל יומיים', 'כל חצי שנה' (לדף הניתוח #25)
  static String every(AppLocalizations l10n, int amount, String? unit) {
    switch (unit) {
      case 'weeks':
        return l10n.everyWeeks(amount);
      case 'months':
        return amount == 6 ? l10n.everyHalfYear : l10n.everyMonths(amount);
      case 'years':
        return l10n.everyYears(amount);
      default:
        return l10n.everyDays(amount);
    }
  }

  static String days(AppLocalizations l10n, int days, String? unit) {
    if (!usesMonths(unit) || days < 30) return l10n.durationDays(days);

    final months = ((days / 30.44) * 2).round() / 2; // עיגול לחצי חודש
    if (months == 1) return l10n.monthsApproxOne;
    if (months == 2) return l10n.monthsApproxTwo;
    final text = months == months.roundToDouble() ? months.toInt().toString() : months.toStringAsFixed(1);
    return l10n.monthsApproxMany(text);
  }
}