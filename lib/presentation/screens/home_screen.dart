import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/entities/ad_policy.dart';
import 'package:doctorfilter/presentation/ads/banner_ad_widget.dart';
import 'package:doctorfilter/presentation/providers/ad_providers.dart';
import 'package:doctorfilter/presentation/providers/filter_provider.dart';
import 'package:doctorfilter/presentation/providers/notification_sync_provider.dart';
import 'package:doctorfilter/presentation/providers/preset_provider.dart';
import 'package:doctorfilter/presentation/widgets/kelvin_dial.dart';
import 'package:doctorfilter/presentation/widgets/overlay_permission_banner.dart';
import 'package:doctorfilter/presentation/widgets/power_button.dart';
import 'package:doctorfilter/presentation/widgets/preset_carousel.dart';
import 'package:doctorfilter/presentation/widgets/subzero_slider.dart';
import 'education_screen.dart';
import 'paywall_screen.dart';
import 'presets_screen.dart';
import 'scheduler_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Shows an interstitial only if the policy allows one, and only records it
  /// as shown if one actually appeared.
  static Future<void> _maybeShowAd(WidgetRef ref, AdMoment moment) async {
    final policy = ref.read(adPolicyProvider.notifier);
    if (!policy.mayShowInterstitial(moment)) return;

    final shown = await ref.read(interstitialAdManagerProvider).show();
    if (shown) policy.recordInterstitialShown();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterProvider);
    final presetState = ref.watch(presetProvider);
    final filterNotifier = ref.read(filterProvider.notifier);
    final presetNotifier = ref.read(presetProvider.notifier);
    final loc = AppLocalizations.of(context);

    // Keeps the notification's copy of the preset list current. Watched here
    // because the home screen is alive for as long as the app is.
    ref.watch(notificationCatalogSyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/appbarlogo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) => const Icon(
                Icons.visibility_rounded,
                color: AppTheme.amberPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'DoctorFilter',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          if (filterState.canUndo)
            IconButton(
              tooltip: loc?.translate('action_undo') ?? 'Undo',
              icon: const Icon(Icons.undo_rounded),
              onPressed: filterNotifier.undo,
            ),
          IconButton(
            tooltip: 'Pro',
            icon: const Icon(Icons.workspace_premium_rounded, color: AppTheme.amberPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // Permission Banner (if not granted on Android)
            if (!filterState.hasOverlayPermission)
              OverlayPermissionBanner(
                onGrantPressed: () async {
                  await filterNotifier.requestPermission();
                },
              ),

            const SizedBox(height: 12),

            // Focal Power Button
            Center(
              child: PowerButton(
                isActive: filterState.config.isEnabled,
                isLoading: filterState.isBusy,
                onTap: () async {
                  final wasEnabled = filterState.config.isEnabled;
                  await filterNotifier.toggle();
                  if (!context.mounted) return;

                  // Turning the filter off is the user saying they are done: the
                  // one moment an ad interrupts nothing.
                  if (wasEnabled && !ref.read(filterProvider).config.isEnabled) {
                    await _maybeShowAd(ref, AdMoment.filterDisabled);
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            // Active Status text
            Center(
              child: Text(
                filterState.config.isEnabled
                    ? (loc?.translate('filter_active') ?? 'Eye Filter Active')
                    : (loc?.translate('filter_inactive') ?? 'Filter Inactive'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: filterState.config.isEnabled
                      ? AppTheme.amberPrimary
                      : Colors.grey.shade400,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Presets Header & Carousel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc?.translate('nav_presets') ?? 'Presets',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PresetsScreen()),
                      );
                    },
                    child: const Text('Manage'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            PresetCarousel(
              presets: presetState.presets,
              activePresetId: filterState.config.activePresetId,
              onPresetSelected: (id) {
                ref.read(adPolicyProvider.notifier).recordPresetChange();
                presetNotifier.select(id);
              },
            ),

            const SizedBox(height: 20),

            // Kelvin Dial & Spectrum Gauge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: KelvinDial(
                kelvin: filterState.config.kelvin,
                opacityPercent:
                    (filterState.config.compositeAlpha * 100).round(),
                onChanged: filterNotifier.setKelvin,
              ),
            ),

            const SizedBox(height: 16),

            // Subzero Brightness Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SubzeroSlider(
                title: loc?.translate('extra_dim_label') ?? 'Extra Dim',
                value: filterState.config.extraDimPercent,
                max: FilterConfig.maxExtraDimPercent,
                icon: Icons.brightness_medium_rounded,
                onChanged: filterNotifier.setExtraDim,
              ),
            ),

            const SizedBox(height: 12),

            // Density Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SubzeroSlider(
                title: loc?.translate('density_label') ?? 'Filter Density',
                value: filterState.config.densityPercent,
                max: FilterConfig.maxDensityPercent,
                icon: Icons.opacity_rounded,
                onChanged: filterNotifier.setDensity,
              ),
            ),

            const SizedBox(height: 24),
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
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
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
            label: loc?.translate('nav_education') ?? 'Eye Health',
          ),
        ],
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetsScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulerScreen()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EducationScreen()));
          }
        },
          ),
        ],
      ),
    );
  }
}
