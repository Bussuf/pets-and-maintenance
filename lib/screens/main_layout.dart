import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// שים לב: הייבוא של abstract_background.dart הוסר לחלוטין
import 'dashboard_screen.dart';
import '../widgets/app_drawer.dart';
import '../widgets/animated_fab_menu.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // משיכת הערך הנוכחי כדי להדגיש את הפריט הנבחר בתפריט
    final currentTheme = ref.watch(themeProvider);

    // ה-Scaffold כעת עומד בפני עצמו ושואב את צבע הרקע מה-Theme באופן טבעי
    return Scaffold(
      drawer: const AppDrawer(),
      body: const DashboardScreen(),
      floatingActionButton: _buildContextAwareFab(context),
    );
  }

  Widget _buildContextAwareFab(BuildContext context) {
    return const AnimatedFabMenu();
  }
}