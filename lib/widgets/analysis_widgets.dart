import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// סקשן מתקפל בדף ניתוח מעקב משימה (#25): כותרת, צ'יפ סיכום שמוצג תמיד, ותוכן.
/// זוכר פתוח/סגור לפי id - משותף לכל המשימות. בפעם הראשונה - מקופל
class AnalysisSection extends StatefulWidget {
  final String id;
  final Widget title;
  final String? chip;
  final Widget child;

  const AnalysisSection({
    Key? key,
    required this.id,
    required this.title,
    required this.child,
    this.chip,
  }) : super(key: key);

  @override
  State<AnalysisSection> createState() => _AnalysisSectionState();
}

class _AnalysisSectionState extends State<AnalysisSection> {
  static const _prefix = 'analysis_open_';
  static final Map<String, bool> _cache = {}; // כדי שלא יהיה 'קפיצה' בפתיחה חוזרת של הדף

  late bool _open = _cache[widget.id] ?? false;

  @override
  void initState() {
    super.initState();
    if (!_cache.containsKey(widget.id)) _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('$_prefix${widget.id}') ?? false;
      _cache[widget.id] = saved;
      if (mounted && saved != _open) setState(() => _open = saved);
    } catch (e) {
      debugPrint('Failed to load section state: $e');
    }
  }

  Future<void> _toggle() async {
    setState(() => _open = !_open);
    _cache[widget.id] = _open;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix${widget.id}', _open);
    } catch (e) {
      debugPrint('Failed to save section state: $e');
    }
  }

  /// האם הכותרת והצ'יפ נכנסים יחד בשורה אחת (מודדים את הטקסט בפועל, כולל גודל הגופן במכשיר)
  // מקבלת את הגופן/כיוון/סגנון מבחוץ - כדי לא לשאול עליהם מתוך שלב הפריסה (LayoutBuilder),
  // מה שגרם לשגיאה '_dependents.isEmpty' בסגירת הדף
  bool _fitsOneLine(double maxWidth, TextStyle baseStyle, TextScaler scaler, TextDirection direction) {
    final title = widget.title;
    if (title is! Text || title.data == null) return false;
    double width(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: baseStyle.merge(style)),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }
    final titleWidth = width(title.data!, title.style ?? const TextStyle());
    final chipWidth = width(widget.chip!, const TextStyle(fontSize: 12)) + 20; // ריפוד הצ'יפ
    return titleWidth + 8 + chipWidth <= maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // נשאלים כאן (בבנייה) ולא בתוך LayoutBuilder - ראו _fitsOneLine
    final baseStyle = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    // הצ'יפ באותה שורה עם הכותרת כשיש מקום, ואחרת בשורה מתחת - כך אף פעם לא נחתך
                    child: widget.chip == null
                        ? widget.title
                        : LayoutBuilder(
                      builder: (context, constraints) {
                        if (_fitsOneLine(constraints.maxWidth, baseStyle, scaler, direction)) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(child: widget.title),
                              const SizedBox(width: 8),
                              SummaryChip(text: widget.chip!),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            widget.title,
                            const SizedBox(height: 6),
                            SummaryChip(text: widget.chip!),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: widget.child,
            ),
          ],
        ],
      ),
    );
  }
}

/// צ'יפ סיכום קטן (מוצג גם כשהסקשן מקופל)
class SummaryChip extends StatelessWidget {
  final String text;

  const SummaryChip({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer),
      ),
    );
  }
}

/// אריח מספר: תווית קטנה, מספר גדול, ויחידה אופציונלית
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;

  const StatTile({Key? key, required this.label, required this.value, this.unit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          // מספר ארוך מתכווץ במקום לחרוג מהאריח
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text.rich(
              TextSpan(
                text: value,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// שורת פרט בראש הדף: אייקון, שם ההגדרה, והערך שלה. muted = הגדרה כבויה (מעומעמת, לא נעלמת)
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool muted;

  const DetailRow({Key? key, required this.icon, required this.label, required this.value, this.muted = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor = muted ? theme.colorScheme.onSurfaceVariant.withOpacity(0.6) : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: muted ? valueColor : theme.colorScheme.primary),
          const SizedBox(width: 10),
          // התווית ברוחב הטבעי שלה, והערך מקבל את כל השאר - כך ערכים ארוכים לא נשברים
          Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
