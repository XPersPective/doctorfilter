import 'package:doctorfilter/core/math/kelvin_engine.dart';
import 'filter_config.dart';

/// A named filter configuration the user can switch to.
///
/// Carries the same three axes as [FilterConfig] and nothing else. It notably
/// does *not* store RGB: the previous model kept hand-entered colour values
/// alongside a Kelvin label, and the two drifted apart badly enough that a
/// preset labelled 3500 K was rendering a 5405 K colour. Colour is always
/// derived from [kelvin], so the label and the pixels cannot disagree.
final class FilterPreset {
  FilterPreset({
    required this.id,
    required this.nameKey,
    required int kelvin,
    required int densityPercent,
    required int extraDimPercent,
    this.iconIdentifier = '',
    this.isCustom = false,
    this.isProOnly = false,
    this.sortOrder = 0,
  })  : kelvin = kelvin.clamp(KelvinEngine.minKelvin, KelvinEngine.maxKelvin),
        densityPercent =
            densityPercent.clamp(0, FilterConfig.maxDensityPercent),
        extraDimPercent =
            extraDimPercent.clamp(0, FilterConfig.maxExtraDimPercent);

  /// Unique identifier.
  final int id;

  /// Localization key for built-in presets, or the user's own label for custom ones.
  final String nameKey;

  /// Tint colour temperature, 1700–6500 K.
  final int kelvin;

  /// Tint strength, 0–80 %.
  final int densityPercent;

  /// Extra darkening, 0–70 %.
  final int extraDimPercent;

  /// Icon key (e.g. 'sun', 'moon', 'candle') or 'custom'.
  final String iconIdentifier;

  /// Whether the user created this preset.
  final bool isCustom;

  /// Whether this preset is reserved for Pro.
  final bool isProOnly;

  /// Position on the home screen; the user can reorder presets.
  final int sortOrder;

  /// The tint colour this preset renders, derived from [kelvin].
  ({int r, int g, int b}) get tintRgb => KelvinEngine.kelvinToRgb(kelvin);

  /// Circadian impact band of this preset.
  MelatoninSafetyLevel get safetyLevel => KelvinEngine.safetyLevel(kelvin);

  /// Applies this preset onto an existing runtime configuration.
  FilterConfig applyTo(FilterConfig config) => config.copyWith(
        activePresetId: id,
        kelvin: kelvin,
        densityPercent: densityPercent,
        extraDimPercent: extraDimPercent,
      );

  FilterPreset copyWith({
    int? id,
    String? nameKey,
    int? kelvin,
    int? densityPercent,
    int? extraDimPercent,
    String? iconIdentifier,
    bool? isCustom,
    bool? isProOnly,
    int? sortOrder,
  }) {
    return FilterPreset(
      id: id ?? this.id,
      nameKey: nameKey ?? this.nameKey,
      kelvin: kelvin ?? this.kelvin,
      densityPercent: densityPercent ?? this.densityPercent,
      extraDimPercent: extraDimPercent ?? this.extraDimPercent,
      iconIdentifier: iconIdentifier ?? this.iconIdentifier,
      isCustom: isCustom ?? this.isCustom,
      isProOnly: isProOnly ?? this.isProOnly,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterPreset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nameKey == other.nameKey &&
          kelvin == other.kelvin &&
          densityPercent == other.densityPercent &&
          extraDimPercent == other.extraDimPercent &&
          iconIdentifier == other.iconIdentifier &&
          isCustom == other.isCustom &&
          isProOnly == other.isProOnly &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(id, nameKey, kelvin, densityPercent,
      extraDimPercent, iconIdentifier, isCustom, isProOnly, sortOrder);

  @override
  String toString() => 'FilterPreset($id, $nameKey, ${kelvin}K, '
      'density: $densityPercent%, dim: $extraDimPercent%)';
}
