import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/presentation/providers/filter_provider.dart';
import 'package:doctorfilter/presentation/providers/theme_and_locale_provider.dart';
import 'paywall_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final filterState = ref.watch(filterProvider);
    final loc = AppLocalizations.of(context);

    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('nav_settings') ?? 'Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pro Banner Card
          Card(
            margin: EdgeInsets.zero,
            color: AppTheme.amberPrimary.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppTheme.amberPrimary, width: 1.5),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.amberPrimary,
                size: 36,
              ),
              title: Text(
                loc?.translate('pro_title') ?? 'DoctorFilter Pro',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                loc?.translate('pro_subtitle') ?? 'Ad-free and unlimited custom profiles',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(48, 36),
                ),
                child: const Text('Upgrade', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Appearance & Controls Section
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                // Language Selector
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppTheme.amberPrimary),
                  title: Text(loc?.translate('app_language') ?? 'Language'),
                  subtitle: Text(_getLanguageName(
                      currentLocale?.languageCode ??
                          Localizations.localeOf(context).languageCode)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showLanguagePicker(context, ref),
                ),
                const Divider(height: 1, indent: 56),
                // Dark Theme Toggle
                SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppTheme.amberPrimary,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Reduces eye fatigue at night'),
                  value: isDark,
                  onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                ),
                const Divider(height: 1, indent: 56),
                // Notification Bar Control Toggle
                SwitchListTile(
                  secondary: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppTheme.amberPrimary,
                  ),
                  title: const Text('Notification Bar Controls'),
                  subtitle: const Text('Show quick toggle widget in notification drawer'),
                  value: filterState.config.isNotificationEnabled,
                  onChanged: (val) {
                    ref.read(filterProvider.notifier).setNotificationEnabled(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // App Info & Version
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppTheme.amberPrimary),
                  title: Text(loc?.translate('app_about') ?? 'About'),
                  subtitle: const Text('DoctorFilter v2.0.0 (Clean Architecture Build)'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded, color: AppTheme.amberPrimary),
                  title: Text(loc?.translate('app_rate') ?? 'Rate DoctorFilter'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.share_outlined, color: AppTheme.amberPrimary),
                  title: Text(loc?.translate('app_share') ?? 'Share with Friends'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    try {
      final item = AppLocalizations.supportedLanguages.firstWhere((l) => l.code == code);
      return '${item.nativeName} (${item.englishName})';
    } catch (_) {
      return code.toUpperCase();
    }
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = AppLocalizations.supportedLanguages.where((lang) {
              final q = searchQuery.toLowerCase();
              return lang.englishName.toLowerCase().contains(q) ||
                  lang.nativeName.toLowerCase().contains(q) ||
                  lang.code.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  const Text(
                    'Select Language',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search 71 languages...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) => setState(() => searchQuery = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final lang = filtered[index];
                        final isCurrent = ref.watch(localeProvider)?.languageCode == lang.code;

                        return ListTile(
                          title: Text(
                            lang.nativeName,
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? AppTheme.amberPrimary : null,
                            ),
                          ),
                          subtitle: Text(lang.englishName),
                          trailing: isCurrent
                              ? const Icon(Icons.check_rounded, color: AppTheme.amberPrimary)
                              : null,
                          onTap: () {
                            ref.read(localeProvider.notifier).setLocale(lang.code);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
