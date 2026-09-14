import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';

/// Contract for managing screen overlay filter hardware/platform states.
/// Pure Dart interface with zero Flutter dependencies.
abstract interface class IFilterRepository {
  /// Fetches the currently persisted filter runtime configuration.
  Future<Result<FilterConfig>> getFilterConfig();

  /// Updates and persists the filter runtime configuration.
  Future<Result<void>> updateFilterConfig(FilterConfig config);

  /// Commands the native overlay window to show or hide.
  Future<Result<void>> setOverlayActive(bool isActive);

  /// Commands the native persistent control notification to show or hide.
  Future<Result<void>> setNotificationActive(bool isActive);

  /// Checks if Android `SYSTEM_ALERT_WINDOW` permission is currently granted.
  Future<Result<bool>> checkOverlayPermission();

  /// Requests the user to grant overlay permission by launching system settings.
  Future<Result<void>> requestOverlayPermission();

  /// Watches runtime updates streamed from native side (e.g. notification bar button presses).
  Stream<FilterConfig> watchFilterConfig();
}
