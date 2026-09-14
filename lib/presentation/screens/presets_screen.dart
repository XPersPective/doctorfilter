import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/presentation/providers/preset_provider.dart';

class PresetsScreen extends ConsumerWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetState = ref.watch(presetProvider);
    final presetNotifier = ref.read(presetProvider.notifier);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('nav_presets') ?? 'Light Presets'),
        actions: [
          IconButton(
            tooltip: 'Reset to Defaults',
            icon: const Icon(Icons.restore_rounded),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset Presets'),
                  content: const Text('Restore all 7 default factory presets?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await presetNotifier.resetToDefaults();
              }
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: presetState.presets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final preset = presetState.presets[index];
          final isSelected = preset.id == presetState.activePresetId;
          final rgb = KelvinEngine.kelvinToRgb(preset.kelvin);
          final presetColor = Color.fromARGB(255, rgb.r, rgb.g, rgb.b);

          return Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.amberPrimary
                    : Theme.of(context).dividerColor.withValues(alpha: 0.15),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: presetColor,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: presetColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              title: Text(
                loc?.translate('preset_${preset.nameKey}') ?? preset.nameKey,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 15,
                  color: isSelected ? AppTheme.amberPrimary : null,
                ),
              ),
              subtitle: Text(
                '${preset.kelvin}K • Density: ${preset.alphaPercent}% • Brightness: ${preset.brightnessPercent}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.amberPrimary)
                  : ElevatedButton(
                      onPressed: () => presetNotifier.selectPreset(preset.id),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: const Size(48, 36),
                      ),
                      child: const Text('Apply', style: TextStyle(fontSize: 12)),
                    ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomPresetDialog(context, ref),
        backgroundColor: AppTheme.amberPrimary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Preset', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddCustomPresetDialog(BuildContext context, WidgetRef ref) {
    int kelvin = 3000;
    int alpha = 60;
    int brightness = 180;
    final textController = TextEditingController(text: 'My Night Profile');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final rgb = KelvinEngine.kelvinToRgb(kelvin);
            final previewColor = Color.fromARGB(255, rgb.r, rgb.g, rgb.b);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Custom Preset',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: previewColor,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Preset Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Color Temperature: $kelvin K', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: kelvin.toDouble(),
                    min: 1000,
                    max: 6500,
                    divisions: 55,
                    onChanged: (val) => setState(() => kelvin = val.round()),
                  ),
                  Text('Density: $alpha', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: alpha.toDouble(),
                    min: 10,
                    max: 220,
                    divisions: 42,
                    onChanged: (val) => setState(() => alpha = val.round()),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (textController.text.trim().isEmpty) return;
                      final rgb = KelvinEngine.kelvinToRgb(kelvin);
                      await ref.read(presetProvider.notifier).saveCustomPreset(
                            name: textController.text.trim(),
                            kelvin: kelvin,
                            red: rgb.r,
                            green: rgb.g,
                            blue: rgb.b,
                            alpha: alpha,
                            brightness: brightness,
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Preset'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
