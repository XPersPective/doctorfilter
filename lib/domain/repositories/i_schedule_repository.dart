import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/schedule_rule.dart';

/// Contract for managing automated circadian scheduling.
/// Pure Dart interface with zero Flutter dependencies.
abstract interface class IScheduleRepository {
  /// Fetches the current schedule rule.
  Future<Result<ScheduleRule>> getScheduleRule();

  /// Persists a schedule rule.
  Future<Result<void>> saveScheduleRule(ScheduleRule rule);

  /// Synchronizes with the native alarm / WorkManager scheduler.
  Future<Result<void>> setNativeScheduleActive(bool isActive, ScheduleRule rule);
}
