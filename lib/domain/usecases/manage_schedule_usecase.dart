import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/schedule_rule.dart';
import 'package:doctorfilter/domain/repositories/i_schedule_repository.dart';

final class ManageScheduleUseCase {
  const ManageScheduleUseCase(this._repository);

  final IScheduleRepository _repository;

  Future<Result<ScheduleRule>> getSchedule() => _repository.getScheduleRule();

  Future<Result<ScheduleRule>> updateSchedule(ScheduleRule rule) async {
    final saveResult = await _repository.saveScheduleRule(rule);
    if (saveResult is FailureResult<void>) {
      return FailureResult(saveResult.failure);
    }

    final nativeSync = await _repository.setNativeScheduleActive(rule.isEnabled, rule);
    if (nativeSync is FailureResult<void>) {
      return FailureResult(nativeSync.failure);
    }

    return Result.success(rule);
  }
}
