import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/main_layout.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // האזנה למצב ערכת הנושא
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pets & Maintenance',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he', ''), // כפיית עברית כרגע

      // שימוש בערכות הנושא של Google Stock שיצרנו
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // חיבור משתנה ה-State שמגיע מה-Provider
      themeMode: themeMode,

      home: const MainLayout(),
    );
  }
}