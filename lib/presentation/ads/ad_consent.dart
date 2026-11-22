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
  static const _updateTimeout = Duration(seconds: 12);
  static const _dialogTimeout = Duration(minutes: 2);
  static const _sdkTimeout = Duration(seconds: 15);

  /// Whether the user's region requires a way back into the consent form.
  ///
  /// GDPR lets a user withdraw consent as easily as they gave it; AdMob
  /// enforces that by requiring a visible entry point when UMP says so.
  static bool privacyOptionsRequired = false;

  /// Reopens the consent form so the user can change their choice.
  static Future<void> showPrivacyOptions() =>
      ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null && kDebugMode) {
          debugPrint('[Ads] Privacy options failed: ${error.message}');
        }
      });

  static final _sdkReady = ValueNotifier(false);

  /// A bounded wait for callers that build before foreground initialization.
  static Future<bool> waitForSdk() async {
    if (_sdkReady.value) return true;
    final ready = Completer<bool>();
    void listener() => ready.complete(true);
    _sdkReady.addListener(listener);
    try {
      return await ready.future.timeout(_sdkTimeout, onTimeout: () => false);
    } finally {
      _sdkReady.removeListener(listener);
    }
  }

  static Future<bool> initialize({required bool Function() isEligible}) async {
    if (_sdkReady.value) return true;

    try {
      if (!await _requestUmpConsent() || !isEligible()) return false;
      await _requestTrackingAuthorization().timeout(_dialogTimeout);
      if (!isEligible()) return false;
      await MobileAds.instance.initialize().timeout(_sdkTimeout);
      _sdkReady.value = true;
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Ads] Consent or SDK initialization failed: $error');
      }
      return false;
    }
  }

  static Future<bool> _requestUmpConsent() async {
    final updated = Completer<bool>();
    final consent = ConsentInformation.instance;
    consent.requestConsentInfoUpdate(
      ConsentRequestParameters(consentDebugSettings: _debugSettings),
      () {
        if (!updated.isCompleted) updated.complete(true);
      },
      (error) {
        if (kDebugMode) debugPrint('[Ads] UMP update failed: ${error.message}');
        if (!updated.isCompleted) updated.complete(false);
      },
    );

    if (await updated.future.timeout(_updateTimeout, onTimeout: () => false)) {
      await _loadAndShowFormIfRequired().timeout(_dialogTimeout);
      privacyOptionsRequired =
          await consent.getPrivacyOptionsRequirementStatus().timeout(
            _updateTimeout,
          ) ==
          PrivacyOptionsRequirementStatus.required;
    }

    // A failed refresh can still have a valid choice from a prior launch.
    return consent.canRequestAds().timeout(_updateTimeout);
  }

  /// Debug builds only: `--dart-define=UMP_DEBUG_EEA=true` makes UMP treat the
  /// device as being in the EEA, so the form can be tested from anywhere.
  /// `UMP_TEST_DEVICE_ID` is the hashed id UMP prints to logcat on first run.
  static ConsentDebugSettings? get _debugSettings {
    if (!kDebugMode || !const bool.fromEnvironment('UMP_DEBUG_EEA')) {
      return null;
    }
    const deviceId = String.fromEnvironment('UMP_TEST_DEVICE_ID');
    return ConsentDebugSettings(
      debugGeography: DebugGeography.debugGeographyEea,
      testIdentifiers: deviceId.isEmpty ? null : [deviceId],
    );
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

    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
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
