import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/errors/failure.dart';
import 'package:doctorfilter/data/datasources/native/platform_channel_datasource.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/repositories/i_filter_repository.dart';
import 'package:doctorfilter/domain/usecases/toggle_filter_usecase.dart';
import 'core_providers.dart';

final class FilterState {
  const FilterState({
    required this.config,
    required this.hasOverlayPermission,
    this.isBusy = false,
    this.errorKey,
  });

  final FilterConfig config;
  final bool hasOverlayPermission;
  final bool isBusy;

  /// Localization key of the last failure, or null. A key rather than a message:
  /// the domain layer does not know what language the user reads.
  final String? errorKey;

  FilterState copyWith({
    FilterConfig? config,
    bool? hasOverlayPermission,
    bool? isBusy,
    String? errorKey,
    bool clearError = false,
  }) {
    return FilterState(
      config: config ?? this.config,
      hasOverlayPermission: hasOverlayPermission ?? this.hasOverlayPermission,
      isBusy: isBusy ?? this.isBusy,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
    );
  }
}

/// Owns the live filter configuration.
///
/// This object is the single source of truth. Disk is read once at startup and
/// written afterwards, never read back during a session — the previous design
/// re-read from disk on every slider tick, and concurrent read-modify-write
/// cycles lost each other's changes, which the user experienced as settings
/// resetting themselves.
///
/// Every mutation follows the same order: update memory, push to the overlay so
/// the screen reacts immediately, then persist (debounced).
class FilterNotifier extends StateNotifier<FilterState> with WidgetsBindingObserver {
  FilterNotifier(this._repository, this._toggleFilter)
      : super(FilterState(
          config: FilterConfig.initial(),
          hasOverlayPermission: false,
          isBusy: true,
        )) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  final IFilterRepository _repository;
  final ToggleFilterUseCase _toggleFilter;
  StreamSubscription<NativeFilterEvent>? _nativeSubscription;

  Future<void> _init() async {
    final loaded = await _repository.loadConfig();
    final config = loaded.dataOrNull ?? FilterConfig.initial();
    final permission = await _repository.checkOverlayPermission();

    if (!mounted) return;
    state = FilterState(
      config: config,
      hasOverlayPermission: permission.dataOrNull ?? false,
      isBusy: false,
    );

    _nativeSubscription = _repository.nativeEvents.listen(_onNativeEvent);
  }

  /// The overlay permission can only be granted in system settings, so the app
  /// is backgrounded while it happens. Re-checking on resume is what makes the
  /// "grant permission" banner disappear by itself instead of lingering after
  /// the user has already done what it asked.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    switch (lifecycleState) {
      case AppLifecycleState.resumed:
        refreshPermission();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _repository.flush();
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _onNativeEvent(NativeFilterEvent event) {
    if (!mounted) return;
    final updated = switch (event) {
      NativeFilterToggled(:final isEnabled) =>
        state.config.copyWith(isEnabled: isEnabled),
      NativePresetSelected(:final presetId) =>
        state.config.copyWith(activePresetId: presetId),
      NativeAxisChanged(:final kelvin, :final densityPercent, :final extraDimPercent) =>
        state.config.copyWith(
          kelvin: kelvin,
          densityPercent: densityPercent,
          extraDimPercent: extraDimPercent,
        ),
    };
    state = state.copyWith(config: updated);
    _repository.persist(updated);
  }

  Future<void> refreshPermission() async {
    final permission = await _repository.checkOverlayPermission();
    if (!mounted) return;
    state = state.copyWith(hasOverlayPermission: permission.dataOrNull ?? false);
  }

  Future<void> requestPermission() => _repository.requestOverlayPermission();

  Future<void> toggle({bool? forceState}) async {
    state = state.copyWith(isBusy: true, clearError: true);
    final result = await _toggleFilter(state.config, forceState: forceState);
    if (!mounted) return;

    state = result.fold(
      (failure) => state.copyWith(
        isBusy: false,
        errorKey: failure is PermissionFailure ? failure.message : 'error_filter_failed',
        hasOverlayPermission:
            failure is PermissionFailure ? false : state.hasOverlayPermission,
      ),
      (config) => state.copyWith(
        config: config,
        isBusy: false,
        hasOverlayPermission: true,
        clearError: true,
      ),
    );
  }

  void setKelvin(int kelvin) => _apply(state.config.copyWith(kelvin: kelvin));

  void setDensity(int percent) =>
      _apply(state.config.copyWith(densityPercent: percent));

  void setExtraDim(int percent) =>
      _apply(state.config.copyWith(extraDimPercent: percent));

  /// Adopts a configuration produced elsewhere (applying a preset, undo).
  void adopt(FilterConfig config) {
    if (!mounted || config == state.config) return;
    state = state.copyWith(config: config);
  }

  Future<void> setNotificationEnabled(bool isEnabled) async {
    _apply(state.config.copyWith(isNotificationEnabled: isEnabled));
  }

  /// Memory first, screen second, disk last.
  ///
  /// Changing an axis by hand means the result is no longer the preset that was
  /// selected, so the active preset is cleared — otherwise the UI keeps a preset
  /// highlighted while showing values that are not its own.
  void _apply(FilterConfig config, {bool keepPreset = false}) {
    if (config == state.config) return;
    final next = keepPreset ? config : config.copyWith(activePresetId: _noPreset);
    state = state.copyWith(config: next);
    if (next.isEnabled) {
      _repository.applyToPlatform(next);
    }
    _repository.persist(next);
  }

  /// Sentinel for "the current values match no stored preset".
  static const int _noPreset = -1;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nativeSubscription?.cancel();
    _repository.flush();
    super.dispose();
  }
}

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier(
    ref.watch(filterRepositoryProvider),
    ref.watch(toggleFilterUseCaseProvider),
  );
});

/// The live configuration on its own, for widgets that do not care about
/// permission or busy state and should not rebuild when those change.
final filterConfigProvider = Provider<FilterConfig>((ref) {
  return ref.watch(filterProvider.select((state) => state.config));
});
