import 'package:doctorfilter/core/errors/failure.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/data/datasources/local/database_helper.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';
import 'package:doctorfilter/domain/repositories/i_preset_repository.dart';

class PresetRepositoryImpl implements IPresetRepository {
  const PresetRepositoryImpl([this._dbHelper]);

  final DatabaseHelper? _dbHelper;
  DatabaseHelper get _db => _dbHelper ?? DatabaseHelper.instance;

  @override
  Future<Result<List<FilterPreset>>> getAllPresets() async {
    try {
      final presets = await _db.getAllPresets();
      return Result.success(presets);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to query presets', cause: e));
    }
  }

  @override
  Future<Result<FilterPreset?>> getPresetById(int id) async {
    try {
      final preset = await _db.getPresetById(id);
      return Result.success(preset);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch preset with id $id', cause: e));
    }
  }

  @override
  Future<Result<void>> savePreset(FilterPreset preset) async {
    try {
      await _db.insertOrUpdatePreset(preset);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to save preset', cause: e));
    }
  }

  @override
  Future<Result<void>> deletePreset(int id) async {
    try {
      await _db.deletePreset(id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to delete preset $id', cause: e));
    }
  }

  @override
  Future<Result<void>> resetToDefaultPresets() async {
    try {
      await _db.resetToDefaults();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to reset presets', cause: e));
    }
  }
}
