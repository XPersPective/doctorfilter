import 'package:doctorfilter/core/errors/failure.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';
import 'package:doctorfilter/domain/repositories/i_filter_repository.dart';
import 'package:doctorfilter/domain/repositories/i_preset_repository.dart';

final class ApplyPresetUseCase {
  const ApplyPresetUseCase(this._filterRepository, this._presetRepository);

  final IFilterRepository _filterRepository;
  final IPresetRepository _presetRepository;

  Future<Result<FilterConfig>> call(int presetId) async {
    final presetResult = await _presetRepository.getPresetById(presetId);
    if (presetResult is FailureResult<FilterPreset?>) {
      return FailureResult(presetResult.failure);
    }

    final preset = (presetResult as Success<FilterPreset?>).data;
    if (preset == null) {
      return const FailureResult(UnexpectedFailure('Requested preset not found'));
    }

    final configResult = await _filterRepository.getFilterConfig();
    if (configResult is FailureResult<FilterConfig>) {
      return configResult;
    }

    final currentConfig = (configResult as Success<FilterConfig>).data;
    final updatedConfig = currentConfig.copyWith(
      activePresetId: preset.id,
      kelvin: preset.kelvin,
      red: preset.red,
      green: preset.green,
      blue: preset.blue,
      alpha: preset.alpha,
      brightness: preset.brightness,
    );

    final saveResult = await _filterRepository.updateFilterConfig(updatedConfig);
    if (saveResult is FailureResult<void>) {
      return FailureResult(saveResult.failure);
    }

    return Result.success(updatedConfig);
  }
}
