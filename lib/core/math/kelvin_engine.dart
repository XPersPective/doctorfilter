import 'dart:math' as math;

/// Represents a Kelvin color temperature safety rating according to
/// circadian rhythm and melatonin suppression scientific studies.
enum MelatoninSafetyLevel {
  /// < 2500K: Minimal to zero melatonin suppression. Ideal for nighttime and bedtime.
  safeBedtime,

  /// 2500K - 4500K: Warm and soothing light. Suitable for relaxing evenings.
  relaxingEvening,

  /// 4500K - 5500K: Balanced light for indoor daytime reading and study.
  balancedDaylight,

  /// > 5500K: High-energy visible (HEV) blue light. Suppresses melatonin; day use only.
  highBlueLightRisk,
}

/// High-precision mathematical engine for Kelvin color temperature conversions,
/// CIE 1931 xy chromaticity, and Correlated Color Temperature (CCT) estimations.
abstract final class KelvinEngine {
  /// Supported minimum Kelvin for eye protection filters.
  static const int minKelvin = 1000;

  /// Supported maximum Kelvin for eye protection filters.
  static const int maxKelvin = 7000;

  /// Standard reference daylight (D65).
  static const int standardDaylightKelvin = 6500;

  /// Converts a Kelvin color temperature into 8-bit RGB components (0-255)
  /// using Tanner Helland's Planckian locus approximation algorithm.
  ///
  /// Returns a Dart 3 Record `(int r, int g, int b)`.
  static ({int r, int g, int b}) kelvinToRgb(int kelvin) {
    final clampedKelvin = kelvin.clamp(minKelvin, maxKelvin);
    final temp = clampedKelvin / 100.0;

    double red;
    double green;
    double blue;

    // Calculate Red
    if (temp <= 66.0) {
      red = 255.0;
    } else {
      red = temp - 60.0;
      red = 329.698727446 * math.pow(red, -0.1332047592);
    }

    // Calculate Green
    if (temp <= 66.0) {
      green = temp;
      green = 99.4708025861 * math.log(green) - 161.1195681661;
    } else {
      green = temp - 60.0;
      green = 288.1221695283 * math.pow(green, -0.0755148492);
    }

    // Calculate Blue
    if (temp >= 66.0) {
      blue = 255.0;
    } else if (temp <= 19.0) {
      blue = 0.0;
    } else {
      blue = temp - 10.0;
      blue = 138.5177312231 * math.log(blue) - 305.0447927307;
    }

    return (
      r: red.clamp(0.0, 255.0).round(),
      g: green.clamp(0.0, 255.0).round(),
      b: blue.clamp(0.0, 255.0).round(),
    );
  }

  /// Calculates the Correlated Color Temperature (CCT) in Kelvin from RGB values
  /// using CIE 1931 xy chromaticity coordinates and McCamy's empirical formula.
  ///
  /// Returns estimated Kelvin (1000 - 15000), or `null` if calculation is out of bounds.
  static int? rgbToKelvin(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) return null;

    // 1. Gamma expansion (sRGB -> Linear RGB)
    double linearize(int channel) {
      final v = channel / 255.0;
      return (v > 0.04045) ? math.pow((v + 0.055) / 1.055, 2.4).toDouble() : (v / 12.92);
    }

    final rLin = linearize(r);
    final gLin = linearize(g);
    final bLin = linearize(b);

    // 2. Convert to CIE 1931 XYZ
    final xX = (rLin * 0.4124) + (gLin * 0.3576) + (bLin * 0.1805);
    final yY = (rLin * 0.2126) + (gLin * 0.7152) + (bLin * 0.0722);
    final zZ = (rLin * 0.0193) + (gLin * 0.1192) + (bLin * 0.9505);

    final sumXYZ = xX + yY + zZ;
    if (sumXYZ <= 0.0 || !sumXYZ.isFinite) return null;

    // 3. Chromaticity coordinates
    final x = xX / sumXYZ;
    final y = yY / sumXYZ;

    final denominator = 0.1858 - y;
    if (denominator.abs() < 1e-6) return null;

    // 4. McCamy's approximation
    final n = (x - 0.3320) / denominator;
    final cct = (437 * math.pow(n, 3)) +
        (3601 * math.pow(n, 2)) +
        (6861 * n) +
        5517;

    if (!cct.isFinite || cct < 500 || cct > 20000) {
      return null;
    }

    return cct.round();
  }

  /// Categorizes a Kelvin color temperature into its biological melatonin impact.
  static MelatoninSafetyLevel getSafetyLevel(int kelvin) {
    if (kelvin < 2500) {
      return MelatoninSafetyLevel.safeBedtime;
    } else if (kelvin < 4500) {
      return MelatoninSafetyLevel.relaxingEvening;
    } else if (kelvin < 5500) {
      return MelatoninSafetyLevel.balancedDaylight;
    } else {
      return MelatoninSafetyLevel.highBlueLightRisk;
    }
  }

  /// Calculates estimated percentage of harmful high-energy blue light blocked (0% - 100%).
  static double calculateBlueLightBlockedPercentage(int kelvin, int opacityPercent) {
    final clampedK = kelvin.clamp(minKelvin, 6500);
    // As kelvin decreases from 6500K to 1000K, blue spectral energy decreases
    final spectralBlueFactor = 1.0 - ((clampedK - minKelvin) / (6500 - minKelvin));
    final opacityFactor = (opacityPercent.clamp(0, 100)) / 100.0;

    final blocked = (spectralBlueFactor * 0.8 + opacityFactor * 0.2) * 100.0;
    return blocked.clamp(0.0, 99.0);
  }
}
