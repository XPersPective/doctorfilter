import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:doctorfilter/core/config/env_config.dart';

/// Loads and shows interstitial ads at natural pause points (filter disabled).
/// Ads are shown at most every [showInterval] eligible events.
class InterstitialAdManager {
  static const showInterval = 3;

  int _eventCount = 0;
  InterstitialAd? _ad;
  bool _isLoading = false;

  bool get _isSupported =>
      Platform.isAndroid || Platform.isIOS;

  Future<void> preload() async {
    if (!_isSupported || _ad != null || _isLoading) return;
    _isLoading = true;
    await InterstitialAd.load(
      adUnitId: EnvConfig.adMobInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _isLoading = false;
          if (kDebugMode) {
            debugPrint('[Ads] Interstitial failed to load: ${error.message}');
          }
        },
      ),
    );
  }

  /// Called when the user turns the filter off; shows an ad occasionally.
  void maybeShowOnFilterDisabled() {
    if (!_isSupported) return;
    _eventCount++;
    if (_eventCount % showInterval != 0) return;

    final ad = _ad;
    _ad = null;
    if (ad == null) {
      preload();
      return;
    }
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
    ad.show();
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
