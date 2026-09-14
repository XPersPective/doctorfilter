import 'dart:async';
import 'package:doctorfilter/core/errors/failure.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/data/datasources/local/preferences_datasource.dart';
import 'package:doctorfilter/data/datasources/native/platform_channel_datasource.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/repositories/i_filter_repository.dart';

class FilterRepositoryImpl implements IFilterRepository {
  FilterRepositoryImpl({
    required PreferencesDataSource preferencesDataSource,
    required PlatformChannelDataSource platformChannelDataSource,
  })  : _prefs = preferencesDataSource,
        _native = platformChannelDataSource {
    _initNativeListeners();
  }

  final PreferencesDataSource _prefs;
  final PlatformChannelDataSource _native;
  final StreamController<FilterConfig> _streamController =
      StreamController<FilterConfig>.broadcast();

  void _initNativeListeners() {
    _native.onFilterStateChanged.listen((isEnabled) {
      final current = _prefs.getFilterConfig();
      final updated = current.copyWith(isEnabled: isEnabled);
      _prefs.saveFilterConfig(updated);
      _streamController.add(updated);
    });

    _native.onDensityChanged.listen((alpha) {
      final current = _prefs.getFilterConfig();
      final updated = current.copyWith(alpha: alpha);
      _prefs.saveFilterConfig(updated);
      _streamController.add(updated);
    });
  }

  @override
  Future<Result<FilterConfig>> getFilterConfig() async {
    try {
      final config = _prefs.getFilterConfig();
      return Result.success(config);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to read filter config', cause: e));
    }
  }

  @override
  Future<Result<void>> updateFilterConfig(FilterConfig config) async {
    try {
      await _prefs.saveFilterConfig(config);
      if (config.isEnabled) {
        await _native.updateOverlay(config);
      }
      _streamController.add(config);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(PlatformFailure('Failed to update filter config', cause: e));
    }
  }

  @override
  Future<Result<void>> setOverlayActive(bool isActive) async {
    try {
      final config = _prefs.getFilterConfig().copyWith(isEnabled: isActive);
      await _prefs.saveFilterConfig(config);

      if (isActive) {
        await _native.startOverlay(config);
      } else {
        await _native.stopOverlay();
      }
      _streamController.add(config);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(PlatformFailure('Failed to toggle overlay', cause: e));
    }
  }

  @override
  Future<Result<void>> setNotificationActive(bool isActive) async {
    try {
      final config = _prefs.getFilterConfig().copyWith(isNotificationEnabled: isActive);
      await _prefs.saveFilterConfig(config);
      _streamController.add(config);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(PlatformFailure('Failed to update notification setting', cause: e));
    }
  }

  @override
  Future<Result<bool>> checkOverlayPermission() async {
    try {
      final isGranted = await _native.checkOverlayPermission();
      return Result.success(isGranted);
    } catch (e) {
      return Result.failure(PermissionFailure('Failed to check overlay permission', cause: e));
    }
  }

  @override
  Future<Result<void>> requestOverlayPermission() async {
    try {
      await _native.requestOverlayPermission();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(PermissionFailure('Failed to request overlay permission', cause: e));
    }
  }

  @override
  Stream<FilterConfig> watchFilterConfig() => _streamController.stream;

  void dispose() {
    _streamController.close();
  }
}
