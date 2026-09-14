import 'circadian_mode.dart';

/// Represents an automated schedule rule for the eye protection filter.
/// Pure Dart entity with zero UI or framework dependencies.
final class ScheduleRule {
  const ScheduleRule({
    required this.id,
    required this.isEnabled,
    required this.startHour,
    required this.startMinute,
    required this.stopHour,
    required this.stopMinute,
    required this.mode,
    required this.targetPresetId,
  });

  /// Unique schedule rule ID.
  final int id;

  /// Whether this automation schedule is active.
  final bool isEnabled;

  /// Start time hour (0 - 23).
  final int startHour;

  /// Start time minute (0 - 59).
  final int startMinute;

  /// Stop time hour (0 - 23).
  final int stopHour;

  /// Stop time minute (0 - 59).
  final int stopMinute;

  /// Scheduling calculation mode (fixed time or sunset-sunrise).
  final CircadianMode mode;

  /// The preset to automatically activate during this window.
  final int targetPresetId;

  /// Formatted start time string (HH:mm).
  String get startTimeFormatted {
    final h = startHour.toString().padLeft(2, '0');
    final m = startMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Formatted stop time string (HH:mm).
  String get stopTimeFormatted {
    final h = stopHour.toString().padLeft(2, '0');
    final m = stopMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  factory ScheduleRule.defaultBedtime() {
    return const ScheduleRule(
      id: 1,
      isEnabled: false,
      startHour: 22,
      startMinute: 0,
      stopHour: 7,
      stopMinute: 0,
      mode: CircadianMode.manualTime,
      targetPresetId: 3, // Default to 'ay' (Bedtime/Moonlight)
    );
  }

  ScheduleRule copyWith({
    int? id,
    bool? isEnabled,
    int? startHour,
    int? startMinute,
    int? stopHour,
    int? stopMinute,
    CircadianMode? mode,
    int? targetPresetId,
  }) {
    return ScheduleRule(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      stopHour: stopHour ?? this.stopHour,
      stopMinute: stopMinute ?? this.stopMinute,
      mode: mode ?? this.mode,
      targetPresetId: targetPresetId ?? this.targetPresetId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleRule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isEnabled == other.isEnabled &&
          startHour == other.startHour &&
          startMinute == other.startMinute &&
          stopHour == other.stopHour &&
          stopMinute == other.stopMinute &&
          mode == other.mode &&
          targetPresetId == other.targetPresetId;

  @override
  int get hashCode =>
      id.hashCode ^
      isEnabled.hashCode ^
      startHour.hashCode ^
      startMinute.hashCode ^
      stopHour.hashCode ^
      stopMinute.hashCode ^
      mode.hashCode ^
      targetPresetId.hashCode;
}
