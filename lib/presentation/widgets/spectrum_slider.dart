import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

import 'band_style.dart';

/// Colour temperature control.
///
/// The slider sits *on* the spectrum it selects from, rather than beside it. The
/// previous layout stacked a gradient bar above a separate grey track, which
/// left the user picking a colour from a control that showed none of it — and
/// cost twice the vertical space for the privilege.
class SpectrumSlider extends StatelessWidget {
  const SpectrumSlider({
    super.key,
    required this.kelvin,
    required this.onChanged,
  });

  final int kelvin;
  final ValueChanged<int> onChanged;

  /// The track is painted from the engine itself, so what the user drags across
  /// is the actual output at each temperature rather than a designer's guess.
  static List<Color> _spectrum() {
    const steps = 12;
    return List.generate(steps, (index) {
      final temperature =
          KelvinEngine.minKelvin +
          ((KelvinEngine.maxKelvin - KelvinEngine.minKelvin) *
              index ~/
              (steps - 1));
      final rgb = KelvinEngine.kelvinToRgb(temperature);
      return Color.fromARGB(255, rgb.r, rgb.g, rgb.b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final rgb = KelvinEngine.kelvinToRgb(kelvin);
    final tint = Color.fromARGB(255, rgb.r, rgb.g, rgb.b);
    final band = bandStyle(context, kelvin);
    final bandLabel = band.label;
    final bandColour = band.colour;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                loc?.translate('kelvin_label') ?? 'Colour temperature',
                style: context.texts.labelLarge?.copyWith(
                  color: context.colours.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '$kelvin K',
              style: context.texts.titleMedium?.copyWith(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 22,
            trackShape: _SpectrumTrackShape(_spectrum()),
            thumbShape: _RingThumbShape(tint: tint),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            overlayColor: tint.withValues(alpha: 0.18),
          ),
          child: MergeSemantics(
            child: Semantics(
              label:
                  AppLocalizations.of(context)?.translate('kelvin_label') ??
                  'Colour temperature',
              child: Slider(
                value: kelvin
                    .clamp(KelvinEngine.minKelvin, KelvinEngine.maxKelvin)
                    .toDouble(),
                min: KelvinEngine.minKelvin.toDouble(),
                max: KelvinEngine.maxKelvin.toDouble(),
                divisions:
                    (KelvinEngine.maxKelvin - KelvinEngine.minKelvin) ~/ 50,
                label: '$kelvin K',
                semanticFormatterCallback: (value) => '${value.round()} K',
                onChanged: (value) {
                  final next = value.round();
                  if (next != kelvin) HapticFeedback.selectionClick();
                  onChanged(next);
                },
              ),
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _BandChip(label: bandLabel, colour: bandColour),
        ),
      ],
    );
  }
}

/// Paints the track as the spectrum rather than as two flat segments.
class _SpectrumTrackShape extends SliderTrackShape {
  const _SpectrumTrackShape(this.colours);

  final List<Color> colours;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final height = sliderTheme.trackHeight ?? 22;
    final width = parentBox.size.width - _horizontalPadding * 2;
    return Rect.fromLTWH(
      offset.dx + _horizontalPadding,
      offset.dy + (parentBox.size.height - height) / 2,
      width,
      height,
    );
  }

  /// Room for the thumb to sit fully inside the track at either end.
  static const double _horizontalPadding = 14;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );
    final rounded = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );

    context.canvas.drawRRect(
      rounded,
      Paint()
        ..shader = LinearGradient(
          colors: colours,
          // Mirrored in RTL so "warmer" stays on the side the language reads from.
          begin: textDirection == TextDirection.rtl
              ? Alignment.centerRight
              : Alignment.centerLeft,
          end: textDirection == TextDirection.rtl
              ? Alignment.centerLeft
              : Alignment.centerRight,
        ).createShader(rect),
    );
  }
}

/// A ring showing the selected tint, so the thumb is a preview of the choice.
class _RingThumbShape extends SliderComponentShape {
  const _RingThumbShape({required this.tint});

  final Color tint;

  static const double _radius = 13;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // A dark halo first: a pale thumb on a pale part of the spectrum would
    // otherwise vanish exactly where the daylight end needs to be grabbable.
    canvas.drawCircle(
      center,
      _radius,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawCircle(center, _radius - 2, Paint()..color = Colors.white);
    canvas.drawCircle(center, _radius - 4.5, Paint()..color = tint);
  }
}

class _BandChip extends StatelessWidget {
  const _BandChip({required this.label, required this.colour});

  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colour.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: context.texts.labelSmall?.copyWith(
          color: colour,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
