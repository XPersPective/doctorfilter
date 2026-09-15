import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/domain/entities/pro_status.dart';
import 'package:doctorfilter/domain/repositories/i_purchase_repository.dart';
import 'core_providers.dart';

/// The single place the app asks "is this user Pro?".
///
/// Ads, notification controls and preset locks all read this and nothing else.
/// Entitlement logic copied into three widgets is entitlement logic that
/// eventually disagrees with itself, and the failure mode — someone who paid
/// still seeing ads — is the expensive kind.
class ProStatusNotifier extends StateNotifier<ProStatus> {
  ProStatusNotifier(this._ref) : super(ProStatus.free()) {
    // Read from disk first so a returning Pro user never sees a flash of ads
    // while the store is being contacted.
    state = _ref.read(preferencesDataSourceProvider).getProStatus();

    final store = _ref.read(purchaseRepositoryProvider);
    _storeUpdates = store.entitlementUpdates.listen(_onStoreEntitlement);
    _restoreQuietly(store);
  }

  final Ref _ref;
  StreamSubscription<ProStatus>? _storeUpdates;

  /// Asks the store what this account owns, without showing the user anything.
  ///
  /// Covers the reinstall, the new phone, and the purchase that completed on
  /// another device. A silent failure here is fine: local entitlement already
  /// stands, and the user can still restore by hand from the paywall.
  Future<void> _restoreQuietly(IPurchaseRepository store) async {
    if (!store.isAvailable) return;
    await store.restorePurchases();
  }

  void _onStoreEntitlement(ProStatus fromStore) {
    if (!mounted || !fromStore.isLifetime) return;
    grantLifetime();
  }

  /// Records a completed purchase.
  ///
  /// Stored locally because there is no server: the app has no backend, no
  /// account and no secret it could keep. This is stated plainly in the README
  /// rather than dressed up — a determined user can grant themselves Pro, and
  /// running a licence server to stop them would cost every honest user their
  /// privacy for the sake of a handful of copies.
  Future<void> grantLifetime() async {
    if (state.isLifetime) return;
    state = ProStatus.lifetime();
    await _ref.read(preferencesDataSourceProvider).setProStatus(state);
  }

  /// Grants a temporary pass earned by watching a rewarded ad.
  Future<void> grantTemporaryPass(Duration duration) async {
    if (state.isLifetime) return;
    state = ProStatus.pass(DateTime.now().add(duration));
    await _ref.read(preferencesDataSourceProvider).setProStatus(state);
  }

  /// Drops entitlement — a refund, or a restore that found nothing.
  Future<void> revoke() async {
    state = ProStatus.free();
    await _ref.read(preferencesDataSourceProvider).setProStatus(state);
  }

  /// Re-reads stored entitlement, expiring a lapsed pass.
  void refresh() {
    final stored = _ref.read(preferencesDataSourceProvider).getProStatus();
    if (stored != state) state = stored;
  }

  @override
  void dispose() {
    _storeUpdates?.cancel();
    super.dispose();
  }
}

final proStatusProvider =
    StateNotifierProvider<ProStatusNotifier, ProStatus>((ref) {
  return ProStatusNotifier(ref);
});

/// Convenience for the many widgets that only need the yes/no.
final isProProvider = Provider<bool>((ref) {
  return ref.watch(proStatusProvider).isActive;
});

/// The product as the store describes it, price included.
///
/// Null while loading or when there is no store to ask; the paywall shows its
/// own message in that case rather than a blank price.
final proOfferProvider = FutureProvider<ProOffer?>((ref) async {
  final store = ref.watch(purchaseRepositoryProvider);
  if (!store.isAvailable) return null;
  final result = await store.loadOffer();
  return result.dataOrNull;
});
