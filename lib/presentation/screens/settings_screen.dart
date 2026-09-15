import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/presentation/providers/filter_provider.dart';
import 'package:doctorfilter/presentation/providers/pro_provider.dart';
import 'package:doctorfilter/presentation/providers/theme_and_locale_provider.dart';
import 'package:doctorfilter/presentation/services/app_links.dart';
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
