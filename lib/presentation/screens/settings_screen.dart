import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/presentation/providers/filter_provider.dart';
import 'package:doctorfilter/presentation/providers/pro_provider.dart';
import 'package:doctorfilter/presentation/providers/theme_and_locale_provider.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';
import 'package:doctorfilter/presentation/providers/preset_provider.dart';
import 'package:doctorfilter/presentation/services/app_links.dart';
import 'package:doctorfilter/presentation/services/settings_backup.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'about_screen.dart';
import 'language_screen.dart';
import 'paywall_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final isPro = ref.watch(isProProvider);
    final isAmoled = ref.watch(amoledProvider);
    final themeFollowsFilter = ref.watch(themeFollowsFilterProvider);
    final config = ref.watch(filterConfigProvider);

    return Scaffold(
      appBar: AppBar(title: Text(loc?.translate('nav_settings') ?? 'Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (!isPro) _ProCard(onTap: () => _open(context, const PaywallScreen())),

          _SectionLabel(
            loc?.translate('settings_appearance') ?? 'Appearance',
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(loc?.translate('app_language') ?? 'Language'),
                  subtitle: Text(
                    _languageName(
                      locale?.languageCode ??
                          Localizations.localeOf(context).languageCode,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(context, const LanguageScreen()),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: context.colours.primary,
                  ),
                  title: Text(loc?.translate('settings_theme') ?? 'Dark theme'),
                  subtitle: Text(
                    loc?.translate('settings_theme_desc') ??
                        'Easier on the eyes at night.',
                  ),
                  value: isDark,
                  onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                ),
                // Only while the dark theme is actually showing: a "true black"
                // switch under a white screen does nothing visible, and a
                // control that appears to do nothing reads as broken.
                if (isDark) ...[
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: Icon(
                      Icons.contrast_rounded,
                      color: context.colours.primary,
                    ),
                    title: Text(
                      loc?.translate('settings_amoled') ?? 'True black (OLED)',
                    ),
                    subtitle: Text(
                      loc?.translate('settings_amoled_desc') ??
                          'Unlit pixels emit no light at all, and use less battery.',
                    ),
                    value: isAmoled,
                    onChanged: (_) => ref.read(amoledProvider.notifier).toggle(),
                  ),
                ],
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Icon(
                    Icons.auto_mode_rounded,
                    color: context.colours.primary,
                  ),
                  title: Text(
                    loc?.translate('settings_theme_follows') ??
                        'Go dark with the filter',
                  ),
                  subtitle: Text(
                    loc?.translate('settings_theme_follows_desc') ??
                        'A bright app on a dimmed screen undoes the filter.',
                  ),
                  value: themeFollowsFilter,
                  onChanged: (_) =>
                      ref.read(themeFollowsFilterProvider.notifier).toggle(),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Icon(
                    Icons.notifications_active_outlined,
                    color: context.colours.primary,
                  ),
                  title: Text(
                    loc?.translate('settings_notification') ??
                        'Notification controls',
                  ),
                  subtitle: Text(
                    loc?.translate('settings_notification_desc') ??
                        'Control the filter without opening the app.',
                  ),
                  value: config.isNotificationEnabled,
                  onChanged:
                      ref.read(filterProvider.notifier).setNotificationEnabled,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SectionLabel(loc?.translate('settings_backup') ?? 'Back up settings'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.save_alt_rounded),
                  title: Text(
                    loc?.translate('settings_backup') ?? 'Back up settings',
                  ),
                  subtitle: Text(
                    loc?.translate('settings_backup_desc') ??
                        'Save your presets and filter settings as a file.',
                  ),
                  onTap: () => _export(context, ref),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.restore_page_outlined),
                  title: Text(
                    loc?.translate('settings_restore') ?? 'Restore from a file',
                  ),
                  onTap: () => _import(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SectionLabel(loc?.translate('settings_about_section') ?? 'About'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(loc?.translate('app_about') ?? 'About'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(context, const AboutScreen()),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded),
                  title: Text(loc?.translate('app_rate') ?? 'Rate the app'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: AppLinks.requestReview,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: Text(loc?.translate('app_share') ?? 'Share'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => AppLinks.share(
                    loc?.translate('app_share_text') ??
                        'DoctorFilter — a blue light filter that shows you the real numbers.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _export(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context);
    final ok = await SettingsBackup.export(
      config: ref.read(filterConfigProvider),
      presets: ref.read(presetProvider).presets,
    );
    if (!context.mounted) return;
    _toast(
      context,
      ok
          ? loc?.translate('backup_exported') ?? 'Backup created.'
          : loc?.translate('backup_failed') ?? 'The backup could not be created.',
    );
  }

  static Future<void> _import(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context);
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    final file = picked?.files.singleOrNull;
    if (file == null) return;

    // withData is honoured on Android and iOS; on desktop the bytes can come
    // back null and only the path is set.
    final json = file.bytes != null
        ? String.fromCharCodes(file.bytes!)
        : file.path != null
            ? await File(file.path!).readAsString()
            : null;

    final ok = json != null &&
        await SettingsBackup.import(
          json: json,
          preferences: ref.read(preferencesDataSourceProvider),
          database: ref.read(databaseHelperProvider),
        );

    if (ok) {
      await ref.read(filterProvider.notifier).reload();
      await ref.read(presetProvider.notifier).load();
    }
    if (!context.mounted) return;
    _toast(
      context,
      ok
          ? loc?.translate('backup_imported') ?? 'Settings restored.'
          : loc?.translate('backup_import_failed') ??
              'That file could not be read.',
    );
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  static String _languageName(String code) {
    for (final language in AppLocalizations.supportedLanguages) {
      if (language.code == code) {
        return '${language.nativeName} (${language.englishName})';
      }
    }
    return code.toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text,
        style: context.texts.labelLarge?.copyWith(
          color: context.colours.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Card(
      margin: EdgeInsets.zero,
      // primaryContainer / onPrimaryContainer rather than a hand-picked amber:
      // the old card used a fixed dark-mode accent with white text on it, which
      // in light mode was white on pale orange and effectively invisible.
      color: context.colours.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 34,
                color: context.colours.onPrimaryContainer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc?.translate('pro_title') ?? 'DoctorFilter Pro',
                      style: context.texts.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colours.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc?.translate('pro_subtitle') ??
                          'One payment. No subscription.',
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colours.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colours.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
