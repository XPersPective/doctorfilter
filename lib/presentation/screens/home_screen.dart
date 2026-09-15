import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/domain/entities/ad_policy.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/presentation/ads/banner_ad_widget.dart';
import 'package:doctorfilter/presentation/providers/ad_providers.dart';
import 'package:doctorfilter/presentation/providers/filter_provider.dart';
import 'package:doctorfilter/presentation/providers/notification_sync_provider.dart';
import 'package:doctorfilter/presentation/providers/preset_provider.dart';
import 'package:doctorfilter/presentation/providers/pro_provider.dart';
import 'package:doctorfilter/presentation/widgets/axis_slider.dart';
import 'package:doctorfilter/presentation/widgets/overlay_permission_banner.dart';
import 'package:doctorfilter/presentation/widgets/power_button.dart';
import 'package:doctorfilter/presentation/widgets/preset_grid.dart';
import 'package:doctorfilter/presentation/widgets/spectrum_slider.dart';
import 'education_screen.dart';
import 'presets_screen.dart';
import 'scheduler_screen.dart';
import 'settings_screen.dart';

/// The control screen.
///
/// Laid out so everything fits without scrolling on a normal phone: the power
/// control sits in the app bar rather than as a large circle in the body, the
/// presets are a grid instead of a carousel that hid most of them, and the
/// colour slider is drawn on the spectrum rather than beside it. The banner
/// keeps its place at the bottom.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterProvider);
    final filter = ref.read(filterProvider.notifier);
    final presets = ref.watch(presetProvider).presets;
    final loc = AppLocalizations.of(context);
    final config = filterState.config;

    // Keeps the notification's copy of the preset list current.
    ref.watch(notificationCatalogSyncProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: _Title(isPro: ref.watch(isProProvider)),
        actions: [
          if (filterState.canUndo)
            IconButton(
              tooltip: loc?.translate('action_undo') ?? 'Undo',
              icon: const Icon(Icons.undo_rounded),
              onPressed: filter.undo,
            ),
          IconButton(
            tooltip: loc?.translate('nav_settings') ?? 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _open(context, const SettingsScreen()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            if (!filterState.hasOverlayPermission)
              OverlayPermissionBanner(
                onGrantPressed: filter.requestPermission,
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  PowerButton(
                    isActive: config.isEnabled,
                    isLoading: filterState.isBusy,
                    label: config.isEnabled
                        ? (loc?.translate('filter_active') ?? 'Filter on')
                        : (loc?.translate('filter_inactive') ?? 'Filter off'),
                    onTap: () => _toggle(context, ref),
                  ),
                  const SizedBox(width: 12),
                  // Flexible, not Spacer: the caption is a full sentence and in
                  // a longer language it will not fit beside the button.
                  Expanded(child: _MelanopicBadge(config: config)),
                ],
              ),
            ),

            if (config.isColourOnly && config.isEnabled)
              _ColourOnlyHint(loc: loc),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PresetGrid(
                presets: presets,
                activePresetId: config.activePresetId,
                onReorder: ref.read(presetProvider.notifier).reorder,
                onSelected: (id) {
                  ref.read(adPolicyProvider.notifier).recordPresetChange();
                  ref.read(presetProvider.notifier).select(id);
                },
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SpectrumSlider(
                kelvin: config.kelvin,
                onChanged: filter.setKelvin,
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AxisSlider(
                label: loc?.translate('density_label') ?? 'Filter density',
                value: config.densityPercent,
                max: FilterConfig.maxDensityPercent,
                icon: Icons.opacity_rounded,
                onChanged: filter.setDensity,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AxisSlider(
                label: loc?.translate('extra_dim_label') ?? 'Extra dim',
                hint: loc?.translate('extra_dim_hint'),
                value: config.extraDimPercent,
                max: FilterConfig.maxExtraDimPercent,
                icon: Icons.brightness_medium_rounded,
                onChanged: filter.setExtraDim,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          NavigationBar(
            selectedIndex: 0,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.tune_outlined),
                selectedIcon: const Icon(Icons.tune_rounded),
                label: loc?.translate('nav_home') ?? 'Home',
              ),
              NavigationDestination(
                icon: const Icon(Icons.palette_outlined),
                selectedIcon: const Icon(Icons.palette_rounded),
                label: loc?.translate('nav_presets') ?? 'Presets',
              ),
              NavigationDestination(
                icon: const Icon(Icons.schedule_outlined),
                selectedIcon: const Icon(Icons.schedule_rounded),
                label: loc?.translate('nav_schedule') ?? 'Schedule',
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book_rounded),
                label: loc?.translate('nav_education') ?? 'Eye health',
              ),
            ],
            onDestinationSelected: (index) => switch (index) {
              1 => _openPresets(context, ref),
              2 => _open(context, const SchedulerScreen()),
              3 => _open(context, const EducationScreen()),
              _ => null,
            },
          ),
        ],
      ),
    );
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  /// Leaving the presets screen is one of the few natural pause points where an
  /// ad interrupts nothing.
  static Future<void> _openPresets(BuildContext context, WidgetRef ref) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const PresetsScreen()),
    );
    await _maybeShowAd(ref, AdMoment.leftPresets);
  }

  static Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final wasEnabled = ref.read(filterProvider).config.isEnabled;
    await ref.read(filterProvider.notifier).toggle();

    final state = ref.read(filterProvider);
    if (state.errorKey != null && context.mounted) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc?.translate(state.errorKey!) ??
                'The filter could not be started.',
          ),
        ),
      );
      return;
    }

    // Turning it off is the user saying they are done for now.
    if (wasEnabled && !state.config.isEnabled) {
      await _maybeShowAd(ref, AdMoment.filterDisabled);
    }
  }

  static Future<void> _maybeShowAd(WidgetRef ref, AdMoment moment) async {
    final policy = ref.read(adPolicyProvider.notifier);
    if (!policy.mayShowInterstitial(moment)) return;

    // Recorded only if one actually appeared, so a failed load does not silently
    // spend the user's next eligible slot.
    final shown = await ref.read(interstitialAdManagerProvider).show();
    if (shown) policy.recordInterstitialShown();
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DoctorFilter',
          style: context.texts.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (isPro) ...[
          const SizedBox(width: 4),
          // Superscript, the way a trademark sits: a badge the owner notices and
          // nobody else has to read.
          Transform.translate(
            offset: const Offset(0, -2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: context.colours.primary,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'PRO',
                style: context.texts.labelSmall?.copyWith(
                  color: context.colours.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The headline number: how much circadian light the current settings remove.
class _MelanopicBadge extends StatelessWidget {
  const _MelanopicBadge({required this.config});

  final FilterConfig config;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final percent = (config.melanopicReduction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$percent%',
          style: context.texts.headlineSmall?.copyWith(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: context.colours.primary,
          ),
        ),
        Text(
          loc?.translate('melanopic_reduction', args: {'percent': '$percent'}) ??
              '$percent% less circadian light',
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.texts.bodySmall?.copyWith(
            color: context.colours.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Nudge for the configuration that feels protective but mostly is not.
class _ColourOnlyHint extends StatelessWidget {
  const _ColourOnlyHint({required this.loc});

  final AppLocalizations? loc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: context.colours.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loc?.translate('colour_only_warning') ??
                  'Warming alone does little. Add some extra dim for a real effect.',
              style: context.texts.bodySmall?.copyWith(
                color: context.colours.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
