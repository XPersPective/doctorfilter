import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Outward-facing actions: rating and sharing.
///
/// Both were wired to empty callbacks before, so the menu items existed and did
/// nothing — the kind of dead control that makes a user distrust the rest of the
/// app.
abstract final class AppLinks {
  /// Play Store listing. The App Store id is added when iOS ships.
  static const String _packageName = 'com.crazypenguin.doctorfilter';
  static const String _playListing =
      'https://play.google.com/store/apps/details?id=$_packageName';
  static const String repository = 'https://github.com/XPersPective/doctorfilter';

  /// Asks for a rating.
  ///
  /// Prefers the in-app review sheet, which never leaves the app. The OS decides
  /// whether to actually show it — quotas, recent reviews — and gives no way to
  /// know, so when it is unavailable this falls through to the store listing
  /// rather than appearing to do nothing.
  static Future<void> requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
        return;
      }
    } catch (error) {
      if (kDebugMode) debugPrint('[Links] In-app review unavailable: $error');
    }
    await openStoreListing();
  }

  static Future<void> openStoreListing() async {
    try {
      await InAppReview.instance.openStoreListing();
    } catch (error) {
      await openUrl(_playListing);
    }
  }

  /// Shares the app.
  ///
  /// Hands off to the platform's own share sheet, so the user picks the app they
  /// already use rather than being sent somewhere we chose for them.
  /// Runs one of the user's own Shortcuts by name.
  ///
  /// The only way an app can toggle iOS's colour filter: Shortcuts has an
  /// action for it, and an app may ask Shortcuts to run one. There is a brief
  /// hop into Shortcuts and back — unavoidable, and worth saying rather than
  /// hiding, because a user who is not expecting it thinks something broke.
  ///
  /// Returns false when Shortcuts does not answer, usually because no shortcut
  /// by that name exists.
  static Future<bool> runShortcut(String name) async {
    final uri = Uri.parse(
      'shortcuts://x-callback-url/run-shortcut'
      '?name=${Uri.encodeComponent(name)}',
    );

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<void> share(String message) async {
    if (!_isMobile) return;
    try {
      await SharePlus.instance.share(
        ShareParams(text: '$message\n\n$_playListing'),
      );
    } catch (error) {
      if (kDebugMode) debugPrint('[Links] Share failed: $error');
    }
  }

  static Future<void> openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) {
      if (kDebugMode) debugPrint('[Links] Could not open $url: $error');
    }
  }

  static bool get _isMobile => Platform.isAndroid || Platform.isIOS;
}
