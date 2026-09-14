import 'package:doctorfilter/core/errors/failure.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/data/datasources/local/preferences_datasource.dart';
import 'package:doctorfilter/data/datasources/native/platform_channel_datasource.dart';
import 'package:doctorfilter/domain/entities/schedule_rule.dart';
import 'package:doctorfilter/domain/repositories/i_schedule_repository.dart';

class ScheduleRepositoryImpl implements IScheduleRepository {
  const ScheduleRepositoryImpl({
    required PreferencesDataSource preferencesDataSource,
    required PlatformChannelDataSource platformChannelDataSource,
  })  : _prefs = preferencesDataSource,
        _native = platformChannelDataSource;

  final PreferencesDataSource _prefs;
  final PlatformChannelDataSource _native;

  @override
  Future<Result<ScheduleRule>> getScheduleRule() async {
    try {
      final rule = _prefs.getScheduleRule();
      return Result.success(rule);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to get schedule rule', cause: e));
    }
  }

  @override
  Future<Result<void>> saveScheduleRule(ScheduleRule rule) async {
    try {
      await _prefs.saveScheduleRule(rule);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to save schedule rule', cause: e));
    }
  }

  @override
  Future<Result<void>> setNativeScheduleActive(bool isActive, ScheduleRule rule) async {
    try {
      final updated = rule.copyWith(isEnabled: isActive);
      await _prefs.saveScheduleRule(updated);
      await _native.setSchedule(updated);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(PlatformFailure('Failed to sync native schedule', cause: e));
    }
  }
}
