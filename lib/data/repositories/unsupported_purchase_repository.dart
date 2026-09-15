import 'package:doctorfilter/core/errors/failure.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/pro_status.dart';
import 'package:doctorfilter/domain/repositories/i_purchase_repository.dart';

/// Stands in on platforms with no store the app can sell through — Linux, and
/// Windows until the Microsoft Store integration lands.
///
/// It reports [isAvailable] as false rather than throwing, so the UI hides the
/// purchase button instead of offering one that fails. Showing a user a "Buy
/// Pro" button that cannot work is worse than not mentioning Pro at all.
class UnsupportedPurchaseRepository implements IPurchaseRepository {
  const UnsupportedPurchaseRepository();

  @override
  bool get isAvailable => false;

  @override
  Future<Result<ProOffer>> loadOffer() async =>
      const Result.failure(PlatformFailure('store_unavailable'));

  @override
  Future<Result<PurchaseOutcome>> buyLifetime() async =>
      const Result.success(PurchaseOutcome.unavailable);

  @override
  Future<Result<PurchaseOutcome>> restorePurchases() async =>
      const Result.success(PurchaseOutcome.nothingToRestore);

  @override
  Stream<ProStatus> get entitlementUpdates => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
