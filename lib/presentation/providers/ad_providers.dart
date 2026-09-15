import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/domain/entities/ad_policy.dart';
import 'package:doctorfilter/presentation/ads/interstitial_ad_manager.dart';
import 'package:doctorfilter/presentation/ads/rewarded_ad_manager.dart';
import 'core_providers.dart';
import 'pro_provider.dart';

/// Tracks ad exposure and answers "may we show one right now?".
///
/// The rules live in [AdPolicy], which is pure; this only holds the state they
/// read and records what happened. Keeping the two apart is what lets the limits
/// be tested without an ad SDK or a device.
class AdPolicyNotifier extends StateNotifier<AdPolicyState> {
  AdPolicyNotifier(this._ref) : super(_load(_ref)) {
    // Opening the app is a session. Counted once, here, so "one interstitial per
    // session" has a boundary that means something.
    state = state.copyWith(sessionCount: state.sessionCount + 1);
    _persist();
  }

  final Ref _ref;

  static AdPolicyState _load(Ref ref) =>
      ref.read(preferencesDataSourceProvider).getAdPolicyState();

  /// Whether an interstitial may be shown at this moment.
  bool mayShowInterstitial(AdMoment moment) => AdPolicy.mayShowInterstitial(
        state: state,
        moment: moment,
        isPro: _ref.read(isProProvider),
        now: DateTime.now(),
      );

  /// Records that one was actually shown. Only call after it appeared —
  /// recording an ad that failed to load would silently cost the user their
  /// next eligible slot for nothing.
  void recordInterstitialShown() {
    final now = DateTime.now();
    state = state.copyWith(
      lastInterstitialAt: now,
      interstitialsThisSession: state.interstitialsThisSession + 1,
    );
    _persist();
  }

  void recordPresetChange() {
    state = state.copyWith(
      presetChangesThisSession: state.presetChangesThisSession + 1,
    );
  }

  bool get mayWatchRewarded => AdPolicy.mayWatchRewarded(
        state: state,
        isPro: _ref.read(isProProvider),
        now: DateTime.now(),
      );

  /// Records a completed rewarded view and grants the pass it earned.
  Future<void> recordRewardedWatched() async {
    final now = DateTime.now();
    final sameDay = state.rewardedDay != null &&
        state.rewardedDay!.year == now.year &&
        state.rewardedDay!.month == now.month &&
        state.rewardedDay!.day == now.day;

    state = state.copyWith(
      rewardedDay: now,
      rewardedViewsToday: sameDay ? state.rewardedViewsToday + 1 : 1,
    );
    await _persist();

    await _ref
        .read(proStatusProvider.notifier)
        .grantTemporaryPass(AdPolicy.rewardedPassDuration);
  }

  Future<void> _persist() =>
      _ref.read(preferencesDataSourceProvider).saveAdPolicyState(state);
}

final adPolicyProvider =
    StateNotifierProvider<AdPolicyNotifier, AdPolicyState>((ref) {
  return AdPolicyNotifier(ref);
});

/// Whether the bottom banner should be on screen.
final showBannerProvider = Provider<bool>((ref) {
  return AdPolicy.showBanner(isPro: ref.watch(isProProvider));
});

/// Preloads one interstitial, and refuses to start the SDK at all for Pro users.
final interstitialAdManagerProvider = Provider<InterstitialAdManager>((ref) {
  final manager = InterstitialAdManager();
  if (!ref.watch(isProProvider)) manager.preload();
  ref.onDispose(manager.dispose);
  return manager;
});

final rewardedAdManagerProvider = Provider<RewardedAdManager>((ref) {
  final manager = RewardedAdManager();
  ref.onDispose(manager.dispose);
  return manager;
});
