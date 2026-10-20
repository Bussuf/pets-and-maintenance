import '../l10n/app_localizations.dart';

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