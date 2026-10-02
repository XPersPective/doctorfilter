import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/config/env_config.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/data/repositories/other_apps_repository.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';
import 'package:doctorfilter/presentation/services/app_links.dart';

const _ownPackage = 'com.crazypenguin.doctorfilter';

final otherAppsProvider = FutureProvider<List<OtherApp>>((ref) {
  return OtherAppsRepository(
    url: EnvConfig.otherAppsUrl,
    prefs: ref.watch(sharedPreferencesProvider),
  ).load(ownPackage: _ownPackage);
});

/// "Discover our other apps": the developer's catalogue, read from GitHub.
///
/// Promotion only — opening a store page earns nothing and unlocks nothing.
/// The list comes from a public `apps.json`, so adding an app to every app's
/// Discover tab is a commit there, not a release here.
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  static bool get _isIos => Platform.isIOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final apps = ref.watch(otherAppsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(loc?.translate('discover_title') ?? 'Discover our apps')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(otherAppsProvider.future),
        child: apps.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _Empty(loc: loc),
          data: (list) => list.isEmpty
              ? _Empty(loc: loc)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                      child: Text(
                        loc?.translate('discover_intro') ??
                            'Other apps from the same developer.',
                        style: context.texts.bodyMedium?.copyWith(
                          color: context.colours.onSurfaceVariant,
                        ),
                      ),
                    ),
                    for (final app in list) ...[
                      _AppCard(app: app, lang: lang, isIos: _isIos, loc: loc),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.app, required this.lang, required this.isIos, this.loc});

  final OtherApp app;
  final String lang;
  final bool isIos;
  final AppLocalizations? loc;

  @override
  Widget build(BuildContext context) {
    final url = app.storeUrl(isIos: isIos);
    final scheme = context.colours;
    final open = url == null ? null : () => AppLinks.openUrl(url);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: app.iconUrl == null
                      ? _placeholder(scheme)
                      : Image.network(
                          app.iconUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder(scheme),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.nameIn(lang),
                      style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.descriptionIn(lang),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (open != null) ...[
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: open,
                        icon: Icon(isIos ? Icons.apple : Icons.shop_rounded, size: 18),
                        label: Text(
                          isIos
                              ? (loc?.translate('discover_get_ios') ?? 'View on the App Store')
                              : (loc?.translate('discover_get_android') ?? 'View on Google Play'),
                        ),
                        style: FilledButton.styleFrom(minimumSize: const Size(48, 40)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _placeholder(ColorScheme scheme) => ColoredBox(
        color: scheme.primaryContainer,
        child: Icon(Icons.apps_rounded, color: scheme.primary, size: 32),
      );
}

/// Shown while the catalogue is empty or unreachable — never an error screen.
class _Empty extends StatelessWidget {
  const _Empty({this.loc});

  final AppLocalizations? loc;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colours;
    // A ListView so pull-to-refresh still works on the empty state.
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        Icon(Icons.rocket_launch_rounded, size: 56, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          loc?.translate('discover_empty') ?? 'More apps are on the way.',
          textAlign: TextAlign.center,
          style: context.texts.titleMedium,
        ),
        if (!Platform.isIOS) ...[
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => AppLinks.openUrl(EnvConfig.developerPlayPage),
              icon: const Icon(Icons.shop_rounded, size: 18),
              label: Text(loc?.translate('discover_all') ?? 'All our apps on Google Play'),
            ),
          ),
        ],
      ],
    );
  }
}
