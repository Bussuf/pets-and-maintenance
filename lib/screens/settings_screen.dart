import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import 'organization_screen.dart';
import '../providers/google_auth_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../providers/items_provider.dart';
import '../services/backup_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../widgets/settings_tiles.dart';
import '../providers/date_format_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _exportBackup(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await BackupService.instance.exportToFile();
    } catch (e) {
      if (context.mounted) _showSnack(context, l10n.backupFailed('$e'));
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(l10n.backupImportConfirmTitle),
        content: Text(l10n.backupImportConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.backupImportConfirmAction)),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final imported = await BackupService.instance.importFromFile();
      if (!imported) return;
      // רענון כל המסכים אחרי החלפת הנתונים
      ref.invalidate(categoriesProvider);
      ref.invalidate(dashboardTasksProvider);
      ref.invalidate(itemsByCategoryProvider);
      ref.invalidate(tasksByCategoryProvider);
      if (context.mounted) _showSnack(context, l10n.backupImportSuccess);
    } catch (e) {
      if (context.mounted) _showSnack(context, l10n.backupFailed('$e'));
    }
  }

  Future<void> _pickReminderTime(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final initialTime = ref.read(settingsProvider).reminderTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: l10n.pickReminderTime,
      confirmText: l10n.ok,
      cancelText: l10n.cancel,
    );

    if (picked != null && picked != initialTime) {
      await ref.read(settingsProvider.notifier).setReminderTime(picked);
      if (context.mounted) _showSnack(context, l10n.reminderTimeUpdated);
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final googleUser = ref.watch(googleAuthProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final notificationsOn = settings.notificationStyle != 'none';
    final dateFormat = ref.watch(dateFormatProvider);

    // שמות השפות תמיד בשפה עצמה - כדי שכל משתמש ימצא את שלו
    const languageNames = {'he': 'עברית', 'en': 'English'};
    final themeNames = {
      ThemeMode.system: l10n.followSystem,
      ThemeMode.light: l10n.themeLight,
      ThemeMode.dark: l10n.themeDark,
    };
    final styleNames = {
      'separated': l10n.notifSeparated,
      'grouped': l10n.notifGrouped,
      'none': l10n.notifNone,
    };
    final styleDescriptions = {
      'separated': l10n.notifSeparatedDesc,
      'grouped': l10n.notifGroupedDesc,
      'none': l10n.notifNoneDesc,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          // --- כללי ---
          SettingsSection(
            title: l10n.generalSection,
            children: [
              SettingsTile(
                icon: Icons.language,
                title: l10n.languageSection,
                subtitle: currentLocale == null ? l10n.followSystem : languageNames[currentLocale.languageCode],
                onTap: () async {
                  final code = await showChoiceSheet<String>(
                    context,
                    title: l10n.languageSection,
                    selected: currentLocale?.languageCode ?? 'system',
                    options: [
                      ChoiceOption(value: 'system', title: l10n.followSystem),
                      ChoiceOption(value: 'he', title: languageNames['he']!),
                      ChoiceOption(value: 'en', title: languageNames['en']!),
                    ],
                  );
                  if (code != null) {
                    ref.read(localeProvider.notifier).setLocale(code == 'system' ? null : Locale(code));
                  }
                },
              ),
              SettingsTile(
                icon: Icons.palette_outlined,
                title: l10n.themeTitle,
                subtitle: themeNames[themeMode],
                onTap: () async {
                  final mode = await showChoiceSheet<ThemeMode>(
                    context,
                    title: l10n.themeTitle,
                    selected: themeMode,
                    options: [
                      for (final m in [ThemeMode.system, ThemeMode.light, ThemeMode.dark])
                        ChoiceOption(value: m, title: themeNames[m]!),
                    ],
                  );
                  if (mode != null) ref.read(themeProvider.notifier).setTheme(mode);
                },
              ),
              SettingsTile(
                icon: Icons.calendar_today_outlined,
                title: l10n.dateFormatTitle,
                subtitle: DateFormatNotifier.format(DateTime.now()),
                onTap: () async {
                  final now = DateTime.now();
                  final names = {
                    'auto': l10n.dateFormatAuto,
                    'dmy': l10n.dateFormatDmy,
                    'mdy': l10n.dateFormatMdy,
                    'ymd': l10n.dateFormatYmd,
                  };
                  final pattern = await showChoiceSheet<String>(
                    context,
                    title: l10n.dateFormatTitle,
                    selected: dateFormat,
                    options: [
                      // ליד כל אפשרות - דוגמה עם התאריך של היום
                      for (final o in DateFormatNotifier.options)
                        ChoiceOption(value: o, title: names[o]!, subtitle: DateFormatNotifier.format(now, pattern: o)),
                    ],
                  );
                  if (pattern != null) ref.read(dateFormatProvider.notifier).setFormat(pattern);
                },
              ),
            ],
          ),

          // --- התראות ---
          SettingsSection(
            title: l10n.notificationsSection,
            children: [
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: l10n.notificationStyleTitle,
                subtitle: styleNames[settings.notificationStyle],
                onTap: () async {
                  final style = await showChoiceSheet<String>(
                    context,
                    title: l10n.notificationStyleTitle,
                    selected: settings.notificationStyle,
                    options: [
                      for (final s in ['separated', 'grouped', 'none'])
                        ChoiceOption(value: s, title: styleNames[s]!, subtitle: styleDescriptions[s]),
                    ],
                  );
                  if (style != null) ref.read(settingsProvider.notifier).setNotificationStyle(style);
                },
              ),
              SettingsTile(
                icon: Icons.access_time,
                title: l10n.dailyReminderTime,
                subtitle: notificationsOn
                    ? ref.read(settingsProvider.notifier).formattedReminderTime
                    : l10n.notificationsOff,
                enabled: notificationsOn,
                onTap: () => _pickReminderTime(context, ref),
              ),
            ],
          ),

          // --- חשבונות וסנכרון ---
          SettingsSection(
            title: l10n.syncSection,
            children: [
              SettingsTile(
                icon: Icons.calendar_month_outlined,
                leading: googleUser?.photoUrl != null
                    ? CircleAvatar(radius: 18, backgroundImage: NetworkImage(googleUser!.photoUrl!))
                    : null,
                title: l10n.googleCalendarSync,
                subtitle: googleUser?.email ?? l10n.notConnectedGoogle,
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: googleUser != null ? theme.colorScheme.error : null,
                  ),
                  onPressed: () async {
                    if (googleUser != null) {
                      await ref.read(googleAuthProvider.notifier).signOut();
                      if (context.mounted) _showSnack(context, l10n.googleDisconnected);
                    } else {
                      final ok = await ref.read(googleAuthProvider.notifier).signIn();
                      if (!context.mounted) return;
                      if (!ok) {
                        _showSnack(context, l10n.googleSignInFailed);
                      } else if (ref.read(googleAuthProvider) != null) {
                        // רק אם באמת התחבר - ביטול בבחירת החשבון אינו הצלחה
                        _showSnack(context, l10n.googleConnected);
                      }
                    }
                  },
                  child: Text(googleUser != null ? l10n.disconnect : l10n.connect),
                ),
              ),
            ],
          ),

          // --- נתונים ---
          SettingsSection(
            title: l10n.contentSection,
            children: [
              SettingsTile(
                icon: Icons.edit_note,
                title: l10n.organizeGroupsItems,
                subtitle: l10n.organizeSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrganizationScreen()),
                ),
              ),
              SettingsTile(
                icon: Icons.upload_file,
                title: l10n.backupExport,
                subtitle: l10n.backupExportSubtitle,
                showChevron: false,
                onTap: () => _exportBackup(context),
              ),
              SettingsTile(
                icon: Icons.restore,
                title: l10n.backupImport,
                subtitle: l10n.backupImportSubtitle,
                isDanger: true,
                showChevron: false,
                onTap: () => _importBackup(context, ref),
              ),
            ],
          ),

          // --- אודות ---
          SettingsSection(
            title: l10n.aboutSection,
            children: [
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) => SettingsTile(
                  icon: Icons.info_outline,
                  title: l10n.versionTitle,
                  subtitle: snapshot.hasData ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})' : '…',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
