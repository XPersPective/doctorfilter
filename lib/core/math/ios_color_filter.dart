import 'dart:math' as math;

import 'kelvin_engine.dart';

/// Where to put the two sliders in iOS Settings → Accessibility → Display &
/// Text Size → Color Filters → Color Tint, to land on a chosen colour
/// temperature.
///
/// iOS gives no way for an app to draw over other apps, and no way to set these
/// sliders programmatically — no App Store app can do either, and section 7.2
/// forbids promising otherwise. What the app *can* do is compute where the
/// sliders should sit and show the user, once, so they never have to guess.
///
/// Both sliders are unlabelled: they have no numbers, only a position. So the
/// output here is a **fraction of the way along each slider**, which is the only
/// thing the user can actually act on.
abstract final class IosColourFilter {
  /// The hue slider spans the full colour wheel, so a fraction maps to degrees.
  static const double _hueSliderDegrees = 360.0;

  /// Slider positions for a target colour temperature.
  ///
  /// [tintFraction] mirrors the app's density axis: how strongly the tint is
  /// applied. [hueFraction] is where the warm hue itself sits on the wheel.
  static ({double hueFraction, double intensityFraction}) forKelvin(
    int kelvin, {
    int densityPercent = 100,
  }) {
    final rgb = KelvinEngine.kelvinToRgb(
      kelvin.clamp(KelvinEngine.minKelvin, KelvinEngine.maxKelvin),
    );
    final hsv = _toHsv(rgb.r / 255.0, rgb.g / 255.0, rgb.b / 255.0);

    // The tint's own saturation is how far from white the target colour is;
    // scaling it by the density axis keeps the iOS setup consistent with what
    // the same preset does on Android.
    final intensity = hsv.saturation * (densityPercent.clamp(0, 100) / 100.0);

    return (
      hueFraction: (hsv.hue / _hueSliderDegrees).clamp(0.0, 1.0),
      intensityFraction: intensity.clamp(0.0, 1.0),
    );
  }

  /// Where to put Accessibility → Reduce White Point, as a fraction.
  ///
  /// The same extra-dim axis: iOS dims below the hardware minimum exactly as
  /// the Android overlay does, so the value carries over unchanged.
  static double reduceWhitePointFraction(int extraDimPercent) =>
      (extraDimPercent / 100.0).clamp(0.0, 1.0);

  /// What the app would *say* the resulting screen is, so the wizard can show
  /// the same Kelvin reading the user picked rather than a second number.
  ///
  /// Rounded to the nearest 50 K: the sliders have no numbers on them, so the
  /// user cannot be more precise than that and pretending otherwise would be a
  /// false promise of accuracy.
  static int achievableKelvin(int kelvin) {
    final clamped = kelvin.clamp(KelvinEngine.minKelvin, KelvinEngine.maxKelvin);
    return (clamped / 50).round() * 50;
  }

  static ({double hue, double saturation}) _toHsv(double r, double g, double b) {
    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    final delta = max - min;

    if (delta == 0 || max == 0) return (hue: 0, saturation: 0);

    final double hue;
    if (max == r) {
      hue = 60 * (((g - b) / delta) % 6);
    } else if (max == g) {
      hue = 60 * (((b - r) / delta) + 2);
    } else {
      hue = 60 * (((r - g) / delta) + 4);
    }

    return (hue: hue < 0 ? hue + 360 : hue, saturation: delta / max);
  }
}
