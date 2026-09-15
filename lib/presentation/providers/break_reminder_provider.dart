import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import 'pro_provider.dart';

/// State of the 20-20-20 eye-break reminder.
final class BreakReminder {
  const BreakReminder({required this.isEnabled, required this.intervalMinutes});

  final bool isEnabled;
  final int intervalMinutes;

  /// The 20 in 20-20-20. Free users get this and nothing else to fiddle with.
  static const int defaultInterval = 20;

  static const int minInterval = 5;
  static const int maxInterval = 120;
}

/// Owns the reminder setting and keeps the platform alarm in step with it.
///
/// The alarm itself lives natively: it has to fire while the app is closed,
/// which is nearly all of the time it matters.
class BreakReminderNotifier extends StateNotifier<BreakReminder> {
  BreakReminderNotifier(this._ref)
      : super(
          BreakReminder(
            isEnabled: _ref.read(preferencesDataSourceProvider).breakReminderEnabled(),
            intervalMinutes:
                _ref.read(preferencesDataSourceProvider).breakIntervalMinutes(),
          ),
        );

  final Ref _ref;

  Future<void> setEnabled(bool isEnabled) async {
    state = BreakReminder(
      isEnabled: isEnabled,
      intervalMinutes: state.intervalMinutes,
    );
    await _ref.read(preferencesDataSourceProvider).setBreakReminderEnabled(isEnabled);
    await _sync();
  }

  /// Changing the interval is a Pro feature; the reminder itself is not.
  ///
  /// Twenty minutes is the evidence-backed number, so the free version gets the
  /// version that works. Paying buys a different number, not a working one.
  Future<void> setInterval(int minutes) async {
    if (!_ref.read(isProProvider)) return;

    final clamped =
        minutes.clamp(BreakReminder.minInterval, BreakReminder.maxInterval);
    state = BreakReminder(isEnabled: state.isEnabled, intervalMinutes: clamped);
    await _ref.read(preferencesDataSourceProvider).setBreakIntervalMinutes(clamped);
    await _sync();
  }

  Future<void> _sync() async {
    await _ref.read(platformChannelDataSourceProvider).setBreakReminder(
          isEnabled: state.isEnabled,
          intervalMinutes: state.intervalMinutes,
        );
  }
}

final breakReminderProvider =
    StateNotifierProvider<BreakReminderNotifier, BreakReminder>((ref) {
  return BreakReminderNotifier(ref);
});
