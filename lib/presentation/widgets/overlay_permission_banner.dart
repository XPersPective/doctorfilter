import 'package:flutter/material.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

/// Shown while the app lacks permission to draw over other apps.
///
/// Not dismissible, because without this permission the app cannot do the one
/// thing it exists for. It disappears by itself the moment the permission is
/// granted — the notifier rechecks on resume, which is what stops it hanging
/// around after the user has already done what it asked.
class OverlayPermissionBanner extends StatelessWidget {
  const OverlayPermissionBanner({super.key, required this.onGrantPressed});

  final VoidCallback onGrantPressed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final accent = context.colours.error;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc?.translate('permission_overlay_title') ?? 'Permission needed',
                  style: context.texts.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc?.translate('permission_overlay_desc') ??
                      'DoctorFilter needs permission to draw over other apps.',
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colours.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: onGrantPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: context.colours.onError,
                    minimumSize: const Size(48, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    loc?.translate('permission_grant_btn') ?? 'Grant permission',
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
