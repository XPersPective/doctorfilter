import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/math/ios_color_filter.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/presentation/providers/filter_provider.dart';

/// Walks the user through setting iOS's own colour filter to the temperature
/// they chose here.
///
/// Apple gives no app the ability to draw over other apps, and none to move the
/// Accessibility sliders. No App Store app can do either, and section 7.2
/// forbids implying otherwise. So the app does the part it actually can: work
/// out where the two sliders belong and show the user, once, so they are not
/// left guessing at unlabelled controls.
///
/// Once set, the values stay — through leaving the app, restarting the phone,
/// even uninstalling this app. That is the point: it is a setup, not a switch.
class IosSetupScreen extends ConsumerWidget {
  const IosSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final config = ref.watch(filterConfigProvider);

    final tint = IosColourFilter.forKelvin(
      config.kelvin,
      densityPercent: config.densityPercent,
    );
    final whitePoint =
        IosColourFilter.reduceWhitePointFraction(config.extraDimPercent);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('ios_setup_title') ?? 'Set up your screen'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            loc?.translate('ios_setup_intro') ??
                'iOS has its own screen filter. This app works out the right '
                    'settings for it and shows you where to put them. You do this '
                    'once — the values stay put afterwards.',
            style: context.texts.bodyMedium,
          ),
          const SizedBox(height: 24),

          _Step(
            number: 1,
            title: loc?.translate('ios_setup_step_path') ??
                'Open Settings → Accessibility → Display & Text Size → '
                    'Colour Filters',
            body: loc?.translate('ios_setup_step_path_body') ??
                'Turn Colour Filters on and choose Colour Tint.',
          ),

          _SliderStep(
            number: 2,
            label: loc?.translate('ios_setup_hue') ?? 'Hue',
            fraction: tint.hueFraction,
          ),
          _SliderStep(
            number: 3,
            label: loc?.translate('ios_setup_intensity') ?? 'Intensity',
            fraction: tint.intensityFraction,
          ),

          if (config.extraDimPercent > 0)
            _SliderStep(
              number: 4,
              label: loc?.translate('ios_setup_white_point') ??
                  'Accessibility → Display & Text Size → Reduce White Point',
              fraction: whitePoint,
            ),

          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: context.colours.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      // The sliders carry no numbers, so a fraction is the most
                      // precise instruction that exists. Saying otherwise would
                      // promise an accuracy the control cannot give.
                      loc?.translate('ios_setup_precision') ??
                          'The iOS sliders have no numbers on them, so these are '
                              'positions along each slider rather than exact values. '
                              'Close is close enough — a few degrees either way is '
                              'not something you can see.',
                      style: context.texts.bodySmall
                          ?.copyWith(color: context.colours.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepNumber(number),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.texts.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(body, style: context.texts.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A step that shows where a slider should sit, drawn to scale.
///
/// A picture of the position is the instruction: "about a third of the way
/// along" is something a person can act on, where a number they cannot see on
/// their own screen is not.
class _SliderStep extends StatelessWidget {
  const _SliderStep({
    required this.number,
    required this.label,
    required this.fraction,
  });

  final int number;
  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final percent = (fraction * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepNumber(number),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: context.texts.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: context.texts.titleSmall
                          ?.copyWith(color: context.colours.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SliderDiagram(fraction: fraction),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderDiagram extends StatelessWidget {
  const _SliderDiagram({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const thumb = 18.0;
        final travel = (constraints.maxWidth - thumb).clamp(0.0, double.infinity);

        return SizedBox(
          height: thumb,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.colours.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                left: travel * fraction.clamp(0.0, 1.0),
                child: Container(
                  width: thumb,
                  height: thumb,
                  decoration: BoxDecoration(
                    color: context.colours.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepNumber extends StatelessWidget {
  const _StepNumber(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colours.primary.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: context.texts.labelMedium?.copyWith(
          color: context.colours.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
