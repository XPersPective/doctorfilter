import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';
import 'core_providers.dart';
import 'preset_provider.dart';
import 'pro_provider.dart';
import 'theme_and_locale_provider.dart';

/// How many presets a free user can reach from the notification.
///
/// One, not zero. Someone who has never felt the app switch presets from the
/// lock screen has no reason to pay for the ability to; someone who has felt it
/// once knows exactly what they would be buying. The rest stay visible with a
/// padlock so the offer is legible rather than hidden.
const int kFreeNotificationPresets = 1;

/// Keeps the native side's copy of the preset list current.
///
/// The notification is often rebuilt by a service running with no Flutter engine
/// alive — after a reboot, or once the system has reclaimed the UI process — so
/// it cannot read the database or the translation files. It gets a flattened
/// snapshot instead, pushed whenever the list, the language or the user's
/// entitlement changes.
///
/// Watch this provider once, high in the widget tree, and it keeps itself in
/// sync from then on.
final notificationCatalogSyncProvider = Provider<void>((ref) {
  final presets = ref.watch(presetProvider).presets;
  final isPro = ref.watch(isProProvider);
  final locale = ref.watch(localeProvider);

  if (presets.isEmpty) return;

  _pushCatalog(ref, presets: presets, isPro: isPro, locale: locale);
});

Future<void> _pushCatalog(
  Ref ref, {
  required List<FilterPreset> presets,
  required bool isPro,
  required Locale? locale,
}) async {
  // Loaded here rather than taken from a BuildContext: this runs outside the
  // widget tree, and AppLocalizations only needs a locale to do its job.
  final translations = AppLocalizations(locale ?? const Locale('en'));
  await translations.load();

  final entries = <Map<String, Object>>[];
  for (var index = 0; index < presets.length; index++) {
    final preset = presets[index];
    final tint = preset.tintRgb;
    entries.add({
      'id': preset.id,
      'name': preset.isCustom
          ? preset.nameKey
          : translations.translate(preset.nameKey),
      // Packed as a signed 32-bit ARGB int, which is what Android's Color is.
      'colour': _argb(tint.r, tint.g, tint.b),
      'locked': !isPro && index >= kFreeNotificationPresets,
    });
  }

  await ref.read(platformChannelDataSourceProvider).setPresetCatalog(
        presetsJson: jsonEncode(entries),
        isPro: isPro,
        labelsJson: jsonEncode(
          // Escaped because the native side formats these with String.format.
          nativeLabels((key) => translations.translate(key).replaceAll('%', '%%')),
        ),
      );
}

/// The notification, tile and widget text, keyed by Android resource name.
///
/// Values are `String.format` templates, so a literal percent sign is `%%`.
/// Built from existing app strings wherever one says the same thing, so a
/// translator never sees the same sentence twice.
Map<String, String> nativeLabels(String Function(String key) t) => {
      'notification_channel_name': t('native_channel_name'),
      'notification_channel_description': t('native_channel_desc'),
      'notification_title_active': '${t('filter_active')} · %1\$d K',
      'notification_title_paused': t('native_paused'),
      'notification_summary':
          '${t('density_label')} %1\$d%% · ${t('extra_dim_label')} %2\$d%%',
      'break_channel_name': t('settings_breaks'),
      'break_channel_description': t('native_break_channel_desc'),
      'break_title': t('native_break_title'),
      'break_body': t('settings_breaks_desc'),
      'shortcut_needs_permission': t('permission_overlay_required'),
      'notification_action_on': t('filter_turn_on'),
      'notification_action_off': t('filter_turn_off'),
      'notification_action_dimmer': t('native_dimmer'),
      'notification_action_brighter': t('native_brighter'),
      'notification_action_next_preset': t('onboarding_next'),
      'notification_pro_required': t('native_pro_required'),
      'axis_kelvin': t('kelvin_label'),
      'axis_density': t('density_label'),
      'axis_dim': t('extra_dim_label'),
      'tile_subtitle_active': '${t('native_tile_on')} · %1\$d K',
      'tile_subtitle_off': t('native_tile_off'),
      'widget_on': t('filter_active'),
      'widget_off': t('filter_inactive'),
    };

/// Opaque ARGB, sign-extended the way a Kotlin `Int` colour is.
int _argb(int r, int g, int b) {
  final packed = (0xFF << 24) | (r << 16) | (g << 8) | b;
  return packed >= 0x80000000 ? packed - 0x100000000 : packed;
}
