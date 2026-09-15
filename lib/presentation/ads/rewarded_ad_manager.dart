import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:doctorfilter/core/config/env_config.dart';

/// Loads and shows rewarded ads — the optional trade of attention for a
/// temporary Pro pass.
///
/// Never shown on its own initiative. The user asks for it, from a button that
/// says exactly what they get; an ad that appears uninvited is not a reward.
class RewardedAdManager {
  RewardedAd? _ad;
  bool _isLoading = false;

  static bool get _isSupported => Platform.isAndroid || Platform.isIOS;

  bool get isReady => _ad != null;

  Future<void> preload() async {
    if (!_isSupported || _ad != null || _isLoading) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: EnvConfig.adMobRewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _isLoading = false;
          if (kDebugMode) {
            debugPrint('[Ads] Rewarded failed to load: ${error.message}');
          }
        },
      ),
    );
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

    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
      },
    );

    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return earned;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
