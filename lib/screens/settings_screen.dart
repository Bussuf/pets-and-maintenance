import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('הגדרות מערכת'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
        children: [
          // --- מקטע מראה ותצוגה ---
          Text(
            'מראה ותצוגה',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('מערכת'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('בהיר'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('כהה'),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (Set<ThemeMode> newSelection) {
              ref.read(themeProvider.notifier).setTheme(newSelection.first);
            },
          ),

          // --- בחירת שפה ---
          const SizedBox(height: 24),
          Text(l10n.languageSection, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'system', icon: const Icon(Icons.phone_android), label: Text(l10n.languageSystem)),
              // שמות השפות תמיד בשפה עצמה - כדי שכל משתמש ימצא את שלו
              const ButtonSegment(value: 'he', label: Text('עברית')),
              const ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {currentLocale?.languageCode ?? 'system'},
            onSelectionChanged: (Set<String> newSelection) {
              final code = newSelection.first;
              ref.read(localeProvider.notifier).setLocale(code == 'system' ? null : Locale(code));
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(),
          ),

          // --- מקטע התראות ותזכורות ---
          Text(
            'התראות ותזכורות',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'separated',
                icon: Icon(Icons.notifications_active),
                label: Text('נפרד'),
              ),
              ButtonSegment(
                value: 'grouped',
                icon: Icon(Icons.list_alt),
                label: Text('מרוכז'),
              ),
              ButtonSegment(
                value: 'none',
                icon: Icon(Icons.notifications_off),
                label: Text('ללא'),
              ),
            ],
            selected: {settings.notificationStyle},
            onSelectionChanged: (Set<String> newSelection) {
              ref.read(settingsProvider.notifier).setNotificationStyle(newSelection.first);
            },
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              settings.notificationStyle == 'grouped'
                  ? 'התראה אחת ביום המאגדת את כל המשימות לאותו יום'
                  : settings.notificationStyle == 'separated'
                  ? 'קבלת התראה נפרדת לכל משימה'
                  : 'התראות האפליקציה כבויות',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // שעת התראה יומית (מאפיר אם "ללא" נבחר)
          Opacity(
            opacity: settings.notificationStyle == 'none' ? 0.4 : 1.0,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: settings.notificationStyle == 'none'
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.primaryContainer,
                child: Icon(Icons.access_time,
                    color: settings.notificationStyle == 'none'
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary
                ),
              ),
              title: const Text('שעת תזכורת יומית', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                settings.notificationStyle == 'none'
                    ? 'התראות כבויות'
                    : 'בשעה ${ref.read(settingsProvider.notifier).formattedReminderTime} (לחץ לשינוי)',
              ),
              trailing: const Icon(Icons.edit_outlined, size: 20),
              enabled: settings.notificationStyle != 'none',
              onTap: () async {
                final initialTime = settings.reminderTime;
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initialTime,
                  helpText: 'בחר שעת תזכורת',
                  confirmText: 'אישור',
                  cancelText: 'ביטול',
                );

                if (picked != null && picked != initialTime) {
                  await ref.read(settingsProvider.notifier).setReminderTime(picked);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('שעת ההתראות עודכנה בהצלחה'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(),
          ),

          // --- מקטע סנכרון ושירותים ---
          Text(
            'סנכרון ושירותים',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: googleUser != null
                    ? theme.colorScheme.primary.withOpacity(0.5)
                    : theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(12),
              color: googleUser != null
                  ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                  : Colors.transparent,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: googleUser != null ? Colors.white : theme.colorScheme.surfaceContainerHighest,
                backgroundImage: googleUser?.photoUrl != null ? NetworkImage(googleUser!.photoUrl!) : null,
                child: googleUser?.photoUrl == null
                    ? Icon(Icons.calendar_month, color: googleUser != null ? theme.colorScheme.primary : Colors.grey)
                    : null,
              ),
              title: const Text('סנכרון יומן גוגל', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                googleUser != null ? 'מחובר: ${googleUser.email}' : 'לא מחובר ליומן גוגל',
                style: TextStyle(
                  color: googleUser != null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              trailing: FilledButton.tonal(
                onPressed: () async {
                  if (googleUser != null) {
                    await ref.read(googleAuthProvider.notifier).signOut();
                  } else {
                    await ref.read(googleAuthProvider.notifier).signIn();
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: googleUser != null ? theme.colorScheme.errorContainer : null,
                  foregroundColor: googleUser != null ? theme.colorScheme.onErrorContainer : null,
                ),
                child: Text(googleUser != null ? 'ניתוק' : 'התחבר'),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(),
          ),

          // --- מקטע ניהול תוכן ---
          Text(
            'ניהול תוכן',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.folder_copy_outlined, color: theme.colorScheme.primary),
            ),
            title: const Text('ארגון קבוצות ופריטים', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('עריכה, מחיקה וסידור מחדש של התוכן'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrganizationScreen()),
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(),
          ),

          // --- מקטע גיבוי ושחזור ---
          Text(
            l10n.backupSection,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.upload_file, color: theme.colorScheme.primary),
            ),
            title: Text(l10n.backupExport, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(l10n.backupExportSubtitle),
            onTap: () => _exportBackup(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.errorContainer,
              child: Icon(Icons.restore, color: theme.colorScheme.error),
            ),
            title: Text(l10n.backupImport, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(l10n.backupImportSubtitle),
            onTap: () => _importBackup(context, ref),
          ),
        ],
      ),
    );
  }
}