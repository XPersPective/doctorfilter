import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

/// One of the filter's percentage axes.
///
/// Label, value and track on three tight rows rather than inside a bordered
/// card: two of these plus the spectrum used to fill the screen, which left no
/// room for the presets the user came for.
class AxisSlider extends StatelessWidget {
  const AxisSlider({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.icon,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final int value;
  final int max;
  final IconData icon;
  final ValueChanged<int> onChanged;

  /// Shown under the label. Worth the line for "extra dim", which means nothing
  /// to a new user until told it goes below the hardware minimum.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: context.colours.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: context.texts.labelLarge?.copyWith(
                  color: context.colours.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '$value%',
              style: context.texts.titleMedium?.copyWith(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 26, top: 2),
            child: Text(
              hint!,
              style: context.texts.bodySmall?.copyWith(
                color: context.colours.onSurfaceVariant,
              ),
            ),
          ),
        Slider(
          value: value.toDouble().clamp(0, max.toDouble()),
          max: max.toDouble(),
          // Steps of 5: finer than anyone can perceive in one drag, and it keeps
          // the haptic from firing on every pixel.
          divisions: max ~/ 5,
          label: '$value%',
          semanticFormatterCallback: (value) => '${value.round()} percent',
          onChanged: (raw) {
            final next = raw.round();
            if (next != value) HapticFeedback.selectionClick();
            onChanged(next);
          },
        ),
      ],
    );
  }
}
