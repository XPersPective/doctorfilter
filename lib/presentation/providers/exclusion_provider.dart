import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

/// Which apps the filter steps aside for.
final class ExclusionState {
  const ExclusionState({
    required this.isEnabled,
    required this.packages,
    required this.hasPermission,
  });

  final bool isEnabled;
  final Set<String> packages;

  /// Usage access, which the user grants in system settings and can revoke.
  final bool hasPermission;

  bool get isActive => isEnabled && hasPermission && packages.isNotEmpty;
}

/// Owns the exclusion list; the watching itself happens natively.
///
/// A warm, dimmed screen is wrong for exactly the tasks where colour is the
/// point — taking a photo, editing one, watching a film. Without this the user
/// turns the filter off to look at something and forgets to turn it back on.
class ExclusionNotifier extends StateNotifier<ExclusionState> {
  ExclusionNotifier(this._ref)
      : super(
          ExclusionState(
            isEnabled: _ref.read(preferencesDataSourceProvider).appExclusionsEnabled(),
            packages:
                _ref.read(preferencesDataSourceProvider).excludedPackages().toSet(),
            hasPermission: false,
          ),
        ) {
    refreshPermission();
  }

  final Ref _ref;

  /// Re-asked rather than remembered: usage access can be withdrawn in system
  /// settings at any time, and a feature that silently stopped working is worse
  /// than one that says it needs permission.
  Future<void> refreshPermission() async {
    final granted =
        await _ref.read(platformChannelDataSourceProvider).hasUsageAccess();
    if (!mounted) return;

    state = ExclusionState(
      isEnabled: state.isEnabled,
      packages: state.packages,
      hasPermission: granted,
    );
    await _sync();
  }

  Future<void> requestPermission() =>
      _ref.read(platformChannelDataSourceProvider).requestUsageAccess();

  Future<void> setEnabled(bool isEnabled) async {
    state = ExclusionState(
      isEnabled: isEnabled,
      packages: state.packages,
      hasPermission: state.hasPermission,
    );
    await _ref.read(preferencesDataSourceProvider).setAppExclusionsEnabled(isEnabled);
    await _sync();
  }

  Future<void> toggle(String packageName) async {
    final next = Set<String>.from(state.packages);
    if (!next.remove(packageName)) next.add(packageName);

    state = ExclusionState(
      isEnabled: state.isEnabled,
      packages: next,
      hasPermission: state.hasPermission,
    );
    await _ref
        .read(preferencesDataSourceProvider)
        .setExcludedPackages(next.toList());
    await _sync();
  }

  Future<void> _sync() async {
    await _ref.read(platformChannelDataSourceProvider).setAppExclusions(
          // Never armed without the permission: the native side would poll for
          // a foreground app it is not allowed to see.
          isEnabled: state.isEnabled && state.hasPermission,
          packages: state.packages.toList(),
        );
  }
}

final exclusionProvider =
    StateNotifierProvider<ExclusionNotifier, ExclusionState>((ref) {
  return ExclusionNotifier(ref);
});

/// The installed-app list for the picker. Auto-disposed — it is a few hundred
/// icons and there is no reason to hold them once the picker closes.
final installedAppsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(platformChannelDataSourceProvider).launchableApps();
});
