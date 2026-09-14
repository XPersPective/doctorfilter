import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';

/// Contract for accessing and managing light filter presets.
/// Pure Dart interface with zero Flutter dependencies.
abstract interface class IPresetRepository {
  /// Retrieves all light presets (both defaults and custom profiles).
  Future<Result<List<FilterPreset>>> getAllPresets();

  /// Retrieves a specific preset by ID.
  Future<Result<FilterPreset?>> getPresetById(int id);

  /// Saves or updates a preset.
  Future<Result<void>> savePreset(FilterPreset preset);

  /// Deletes a custom preset.
  Future<Result<void>> deletePreset(int id);

  /// Restores presets back to the default factory values.
  Future<Result<void>> resetToDefaultPresets();
}
