import 'package:doctorfilter/core/errors/failure.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/repositories/i_filter_repository.dart';

/// Turns the filter on or off.
///
/// Exists as a use case because turning it *on* is not a simple state flip: it
/// is gated on a permission the user may not have granted, and without that
/// permission the overlay silently does nothing at all. Getting that wrong
/// leaves the app claiming to protect a screen it cannot draw on.
final class ToggleFilterUseCase {
  const ToggleFilterUseCase(this._repository);

  final IFilterRepository _repository;

  /// Returns the configuration that is now in effect.
  Future<Result<FilterConfig>> call(FilterConfig current, {bool? forceState}) async {
    final shouldEnable = forceState ?? !current.isEnabled;

    if (shouldEnable) {
      final permission = await _repository.checkOverlayPermission();
      if (permission case FailureResult(:final failure)) {
        return FailureResult(failure);
      }
      if (permission.dataOrNull != true) {
        await _repository.requestOverlayPermission();
        return const FailureResult(
          PermissionFailure('overlay_permission_required'),
        );
      }
    }

    final updated = current.copyWith(isEnabled: shouldEnable);

    final applied = await _repository.applyToPlatform(updated);
    if (applied case FailureResult(:final failure)) {
      return FailureResult(failure);
    }

    _repository.persist(updated);
    return Result.success(updated);
  }
}
