import 'package:flutter/material.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

class OverlayPermissionBanner extends StatelessWidget {
  const OverlayPermissionBanner({
    super.key,
    required this.onGrantPressed,
  });

  final VoidCallback onGrantPressed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.amberPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.amberPrimary.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.amberPrimary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc?.translate('permission_overlay_title') ?? 'Overlay Permission Required',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.amberPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc?.translate('permission_overlay_desc') ??
                      'DoctorFilter needs permission to display the eye-protective tint over other apps.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: onGrantPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.amberPrimary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(48, 36),
                  ),
                  child: Text(
                    loc?.translate('permission_grant_btn') ?? 'Grant Permission',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
