import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized, type-safe configuration manager for application environments,
/// API endpoints, In-App Purchases, and Advertisements.
///
/// Supports hybrid configuration:
/// 1. Compile-time `--dart-define` flags (highest priority, optimal for CI/CD)
/// 2. Local `.env` file via `flutter_dotenv` (convenient for local development)
/// 3. Safe fallback defaults (prevents runtime crashes in open-source builds)
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

  static String get apiBaseUrl => _getValue(
        'API_BASE_URL',
        compileTimeValue: const String.fromEnvironment('API_BASE_URL'),
        defaultValue: 'https://api.doctorfilter.com/v1',
      );

  static bool get isProduction => appEnv.toLowerCase() == 'production';
  static bool get isDevelopment => appEnv.toLowerCase() == 'development';

  // ---------------------------------------------------------------------------
  // In-App Purchases (RevenueCat / StoreKit / Google Play Billing)
  // ---------------------------------------------------------------------------
  /// RevenueCat Public Apple SDK Key (Safe for client-side release)
  static String get revenueCatAppleApiKey => _getValue(
        'REVENUECAT_APPLE_API_KEY',
        compileTimeValue:
            const String.fromEnvironment('REVENUECAT_APPLE_API_KEY'),
        defaultValue: 'appl_mock_key_for_development',
      );

  /// RevenueCat Public Google SDK Key (Safe for client-side release)
  static String get revenueCatGoogleApiKey => _getValue(
        'REVENUECAT_GOOGLE_API_KEY',
        compileTimeValue:
            const String.fromEnvironment('REVENUECAT_GOOGLE_API_KEY'),
        defaultValue: 'goog_mock_key_for_development',
      );

  static String get revenueCatEntitlementId => _getValue(
        'REVENUECAT_ENTITLEMENT_ID',
        compileTimeValue:
            const String.fromEnvironment('REVENUECAT_ENTITLEMENT_ID'),
        defaultValue: 'pro_features',
      );

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

  // ---------------------------------------------------------------------------
  // Monitoring & Crash Reporting
  // ---------------------------------------------------------------------------
  static String get sentryDsn => _getValue(
        'SENTRY_DSN',
        compileTimeValue: const String.fromEnvironment('SENTRY_DSN'),
        defaultValue: '',
      );
}
