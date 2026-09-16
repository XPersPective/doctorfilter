import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Collects the consent AdMob requires before any ad may be requested.
///
/// Two separate obligations, both handled here because both must complete before
/// the first ad request:
///
/// * **UMP** — Google's consent platform. In the EEA and UK, serving a
///   personalised ad without it breaches both GDPR and AdMob's own policy, and
///   Google will stop serving ads to the app entirely.
/// * **ATT** — Apple's App Tracking Transparency prompt. Required on iOS 14.5+
///   before the advertising identifier can be read; skipping it is an App Store
///   rejection.
///
/// Consent is only ever requested for users who need to be asked. UMP itself
/// decides that from the user's region, which is why the form is *requested*
/// rather than *shown* unconditionally.
abstract final class AdConsent {
  static bool _completed = false;

  /// Whether ads may now be requested.
  ///
  /// False until consent has been resolved, so an ad widget that builds early
  /// does not fire a request Google would reject.
  static bool get canRequestAds => _completed;

  static final Completer<void> _sdkReady = Completer<void>();

  /// Completes once consent is settled and the SDK is initialised.
  ///
  /// Every ad load waits on this. A banner requested while the consent form
  /// was still up simply never answered — neither loaded nor failed — so the
  /// app looked ad-free to free users. Never completes for Pro users, whose
  /// SDK is never started.
  static Future<void> get sdkReady => _sdkReady.future;

  static void markSdkReady() {
    if (!_sdkReady.isCompleted) _sdkReady.complete();
  }

  /// Resolves consent. Safe to call more than once; only the first does work.
  ///
  /// Never throws. A consent failure should cost the app its ad revenue for the
  /// session, not its launch.
  static Future<void> gather() async {
    if (_completed) return;
    if (!_isSupported) {
      _completed = true;
      return;
    }

    try {
      await _requestUmpConsent();
      await _requestTrackingAuthorization();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Ads] Consent could not be gathered: $error');
      }
    } finally {
      // Either way the app carries on. Without consent Google serves
      // non-personalised ads rather than none.
      _completed = true;
    }
  }

  static bool get _isSupported => Platform.isAndroid || Platform.isIOS;

  static Future<void> _requestUmpConsent() async {
    final completer = _Completer();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        final available = await ConsentInformation.instance.isConsentFormAvailable();
        if (available) {
          await _loadAndShowFormIfRequired();
        }
        completer.done();
      },
      (error) {
        if (kDebugMode) {
          debugPrint('[Ads] UMP update failed: ${error.message}');
        }
        completer.done();
      },
    );

    await completer.future;
  }

  static Future<void> _loadAndShowFormIfRequired() async {
    final completer = _Completer();
    ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null && kDebugMode) {
        debugPrint('[Ads] UMP form failed: ${error.message}');
      }
      completer.done();
    });
    await completer.future;
  }

  /// Asks for App Tracking Transparency on iOS.
  ///
  /// A no-op on Android, and on iOS only prompts when the user has not already
  /// answered — the system shows the dialog at most once per install regardless,
  /// but asking only when needed avoids a pointless await.
  static Future<void> _requestTrackingAuthorization() async {
    if (!Platform.isIOS) return;

    final status =
        await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status != TrackingStatus.notDetermined) return;

    await AppTrackingTransparency.requestTrackingAuthorization();
  }
}

/// A one-shot completer that ignores repeat completions.
///
/// The UMP callbacks are documented as firing once, but a double call would
/// otherwise throw and take the launch down with it.
class _Completer {
  final _completer = Completer<void>();

  Future<void> get future => _completer.future;

  void done() {
    if (!_completer.isCompleted) _completer.complete();
  }
}
