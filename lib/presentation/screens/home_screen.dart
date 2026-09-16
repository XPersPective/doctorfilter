import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/domain/entities/ad_policy.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/presentation/ads/banner_ad_widget.dart';
import 'package:doctorfilter/presentation/providers/ad_providers.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';
import 'package:doctorfilter/presentation/providers/bypass_provider.dart';
import 'package:doctorfilter/presentation/providers/filter_provider.dart';
import 'package:doctorfilter/presentation/providers/notification_sync_provider.dart';
import 'package:doctorfilter/presentation/providers/preset_provider.dart';
import 'package:doctorfilter/presentation/providers/pro_provider.dart';
import 'package:doctorfilter/presentation/providers/theme_and_locale_provider.dart';
import 'package:doctorfilter/presentation/widgets/axis_slider.dart';
import 'package:doctorfilter/presentation/widgets/band_style.dart';
import 'package:doctorfilter/presentation/widgets/melanopic_ring.dart';
import 'package:doctorfilter/presentation/widgets/overlay_permission_banner.dart';
import 'package:doctorfilter/presentation/widgets/power_button.dart';
import 'package:doctorfilter/presentation/widgets/preset_grid.dart';
import 'package:doctorfilter/presentation/widgets/spectrum_slider.dart';
import 'package:doctorfilter/presentation/providers/paywall_request_provider.dart';
import 'education_screen.dart';
import 'ios_setup_screen.dart';
import 'presets_screen.dart';
import 'scheduler_screen.dart';
import 'paywall_screen.dart';
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

    // The locked chips in the notification launch the app asking for the
    // paywall; without this the tap only brought the app forward, which reads
    // as the button being broken.
    ref.listen(nativePaywallRequestProvider, (_, next) {
      if (next.hasValue && context.mounted) {
        _open(context, const PaywallScreen());
      }
    });

    final bypass = ref.watch(bypassProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: _Title(isPro: ref.watch(isProProvider)),
        actions: [
          if (config.isEnabled)
            _BypassAction(
              remaining: bypass,
              onStart: ref.read(bypassProvider.notifier).start,
              onCancel: ref.read(bypassProvider.notifier).cancel,
            ),
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
            // iOS cannot draw over other apps at all, so the permission banner
            // would be asking for something that does not exist there.
            if (!_isIos && !filterState.hasOverlayPermission)
              OverlayPermissionBanner(
                onGrantPressed: filter.requestPermission,
              ),

            if (_isIos)
              _IosProtectionCard(
                isSetUp: ref.watch(iosSetupProvider),
                onOpenWizard: () => _open(context, const IosSetupScreen()),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  // No power button on iOS: there is nothing to switch. The
                  // system filter the user set up stays on until they turn it
                  // off themselves, and a button implying otherwise would be a
                  // control that does nothing.
                  if (!_isIos) ...[
                    PowerButton(
                      isActive: config.isEnabled,
                      isLoading: filterState.isBusy,
                      label: config.isEnabled
                          ? (loc?.translate('filter_active') ?? 'Filter on')
                          : (loc?.translate('filter_inactive') ?? 'Filter off'),
                      onTap: () => _toggle(context, ref),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Expanded, not Spacer: the caption is a full sentence and in
                  // a longer language it will not fit beside the button.
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final band = bandStyle(context, config.kelvin);
                        return MelanopicRing(
                          melanopicReduction: config.melanopicReduction,
                          bandColour: band.colour,
                          bandLabel: band.label,
                        );
                      },
                    ),
                  ),
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

            // Shown only to users who turned on true black, because that is the
            // only signal the app has that the panel is OLED — Android exposes
            // no panel type, and claiming a battery saving on an LCD would be
            // simply false.
            if (ref.watch(amoledProvider) && config.extraDimPercent > 0)
              _OledEnergyNote(config: config),
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

/// What the dimming is doing to the panel's power draw, stated carefully.
///
/// On an OLED panel each pixel emits its own light, so darker pixels draw less
/// current — the overlay is composited into the frame, so the pixels really do
/// end up darker. The relationship is not one-for-one (driver and controller
/// power do not scale with brightness), which is why this says "roughly" and
/// gives no figure it cannot stand behind.
class _OledEnergyNote extends StatelessWidget {
  const _OledEnergyNote({required this.config});

  final FilterConfig config;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final percent = (config.luminanceReduction * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Icon(
            Icons.battery_saver_outlined,
            size: 16,
            color: context.colours.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loc?.translate('oled_energy', args: {'percent': '$percent'}) ??
                  'Your screen is emitting about $percent% less light. On an '
                      'OLED panel its power draw falls with it, though not '
                      'exactly one-for-one.',
              style: context.texts.bodySmall
                  ?.copyWith(color: context.colours.onSurfaceVariant),
            ),
          ),
        ],
      ),
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

/// Pause-and-peek, in the app bar.
///
/// A button while the filter is running, a live countdown once it is paused —
/// same control, so nobody has to find a second one to put the filter back.
class _BypassAction extends StatelessWidget {
  const _BypassAction({
    required this.remaining,
    required this.onStart,
    required this.onCancel,
  });

  final Duration? remaining;
  final Future<void> Function() onStart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (remaining == null) {
      return IconButton(
        tooltip: loc?.translate('bypass_action') ?? 'Pause briefly',
        icon: const Icon(Icons.visibility_outlined),
        onPressed: onStart,
      );
    }

    return TextButton.icon(
      onPressed: onCancel,
      icon: const Icon(Icons.play_arrow_rounded, size: 18),
      label: Text('${remaining!.inSeconds}'),
      style: TextButton.styleFrom(
        foregroundColor: context.colours.primary,
        minimumSize: const Size(48, 44),
      ),
    );
  }
}

/// Whether this build is running on iOS, where the whole filter model differs.
///
/// A plain platform check rather than an abstraction: there are three places
/// that branch, all of them in this file, and one interface per platform for
/// that would be more machinery than the problem has.
bool get _isIos => !kIsWeb && Platform.isIOS;

/// The iOS home state: set up, or not yet.
///
/// Apple gives no app a way to read whether Colour Filters is switched on, so
/// this reflects what the user told us rather than something checked. The app
/// says which it is instead of guessing, and the button is always there to walk
/// through the settings again.
class _IosProtectionCard extends StatelessWidget {
  const _IosProtectionCard({
    required this.isSetUp,
    required this.onOpenWizard,
  });

  final bool isSetUp;
  final VoidCallback onOpenWizard;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          isSetUp ? Icons.verified_rounded : Icons.tune_rounded,
          color: isSetUp ? context.bands.sleepFriendly : context.colours.primary,
        ),
        title: Text(
          isSetUp
              ? loc?.translate('ios_protection_on') ?? 'Protection is set up'
              : loc?.translate('ios_protection_off') ??
                  'Protection is not set up yet',
          style: context.texts.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: TextButton(
          onPressed: onOpenWizard,
          child: Text(
            isSetUp
                ? loc?.translate('ios_protection_redo') ?? 'Change the settings'
                : loc?.translate('ios_protection_action') ?? 'Set it up',
          ),
        ),
      ),
    );
  }
}
