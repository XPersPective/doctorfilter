import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import 'pro_provider.dart';

/// Whether the filter follows the light in the room.
///
/// The right amount of dimming is a property of the room, not of the settings:
/// 45% is gentle in a lit kitchen and nearly opaque in a dark bedroom, and the
/// same person wants both without touching a slider.
///
/// The adjustment itself happens natively, against the painted overlay only —
/// the user's stored values are never rewritten by the room.
class AmbientNotifier extends StateNotifier<bool> {
  AmbientNotifier(this._ref)
      : super(
          // Pro-only, so an expired or refunded entitlement has to switch it
          // off rather than leave a paid feature quietly running.
          _ref.read(preferencesDataSourceProvider).ambientAdaptation() &&
              _ref.read(isProProvider),
        ) {
    _sync();
  }

  final Ref _ref;

  Future<void> setEnabled(bool isEnabled) async {
    if (isEnabled && !_ref.read(isProProvider)) return;

    state = isEnabled;
    await _ref.read(preferencesDataSourceProvider).setAmbientAdaptation(isEnabled);
    await _sync();
  }

  Future<void> _sync() async {
    await _ref
        .read(platformChannelDataSourceProvider)
        .setAmbientAdaptation(isEnabled: state);
  }
}

final ambientProvider = StateNotifierProvider<AmbientNotifier, bool>((ref) {
  return AmbientNotifier(ref);
});
