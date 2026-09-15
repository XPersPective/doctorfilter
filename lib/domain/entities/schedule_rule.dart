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
    this.transitionMinutes = defaultTransitionMinutes,
  });

  /// A filter that appears instantly at bedtime is startling, which is the
  /// opposite of what it is for. Thirty minutes is slow enough that the change
  /// is never consciously noticed.
  static const int defaultTransitionMinutes = 30;

  /// Longest fade offered — the length of the pre-sleep window in Brown et al.
  /// (2022), so the bedtime assistant can spread the whole descent across it.
  static const int maxTransitionMinutes = 180;

  /// How far before bedtime the wind-down starts.
  ///
  /// The three hours before sleep are the window the evening guidance is
  /// written for; starting the descent at its beginning means the screen is at
  /// the target by the time it matters rather than on the way there.
  static const int windDownHours = 3;

  /// The schedule for someone who just wants to tell the app when they sleep.
  ///
  /// The filter begins its descent [windDownHours] before bed and takes the
  /// whole window to get there, which is the point: a step change at 22:00 is
  /// something the user notices and resents, and resented settings get turned
  /// off.
  ScheduleRule forBedtime({required int bedHour, required int bedMinute}) {
    final startMinutes =
        (bedHour * 60 + bedMinute - windDownHours * 60 + 24 * 60) % (24 * 60);

    return copyWith(
      isEnabled: true,
      startHour: startMinutes ~/ 60,
      startMinute: startMinutes % 60,
      transitionMinutes: windDownHours * 60,
    );
  }

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

  /// How long the filter takes to fade in at the start of the window, and out
  /// again at the end. Zero switches instantly.
  final int transitionMinutes;

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
    int? transitionMinutes,
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
      transitionMinutes: (transitionMinutes ?? this.transitionMinutes)
          .clamp(0, maxTransitionMinutes),
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
          targetPresetId == other.targetPresetId &&
          transitionMinutes == other.transitionMinutes;

  @override
  int get hashCode =>
      id.hashCode ^
      isEnabled.hashCode ^
      startHour.hashCode ^
      startMinute.hashCode ^
      stopHour.hashCode ^
      stopMinute.hashCode ^
      mode.hashCode ^
      targetPresetId.hashCode ^
      transitionMinutes.hashCode;
}
