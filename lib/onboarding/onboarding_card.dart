import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/categories_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import 'onboarding.dart';

/// כרטיס ההזמנה להדרכה בראש הדשבורד (#26).
/// מוצג כשאין נתונים של המשתמש, הוא לא סגר אותו, ולא השלים את ההדרכה (Onboarding.shouldShowCard).
/// "התחל" יוצר את נתוני הדוגמה (פעם אחת) ומריץ את ההדרכה המלאה.
class OnboardingStartCard extends ConsumerStatefulWidget {
  const OnboardingStartCard({super.key});

  @override
  ConsumerState<OnboardingStartCard> createState() => _OnboardingStartCardState();
}

class _OnboardingStartCardState extends ConsumerState<OnboardingStartCard> {
  String? _signature; // מתי לבדוק מחדש: שינוי במשימות/קבוצות או בהדרכה
  Future<bool>? _visible;
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    await Onboarding.ensureSample();
    ref.invalidate(categoriesProvider);
    ref.invalidate(dashboardTasksProvider);
    await ref.read(dashboardTasksProvider.future);
    if (!mounted) return;
    setState(() => _busy = false);
    await Onboarding.startTour(context);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(dashboardTasksProvider).value;
    final categories = ref.watch(categoriesProvider).value;

    return ValueListenableBuilder<int>(
      valueListenable: Onboarding.changes,
      builder: (context, revision, _) {
        // בזמן הדרכה (או לפני שהנתונים נטענו) - לא מציגים
        if (Onboarding.isActive || tasks == null || categories == null) return const SizedBox.shrink();

        final signature = '${tasks.length}|${categories.length}|$revision';
        if (signature != _signature) {
          _signature = signature;
          _visible = Onboarding.shouldShowCard().then((visible) {
            Onboarding.cardVisible.value = visible;
            return visible;
          });
        }

        return FutureBuilder<bool>(
          future: _visible,
          builder: (context, snapshot) {
            if (snapshot.data != true) return const SizedBox.shrink();
            return _buildCard(context);
          },
        );
      },
    );
  }

  Widget _buildCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.obStartCardTitle,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  color: scheme.onPrimaryContainer,
                  onPressed: Onboarding.dismissCard,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Text(
                l10n.obStartCardBody,
                style: TextStyle(color: scheme.onPrimaryContainer, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _start,
              icon: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow),
              label: Text(l10n.obStartCardButton),
            ),
          ],
        ),
      ),
    );
  }
}

/// המסך הריק כשאין במסד כלום (#26): במקום "אין משימות להצגה" - הסבר, וקישור שמחזיר את כרטיס ההזמנה.
/// כשהכרטיס כבר מוצג - לא מציגים כלום, הכרטיס מסביר בעצמו
class OnboardingEmptyState extends StatelessWidget {
  const OnboardingEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool?>(
      valueListenable: Onboarding.cardVisible,
      builder: (context, cardVisible, _) {
        if (cardVisible != false) return const SizedBox.shrink();
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.obEmptyTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.obEmptyBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                ),
                TextButton(
                  onPressed: Onboarding.reshowCard,
                  child: Text(
                    l10n.obEmptyLink,
                    style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
