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
      );
}

/// Opaque ARGB, sign-extended the way a Kotlin `Int` colour is.
int _argb(int r, int g, int b) {
  final packed = (0xFF << 24) | (r << 16) | (g << 8) | b;
  return packed >= 0x80000000 ? packed - 0x100000000 : packed;
}
