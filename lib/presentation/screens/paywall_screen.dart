import 'package:flutter/material.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final features = [
      (
        icon: Icons.block_rounded,
        title: '100% Ad-Free Experience',
        desc: 'Zero interruptions, zero banners, clean view.',
      ),
      (
        icon: Icons.tune_rounded,
        title: 'Unlimited Custom Presets',
        desc: 'Save and name infinite custom RGB & Kelvin profiles.',
      ),
      (
        icon: Icons.wb_twilight_rounded,
        title: 'Smart Sunset/Sunrise Automation',
        desc: 'Synchronizes smoothly with solar circadian cycles.',
      ),
      (
        icon: Icons.bolt_rounded,
        title: 'Ultra Sub-Zero Engine',
        desc: 'Fine-tuned 0.5% increment density controls.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.amberPrimary.withValues(alpha: 0.15),
                  border: Border.all(color: AppTheme.amberPrimary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.amberPrimary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppTheme.amberPrimary,
                  size: 52,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                loc?.translate('pro_title') ?? 'DoctorFilter Pro',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                loc?.translate('pro_subtitle') ??
                    'Lifetime eye protection without ads and with unlimited custom profiles',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400, height: 1.4),
              ),
            ),

            const SizedBox(height: 32),

            // Feature List
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.deepNightCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.deepNightBorder),
                      ),
                      child: Icon(f.icon, color: AppTheme.amberPrimary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f.desc,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Plan Card (Lifetime)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.amberPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.amberPrimary, width: 2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lifetime Access',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pay once, enjoy forever',
                        style: TextStyle(fontSize: 12, color: AppTheme.amberSecondary),
                      ),
                    ],
                  ),
                  Text(
                    'PRO',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.amberPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Upgrade Button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('DoctorFilter Pro activated!')),
                );
                Navigator.pop(context);
              },
              child: Text(
                loc?.translate('pro_upgrade_btn') ?? 'Unlock Lifetime Access',
              ),
            ),

            const SizedBox(height: 12),

            // Restore Purchases
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchases restored successfully.')),
                  );
                },
                child: Text(
                  loc?.translate('pro_restore_btn') ?? 'Restore Purchases',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
