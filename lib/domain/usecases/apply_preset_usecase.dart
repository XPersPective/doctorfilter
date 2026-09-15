import 'package:doctorfilter/core/errors/failure.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';
import 'package:doctorfilter/domain/repositories/i_filter_repository.dart';
import 'package:doctorfilter/domain/repositories/i_preset_repository.dart';

/// Switches the live configuration to a stored preset.
final class ApplyPresetUseCase {
  const ApplyPresetUseCase(this._filterRepository, this._presetRepository);

  final IFilterRepository _filterRepository;
  final IPresetRepository _presetRepository;

  Future<Result<FilterConfig>> call(FilterConfig current, int presetId) async {
    final lookup = await _presetRepository.getPresetById(presetId);
    if (lookup case FailureResult(:final failure)) {
      return FailureResult(failure);
    }

    final preset = lookup.dataOrNull;
    if (preset == null) {
      return const FailureResult(UnexpectedFailure('preset_not_found'));
    }

    final updated = preset.applyTo(current);

    if (updated.isEnabled) {
      final applied = await _filterRepository.applyToPlatform(updated);
      if (applied case FailureResult(:final failure)) {
        return FailureResult(failure);
      }
    }

    _filterRepository.persist(updated);
    return Result.success(updated);
  }

  /// Convenience for callers that already hold the preset.
  Future<Result<FilterConfig>> applyPreset(
    FilterConfig current,
    FilterPreset preset,
  ) =>
      call(current, preset.id);
}
