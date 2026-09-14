/// Represents a pre-configured or custom eye protection light preset.
/// Pure Dart entity with zero UI or framework dependencies.
final class FilterPreset {
  const FilterPreset({
    required this.id,
    required this.nameKey,
    required this.kelvin,
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
    required this.brightness,
    this.iconIdentifier = '',
    this.isCustom = false,
    this.isProOnly = false,
  });

  /// Unique identifier for the preset.
  final int id;

  /// Localization key or custom preset label.
  final String nameKey;

  /// Correlated Color Temperature in Kelvin (1000 - 7000).
  final int kelvin;

  /// Red component (0 - 255).
  final int red;

  /// Green component (0 - 255).
  final int green;

  /// Blue component (0 - 255).
  final int blue;

  /// Overlay alpha / density (0 - 255).
  final int alpha;

  /// Hardware/Subzero brightness level (0 - 255).
  final int brightness;

  /// Icon identifier or asset key (e.g. 'gunes', 'florasan', 'lamba', 'ay', 'mum', 'kitap', 'agac').
  final String iconIdentifier;

  /// Whether this is a user-created custom preset.
  final bool isCustom;

  /// Whether this preset is restricted to Pro members.
  final bool isProOnly;

  /// Calculates alpha as a percentage (0 - 100%).
  int get alphaPercent => ((alpha / 255.0) * 100).round().clamp(0, 100);

  /// Calculates brightness as a percentage (0 - 100%).
  int get brightnessPercent => ((brightness / 255.0) * 100).round().clamp(0, 100);

  FilterPreset copyWith({
    int? id,
    String? nameKey,
    int? kelvin,
    int? red,
    int? green,
    int? blue,
    int? alpha,
    int? brightness,
    String? iconIdentifier,
    bool? isCustom,
    bool? isProOnly,
  }) {
    return FilterPreset(
      id: id ?? this.id,
      nameKey: nameKey ?? this.nameKey,
      kelvin: kelvin ?? this.kelvin,
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
      alpha: alpha ?? this.alpha,
      brightness: brightness ?? this.brightness,
      iconIdentifier: iconIdentifier ?? this.iconIdentifier,
      isCustom: isCustom ?? this.isCustom,
      isProOnly: isProOnly ?? this.isProOnly,
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
          red == other.red &&
          green == other.green &&
          blue == other.blue &&
          alpha == other.alpha &&
          brightness == other.brightness &&
          iconIdentifier == other.iconIdentifier &&
          isCustom == other.isCustom &&
          isProOnly == other.isProOnly;

  @override
  int get hashCode =>
      id.hashCode ^
      nameKey.hashCode ^
      kelvin.hashCode ^
      red.hashCode ^
      green.hashCode ^
      blue.hashCode ^
      alpha.hashCode ^
      brightness.hashCode ^
      iconIdentifier.hashCode ^
      isCustom.hashCode ^
      isProOnly.hashCode;

  @override
  String toString() {
    return 'FilterPreset(id: $id, nameKey: $nameKey, kelvin: $kelvin, RGB: ($red, $green, $blue), alpha: $alpha, brightness: $brightness)';
  }
}
