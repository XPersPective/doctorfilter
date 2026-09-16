import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:doctorfilter/core/config/env_config.dart';
import 'package:doctorfilter/presentation/ads/ad_consent.dart';
import 'package:doctorfilter/presentation/providers/ad_providers.dart';

/// Banner anchored above the bottom navigation bar.
///
/// Takes up no space at all when it is not showing — while loading, on an
/// unsupported platform, or for a Pro user. Reserving a blank strip "so the
/// layout does not jump" would leave every paying user staring at a hole where
/// they used to be advertised at.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  bool get _isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    // Read rather than watch: a Pro user must never have the SDK started, and
    // entitlement gained mid-session is handled by the build method below.
    if (_isSupported && ref.read(showBannerProvider)) {
      AdConsent.sdkReady.then((_) {
        if (mounted && ref.read(showBannerProvider)) _loadAd();
      });
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: EnvConfig.adMobBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('[Ads] Banner failed to load: ${error.message}');
          }
          ad.dispose();
          if (mounted) setState(() => _isLoaded = false);
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(showBannerProvider) || !_isSupported || !_isLoaded) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
