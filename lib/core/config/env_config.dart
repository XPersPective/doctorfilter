import 'package:flutter/foundation.dart';

/// Where the app's ad unit ids come from.
///
/// Two sources, in order:
/// 1. `--dart-define` at build time, which is how release builds are made.
/// 2. Google's own published *test* ids.
///
/// The fallback matters for an open-source project: anyone can clone this repo
/// and run the app immediately, and they get test ads rather than a crash — or,
/// worse, live traffic billed against someone else's account. No real id is ever
/// committed.
///
/// There is deliberately no `.env` file. It was a build-time asset, and because
/// secrets are (correctly) gitignored, a fresh clone failed to build on a
/// missing asset — a repo that cannot be cloned and run is not really open
/// source. `--dart-define` needs no asset, works identically in CI, and keeps
/// values out of the bundle where a curious user could read them.
///
/// There are no purchase keys here either: `in_app_purchase` authenticates with
/// the app's signature, so there is no secret to keep. And no analytics or
/// crash-reporting DSN, because the app collects neither.
///
/// Example release build:
/// ```
/// flutter build appbundle --release \
///   --dart-define=ADMOB_ANDROID_BANNER_UNIT_ID=ca-app-pub-…/… \
///   --dart-define=ADMOB_ANDROID_INTERSTITIAL_UNIT_ID=ca-app-pub-…/… \
///   --dart-define=ADMOB_ANDROID_REWARDED_UNIT_ID=ca-app-pub-…/…
/// ```
abstract final class EnvConfig {
  /// Kept so callers need not care whether configuration is async.
  ///
  /// Nothing to load any more, but removing the call from `main` would make the
  /// next person wonder where configuration went.
  static Future<void> init() async {}

  static String get appName => const String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'DoctorFilter',
      );

  /// True only when real ad ids were supplied at build time.
  ///
  /// Useful in debug output: "ads are not showing" is almost always a build
  /// that quietly fell back to Google's test units.
  static bool get hasProductionAdIds =>
      const String.fromEnvironment('ADMOB_ANDROID_BANNER_UNIT_ID').isNotEmpty;

  // ---------------------------------------------------------------------------
  // Google AdMob
  //
  // Defaults are Google's official sample units:
  // https://developers.google.com/admob/android/test-ads
  // ---------------------------------------------------------------------------

  static bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  static String get adMobBannerUnitId => _isIos
      ? const String.fromEnvironment(
          'ADMOB_IOS_BANNER_UNIT_ID',
          defaultValue: 'ca-app-pub-3940256099942544/2934735716',
        )
      : const String.fromEnvironment(
          'ADMOB_ANDROID_BANNER_UNIT_ID',
          defaultValue: 'ca-app-pub-3940256099942544/6300978111',
        );

  static String get adMobInterstitialUnitId => _isIos
      ? const String.fromEnvironment(
          'ADMOB_IOS_INTERSTITIAL_UNIT_ID',
          defaultValue: 'ca-app-pub-3940256099942544/4411468910',
        )
      : const String.fromEnvironment(
          'ADMOB_ANDROID_INTERSTITIAL_UNIT_ID',
          defaultValue: 'ca-app-pub-3940256099942544/1033173712',
        );

  static String get adMobRewardedUnitId => _isIos
      ? const String.fromEnvironment(
          'ADMOB_IOS_REWARDED_UNIT_ID',
          defaultValue: 'ca-app-pub-3940256099942544/1712485313',
        )
      : const String.fromEnvironment(
          'ADMOB_ANDROID_REWARDED_UNIT_ID',
          defaultValue: 'ca-app-pub-3940256099942544/5224354917',
        );
}
