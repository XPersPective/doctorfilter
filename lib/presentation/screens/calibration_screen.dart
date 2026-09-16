import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';
import 'package:doctorfilter/presentation/providers/filter_provider.dart';

/// One-time white-point correction for the panel in the user's hand.
///
/// Panels are not their nominal white point: OLED and LCD differ, and every
/// manufacturer tunes its own tint on top. Without this the app's "2700 K" is
/// 2700 K in the arithmetic and something else on the glass — which for an app
/// that puts its numbers on screen is the difference between being precise and
/// being honest.
///
/// The correction changes what the panel is asked to emit, not the setting. The
/// melanopic and blue-light figures stay based on the value the user chose,
/// because correcting a screen that runs cool is not the same as changing the
/// setting.
class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  static const int _range = 400;

  late int _offset = ref.read(preferencesDataSourceProvider).calibrationOffsetK();

  @override
  void dispose() {
    // Whatever the overlay was showing during the preview has to go back to the
    // user's real configuration, saved or not.
    final filter = ref.read(filterConfigProvider);
    if (filter.isEnabled) {
      ref.read(filterRepositoryProvider).applyToPlatform(filter);
    }
    super.dispose();
  }

  Future<void> _preview(int offset) async {
    setState(() => _offset = offset);
    await ref.read(preferencesDataSourceProvider).setCalibrationOffsetK(offset);

    // Live, because the whole point is comparing the reference card against the
    // real screen; a correction you can only judge after leaving the screen is
    // not a correction anyone will get right.
    final filter = ref.read(filterConfigProvider);
    if (filter.isEnabled) {
      await ref.read(filterRepositoryProvider).applyToPlatform(filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isFilterOn = ref.watch(filterConfigProvider).isEnabled;

    // What 6500 K looks like once the correction is applied — the reference the
    // user compares against a sheet of paper.
    final reference = KelvinEngine.kelvinToRgb(
      (KelvinEngine.maxKelvin + _offset)
          .clamp(KelvinEngine.minKelvin, KelvinEngine.maxKelvin),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('calibration_title') ?? 'Calibrate screen'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            loc?.translate('calibration_intro') ??
                'Hold a sheet of white paper next to your screen in the light '
                    'you normally use. Adjust until the panel below looks like '
                    'the paper.',
            style: context.texts.bodyMedium,
          ),
          const SizedBox(height: 20),

          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, reference.r, reference.g, reference.b),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colours.outlineVariant),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Text(
                loc?.translate('calibration_warmer') ?? 'Warmer',
                style: context.texts.labelSmall
                    ?.copyWith(color: context.colours.onSurfaceVariant),
              ),
              Expanded(
                child: Slider(
                  value: _offset.toDouble(),
                  min: -_range.toDouble(),
                  max: _range.toDouble(),
                  // 25 K steps: finer than the eye can judge against paper, and
                  // coarse enough that the slider settles where it is put.
                  divisions: (_range * 2) ~/ 25,
                  label: ltrIsolate('${_offset > 0 ? '+' : ''}$_offset K'),
                  onChanged: (value) => _preview(value.round()),
                ),
              ),
              Text(
                loc?.translate('calibration_cooler') ?? 'Cooler',
                style: context.texts.labelSmall
                    ?.copyWith(color: context.colours.onSurfaceVariant),
              ),
            ],
          ),

          Center(
            child: Text(
              _offset == 0
                  ? loc?.translate('calibration_none') ?? 'No correction'
                  : ltrIsolate('${_offset > 0 ? '+' : ''}$_offset K'),
              style: context.texts.titleMedium,
            ),
          ),

          if (!isFilterOn) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: context.colours.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc?.translate('calibration_filter_off') ??
                        'Turn the filter on to see the correction on the real '
                            'screen rather than just on this card.',
                    style: context.texts.bodySmall
                        ?.copyWith(color: context.colours.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: _offset == 0 ? null : () => _preview(0),
              child: Text(loc?.translate('action_reset') ?? 'Reset'),
            ),
          ),
        ],
      ),
    );
  }
}
