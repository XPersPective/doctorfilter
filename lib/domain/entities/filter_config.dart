/// Current active screen filter runtime state.
/// Pure Dart entity with zero UI or framework dependencies.
final class FilterConfig {
  const FilterConfig({
    required this.isEnabled,
    required this.activePresetId,
    required this.kelvin,
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
    required this.brightness,
    required this.isNotificationEnabled,
    required this.isScheduleEnabled,
  });

  /// Whether the screen overlay filter is currently running.
  final bool isEnabled;

  /// Identifier of the currently active preset.
  final int activePresetId;

  /// Correlated Color Temperature in Kelvin (1000 - 7000).
  final int kelvin;

  /// Red component (0 - 255).
  final int red;

  /// Green component (0 - 255).
  final int green;

  /// Blue component (0 - 255).
  final int blue;

  /// Overlay density / alpha (0 - 255).
  final int alpha;

  /// Screen brightness (0 - 255).
  final int brightness;

  /// Whether the foreground quick-control notification is active.
  final bool isNotificationEnabled;

  /// Whether the automatic circadian scheduler is active.
  final bool isScheduleEnabled;

  /// Calculates alpha as percentage (0 - 100%).
  int get alphaPercent => ((alpha / 255.0) * 100).round().clamp(0, 100);

  /// Calculates brightness as percentage (0 - 100%).
  int get brightnessPercent => ((brightness / 255.0) * 100).round().clamp(0, 100);

  /// Default baseline configuration.
  factory FilterConfig.initial() {
    return const FilterConfig(
      isEnabled: false,
      activePresetId: 0,
      kelvin: 5500,
      red: 255,
      green: 219,
      blue: 186,
      alpha: 25,
      brightness: 190,
      isNotificationEnabled: true,
      isScheduleEnabled: false,
    );
  }

  FilterConfig copyWith({
    bool? isEnabled,
    int? activePresetId,
    int? kelvin,
    int? red,
    int? green,
    int? blue,
    int? alpha,
    int? brightness,
    bool? isNotificationEnabled,
    bool? isScheduleEnabled,
  }) {
    return FilterConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      activePresetId: activePresetId ?? this.activePresetId,
      kelvin: kelvin ?? this.kelvin,
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
      alpha: alpha ?? this.alpha,
      brightness: brightness ?? this.brightness,
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
          red == other.red &&
          green == other.green &&
          blue == other.blue &&
          alpha == other.alpha &&
          brightness == other.brightness &&
          isNotificationEnabled == other.isNotificationEnabled &&
          isScheduleEnabled == other.isScheduleEnabled;

  @override
  int get hashCode =>
      isEnabled.hashCode ^
      activePresetId.hashCode ^
      kelvin.hashCode ^
      red.hashCode ^
      green.hashCode ^
      blue.hashCode ^
      alpha.hashCode ^
      brightness.hashCode ^
      isNotificationEnabled.hashCode ^
      isScheduleEnabled.hashCode;
}
