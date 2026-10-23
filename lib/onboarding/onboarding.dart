import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../database/sample_data.dart';
import '../l10n/app_localizations.dart';

/// הדרכה על המסך (#26): צללית על כל המסך חוץ מהאזור המוסבר, וחלונית כחולה עם טקסט.
/// כמו מסך ה-FAB: שכבה שקופה מעל האפליקציה - אבל עם "חור" סביב המטרה.
/// השכבה יושבת ב-Overlay של הניווט הראשי, כך שהיא שורדת מעבר בין מסכים.
///
/// הזרימה: התקנה חדשה ← מסך "שלום" (לבד, פעם אחת) ← כרטיס בראש הדשבורד ←
/// "התחל" יוצר נתוני דוגמה (#75) ומריץ את ההדרכה המלאה עליהם.

/// על מה ההדרכה מצביעה. כל מטרה היא GlobalKey שמוצמד לווידג'ט אחד במסך
enum OnboardingTarget {
  todayHeader, taskCard, completeButton, nextDue, analysisButton, analysisSummary,
  manualButton, duplicateButton, editButton, groupChips, fab, drawer, menu,
}

/// פעולות של המשתמש באפליקציה שמקדמות צעד "אינטראקטיבי"
enum OnboardingEvent { cardExpanded, completed, analysisOpened, analysisClosed }

class _Step {
  final List<OnboardingTarget> targets; // ריק = חלונית באמצע המסך, בלי פוקוס
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n)? body;
  final String Function(AppLocalizations l10n)? nextLabel; // ברירת מחדל: "הבא"
  final OnboardingEvent? waitFor; // הצעד מתקדם כשהפעולה הזו קורית
  final VoidCallback? onNext; // צעד שמחכה לפעולה אבל יש לו גם כפתור משלו
  final bool preferBelow; // החלונית מתחת למטרה (אם יש מקום) - כדי לא להסתיר את מה שמעליה

  const _Step({
    this.targets = const [],
    required this.title,
    this.body,
    this.nextLabel,
    this.waitFor,
    this.onNext,
    this.preferBelow = false,
  });

  /// מחכה ללחיצה של המשתמש על המטרה עצמה: בלי "הבא", והחור לחיץ
  bool get isInteractive => waitFor != null && onNext == null;
}

class Onboarding {
  Onboarding._();

  static const _welcomePref = 'onboardingWelcomePending';
  static const _taskPref = 'onboardingTaskId';
  static const _sampleIdsPref = 'onboardingSampleIds';
  static const _dismissedPref = 'onboardingCardDismissed';
  static const _completedPref = 'onboardingTourCompleted';
  static const _ownDataPref = 'onboardingHasOwnData'; // פעם אחת היו נתונים של המשתמש - הכרטיס לא חוזר לבד

  static final Map<OnboardingTarget, GlobalKey> _keys = {
    for (final t in OnboardingTarget.values) t: GlobalKey(debugLabel: 'onboarding_${t.name}'),
  };

  /// המפתח של מטרה - להצמיד לווידג'ט אחד בלבד (אחרת: שגיאת GlobalKey כפול)
  static GlobalKey key(OnboardingTarget target) => _keys[target]!;

  /// מפתח למטרה של משימת הדוגמה - רק בזמן הדרכה ורק לכרטיס שלה. אחרת null
  static GlobalKey? keyFor(OnboardingTarget target, String? taskId) =>
      (isActive && taskId != null && taskId == _taskId) ? key(target) : null;

  static String? _taskId; // משימת ההשקיה מנתוני הדוגמה
  static String? get taskId => _taskId;

  /// משתנה בכל התחלה/סיום/ויתור - מסכים מאזינים כדי להיבנות מחדש (מפתחות, כרטיס ההזמנה)
  static final ValueNotifier<int> changes = ValueNotifier(0);

  static NavigatorState? _nav;

  /// הדשבורד רושם כאן איפוס ("הכל" + סגירת כרטיסים פתוחים) - נקרא לפני כל הדרכה,
  /// כדי שהיא תתחיל ממסך מסודר ומוכר
  static VoidCallback? beforeStart;

  // --- מסך "שלום": לבד, פעם אחת בהתקנה חדשה. לא מתחיל את התהליך ---
  static final List<_Step> _welcomeSteps = [
    _Step(title: (l) => l.obWelcomeTitle, body: (l) => l.obWelcomeBody, nextLabel: (l) => l.obGotIt),
  ];

  // --- ההדרכה המלאה, על נתוני הדוגמה ---
  static final List<_Step> _tourSteps = [
    _Step(
      targets: const [OnboardingTarget.todayHeader, OnboardingTarget.taskCard],
      title: (l) => l.obCardTitle,
      body: (l) => l.obCardBody,
      waitFor: OnboardingEvent.cardExpanded,
    ),
    _Step(
      targets: const [OnboardingTarget.completeButton],
      preferBelow: true, // לא להסתיר את הכרטיס שזה עתה נפתח
      title: (l) => l.obCompleteTitle,
      body: (l) => l.obCompleteBody,
      waitFor: OnboardingEvent.completed,
    ),
    _Step(targets: const [OnboardingTarget.nextDue], title: (l) => l.obNextDueTitle, body: (l) => l.obNextDueBody),
    _Step(
      targets: const [OnboardingTarget.analysisButton],
      title: (l) => l.obAnalysisButtonTitle,
      body: (l) => l.obAnalysisButtonBody,
      waitFor: OnboardingEvent.analysisOpened,
    ),
    // בדף הניתוח: "הבנתי, אעיין" מעלים את ההדרכה - מעיינים בחופשיות.
    // ביציאה מהדף (חץ או כפתור החזרה של הטלפון) ההדרכה חוזרת בצעד הבא
    _Step(
      targets: const [OnboardingTarget.analysisSummary],
      title: (l) => l.obAnalysisTitle,
      body: (l) => l.obAnalysisBody,
      nextLabel: (l) => l.obBrowse,
      waitFor: OnboardingEvent.analysisClosed,
      onNext: () => _hidden.value = true,
    ),
    _Step(targets: const [OnboardingTarget.manualButton], title: (l) => l.obManualTitle, body: (l) => l.obManualBody),
    _Step(targets: const [OnboardingTarget.duplicateButton], title: (l) => l.obDuplicateTitle, body: (l) => l.obDuplicateBody),
    _Step(targets: const [OnboardingTarget.editButton], title: (l) => l.obEditTitle, body: (l) => l.obEditBody),
    // הדרכה חלקית (בלי משימת דוגמה) מתחילה כאן
    _Step(targets: const [OnboardingTarget.fab], title: (l) => l.obFabTitle, body: (l) => l.obFabBody),
    _Step(targets: const [OnboardingTarget.drawer], title: (l) => l.obDrawerTitle, body: (l) => l.obDrawerBody),
    _Step(targets: const [OnboardingTarget.groupChips], title: (l) => l.obGroupsTitle, body: (l) => l.obGroupsBody),
    _Step(targets: const [OnboardingTarget.menu], title: (l) => l.obMenuTitle, body: (l) => l.obMenuBody),
    _Step(title: (l) => l.obDoneTitle, body: (l) => l.obDoneBody, nextLabel: (l) => l.obGotIt),
  ];
  static const _partialStart = OnboardingTarget.fab;

  static OverlayEntry? _entry;
  static List<_Step> _steps = const [];
  static bool _countsAsCompleted = false; // סיום עד הסוף מעלים את כרטיס ההזמנה (לא במסך "שלום")
  static final ValueNotifier<int> _index = ValueNotifier(0);
  static final ValueNotifier<bool> _hidden = ValueNotifier(false); // בזמן עיון חופשי בדף הניתוח

  static bool get isActive => _entry != null;

  // ---------------- התקנה חדשה ונתוני הדוגמה ----------------

  /// נקרא כשהמסד נוצר לראשונה (התקנה חדשה) - מסך "שלום" יוצג בכניסה
  static Future<void> markFreshInstall() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomePref, true);
  }

  /// נקרא מנתוני הדוגמה: כל המזהים שנוצרו, ומשימת ההשקיה שעליה ההדרכה עובדת
  static Future<void> saveSample(List<String> ids, String wateringTaskId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_sampleIdsPref, ids);
    await prefs.setString(_taskPref, wateringTaskId);
  }

  /// משימת ההשקיה של הדוגמה עדיין קיימת? (אם כן - אפשר הדרכה מלאה)
  static Future<String?> _existingSampleTask() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_taskPref);
    if (id == null) return null;
    return await DatabaseHelper.instance.readTask(id) != null ? id : null;
  }

  /// יוצר את נתוני הדוגמה - רק אם משימת ההשקיה לא קיימת (לא יוצרים פעמיים)
  static Future<void> ensureSample() async {
    if (await _existingSampleTask() != null) return;
    await SampleData.seed(await DatabaseHelper.instance.database);
  }

  // ---------------- כרטיס ההזמנה בדשבורד ----------------

  /// מוצג כשאין נתונים של המשתמש, הוא לא סגר את הכרטיס, ולא השלים את ההדרכה.
  /// "נתונים של המשתמש" = כל קבוצה/פריט/משימה שהמזהה שלה לא שייך לדוגמה (לא לפי שם)
  static Future<bool> shouldShowCard() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getBool(_dismissedPref) ?? false) ||
        (prefs.getBool(_completedPref) ?? false) ||
        (prefs.getBool(_ownDataPref) ?? false)) {
      return false;
    }
    final sample = (prefs.getStringList(_sampleIdsPref) ?? const []).toSet();
    final db = await DatabaseHelper.instance.database;
    for (final table in const ['categories', 'items', 'tasks']) {
      final rows = await db.query(table, columns: ['id']);
      if (rows.any((r) => !sample.contains(r['id']))) {
        // נוצר נתון משלו - הכרטיס נעלם לתמיד, גם אם אחר כך הכל יימחק
        await prefs.setBool(_ownDataPref, true);
        return false;
      }
    }
    return true;
  }

  /// האם כרטיס ההזמנה מוצג עכשיו (null = עוד לא ידוע). המסך הריק מציג קישור למדריך רק כשהכרטיס לא שם
  static final ValueNotifier<bool?> cardVisible = ValueNotifier(null);

  /// "מדריך למשתמשים חדשים" במסך הריק: מחזיר את כרטיס ההזמנה, כמו בהתקנה הראשונה
  static Future<void> reshowCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedPref, false);
    await prefs.setBool(_completedPref, false);
    await prefs.setBool(_ownDataPref, false);
    changes.value++;
  }

  static Future<void> dismissCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedPref, true);
    changes.value++;
  }

  // ---------------- הפעלה ----------------

  /// בדשבורד אחרי שהמשימות נטענו: מסך "שלום" פעם אחת, בהתקנה חדשה
  static Future<void> maybeWelcome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_welcomePref) ?? false)) return;
    await prefs.setBool(_welcomePref, false); // פעם אחת בלבד
    if (context.mounted) _start(context, _welcomeSteps, countsAsCompleted: false);
  }

  /// "התחל" בכרטיס - נתוני הדוגמה כבר נוצרו ונטענו (ensureSample)
  static Future<void> startTour(BuildContext context) async {
    _taskId = await _existingSampleTask();
    if (context.mounted) _start(context, _tourSteps, countsAsCompleted: true);
  }

  /// "מדריך למשתמש חדש" בהגדרות: מלאה אם משימת הדוגמה קיימת, אחרת מצעד הקבוצות
  static Future<void> startReplay(BuildContext context) async {
    _taskId = await _existingSampleTask();
    final from = _taskId != null ? 0 : _tourSteps.indexWhere((s) => s.targets.contains(_partialStart));
    if (context.mounted) _start(context, _tourSteps.sublist(from), countsAsCompleted: true);
  }

  static void _start(BuildContext context, List<_Step> steps, {required bool countsAsCompleted}) {
    if (_entry != null) return;
    _steps = steps;
    _countsAsCompleted = countsAsCompleted;
    _index.value = 0;
    _hidden.value = false;
    _nav = Navigator.of(context, rootNavigator: true);
    beforeStart?.call();
    _entry = OverlayEntry(builder: (_) => const _CoachMarkLayer());
    _nav!.overlay!.insert(_entry!);
    changes.value++;
  }

  /// דיווח מהאפליקציה על פעולה של המשתמש. מקדם את הצעד אם הוא חיכה לה
  static void notify(OnboardingEvent event, String? taskId) {
    if (!isActive || taskId == null || taskId != _taskId) return;
    if (_steps[_index.value].waitFor != event) return;
    // אחרי הפריים - כדי לא לעדכן את השכבה באמצע בנייה של מסך אחר
    WidgetsBinding.instance.addPostFrameCallback((_) => next());
  }

  static void next() {
    if (!isActive) return;
    _hidden.value = false;
    if (_index.value < _steps.length - 1) {
      _index.value++;
    } else {
      finish(completed: true);
    }
  }

  /// completed = הגיעו עד הסוף ("הבנתי" בצעד האחרון). "דלג" = לא הושלמה, והכרטיס נשאר
  /// "דלג": בהדרכה המלאה נחשב כמו סיום - הכרטיס לא חוזר (בחירה של המשתמש),
  /// ומופיעה הודעה קצרה איך לחזור להדרכה. נתוני הדוגמה נשארים
  static Future<void> skip() async {
    final wasTour = _countsAsCompleted;
    final context = _nav?.context;
    await finish(completed: true);
    if (wasTour && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.obSkippedHint), behavior: SnackBarBehavior.floating),
      );
    }
  }

  static Future<void> finish({bool completed = false}) async {
    _entry?.remove();
    _entry = null;
    if (completed && _countsAsCompleted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedPref, true);
    }
    changes.value++;
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
  bool _scrolledThisStep = false;

  @override
  void initState() {
    super.initState();
    // המטרה יכולה לזוז (גלילה, טעינה, מעבר מסך) - בודקים את המיקום שלה בכל פריים
    _ticker = createTicker((_) => _track())..start();
    Onboarding._index.addListener(_onStep);
    Onboarding._hidden.addListener(_onHidden);
  }

  @override
  void dispose() {
    _ticker.dispose();
    Onboarding._index.removeListener(_onStep);
    Onboarding._hidden.removeListener(_onHidden);
    super.dispose();
  }

  _Step get _step => Onboarding._steps[Onboarding._index.value];

  void _onStep() => setState(() {
    _rect = null;
    _scrolledThisStep = false;
  });

  void _onHidden() => setState(() {});

  void _track() {
    if (Onboarding._hidden.value) return;
    Rect? rect;
    BuildContext? firstContext;
    for (final target in _step.targets) {
      final ctx = Onboarding.key(target).currentContext;
      final box = ctx?.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) {
        final r = box.localToGlobal(Offset.zero) & box.size;
        rect = rect == null ? r : rect.expandToInclude(r);
        firstContext ??= ctx;
      }
    }
    // המטרה מחוץ למסך (למשל הכרטיס עבר קבוצה אחרי "השלם") - גוללים אליה פעם אחת
    final height = MediaQuery.sizeOf(context).height;
    if (rect != null && firstContext != null && !_scrolledThisStep && (rect.top < 80 || rect.bottom > height - 120)) {
      _scrolledThisStep = true;
      Scrollable.ensureVisible(firstContext, alignment: 0.3, duration: const Duration(milliseconds: 300));
    }
    if (rect != _rect) setState(() => _rect = rect);
  }

  @override
  Widget build(BuildContext context) {
    // עיון חופשי בדף הניתוח - בלי צללית ובלי חסימה, עד שיוצאים מהדף
    if (Onboarding._hidden.value) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final step = _step;
    final isLast = Onboarding._index.value == Onboarding._steps.length - 1;
    final hole = (step.targets.isEmpty || _rect == null) ? null : _rect!.inflate(6);
    final body = step.body?.call(l10n);

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
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(body, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                // צעד אינטראקטיבי - אין "הבא": מתקדמים בלחיצה על המטרה עצמה
                if (step.isInteractive)
                // צעד לחיצה: אין "הבא" - מסבירים במפורש איך ממשיכים
                  Expanded(
                    child: Text(l10n.obTapHint, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  )
                else ...[
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _blue),
                    onPressed: step.onNext ?? Onboarding.next,
                    child: Text(step.nextLabel?.call(l10n) ?? l10n.obNext),
                  ),
                  const Spacer(),
                ],
                if (!isLast)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    onPressed: Onboarding.skip,
                    child: Text(l10n.obSkip),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    final children = <Widget>[
      Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ScrimPainter(hole)))),
    ];

    // בולעים לחיצות על כל המסך - חוץ מהחור בצעד אינטראקטיבי (שם הלחיצה עוברת לאפליקציה)
    void absorb(double left, double top, double width, double height) {
      if (width <= 0 || height <= 0) return;
      children.add(Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
      ));
    }

    if (hole != null && step.isInteractive) {
      absorb(0, 0, size.width, hole.top);
      absorb(0, hole.bottom, size.width, size.height - hole.bottom);
      absorb(0, hole.top, hole.left, hole.height);
      absorb(hole.right, hole.top, size.width - hole.right, hole.height);
    } else {
      absorb(0, 0, size.width, size.height);
    }

    if (hole == null) {
      children.add(Center(child: Padding(padding: const EdgeInsets.all(24), child: bubble)));
    } else {
      // החלונית מתחת למטרה אם יש שם יותר מקום, אחרת מעליה
      final spaceBelow = size.height - hole.bottom;
      final below = step.preferBelow && spaceBelow > 220 ? true : spaceBelow > hole.top;
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
