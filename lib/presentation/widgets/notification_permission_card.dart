import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';

/// Shown on Android while the app may not post notifications.
///
/// Android 13+ asks for this at runtime. Without it the filter still runs, but
/// the notification cockpit — the controls in the shade — never appears, so the
/// user loses a feature without being told why. Rechecked on every resume, so it
/// disappears as soon as the permission is granted in the system settings.
class NotificationPermissionCard extends ConsumerStatefulWidget {
  const NotificationPermissionCard({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  @override
  ConsumerState<NotificationPermissionCard> createState() =>
      _NotificationPermissionCardState();
}

class _NotificationPermissionCardState
    extends ConsumerState<NotificationPermissionCard> with WidgetsBindingObserver {
  // Assume enabled until the platform answers, so the card never flashes.
  bool _enabled = true;

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (!_isAndroid) return;
    final enabled =
        await ref.read(platformChannelDataSourceProvider).areNotificationsEnabled();
    if (mounted && enabled != _enabled) setState(() => _enabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAndroid || _enabled) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context);
    final accent = context.colours.primary;

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_off_rounded, color: accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc?.translate('permission_notif_title') ?? 'Notifications are off',
                  style: context.texts.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc?.translate('permission_notif_desc') ??
                      'Allow notifications to control the filter from the '
                          'notification shade and lock screen.',
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colours.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => ref
                      .read(platformChannelDataSourceProvider)
                      .requestNotificationPermission(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    loc?.translate('permission_notif_btn') ?? 'Allow notifications',
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
