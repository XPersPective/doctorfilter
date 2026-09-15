import 'package:flutter/material.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

/// The name and colour of the circadian band a colour temperature falls in.
///
/// One place, because the band appears on the spectrum slider and on the home
/// screen's ring, and two copies of a switch like this drift: one of them ends
/// up calling 3000 K "evening" while the other still says "balanced".
({String label, Color colour}) bandStyle(BuildContext context, int kelvin) {
  final loc = AppLocalizations.of(context);

  return switch (KelvinEngine.safetyLevel(kelvin)) {
    MelatoninSafetyLevel.sleepFriendly => (
        label: loc?.translate('band_sleep_friendly') ?? 'Sleep friendly',
        colour: context.bands.sleepFriendly,
      ),
    MelatoninSafetyLevel.evening => (
        label: loc?.translate('band_evening') ?? 'Evening',
        colour: context.bands.evening,
      ),
    MelatoninSafetyLevel.balanced => (
        label: loc?.translate('band_balanced') ?? 'Balanced',
        colour: context.bands.balanced,
      ),
    MelatoninSafetyLevel.blueLightRisk => (
        label: loc?.translate('band_blue_risk') ?? 'Bright, daytime only',
        colour: context.bands.blueRisk,
      ),
  };
}
