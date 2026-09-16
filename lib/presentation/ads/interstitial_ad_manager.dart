import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:doctorfilter/core/config/env_config.dart';
import 'package:doctorfilter/presentation/ads/ad_consent.dart';

/// Loads and shows full-screen ads.
///
/// Knows nothing about *when* one is allowed — that is [AdPolicy]'s job, and the
/// caller has already asked it. This class only deals with the SDK, so the rules
/// stay testable without one.
class InterstitialAdManager {
  InterstitialAd? _ad;
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
    await InterstitialAd.load(
      adUnitId: EnvConfig.adMobInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          done.complete();
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          if (kDebugMode) {
            debugPrint('[Ads] Interstitial failed to load: ${error.message}');
          }
          done.complete();
        },
      ),
    );
    return done.future;
  }

  /// Shows a preloaded ad, returning whether one actually appeared.
  ///
  /// The answer matters: the caller only marks the user's ad budget as spent
  /// when an ad really showed, so a failed load does not quietly cost them their
  /// next eligible slot.
  Future<bool> show() async {
    if (!_isSupported) return false;

    final ad = _ad;
    _ad = null;
    if (ad == null) {
      // Nothing ready. Fetch one for next time rather than blocking the user.
      preload();
      return false;
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

    await ad.show();
    return true;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
