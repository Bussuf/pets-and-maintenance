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
      appBar: AppBar(
        elevation: 0,
        title: Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'ערכת נושא',
            onSelected: (mode) {
              ref.read(themeProvider.notifier).setTheme(mode);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ThemeMode.light,
                child: Row(
                  children: [
                    Icon(Icons.light_mode, color: currentTheme == ThemeMode.light ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 12),
                    Text(l10n.lightMode, style: TextStyle(fontWeight: currentTheme == ThemeMode.light ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode, color: currentTheme == ThemeMode.dark ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 12),
                    Text(l10n.darkMode, style: TextStyle(fontWeight: currentTheme == ThemeMode.dark ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.system,
                child: Row(
                  children: [
                    Icon(Icons.settings_system_daydream, color: currentTheme == ThemeMode.system ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 12),
                    Text(l10n.systemMode, style: TextStyle(fontWeight: currentTheme == ThemeMode.system ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: const DashboardScreen(),
      floatingActionButton: _buildContextAwareFab(context),
    );
  }

  Widget _buildContextAwareFab(BuildContext context) {
    return const AnimatedFabMenu();
  }
}