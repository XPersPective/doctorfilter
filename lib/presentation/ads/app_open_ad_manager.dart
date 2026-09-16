import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:doctorfilter/core/config/env_config.dart';

/// The ad shown while the app opens.
///
/// Knows nothing about *whether* one is allowed — [AdPolicy.mayShowAppOpen]
/// decides that before this is called.
abstract final class AppOpenAdManager {
  /// Loads an ad and shows it only if it arrives within [timeout].
  ///
  /// An app-open ad belongs to the moment of opening. One that turns up
  /// seconds later lands on a user who has already reached for a slider, so a
  /// slow load is dropped rather than shown late. Returns whether it appeared.
  static Future<bool> loadAndShow({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    final loaded = Completer<AppOpenAd?>();
    await AppOpenAd.load(
      adUnitId: EnvConfig.adMobAppOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          if (loaded.isCompleted) {
            ad.dispose();
          } else {
            loaded.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            debugPrint('[Ads] App-open failed to load: ${error.message}');
          }
          if (!loaded.isCompleted) loaded.complete(null);
        },
      ),
    );

    final ad = await loaded.future.timeout(timeout, onTimeout: () => null);
    if (!loaded.isCompleted) loaded.complete(null);
    if (ad == null) return false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
    );
    await ad.show();
    return true;
  }
}
