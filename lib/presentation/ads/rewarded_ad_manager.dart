import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:doctorfilter/core/config/env_config.dart';
import 'package:doctorfilter/presentation/ads/ad_consent.dart';

/// Loads and shows rewarded ads — the optional trade of attention for a
/// temporary Pro pass.
///
/// Never shown on its own initiative. The user asks for it, from a button that
/// says exactly what they get; an ad that appears uninvited is not a reward.
class RewardedAdManager {
  RewardedAd? _ad;
  Future<void>? _loading;

  static bool get _isSupported => Platform.isAndroid || Platform.isIOS;

  bool get isReady => _ad != null;

  /// Completes when the ad has loaded or failed — not when the request was
  /// sent. Callers that preload and then show depend on that; returning early
  /// meant "show" always found nothing.
  Future<void> preload() {
    if (!_isSupported || _ad != null) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    await AdConsent.sdkReady;
    final done = Completer<void>();
    await RewardedAd.load(
      adUnitId: EnvConfig.adMobRewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          done.complete();
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          if (kDebugMode) {
            debugPrint('[Ads] Rewarded failed to load: ${error.message}');
          }
          done.complete();
        },
      ),
    );
    return done.future;
  }

  /// Shows the ad and reports whether the user earned the reward.
  ///
  /// False when they closed it early. The reward is for watching, and quietly
  /// granting it anyway would breach AdMob's terms as well as being a lie about
  /// what the button said.
  Future<bool> showForReward() async {
    if (!_isSupported) return false;

    final ad = _ad;
    _ad = null;
    if (ad == null) {
      preload();
      return false;
    }

    // Answered when the ad closes, not when it opens: show() returns as soon
    // as the ad is on screen, long before the user has earned anything.
    var earned = false;
    final closed = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
        if (!closed.isCompleted) closed.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
        if (!closed.isCompleted) closed.complete(false);
      },
    );

    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return closed.future;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
