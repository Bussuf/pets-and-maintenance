import 'package:flutter/material.dart';

/// קבוצת הגדרות: כותרת קטנה וכרטיס אחד עם שורות מופרדות בקו
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 20, 8, 8),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 64,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// שורת הגדרה אחידה: אייקון, שם, הערך הנוכחי מתחת, וחץ כשהשורה פותחת בחירה או מסך
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Widget? leading; // מחליף את האייקון (למשל תמונת חשבון)
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final bool isDanger;
  final bool enabled;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.leading,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.isDanger = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      enabled: enabled,
      onTap: onTap,
      leading: leading ??
          CircleAvatar(
            radius: 18,
            backgroundColor: isDanger ? scheme.errorContainer : scheme.primaryContainer,
            child: Icon(icon, size: 20, color: isDanger ? scheme.error : scheme.primary),
          ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
      // chevron_right מתהפך אוטומטית ב-RTL ומצביע "קדימה"
      trailing: trailing ?? (onTap != null && showChevron ? const Icon(Icons.chevron_right) : null),
    );
  }
}

/// אפשרות אחת בגיליון בחירה
class ChoiceOption<T> {
  final T value;
  final String title;
  final String? subtitle;

  const ChoiceOption({required this.value, required this.title, this.subtitle});
}

/// גיליון בחירה מלמטה עם כפתורי רדיו. מחזיר את הערך שנבחר, או null אם נסגר בלי בחירה
Future<T?> showChoiceSheet<T>(
    BuildContext context, {
      required String title,
      required List<ChoiceOption<T>> options,
      required T selected,
    }) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: RadioGroup<T>(
        groupValue: selected,
        onChanged: (value) => Navigator.pop(ctx, value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                title,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            for (final option in options)
              RadioListTile<T>(
                value: option.value,
                title: Text(option.title),
                subtitle: option.subtitle == null ? null : Text(option.subtitle!),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
