import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/usecases/toggle_filter_usecase.dart';
import 'package:doctorfilter/domain/usecases/update_filter_params_usecase.dart';
import 'core_providers.dart';

final class FilterState {
  const FilterState({
    required this.config,
    required this.hasOverlayPermission,
    this.isLoading = false,
    this.errorMessage,
  });

  final FilterConfig config;
  final bool hasOverlayPermission;
  final bool isLoading;
  final String? errorMessage;

  FilterState copyWith({
    FilterConfig? config,
    bool? hasOverlayPermission,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FilterState(
      config: config ?? this.config,
      hasOverlayPermission: hasOverlayPermission ?? this.hasOverlayPermission,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier(
    this._toggleFilterUseCase,
    this._updateFilterParamsUseCase,
    this._ref,
  ) : super(FilterState(
          config: FilterConfig.initial(),
          hasOverlayPermission: false,
          isLoading: true,
        )) {
    _init();
  }

  final ToggleFilterUseCase _toggleFilterUseCase;
  final UpdateFilterParamsUseCase _updateFilterParamsUseCase;
  final Ref _ref;

  Future<void> _init() async {
    final filterRepo = _ref.read(filterRepositoryProvider);
    final permResult = await filterRepo.checkOverlayPermission();
    final isPermitted = permResult.dataOrNull ?? false;

    final configResult = await filterRepo.getFilterConfig();
    final config = configResult.dataOrNull ?? FilterConfig.initial();

    state = state.copyWith(
      config: config,
      hasOverlayPermission: isPermitted,
      isLoading: false,
    );

    // Watch real-time native events (e.g. user toggled from notification bar)
    filterRepo.watchFilterConfig().listen((updatedConfig) {
      if (mounted) {
        state = state.copyWith(config: updatedConfig);
      }
    });
  }

  Future<void> checkPermission() async {
    final filterRepo = _ref.read(filterRepositoryProvider);
    final permResult = await filterRepo.checkOverlayPermission();
    final isPermitted = permResult.dataOrNull ?? false;
    state = state.copyWith(hasOverlayPermission: isPermitted);
  }

  Future<void> requestPermission() async {
    final filterRepo = _ref.read(filterRepositoryProvider);
    await filterRepo.requestOverlayPermission();
  }

  Future<void> toggleFilter({bool? forceState}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _toggleFilterUseCase(forceState: forceState);
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (newConfig) {
        state = state.copyWith(
          config: newConfig,
          isLoading: false,
          hasOverlayPermission: true,
        );
      },
    );
  }

  Future<void> updateKelvin(int kelvin) async {
    final rgb = KelvinEngine.kelvinToRgb(kelvin);
    final result = await _updateFilterParamsUseCase(
      kelvin: kelvin,
      red: rgb.r,
      green: rgb.g,
      blue: rgb.b,
    );
    if (result is Success<FilterConfig>) {
      state = state.copyWith(config: result.data);
    }
  }

  Future<void> updateAlpha(int alpha) async {
    final result = await _updateFilterParamsUseCase(alpha: alpha);
    if (result is Success<FilterConfig>) {
      state = state.copyWith(config: result.data);
    }
  }

  Future<void> updateBrightness(int brightness) async {
    final result = await _updateFilterParamsUseCase(brightness: brightness);
    if (result is Success<FilterConfig>) {
      state = state.copyWith(config: result.data);
    }
  }

  Future<void> setNotificationEnabled(bool isEnabled) async {
    final result = await _updateFilterParamsUseCase(isNotificationEnabled: isEnabled);
    if (result is Success<FilterConfig>) {
      state = state.copyWith(config: result.data);
    }
  }
}

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  final toggleUseCase = ref.watch(toggleFilterUseCaseProvider);
  final updateUseCase = ref.watch(updateFilterParamsUseCaseProvider);
  return FilterNotifier(
    toggleUseCase,
    updateUseCase,
    ref,
  );
});
