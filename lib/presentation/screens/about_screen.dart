import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/presentation/services/app_links.dart';

/// About the app.
///
/// Written for the person using it, not the person who built it. The previous
/// version told the user the app was a "Clean Architecture Build", which means
/// nothing to them and answers none of the questions they might actually have:
/// what does it do, can I trust the numbers, does it send anything anywhere.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (_) {
      // Version is nice to have, not worth an error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc?.translate('app_about') ?? 'About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.visibility_rounded,
                  size: 56,
                  color: context.colours.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  'DoctorFilter',
                  style: context.texts.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_version.isNotEmpty)
                  Text(
                    loc?.translate('app_version', args: {'version': _version}) ??
                        'Version $_version',
                    style: context.texts.bodySmall
                        ?.copyWith(color: context.colours.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _Section(
            title: loc?.translate('about_what_title') ?? 'What DoctorFilter does',
            body: loc?.translate('about_what_body') ??
                'DoctorFilter lays a warm, dimmable tint over your screen.',
          ),
          _Section(
            title: loc?.translate('about_science_title') ??
                'How the numbers are worked out',
            body: loc?.translate('about_science_body') ?? '',
          ),
          _Section(
            title: loc?.translate('about_privacy_title') ?? 'Privacy',
            body: loc?.translate('about_privacy_body') ?? '',
          ),
          _Section(
            title: loc?.translate('about_open_source_title') ?? 'Open source',
            body: loc?.translate('about_open_source_body') ?? '',
          ),

          // Sources, with the licence beside them: the claim and the way to
          // check it belong in the same place.
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded),
                  title: Text(loc?.translate('about_sources_title') ?? 'Sources'),
                  subtitle: Text(
                    loc?.translate('edu_sources_note') ??
                        'Brown et al. 2022 · Nagare et al. 2019 · Singh et al. 2023 · CIE S 026',
                    style: context.texts.bodySmall,
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: Text(loc?.translate('about_source_code') ?? 'Source code'),
                  subtitle: const Text('github.com/XPersPective/doctorfilter'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => AppLinks.openUrl(AppLinks.repository),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.gavel_rounded),
                  title: Text(loc?.translate('about_licence') ?? 'Licence'),
                  subtitle: const Text('GPL-3.0'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => AppLinks.openUrl(
                    '${AppLinks.repository}/blob/master/LICENSE',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _Disclaimer(loc: loc),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    if (body.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.texts.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: context.texts.bodyMedium?.copyWith(
              color: context.colours.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// The medical disclaimer.
///
/// Given its own bordered block rather than buried in a paragraph: the app makes
/// claims about light and sleep, and the boundary of those claims should be as
/// easy to find as the claims themselves.
class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.loc});

  final AppLocalizations? loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colours.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colours.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: context.colours.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                loc?.translate('about_disclaimer_title') ?? 'Please note',
                style: context.texts.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc?.translate('about_disclaimer_body') ??
                'DoctorFilter is not a medical device. It does not diagnose, treat '
                    'or prevent any condition.',
            style: context.texts.bodySmall?.copyWith(
              color: context.colours.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
