import 'package:flutter/material.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final topics = [
      (
        title: loc?.translate('intro_slide_title1') ?? 'What is visible light?',
        description: loc?.translate('intro_slide_description1') ??
            'Visible light spans wavelengths between 390 nm and 780 nm. High-energy blue light occupies 390 nm to 470 nm with temperatures exceeding 5000 K.',
        imageAsset: 'assets/images/intro/colorpalet.png',
        icon: Icons.light_mode_outlined,
      ),
      (
        title: loc?.translate('intro_slide_title2') ?? 'What is color temperature, Kelvin (K)?',
        description: loc?.translate('intro_slide_description2') ??
            'Color temperature is a metric of light chromaticity measured in Kelvin (K). Screens exceeding 5000 K emit substantial blue light causing ocular strain.',
        imageAsset: 'assets/images/intro/kelvinchart.png',
        icon: Icons.thermostat_rounded,
      ),
      (
        title: loc?.translate('intro_slide_title3') ?? 'Melatonin hormone to sleep...',
        description: loc?.translate('intro_slide_description3') ??
            'Melatonin regulates your sleep-wake circadian cycle. Blue light at night deceives the pineal gland into believing the sun has not yet set, causing severe sleep latency.',
        imageAsset: 'assets/images/intro/melatonin.png',
        icon: Icons.nightlight_outlined,
      ),
      (
        title: loc?.translate('intro_slide_title4') ?? 'Damages of blue light...',
        description: loc?.translate('intro_slide_description4') ??
            'Direct exposure damages photoreceptor cells in the retina due to inadequate ocular filtration. Chronic exposure is linked to macular degeneration and digital asthenopia.',
        imageAsset: 'assets/images/intro/damage.png',
        icon: Icons.warning_amber_rounded,
      ),
      (
        title: 'The 20-20-20 Rule for Digital Workers',
        description:
            'Every 20 minutes spent staring at a digital display, gaze at an object at least 20 feet (6 meters) away for 20 seconds. This relaxes the ciliary muscle and restores tear-film moisture.',
        imageAsset: 'assets/images/intro/sleep.png',
        icon: Icons.timer_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('nav_education') ?? 'Eye Health & Science'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: topics.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = topics[index];
          return Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.amberPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: AppTheme.amberPrimary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Diagram Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      item.imageAsset,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey.shade300,
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
