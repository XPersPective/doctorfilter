import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:doctorfilter/core/errors/failure.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/pro_status.dart';
import 'package:doctorfilter/domain/repositories/i_purchase_repository.dart';

/// Pro through the platform's own store — Google Play on Android, the App Store
/// on iOS and macOS.
///
/// Both are driven by the same `in_app_purchase` plugin, so this one class
/// covers both without a branch. The user pays with whatever their store account
/// already has set up: Google Play balance, a saved card, carrier billing, Apple
/// Pay. Two taps and a fingerprint.
class StorePurchaseRepository implements IPurchaseRepository {
  StorePurchaseRepository({InAppPurchase? store})
    : _store = store ?? InAppPurchase.instance {
    _subscription = _store.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object _) {
        // A broken stream must not leave the app thinking a purchase is still
        // in flight; fall back to whatever was already granted.
        _entitlement.add(_granted ? ProStatus.lifetime() : ProStatus.free());
        _completeRestore(PurchaseOutcome.unavailable);
      },
    );
  }

  final InAppPurchase _store;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  final _entitlement = StreamController<ProStatus>.broadcast();
  final _outcomes = StreamController<PurchaseOutcome>.broadcast();
  Future<Result<PurchaseOutcome>>? _restoreInFlight;
  Completer<PurchaseOutcome>? _restoreOutcome;
  static const _restoreTimeout = Duration(seconds: 12);

  bool _granted = false;

  @override
  bool get isAvailable => true;

  @override
  Stream<ProStatus> get entitlementUpdates => _entitlement.stream;

  @override
  Future<Result<ProOffer>> loadOffer() async {
    if (!await _store.isAvailable()) {
      return const Result.failure(PlatformFailure('store_unavailable'));
    }

    final response = await _store.queryProductDetails(ProProduct.allIds);
    final product = response.productDetails
        .where((details) => details.id == ProProduct.lifetimeId)
        .firstOrNull;

    if (product == null) {
      // Usually means the product is not set up in the store console yet, or
      // the build is not signed with the uploaded key.
      return const Result.failure(PlatformFailure('product_not_found'));
    }

    return Result.success(
      ProOffer(
        id: product.id,
        title: product.title,
        description: product.description,
        // Straight from the store: already in the user's currency, already
        // formatted the way their locale writes money.
        formattedPrice: product.price,
      ),
    );
  }

  @override
  Future<Result<PurchaseOutcome>> buyLifetime() async {
    if (!await _store.isAvailable()) {
      return const Result.failure(PlatformFailure('store_unavailable'));
    }

    final response = await _store.queryProductDetails({ProProduct.lifetimeId});
    final product = response.productDetails.firstOrNull;
    if (product == null) {
      return const Result.failure(PlatformFailure('product_not_found'));
    }

    final settled = _nextOutcome();
    final started = await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );

    if (!started) {
      return const Result.success(PurchaseOutcome.cancelled);
    }

    // The flow is asynchronous and can outlive this call — a slow payment
    // method, a parental approval. Waiting on the stream keeps the UI honest
    // instead of claiming success the moment the sheet opens.
    return Result.success(await settled);
  }

  @override
  Future<Result<PurchaseOutcome>> restorePurchases() {
    return _restoreInFlight ??= _restorePurchases().whenComplete(() {
      _restoreInFlight = null;
    });
  }

  Future<Result<PurchaseOutcome>> _restorePurchases() async {
    try {
      if (!await _store.isAvailable().timeout(_restoreTimeout)) {
        return const Result.failure(PlatformFailure('store_unavailable'));
      }
      final response = Completer<PurchaseOutcome>();
      _restoreOutcome = response;
      await _store.restorePurchases().timeout(_restoreTimeout);
      final outcome = await response.future.timeout(
        _restoreTimeout,
        onTimeout: () => PurchaseOutcome.nothingToRestore,
      );
      return Result.success(outcome);
    } catch (_) {
      return const Result.failure(PlatformFailure('store_unavailable'));
    } finally {
      _restoreOutcome = null;
    }
  }

  void _completeRestore(PurchaseOutcome outcome) {
    final response = _restoreOutcome;
    if (response != null && !response.isCompleted) response.complete(outcome);
  }

  Future<PurchaseOutcome> _nextOutcome() {
    return _outcomes.stream.first.timeout(
      const Duration(minutes: 5),
      onTimeout: () => PurchaseOutcome.pending,
    );
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    // Play Billing and StoreKit return an empty batch when restore finds no
    // purchases. Let free users continue without waiting for the timeout.
    if (purchases.isEmpty) _completeRestore(PurchaseOutcome.nothingToRestore);

    for (final purchase in purchases) {
      if (!ProProduct.allIds.contains(purchase.productID)) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _outcomes.add(PurchaseOutcome.pending);

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _granted = true;
          _entitlement.add(ProStatus.lifetime());
          _completeRestore(PurchaseOutcome.restored);
          _outcomes.add(
            purchase.status == PurchaseStatus.restored
                ? PurchaseOutcome.restored
                : PurchaseOutcome.purchased,
          );

        case PurchaseStatus.canceled:
          _outcomes.add(PurchaseOutcome.cancelled);

        case PurchaseStatus.error:
          _outcomes.add(PurchaseOutcome.unavailable);
      }

      // Mandatory on both stores. Skipping it makes Play refund the purchase
      // after three days and Apple replay it on every launch.
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await _entitlement.close();
    await _outcomes.close();
  }
}
