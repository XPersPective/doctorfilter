import 'package:flutter/material.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

class KelvinDial extends StatelessWidget {
  const KelvinDial({
    super.key,
    required this.kelvin,
    required this.onChanged,
    this.opacityPercent = 25,
  });

  final int kelvin;
  final ValueChanged<int> onChanged;
  final int opacityPercent;

  @override
  Widget build(BuildContext context) {
    final rgb = KelvinEngine.kelvinToRgb(kelvin);
    final filterColor = Color.fromARGB(255, rgb.r, rgb.g, rgb.b);
    final safetyLevel = KelvinEngine.safetyLevel(kelvin);
    final melanopicPercent = (KelvinEngine.melanopicReduction(
              tintKelvin: kelvin,
              compositeAlpha: opacityPercent / 100.0,
            ) *
            100)
        .round();

    final (safetyText, safetyColor) = switch (safetyLevel) {
      MelatoninSafetyLevel.sleepFriendly => ('Bedtime Safe', AppTheme.safetySafe),
      MelatoninSafetyLevel.evening => ('Evening Relaxing', AppTheme.safetyRelaxed),
      MelatoninSafetyLevel.balanced => ('Balanced Daylight', AppTheme.safetyModerate),
      MelatoninSafetyLevel.blueLightRisk => ('High Blue Light Risk', AppTheme.safetyRisk),
    };

    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          // Header & Kelvin display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc?.translate('kelvin_label') ?? 'Color Temperature',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$kelvin',
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        ' K',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.amberPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Live Color Indicator Circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filterColor,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: filterColor.withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Spectrum gradient track slider
          Container(
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF3E00), // Candle flame ~1700K
                  Color(0xFFFF8B14), // Bedtime ~2000K
                  Color(0xFFFFC062), // Incandescent ~3200K
                  Color(0xFFFFE3B0), // Fluorescent ~4500K
                  Color(0xFFE2F0FF), // Daylight ~6500K
                ],
              ),
            ),
          ),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbColor: filterColor,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              overlayColor: filterColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: kelvin
                  .clamp(KelvinEngine.minKelvin, KelvinEngine.maxKelvin)
                  .toDouble(),
              min: KelvinEngine.minKelvin.toDouble(),
              max: KelvinEngine.maxKelvin.toDouble(),
              divisions: (KelvinEngine.maxKelvin - KelvinEngine.minKelvin) ~/ 100,
              onChanged: (val) => onChanged(val.round()),
            ),
          ),

          // Badges: Safety Level & Blue Light Blocked %
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: safetyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: safetyColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: safetyColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      safetyText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: safetyColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                loc?.translate('melanopic_reduction',
                        args: {'percent': '$melanopicPercent'}) ??
                    '$melanopicPercent% less circadian light',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.amberSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
