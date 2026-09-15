import 'package:doctorfilter/core/math/kelvin_engine.dart';

/// The screen filter's runtime state.
///
/// The filter has exactly three independent axes, and conflating them is what
/// made the previous model confusing and unsafe:
///
/// * [kelvin] — the *hue* of the tint, nothing else.
/// * [densityPercent] — how strongly that tint is applied.
/// * [extraDimPercent] — additional darkening, taking the screen below its
///   hardware minimum brightness. Despite reading like a cosmetic extra this is
///   the *primary* lever: shifting colour without lowering brightness does not
///   meaningfully reduce melatonin suppression (Nagare et al., 2019).
///
/// Every value is clamped in the constructor. The UI is never trusted to keep
/// the screen usable — a fully opaque overlay is a black screen the user cannot
/// escape from, so the limits live here, at the only place all callers pass
/// through.
final class FilterConfig {
  FilterConfig({
    required this.isEnabled,
    required this.activePresetId,
    required int kelvin,
    required int densityPercent,
    required int extraDimPercent,
    required this.isNotificationEnabled,
    required this.isScheduleEnabled,
  })  : kelvin = kelvin.clamp(KelvinEngine.minKelvin, KelvinEngine.maxKelvin),
        densityPercent = densityPercent.clamp(0, maxDensityPercent),
        extraDimPercent = extraDimPercent.clamp(0, maxExtraDimPercent);

  /// Strongest tint the user may apply. Beyond this the screen stops being a
  /// screen and starts being a coloured sheet of glass.
  static const int maxDensityPercent = 80;

  /// Deepest extra dimming the user may apply.
  static const int maxExtraDimPercent = 70;

  /// Hard ceiling on the composite overlay alpha.
  ///
  /// Density and dimming combine multiplicatively, so their individual caps are
  /// not enough on their own: at 80% + 70% the naive composite reaches 94%,
  /// which on a dark tint is indistinguishable from a dead screen. At 92% at
  /// least 8% of the screen always shows through.
  static const double maxCompositeAlpha = 0.92;

  /// Whether the overlay is currently running.
  final bool isEnabled;

  /// Identifier of the preset the current values came from.
  final int activePresetId;

  /// Tint colour temperature, 1700–6500 K.
  final int kelvin;

  /// Tint strength, 0–[maxDensityPercent] %.
  final int densityPercent;

  /// Extra darkening below hardware minimum, 0–[maxExtraDimPercent] %.
  final int extraDimPercent;

  /// Whether the quick-control notification is active.
  final bool isNotificationEnabled;

  /// Whether the automatic scheduler is active.
  final bool isScheduleEnabled;

  /// Effective overlay alpha (0.0–1.0) once density and dimming are combined.
  ///
  /// The two axes stack the way two filters in front of each other do: what the
  /// dimming layer removes, the density layer no longer has to. Capped by
  /// [maxCompositeAlpha].
  double get compositeAlpha {
    final density = densityPercent / 100.0;
    final dim = extraDimPercent / 100.0;
    final combined = density + dim * (1 - density);
    return combined.clamp(0.0, maxCompositeAlpha);
  }

  /// The overlay colour: the Kelvin tint, scaled toward black by the dimming
  /// axis. Returned as 8-bit sRGB, the form the platform layer draws with.
  ({int r, int g, int b}) get overlayColor {
    final tint = KelvinEngine.kelvinToRgb(kelvin);
    final scale = 1.0 - (extraDimPercent / 100.0);
    return (
      r: (tint.r * scale).round().clamp(0, 255),
      g: (tint.g * scale).round().clamp(0, 255),
      b: (tint.b * scale).round().clamp(0, 255),
    );
  }

  /// Overlay alpha as the 0–255 integer the platform layer expects.
  int get overlayAlpha => (compositeAlpha * 255).round().clamp(0, 255);

  /// Fraction of the screen's blue output this configuration removes (0.0–1.0).
  double get blueLightReduction => KelvinEngine.blueLightReduction(
        tintKelvin: kelvin,
        compositeAlpha: compositeAlpha,
      );

  /// Fraction of the screen's melanopic (circadian) output this configuration
  /// removes (0.0–1.0). The headline figure shown to the user.
  double get melanopicReduction => KelvinEngine.melanopicReduction(
        tintKelvin: kelvin,
        compositeAlpha: compositeAlpha,
      );

  /// Fraction by which this configuration reduces overall screen luminance.
  double get luminanceReduction => KelvinEngine.luminanceReduction(
        tintKelvin: kelvin,
        compositeAlpha: compositeAlpha,
      );

  /// Circadian impact band of the current colour temperature.
  MelatoninSafetyLevel get safetyLevel => KelvinEngine.safetyLevel(kelvin);

  /// Whether the user has warmed the screen but left dimming at zero.
  ///
  /// Worth surfacing: colour shift alone is the least effective configuration,
  /// and a user in this state believes they are protected when they largely are
  /// not (Nagare et al., 2019).
  bool get isColourOnly => extraDimPercent == 0 && densityPercent > 0;

  /// Baseline configuration for a first run: a mild evening warm tint.
  factory FilterConfig.initial() => FilterConfig(
        isEnabled: false,
        activePresetId: 0,
        kelvin: 3200,
        densityPercent: 30,
        extraDimPercent: 20,
        isNotificationEnabled: true,
        isScheduleEnabled: false,
      );

  FilterConfig copyWith({
    bool? isEnabled,
    int? activePresetId,
    int? kelvin,
    int? densityPercent,
    int? extraDimPercent,
    bool? isNotificationEnabled,
    bool? isScheduleEnabled,
  }) {
    return FilterConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      activePresetId: activePresetId ?? this.activePresetId,
      kelvin: kelvin ?? this.kelvin,
      densityPercent: densityPercent ?? this.densityPercent,
      extraDimPercent: extraDimPercent ?? this.extraDimPercent,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      isScheduleEnabled: isScheduleEnabled ?? this.isScheduleEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterConfig &&
          runtimeType == other.runtimeType &&
          isEnabled == other.isEnabled &&
          activePresetId == other.activePresetId &&
          kelvin == other.kelvin &&
          densityPercent == other.densityPercent &&
          extraDimPercent == other.extraDimPercent &&
          isNotificationEnabled == other.isNotificationEnabled &&
          isScheduleEnabled == other.isScheduleEnabled;

  @override
  int get hashCode => Object.hash(
        isEnabled,
        activePresetId,
        kelvin,
        densityPercent,
        extraDimPercent,
        isNotificationEnabled,
        isScheduleEnabled,
      );

  @override
  String toString() => 'FilterConfig(enabled: $isEnabled, preset: $activePresetId, '
      '${kelvin}K, density: $densityPercent%, dim: $extraDimPercent%)';
}
