import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/domain/entities/pro_status.dart';
import 'core_providers.dart';

/// The single place the app asks "is this user Pro?".
///
/// Ads, notification controls and preset locks all read this and nothing else.
/// Entitlement logic that gets copied into three widgets is entitlement logic
/// that eventually disagrees with itself, and the failure mode — someone who
/// paid still seeing ads — is the expensive kind.
class ProStatusNotifier extends StateNotifier<ProStatus> {
  ProStatusNotifier(this._ref) : super(ProStatus.free()) {
    state = _ref.read(preferencesDataSourceProvider).getProStatus();
  }

  final Ref _ref;

  /// Records a completed purchase.
  ///
  /// Written locally because there is no server: the app has no backend, no
  /// account, and no secret it could keep. This is stated plainly in the README
  /// rather than dressed up — a determined user can grant themselves Pro, and
  /// building a licence server to stop them would cost every honest user their
  /// privacy.
  Future<void> grantLifetime() async {
    state = ProStatus.lifetime();
    await _ref.read(preferencesDataSourceProvider).setProStatus(state);
  }

  /// Grants a temporary pass earned by watching a rewarded ad.
  Future<void> grantTemporaryPass(Duration duration) async {
    if (state.isLifetime) return;
    state = ProStatus.pass(DateTime.now().add(duration));
    await _ref.read(preferencesDataSourceProvider).setProStatus(state);
  }

  /// Drops entitlement — a refund, or a restore that found no purchase.
  Future<void> revoke() async {
    state = ProStatus.free();
    await _ref.read(preferencesDataSourceProvider).setProStatus(state);
  }

  /// Re-reads stored entitlement, expiring a lapsed pass.
  void refresh() {
    final stored = _ref.read(preferencesDataSourceProvider).getProStatus();
    if (stored != state) state = stored;
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
