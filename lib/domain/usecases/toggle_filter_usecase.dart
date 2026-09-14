import 'package:doctorfilter/core/errors/failure.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/repositories/i_filter_repository.dart';

final class ToggleFilterUseCase {
  const ToggleFilterUseCase(this._repository);

  final IFilterRepository _repository;

  Future<Result<FilterConfig>> call({bool? forceState}) async {
    final configResult = await _repository.getFilterConfig();
    if (configResult is FailureResult<FilterConfig>) {
      return configResult;
    }

    final currentConfig = (configResult as Success<FilterConfig>).data;
    final newState = forceState ?? !currentConfig.isEnabled;

    if (newState) {
      // 1. Check overlay permission first
      final permResult = await _repository.checkOverlayPermission();
      if (permResult is FailureResult<bool>) {
        return FailureResult(permResult.failure);
      }
      final isPermitted = (permResult as Success<bool>).data;
      if (!isPermitted) {
        await _repository.requestOverlayPermission();
        return const FailureResult(
          PermissionFailure('Overlay permission is required to display screen filter.'),
        );
      }
    }

    final updatedConfig = currentConfig.copyWith(isEnabled: newState);

    // 2. Persist updated configuration
    final saveResult = await _repository.updateFilterConfig(updatedConfig);
    if (saveResult is FailureResult<void>) {
      return FailureResult(saveResult.failure);
    }

    // 3. Command native overlay
    final overlayResult = await _repository.setOverlayActive(newState);
    if (overlayResult is FailureResult<void>) {
      return FailureResult(overlayResult.failure);
    }

    // 4. Command native notification if enabled
    if (updatedConfig.isNotificationEnabled) {
      await _repository.setNotificationActive(newState);
    }

    return Result.success(updatedConfig);
  }
}
