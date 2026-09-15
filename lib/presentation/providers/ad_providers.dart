import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/presentation/ads/interstitial_ad_manager.dart';

/// Preloads one interstitial ad and exposes it to the UI layer.
final interstitialAdManagerProvider = Provider<InterstitialAdManager>((ref) {
  final manager = InterstitialAdManager()..preload();
  ref.onDispose(manager.dispose);
  return manager;
});
