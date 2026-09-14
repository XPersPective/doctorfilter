import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';

class PresetCarousel extends StatelessWidget {
  const PresetCarousel({
    super.key,
    required this.presets,
    required this.activePresetId,
    required this.onPresetSelected,
  });

  final List<FilterPreset> presets;
  final int activePresetId;
  final ValueChanged<int> onPresetSelected;

  static const Map<String, ({String title, IconData icon, String assetName})> _presetMeta = {
    'gunes': (title: 'Sunlight', icon: Icons.wb_sunny_rounded, assetName: 'gunes'),
    'florasan': (title: 'Fluorescent', icon: Icons.lightbulb_outline_rounded, assetName: 'florasan'),
    'lamba': (title: 'Incandescent', icon: Icons.lightbulb_rounded, assetName: 'lamba'),
    'ay': (title: 'Moonlight', icon: Icons.nightlight_round, assetName: 'ay'),
    'mum': (title: 'Candle', icon: Icons.fireplace_rounded, assetName: 'mum'),
    'kitap': (title: 'Reading', icon: Icons.menu_book_rounded, assetName: 'kitap'),
    'agac': (title: 'Forest', icon: Icons.park_rounded, assetName: 'agac'),
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final preset = presets[index];
          final isSelected = preset.id == activePresetId;
          final meta = _presetMeta[preset.iconIdentifier] ??
              (title: preset.nameKey, icon: Icons.tune_rounded, assetName: '');

          final assetPath = 'assets/images/app_nameThemeBlue/${meta.assetName}_tikli.png';

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onPresetSelected(preset.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 82,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.amberPrimary.withValues(alpha: 0.18)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.amberPrimary
                      : Theme.of(context).dividerColor.withValues(alpha: 0.15),
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.amberPrimary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image asset or Icon fallback
                  Image.asset(
                    assetPath,
                    width: 32,
                    height: 32,
                    errorBuilder: (_, _, _) => Icon(
                      meta.icon,
                      size: 28,
                      color: isSelected ? AppTheme.amberPrimary : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meta.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppTheme.amberPrimary : Colors.grey.shade300,
                    ),
                  ),
                  Text(
                    '${preset.kelvin}K',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 9,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
