import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

class SubzeroSlider extends StatelessWidget {
  const SubzeroSlider({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.icon,
    this.min = 0,
    this.max = 100,
    this.unit = '%',
  });

  final String title;
  final int value;
  final ValueChanged<int> onChanged;
  final IconData icon;
  final int min;
  final int max;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppTheme.amberPrimary),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                '$value$unit',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.amberPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              activeTrackColor: AppTheme.amberPrimary,
              inactiveTrackColor: AppTheme.amberPrimary.withValues(alpha: 0.2),
              thumbColor: AppTheme.amberPrimary,
              overlayColor: AppTheme.amberPrimary.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
              min: min.toDouble(),
              max: max.toDouble(),
              onChanged: (newVal) {
                final rounded = newVal.round();
                if (rounded != value && rounded % 5 == 0) {
                  HapticFeedback.selectionClick();
                }
                onChanged(rounded);
              },
            ),
          ),
        ],
      ),
    );
  }
}
