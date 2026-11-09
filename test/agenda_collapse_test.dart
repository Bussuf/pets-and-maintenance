import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pets_and_maintenance/widgets/agenda.dart';
import 'package:pets_and_maintenance/widgets/month_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// בדיקות לזיכרון הקיפול של הצ'יפים (#88)
/// הרצה: flutter test test/agenda_collapse_test.dart

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('לחיצה חוזרת על צ\'יפ', () {
    const shown = [AgendaKind.today, AgendaKind.later];

    test('יש סעיף פתוח - מקפלת את המוצגים', () {
      expect(toggledSections({AgendaKind.later}, shown), {AgendaKind.today, AgendaKind.later});
    });

    test('הכל מקופל - פותחת את המוצגים', () {
      expect(toggledSections({AgendaKind.today, AgendaKind.later}, shown), <AgendaKind>{});
    });

    test('לא נוגעת בסעיפים שלא מוצגים', () {
      final result = toggledSections({AgendaKind.today, AgendaKind.later, AgendaKind.focusDay}, shown);
      expect(result, {AgendaKind.focusDay});
    });

    test('בלי סעיפים מוצגים אין "הכל מקופל"', () {
      expect(allSectionsCollapsed({AgendaKind.later}, const []), isFalse);
    });
  });

  group('זיכרון לכל צ\'יפ', () {
    test('ברירת מחדל: מאוחר יותר והסתיימו מקופלים', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(agendaCollapseProvider('home'));
      await settle();
      expect(container.read(agendaCollapseProvider('home')), {AgendaKind.later, AgendaKind.finished});
    });

    test('צ\'יפ אחד לא משפיע על אחר', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(agendaCollapseProvider('home'));
      container.read(agendaCollapseProvider(agendaAllScope));
      await settle();

      container.read(agendaCollapseProvider('home').notifier).toggle(AgendaKind.today);

      expect(container.read(agendaCollapseProvider('home')), contains(AgendaKind.today));
      expect(container.read(agendaCollapseProvider(agendaAllScope)), isNot(contains(AgendaKind.today)));
    });

    test('נשמר בין הפעלות', () async {
      final first = ProviderContainer();
      first.read(agendaCollapseProvider('home'));
      await settle();
      first.read(agendaCollapseProvider('home').notifier).toggle(AgendaKind.today);
      await settle();
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);
      second.read(agendaCollapseProvider('home'));
      await settle();
      expect(second.read(agendaCollapseProvider('home')), contains(AgendaKind.today));
    });

    test('מחיקה מנקה רק את מה שנמחק', () async {
      final first = ProviderContainer();
      first.read(agendaCollapseProvider('home'));
      first.read(agendaCollapseProvider('car'));
      await settle();
      first.read(agendaCollapseProvider('home').notifier).toggle(AgendaKind.today);
      first.read(agendaCollapseProvider('car').notifier).toggle(AgendaKind.today);
      await settle();
      first.dispose();

      await clearAgendaCollapse(['home']);

      final second = ProviderContainer();
      addTearDown(second.dispose);
      second.read(agendaCollapseProvider('home'));
      second.read(agendaCollapseProvider('car'));
      await settle();
      expect(second.read(agendaCollapseProvider('home')), {AgendaKind.later, AgendaKind.finished});
      expect(second.read(agendaCollapseProvider('car')), contains(AgendaKind.today));
    });
  });

  group('עמוד ברצועה', () {
    final today = DateTime(2026, 11, 10);

    test('היום ו-6 הימים הבאים הם עמוד 0', () {
      expect(weekPageOf(today, today), 0);
      expect(weekPageOf(DateTime(2026, 11, 16), today), 0);
    });

    test('היום השביעי הוא כבר העמוד הבא', () {
      expect(weekPageOf(DateTime(2026, 11, 17), today), 1);
    });

    test('יום לפני היום הוא עמוד 1-', () {
      expect(weekPageOf(DateTime(2026, 11, 9), today), -1);
      expect(weekPageOf(DateTime(2026, 11, 3), today), -1);
      expect(weekPageOf(DateTime(2026, 11, 2), today), -2);
    });
  });
}
