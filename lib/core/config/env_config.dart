import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Where the app's ad unit ids come from.
///
/// Three sources, in order:
/// 1. `--dart-define` at build time, which is how release builds are signed.
/// 2. A local `.env`, for development.
/// 3. Google's own published *test* ids.
///
/// The third matters for an open-source project: anyone can clone this repo and
/// run the app immediately, and they get test ads rather than a crash or, worse,
/// traffic against the real account. No real id is ever committed.
///
/// There are deliberately no purchase keys here — `in_app_purchase` talks to the
/// store with the app's signature, so there is no secret to keep. And no
/// analytics or crash-reporting DSN, because the app collects neither.
abstract final class EnvConfig {
  static bool _isInitialized = false;

  /// Initializes the environment configuration.
  /// Safely catches missing `.env` errors so open-source contributors can run
  /// the app without runtime crashes.
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      await dotenv.load(fileName: '.env');
      if (kDebugMode) {
        debugPrint('[EnvConfig] Successfully loaded .env file');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[EnvConfig] Notice: .env file not loaded ($e). '
          'Falling back to compile-time definitions and default test credentials.',
        );
      }
    } finally {
      _isInitialized = true;
    }
  }

  // ---------------------------------------------------------------------------
  // Helper for Hybrid Value Lookup
  // ---------------------------------------------------------------------------
  static String _getValue(
    String key, {
    String defaultValue = '',
    String compileTimeValue = '',
  }) {
    if (compileTimeValue.isNotEmpty) {
      return compileTimeValue;
    }
    return dotenv.maybeGet(key) ?? defaultValue;
  }

  // ---------------------------------------------------------------------------
  // App Environment
  // ---------------------------------------------------------------------------
  static String get appEnv => _getValue(
        'APP_ENV',
        compileTimeValue: const String.fromEnvironment('APP_ENV'),
        defaultValue: 'development',
      );

  static String get appName => _getValue(
        'APP_NAME',
        compileTimeValue: const String.fromEnvironment('APP_NAME'),
        defaultValue: 'DoctorFilter',
      );

  static bool get isProduction => appEnv.toLowerCase() == 'production';
  static bool get isDevelopment => appEnv.toLowerCase() == 'development';

  // ---------------------------------------------------------------------------
  // Google AdMob
  // Uses Google's official sample test unit IDs by default:
  // https://developers.google.com/admob/android/test-ads
  // ---------------------------------------------------------------------------
  static String get adMobAndroidAppId => _getValue(
        'ADMOB_ANDROID_APP_ID',
        compileTimeValue: const String.fromEnvironment('ADMOB_ANDROID_APP_ID'),
        defaultValue: 'ca-app-pub-3940256099942544~3347511713',
      );

  static String get adMobIosAppId => _getValue(
        'ADMOB_IOS_APP_ID',
        compileTimeValue: const String.fromEnvironment('ADMOB_IOS_APP_ID'),
        defaultValue: 'ca-app-pub-3940256099942544~1458002511',
      );

  static String get adMobBannerUnitId => defaultTargetPlatform ==
          TargetPlatform.iOS
      ? _getValue(
          'ADMOB_IOS_BANNER_UNIT_ID',
          compileTimeValue:
              const String.fromEnvironment('ADMOB_IOS_BANNER_UNIT_ID'),
          defaultValue: 'ca-app-pub-3940256099942544/2934735716',
        )
      : _getValue(
          'ADMOB_ANDROID_BANNER_UNIT_ID',
          compileTimeValue:
              const String.fromEnvironment('ADMOB_ANDROID_BANNER_UNIT_ID'),
          defaultValue: 'ca-app-pub-3940256099942544/6300978111',
        );

  static String get adMobInterstitialUnitId => defaultTargetPlatform ==
          TargetPlatform.iOS
      ? _getValue(
          'ADMOB_IOS_INTERSTITIAL_UNIT_ID',
          compileTimeValue:
              const String.fromEnvironment('ADMOB_IOS_INTERSTITIAL_UNIT_ID'),
          defaultValue: 'ca-app-pub-3940256099942544/4411468910',
        )
      : _getValue(
          'ADMOB_ANDROID_INTERSTITIAL_UNIT_ID',
          compileTimeValue:
              const String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL_UNIT_ID'),
          defaultValue: 'ca-app-pub-3940256099942544/1033173712',
        );

  static String get adMobRewardedUnitId => defaultTargetPlatform ==
          TargetPlatform.iOS
      ? _getValue(
          'ADMOB_IOS_REWARDED_UNIT_ID',
          compileTimeValue:
              const String.fromEnvironment('ADMOB_IOS_REWARDED_UNIT_ID'),
          defaultValue: 'ca-app-pub-3940256099942544/1712485313',
        )
      : _getValue(
          'ADMOB_ANDROID_REWARDED_UNIT_ID',
          compileTimeValue:
              const String.fromEnvironment('ADMOB_ANDROID_REWARDED_UNIT_ID'),
          defaultValue: 'ca-app-pub-3940256099942544/5224354917',
        );

}
