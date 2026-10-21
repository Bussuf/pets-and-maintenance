import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_screen.dart';
import '../l10n/app_localizations.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ה-Scaffold כעת עומד בפני עצמו ושואב את צבע הרקע מה-Theme באופן טבעי
    return Scaffold(
      // ה-FAB וה-Drawer נמצאים בתוך הדשבורד עצמו (שיודע מה הצ'יפ המסומן) - לא כאן
      body: const DashboardScreen(),
    );
  }
}
