import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

/// הדרכה על המסך (#26): צללית על כל המסך חוץ מהאזור המוסבר, וחלונית כחולה עם טקסט.
/// כמו מסך ה-FAB: שכבה שקופה מעל האפליקציה - אבל עם "חור" סביב המטרה.
/// השכבה יושבת ב-Overlay של הניווט הראשי, כך שהיא שורדת מעבר בין מסכים.

/// על מה ההדרכה מצביעה. כל מטרה היא GlobalKey שמוצמד לווידג'ט אחד במסך
enum OnboardingTarget { groupChips, fab, menu }

class _Step {
  final OnboardingTarget? target; // null = חלונית באמצע המסך, בלי פוקוס
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) body;
  final String Function(AppLocalizations l10n)? nextLabel; // ברירת מחדל: "הבא"

  const _Step({this.target, required this.title, required this.body, this.nextLabel});
}

class Onboarding {
  Onboarding._();

  static const _pendingPref = 'onboardingPending';

  static final Map<OnboardingTarget, GlobalKey> _keys = {
    for (final t in OnboardingTarget.values) t: GlobalKey(debugLabel: 'onboarding_${t.name}'),
  };

  /// המפתח של מטרה - להצמיד לווידג'ט אחד בלבד (אחרת: שגיאת GlobalKey כפול)
  static GlobalKey key(OnboardingTarget target) => _keys[target]!;

  // כל הצעדים לפי הסדר. צעדי משימת הדוגמה (כרטיס, השלם, ניתוח, כפתורי הכרטיס) - בשלב הבא
  static final List<_Step> _allSteps = [
    _Step(title: (l) => l.obWelcomeTitle, body: (l) => l.obWelcomeBody, nextLabel: (l) => l.obStart),
    // הצגה חוזרת (הגדרות ← אודות) מתחילה כאן
    _Step(target: OnboardingTarget.groupChips, title: (l) => l.obGroupsTitle, body: (l) => l.obGroupsBody),
    _Step(target: OnboardingTarget.fab, title: (l) => l.obFabTitle, body: (l) => l.obFabBody),
    _Step(target: OnboardingTarget.menu, title: (l) => l.obMenuTitle, body: (l) => l.obMenuBody),
    _Step(title: (l) => l.obDoneTitle, body: (l) => l.obDoneBody, nextLabel: (l) => l.obGotIt),
  ];
  static const _replayStart = OnboardingTarget.groupChips;

  static OverlayEntry? _entry;
  static List<_Step> _steps = const [];
  static final ValueNotifier<int> _index = ValueNotifier(0);

  static bool get isActive => _entry != null;

  /// נקרא מנתוני הדוגמה - כלומר רק בהתקנה חדשה
  static Future<void> markPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingPref, true);
  }

  /// בדשבורד אחרי הציור הראשון: מציג פעם אחת, אם סומן בהתקנה
  static Future<void> maybeStart(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_pendingPref) ?? false)) return;
    // פעם אחת בלבד - גם אם יצאו מהאפליקציה באמצע
    await prefs.setBool(_pendingPref, false);
    if (context.mounted) start(context);
  }

  /// replay = הצגה חוזרת מההגדרות: מתחילה מצעד הקבוצות
  static void start(BuildContext context, {bool replay = false}) {
    if (_entry != null) return;
    final from = replay ? _allSteps.indexWhere((s) => s.target == _replayStart) : 0;
    _steps = _allSteps.sublist(from);
    _index.value = 0;
    _entry = OverlayEntry(builder: (_) => const _CoachMarkLayer());
    Navigator.of(context, rootNavigator: true).overlay!.insert(_entry!);
  }

  static void next() {
    if (_index.value < _steps.length - 1) {
      _index.value++;
    } else {
      finish();
    }
  }

  static void finish() {
    _entry?.remove();
    _entry = null;
  }
}

class _CoachMarkLayer extends StatefulWidget {
  const _CoachMarkLayer();

  @override
  State<_CoachMarkLayer> createState() => _CoachMarkLayerState();
}

class _CoachMarkLayerState extends State<_CoachMarkLayer> with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF1A73E8);
  late final Ticker _ticker;
  Rect? _rect; // מיקום המטרה על המסך, null = לא נמצאה (עדיין)

  @override
  void initState() {
    super.initState();
    // המטרה יכולה לזוז (גלילה, טעינה) - בודקים את המיקום שלה בכל פריים
    _ticker = createTicker((_) => _track())..start();
    Onboarding._index.addListener(_onStep);
  }

  @override
  void dispose() {
    _ticker.dispose();
    Onboarding._index.removeListener(_onStep);
    super.dispose();
  }

  _Step get _step => Onboarding._steps[Onboarding._index.value];

  void _onStep() => setState(() => _rect = null);

  void _track() {
    Rect? rect;
    final target = _step.target;
    if (target != null) {
      final box = Onboarding.key(target).currentContext?.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) {
        rect = box.localToGlobal(Offset.zero) & box.size;
      }
    }
    if (rect != _rect) setState(() => _rect = rect);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final step = _step;
    final isLast = Onboarding._index.value == Onboarding._steps.length - 1;
    final hole = (step.target == null || _rect == null) ? null : _rect!.inflate(6);

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(step.title(l10n), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(step.body(l10n), style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _blue),
                  onPressed: Onboarding.next,
                  child: Text(step.nextLabel?.call(l10n) ?? l10n.obNext),
                ),
                const Spacer(),
                if (!isLast)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    onPressed: Onboarding.finish,
                    child: Text(l10n.obSkip),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    final children = <Widget>[
      // הצללית - בולעת לחיצות, כדי שלא ילחצו על האפליקציה מתחת באמצע הסבר
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: CustomPaint(painter: _ScrimPainter(hole)),
        ),
      ),
    ];

    if (hole == null) {
      children.add(Center(child: Padding(padding: const EdgeInsets.all(24), child: bubble)));
    } else {
      // החלונית מתחת למטרה אם יש שם יותר מקום, אחרת מעליה
      final below = size.height - hole.bottom > hole.top;
      final arrowLeft = (hole.center.dx - 8).clamp(28.0, size.width - 44.0);
      children.addAll([
        Positioned(
          left: arrowLeft,
          top: below ? hole.bottom + 8 : null,
          bottom: below ? null : size.height - hole.top + 8,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 16, height: 16, color: _blue),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: below ? hole.bottom + 14 : null,
          bottom: below ? null : size.height - hole.top + 14,
          child: Center(child: bubble),
        ),
      ]);
    }

    return Material(type: MaterialType.transparency, child: Stack(children: children));
  }
}

/// צללית כהה על כל המסך, עם חור מעוגל ומסגרת לבנה סביב המטרה
class _ScrimPainter extends CustomPainter {
  final Rect? hole;
  _ScrimPainter(this.hole);

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.72);
    final full = Path()..addRect(Offset.zero & size);
    if (hole == null) {
      canvas.drawPath(full, scrim);
      return;
    }
    final rrect = RRect.fromRectAndRadius(hole!, Radius.circular(math.min(hole!.shortestSide / 2, 18)));
    canvas.drawPath(Path.combine(PathOperation.difference, full, Path()..addRRect(rrect)), scrim);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.hole != hole;
}
