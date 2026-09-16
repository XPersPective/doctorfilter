import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/data/datasources/native/platform_channel_datasource.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';

/// Contract for reading, persisting and applying the screen filter.
///
/// Deliberately has no per-field update method. The previous interface did, and
/// every caller of it performed a read-modify-write against disk; dragging a
/// slider fired several of those concurrently and they overwrote each other,
/// which is what made the app appear to forget settings. Callers now hold the
/// current configuration in memory and hand over a complete one.
abstract interface class IFilterRepository {
  /// Reads the persisted configuration. Called once, at startup.
  Future<Result<FilterConfig>> loadConfig();

  /// Persists a complete configuration.
  ///
  /// Returns immediately; the write itself is debounced, so dragging a slider
  /// costs one disk write rather than one per frame. Never partial.
  void persist(FilterConfig config);

  /// Writes any pending debounced configuration right now.
  ///
  /// Call before the app can be killed — backgrounding, or shutting down.
  Future<void> flush();

  /// Pushes a configuration to the native overlay, starting, updating or
  /// stopping it according to [FilterConfig.isEnabled].
  Future<Result<void>> applyToPlatform(FilterConfig config);

  /// Whether the native overlay is running right now, which can differ from the
  /// saved configuration when the tile, notification or schedule changed it
  /// while the app was closed.
  Future<Result<bool>> isFilterRunning();

  /// Whether Android's `SYSTEM_ALERT_WINDOW` permission is currently granted.
  Future<Result<bool>> checkOverlayPermission();

  /// Sends the user to the system screen where overlay permission is granted.
  Future<Result<void>> requestOverlayPermission();

  /// Changes that originated natively: notification buttons, the scheduler.
  Stream<NativeFilterEvent> get nativeEvents;
}
