import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/data/datasources/native/platform_channel_datasource.dart';
import 'core_providers.dart';

/// Fires when the notification's locked chip is tapped.
///
/// A stream rather than a flag, because the same request can arrive twice — the
/// user taps a lock, decides not to buy, then taps another — and a flag would
/// only open the paywall the first time.
final nativePaywallRequestProvider = StreamProvider<void>((ref) {
  return ref
      .watch(filterRepositoryProvider)
      .nativeEvents
      .where((event) => event is NativePaywallRequested)
      .map((_) {});
});
