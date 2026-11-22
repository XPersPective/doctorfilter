import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:doctorfilter/core/config/env_config.dart';
import 'package:doctorfilter/presentation/ads/ad_consent.dart';
import 'package:doctorfilter/presentation/providers/ad_providers.dart';

/// Banner anchored above the bottom navigation bar. A missing banner never
/// reserves layout space, and failed requests retry only in the foreground.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget>
    with WidgetsBindingObserver {
  static const _retryInterval = Duration(minutes: 1);
  static const _loadTimeout = Duration(seconds: 20);
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _waitingForSdk = false;
  Timer? _retry;
  Timer? _loadDeadline;
  DateTime? _retryAfter;

  bool get _isSupported =>
      (Platform.isAndroid || Platform.isIOS) &&
      !const bool.fromEnvironment('STORE_SCREENSHOTS');

  bool get _mayLoad =>
      mounted &&
      _isSupported &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
      ref.read(showBannerProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(showBannerProvider, (_, visible) {
      if (!visible) _discardBanner();
      _syncBanner();
    });
    _syncBanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _syncBanner();

  void _syncBanner() {
    if (!_mayLoad) {
      _retry?.cancel();
      _retry = null;
      return;
    }
    if (_bannerAd != null || _waitingForSdk || _retry != null) return;
    final remaining = _retryAfter?.difference(DateTime.now());
    if (remaining != null && remaining > Duration.zero) {
      _retry = Timer(remaining, () {
        _retry = null;
        _syncBanner();
      });
      return;
    }
    _retryAfter = null;
    unawaited(_load());
  }

  Future<void> _load() async {
    _waitingForSdk = true;
    final ready = await AdConsent.waitForSdk();
    _waitingForSdk = false;
    if (!_mayLoad) return;
    if (!ready) {
      _scheduleRetry();
      return;
    }

    final banner = BannerAd(
      adUnitId: EnvConfig.adMobBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || !identical(ad, _bannerAd)) return;
          _loadDeadline?.cancel();
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: _onFailure,
      ),
    );
    _bannerAd = banner;
    _loadDeadline = Timer(_loadTimeout, () => _onFailure(banner, 'timeout'));
    try {
      await banner.load().timeout(_loadTimeout);
    } catch (error) {
      _onFailure(banner, error);
    }
  }

  void _onFailure(Ad ad, Object error) {
    if (!mounted || !identical(ad, _bannerAd)) return;
    if (kDebugMode) debugPrint('[Ads] Banner failed to load: $error');
    final wasLoaded = _isLoaded;
    _discardBanner();
    if (wasLoaded) setState(() {});
    _scheduleRetry();
  }

  void _scheduleRetry() {
    _retryAfter = DateTime.now().add(_retryInterval);
    _syncBanner();
  }

  void _discardBanner() {
    _loadDeadline?.cancel();
    final banner = _bannerAd;
    _bannerAd = null;
    _isLoaded = false;
    if (banner != null) unawaited(banner.dispose());
  }

  @override
  void dispose() {
    _retry?.cancel();
    _discardBanner();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _bannerAd;
    if (!ref.watch(showBannerProvider) || !_isLoaded || banner == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: banner.size.width.toDouble(),
      height: banner.size.height.toDouble(),
      child: AdWidget(ad: banner),
    );
  }
}
