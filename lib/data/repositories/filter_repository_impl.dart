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
        _native = platformChannelDataSource;

  /// Long enough that a slider drag collapses into one write, short enough that
  /// a user who taps and immediately switches apps still has it saved.
  static const _writeDelay = Duration(milliseconds: 150);

  final PreferencesDataSource _prefs;
  final PlatformChannelDataSource _native;

  Timer? _writeTimer;
  FilterConfig? _pending;

  @override
  Future<Result<FilterConfig>> loadConfig() async {
    try {
      return Result.success(_prefs.getFilterConfig());
    } catch (e) {
      return Result.failure(DatabaseFailure('Could not read saved settings', cause: e));
    }
  }

  @override
  void persist(FilterConfig config) {
    _pending = config;
    _writeTimer?.cancel();
    _writeTimer = Timer(_writeDelay, flush);
  }

  @override
  Future<void> flush() async {
    _writeTimer?.cancel();
    _writeTimer = null;
    final config = _pending;
    if (config == null) return;
    _pending = null;
    await _prefs.saveFilterConfig(config);
  }

  @override
  Future<Result<void>> applyToPlatform(FilterConfig config) async {
    try {
      if (!config.isEnabled) {
        await _native.stopOverlay();
        return const Result.success(null);
      }
      // startOverlay is idempotent on the native side: it starts the service if
      // it is not running and repaints if it is, so there is no state to track
      // here that could drift out of sync with the service's real state.
      await _native.startOverlay(config);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(PlatformFailure('Could not apply the filter', cause: e));
    }
  }

  @override
  Future<Result<bool>> checkOverlayPermission() async {
    try {
      return Result.success(await _native.checkOverlayPermission());
    } catch (e) {
      return Result.failure(PermissionFailure('Could not check overlay permission', cause: e));
    }
  }

  @override
  Future<Result<void>> requestOverlayPermission() async {
    try {
      await _native.requestOverlayPermission();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(PermissionFailure('Could not open overlay settings', cause: e));
    }
  }

  @override
  Stream<NativeFilterEvent> get nativeEvents => _native.events;

  /// Flushes rather than dropping: a pending write at teardown is exactly the
  /// change the user made last.
  Future<void> dispose() => flush();
}
