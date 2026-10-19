import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import 'organization_screen.dart';
import '../providers/google_auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final googleUser = ref.watch(googleAuthProvider);

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
        ],
      ),
    );
  }
}