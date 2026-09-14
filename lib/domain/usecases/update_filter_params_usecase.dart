import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/repositories/i_filter_repository.dart';

final class UpdateFilterParamsUseCase {
  const UpdateFilterParamsUseCase(this._repository);

  final IFilterRepository _repository;

  Future<Result<FilterConfig>> call({
    int? kelvin,
    int? red,
    int? green,
    int? blue,
    int? alpha,
    int? brightness,
    bool? isNotificationEnabled,
    bool? isScheduleEnabled,
  }) async {
    final configResult = await _repository.getFilterConfig();
    if (configResult is FailureResult<FilterConfig>) {
      return configResult;
    }

    final currentConfig = (configResult as Success<FilterConfig>).data;
    final updatedConfig = currentConfig.copyWith(
      kelvin: kelvin,
      red: red,
      green: green,
      blue: blue,
      alpha: alpha,
      brightness: brightness,
      isNotificationEnabled: isNotificationEnabled,
      isScheduleEnabled: isScheduleEnabled,
    );

    final saveResult = await _repository.updateFilterConfig(updatedConfig);
    if (saveResult is FailureResult<void>) {
      return FailureResult(saveResult.failure);
    }

    return Result.success(updatedConfig);
  }
}
