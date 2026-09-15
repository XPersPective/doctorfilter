import 'dart:math' as math;

/// Circadian impact band of a colour temperature.
///
/// Thresholds follow melanopsin/ipRGC sensitivity, which peaks near 480 nm: the
/// higher the CCT, the larger the short-wavelength share of the spectrum and the
/// stronger the evening melatonin suppression.
enum MelatoninSafetyLevel {
  /// < 2700 K — deep amber. Bedtime friendly.
  sleepFriendly,

  /// 2700–4000 K — warm white. Comfortable for the evening.
  evening,

  /// 4000–5000 K — neutral white. Balanced indoor daytime use.
  balanced,

  /// > 5000 K — daylight white, significant blue content. Daytime only.
  blueLightRisk,
}

/// CIE 1931 chromaticity coordinates.
typedef Chromaticity = ({double x, double y});

/// 8-bit sRGB triple.
typedef Rgb = ({int r, int g, int b});

/// Linear-light sRGB triple (0.0–1.0 per channel).
typedef LinearRgb = ({double r, double g, double b});

/// Colour-science engine behind the screen filter.
///
/// Forward (Kelvin → tint): Planckian locus (Kim et al., 2002 piecewise cubic fit
/// of the blackbody curve in CIE 1931) → CIE XYZ → linear sRGB (D65) → sRGB gamma.
///
/// Reverse (tint → Kelvin): sRGB → linear → XYZ → CIE 1960 UCS → nearest point
/// on the Planckian locus (the definition of CCT).
///
/// Both directions are round-trip tested: the app shows the user a Kelvin number
/// and must not fabricate it.
abstract final class KelvinEngine {
  /// Lowest supported colour temperature.
  ///
  /// The Kim et al. fit is only defined from 1667 K up, and nothing the app models
  /// is colder — a candle flame sits near 1850 K. 1700 K is the honest floor.
  static const int minKelvin = 1700;

  /// Highest supported colour temperature (CIE standard illuminant D65).
  static const int maxKelvin = 6500;

  /// Reference daylight white point — the "no warming applied" anchor.
  static const int neutralDaylightKelvin = 6500;

  // --- Forward: Kelvin -> chromaticity -> sRGB ------------------------------

  /// CIE 1931 (x, y) chromaticity of a Planckian (blackbody) radiator.
  ///
  /// Kim, Y. et al. (2002). Accurate to ~0.0005 in (x, y) over 1667–25000 K.
  static Chromaticity planckianChromaticity(int kelvin) {
    final t = kelvin.clamp(1667, 25000).toDouble();
    final t2 = t * t;
    final t3 = t2 * t;

    final double x;
    if (t <= 4000) {
      x = -0.2661239e9 / t3 - 0.2343589e6 / t2 + 0.8776956e3 / t + 0.179910;
    } else {
      x = -3.0258469e9 / t3 + 2.1070379e6 / t2 + 0.2226347e3 / t + 0.240390;
    }

    final x2 = x * x;
    final x3 = x2 * x;

    final double y;
    if (t <= 2222) {
      y = -1.1063814 * x3 - 1.34811020 * x2 + 2.18555832 * x - 0.20219683;
    } else if (t <= 4000) {
      y = -0.9549476 * x3 - 1.37418593 * x2 + 2.09137015 * x - 0.16748867;
    } else {
      y = 3.0817580 * x3 - 5.87338670 * x2 + 3.75112997 * x - 0.37001483;
    }

    return (x: x, y: y);
  }

  /// Screen tint colour for a target temperature, in linear light (0.0–1.0).
  ///
  /// Normalised so the brightest channel is 1.0: the tint carries only the *hue*
  /// of the target blackbody. How strongly it is applied is the separate density
  /// axis — without normalisation a warm tint would also darken the screen and
  /// the density slider would mean two things at once.
  static LinearRgb kelvinToLinearRgb(int kelvin) {
    final (:x, :y) = planckianChromaticity(kelvin);
    if (y <= 0) return (r: 1.0, g: 1.0, b: 1.0);

    // Chromaticity -> CIE XYZ at unit luminance.
    final xX = x / y;
    const yY = 1.0;
    final zZ = (1.0 - x - y) / y;

    // CIE XYZ -> linear sRGB (IEC 61966-2-1, D65 white point).
    var r = 3.2404542 * xX - 1.5371385 * yY - 0.4985314 * zZ;
    var g = -0.9692660 * xX + 1.8760108 * yY + 0.0415560 * zZ;
    var b = 0.0556434 * xX - 0.2040259 * yY + 1.0572252 * zZ;

    // Temperatures outside the sRGB gamut yield small negative components.
    r = math.max(0.0, r);
    g = math.max(0.0, g);
    b = math.max(0.0, b);

    final peak = math.max(r, math.max(g, b));
    if (peak <= 0) return (r: 1.0, g: 1.0, b: 1.0);

    return (r: r / peak, g: g / peak, b: b / peak);
  }

  /// Screen tint colour for a target temperature, as 8-bit sRGB.
  static Rgb kelvinToRgb(int kelvin) {
    final lin = kelvinToLinearRgb(kelvin);
    return (
      r: _encodeGamma(lin.r),
      g: _encodeGamma(lin.g),
      b: _encodeGamma(lin.b),
    );
  }

  // --- Reverse: sRGB -> chromaticity -> CCT ---------------------------------

  /// Maximum distance from the Planckian locus (in CIE 1960 UCS) at which a
  /// correlated colour temperature is still meaningful. The CIE considers CCT
  /// undefined beyond |Duv| ≈ 0.05.
  static const double _maxDuv = 0.05;

  /// Correlated colour temperature of an sRGB colour.
  ///
  /// Finds the point on the Planckian locus closest to the sample in the CIE
  /// 1960 UCS (u, v) plane — the definition of CCT — by searching the locus
  /// coarsely and then refining.
  ///
  /// McCamy's (1992) cubic approximation is the usual shortcut here and is what
  /// this engine used previously, but it is only accurate above roughly 2000 K:
  /// at 1700 K it errs by ~5%. That is precisely the bedtime range this app
  /// exists for, and the number is shown to the user, so the exact search is
  /// used instead. It costs a few hundred cheap evaluations.
  ///
  /// Returns `null` for black, or when the sample sits too far from the locus
  /// for a CCT to mean anything — the UI then shows nothing rather than
  /// inventing a number.
  static int? rgbToKelvin(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) return null;

    final rLin = _decodeGamma(r);
    final gLin = _decodeGamma(g);
    final bLin = _decodeGamma(b);

    final xX = 0.4124564 * rLin + 0.3575761 * gLin + 0.1804375 * bLin;
    final yY = 0.2126729 * rLin + 0.7151522 * gLin + 0.0721750 * bLin;
    final zZ = 0.0193339 * rLin + 0.1191920 * gLin + 0.9503041 * bLin;

    final sum = xX + yY + zZ;
    if (sum <= 0 || !sum.isFinite) return null;

    final sample = _toUcs(x: xX / sum, y: yY / sum);

    var best = _nearestOnLocus(sample, from: 1667, to: 25000, step: 100);
    best = _nearestOnLocus(
      sample,
      from: best.kelvin - 100,
      to: best.kelvin + 100,
      step: 1,
    );

    if (best.distance > _maxDuv) return null;
    return best.kelvin;
  }

  /// CIE 1931 (x, y) -> CIE 1960 UCS (u, v), the plane CCT is defined in.
  static ({double u, double v}) _toUcs({required double x, required double y}) {
    final denominator = -2 * x + 12 * y + 3;
    if (denominator.abs() < 1e-12) return (u: 0, v: 0);
    return (u: 4 * x / denominator, v: 6 * y / denominator);
  }

  static ({int kelvin, double distance}) _nearestOnLocus(
    ({double u, double v}) sample, {
    required int from,
    required int to,
    required int step,
  }) {
    var bestKelvin = from;
    var bestDistance = double.infinity;

    for (var k = from.clamp(1667, 25000); k <= to.clamp(1667, 25000); k += step) {
      final (:x, :y) = planckianChromaticity(k);
      final locus = _toUcs(x: x, y: y);
      final du = sample.u - locus.u;
      final dv = sample.v - locus.v;
      final distance = math.sqrt(du * du + dv * dv);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestKelvin = k;
      }
    }

    return (kelvin: bestKelvin, distance: bestDistance);
  }

  // --- Interpretation -------------------------------------------------------

  /// Circadian impact band of a colour temperature.
  static MelatoninSafetyLevel safetyLevel(int kelvin) {
    if (kelvin < 2700) return MelatoninSafetyLevel.sleepFriendly;
    if (kelvin < 4000) return MelatoninSafetyLevel.evening;
    if (kelvin < 5000) return MelatoninSafetyLevel.balanced;
    return MelatoninSafetyLevel.blueLightRisk;
  }

  /// Fraction of the screen's blue output the filter removes (0.0–1.0).
  ///
  /// The overlay composites as `out = screen * (1 - a) + tint * a`, so for a white
  /// screen the blue channel is transmitted at `T = (1 - a) + tintBlue * a` in
  /// linear light, and the reduction is `1 - T`. This falls straight out of how
  /// the filter actually works — it is not a marketing figure.
  ///
  /// [compositeAlpha] is the effective overlay alpha (0.0–1.0) after density and
  /// extra dimming are combined.
  static double blueLightReduction({
    required int tintKelvin,
    required double compositeAlpha,
  }) {
    final a = compositeAlpha.clamp(0.0, 1.0);
    final tintBlue = kelvinToLinearRgb(tintKelvin).b;
    return (1.0 - ((1.0 - a) + tintBlue * a)).clamp(0.0, 1.0);
  }

  /// Melanopic weighting of the three sRGB primaries.
  ///
  /// Melanopsin peaks near 480 nm, so a display's blue primary dominates its
  /// circadian effect while the red primary contributes almost nothing. These
  /// coefficients approximate the melanopic action spectrum of CIE S 026:2018
  /// convolved with the primaries of a typical LED display.
  ///
  /// They are an approximation, and a display-dependent one — which is exactly
  /// why only a *relative* reduction is ever reported to the user. The panel's
  /// own characteristics largely cancel in a before-and-after ratio, whereas an
  /// absolute melanopic lux figure would need the spectrum of the specific
  /// screen and the user's distance from it. Claiming one would be inventing a
  /// number, which is the thing this engine exists to avoid.
  static const _melanopicWeights = (r: 0.03, g: 0.39, b: 0.58);

  /// Fraction by which the filter reduces the screen's melanopic (circadian)
  /// output (0.0–1.0).
  ///
  /// This is the metric the field actually uses — melanopic equivalent daylight
  /// illuminance, CIE S 026:2018 — rather than a blue-channel proxy. Brown et
  /// al. (2022) recommend keeping melanopic EDI below 10 lx in the three hours
  /// before bed; this number says how much of the way the current settings take
  /// the user toward that.
  ///
  /// Note that dimming counts here just as much as warming does, which matches
  /// the evidence: shifting colour without lowering brightness does not
  /// meaningfully reduce melatonin suppression (Nagare et al., 2019).
  static double melanopicReduction({
    required int tintKelvin,
    required double compositeAlpha,
  }) {
    final a = compositeAlpha.clamp(0.0, 1.0);
    final tint = kelvinToLinearRgb(tintKelvin);

    // Per channel the overlay transmits (1 - a) of the screen plus a * tint.
    final transmitted = _melanopicWeights.r * ((1 - a) + tint.r * a) +
        _melanopicWeights.g * ((1 - a) + tint.g * a) +
        _melanopicWeights.b * ((1 - a) + tint.b * a);

    return (1.0 - transmitted).clamp(0.0, 1.0);
  }

  /// Fraction by which overall screen luminance is reduced (0.0–1.0).
  ///
  /// Same composite, weighted by the Rec. 709 luminance coefficients sRGB uses,
  /// so it reflects perceived dimming rather than a raw channel average.
  static double luminanceReduction({
    required int tintKelvin,
    required double compositeAlpha,
  }) {
    final a = compositeAlpha.clamp(0.0, 1.0);
    final tint = kelvinToLinearRgb(tintKelvin);
    final tintLuminance =
        0.2126729 * tint.r + 0.7151522 * tint.g + 0.0721750 * tint.b;
    return (1.0 - ((1.0 - a) + tintLuminance * a)).clamp(0.0, 1.0);
  }

  // --- sRGB transfer function (IEC 61966-2-1) -------------------------------

  static int _encodeGamma(double linear) {
    final v = linear.clamp(0.0, 1.0);
    final encoded = v <= 0.0031308
        ? v * 12.92
        : 1.055 * math.pow(v, 1 / 2.4).toDouble() - 0.055;
    return (encoded * 255).round().clamp(0, 255);
  }

  static double _decodeGamma(int channel) {
    final v = channel.clamp(0, 255) / 255.0;
    return v <= 0.04045
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }
}
