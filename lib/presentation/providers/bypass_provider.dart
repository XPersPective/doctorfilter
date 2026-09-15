import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/domain/repositories/i_filter_repository.dart';
import 'core_providers.dart';
import 'filter_provider.dart';

/// Lifts the filter briefly, then puts it back.
///
/// For the moment you need to see a photo's real colours, check whether a stain
/// is red or brown, or show someone something on your screen. Without this the
/// user turns the filter off, looks, and then forgets to turn it back on — which
/// is the app quietly failing at the thing it is for.
///
/// Deliberately short and automatic. A "pause" with no timer is just an off
/// switch with extra steps.
class BypassNotifier extends StateNotifier<Duration?> {
  BypassNotifier(this._ref) : super(null);

  /// Long enough to look at something properly, short enough that nobody has to
  /// remember it is running.
  static const Duration defaultDuration = Duration(seconds: 15);

  final Ref _ref;
  Timer? _countdown;
  Timer? _restore;

  bool get isActive => state != null;

  /// Suspends the filter for [duration], then restores it.
  ///
  /// Does nothing when the filter is already off — there is nothing to bypass,
  /// and starting a timer would leave the app promising to restore something
  /// that was never there.
  Future<void> start([Duration duration = defaultDuration]) async {
    final config = _ref.read(filterConfigProvider);
    if (!config.isEnabled) return;

    _cancelTimers();

    final repository = _ref.read(filterRepositoryProvider);
    // Straight to the platform, bypassing the notifier: this is a temporary
    // suspension, not a change to the user's settings, and it must not end up
    // persisted or in the undo history.
    await repository.applyToPlatform(config.copyWith(isEnabled: false));

    state = duration;
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state;
      if (remaining == null) return;
      final next = remaining - const Duration(seconds: 1);
      state = next.isNegative ? Duration.zero : next;
    });

    _restore = Timer(duration, () => _restore_(repository));
  }

  /// Puts the filter back early.
  void cancel() {
    if (state == null) return;
    _restore_(_ref.read(filterRepositoryProvider));
  }

  void _restore_(IFilterRepository repository) {
    _cancelTimers();
    state = null;
    final config = _ref.read(filterConfigProvider);
    if (config.isEnabled) repository.applyToPlatform(config);
  }

  void _cancelTimers() {
    _countdown?.cancel();
    _restore?.cancel();
    _countdown = null;
    _restore = null;
  }

  @override
  void dispose() {
    // Leaving the overlay down because a screen was disposed would be the worst
    // possible failure: the filter silently off, with nothing to turn it back on.
    if (state != null) {
      final config = _ref.read(filterConfigProvider);
      if (config.isEnabled) {
        _ref.read(filterRepositoryProvider).applyToPlatform(config);
      }
    }
    _cancelTimers();
    super.dispose();
  }
}

/// Seconds left on a temporary bypass, or null when the filter is not suspended.
final bypassProvider = StateNotifierProvider<BypassNotifier, Duration?>((ref) {
  return BypassNotifier(ref);
});
