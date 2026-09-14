import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';
import 'package:doctorfilter/domain/usecases/apply_preset_usecase.dart';
import 'core_providers.dart';
import 'filter_provider.dart';

final class PresetState {
  const PresetState({
    required this.presets,
    required this.activePresetId,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<FilterPreset> presets;
  final int activePresetId;
  final bool isLoading;
  final String? errorMessage;

  FilterPreset? get activePreset {
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return presets.isNotEmpty ? presets.first : null;
    }
  }

  PresetState copyWith({
    List<FilterPreset>? presets,
    int? activePresetId,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class PresetNotifier extends StateNotifier<PresetState> {
  PresetNotifier(
    this._applyPresetUseCase,
    this._ref,
  ) : super(const PresetState(
          presets: [],
          activePresetId: 0,
          isLoading: true,
        )) {
    loadPresets();
  }

  final ApplyPresetUseCase _applyPresetUseCase;
  final Ref _ref;

  Future<void> loadPresets() async {
    state = state.copyWith(isLoading: true);
    final presetRepo = _ref.read(presetRepositoryProvider);
    final filterRepo = _ref.read(filterRepositoryProvider);

    final presetsResult = await presetRepo.getAllPresets();
    final configResult = await filterRepo.getFilterConfig();

    final presets = presetsResult.dataOrNull ?? [];
    final activeId = configResult.dataOrNull?.activePresetId ?? 0;

    state = state.copyWith(
      presets: presets,
      activePresetId: activeId,
      isLoading: false,
    );
  }

  Future<void> selectPreset(int presetId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _applyPresetUseCase(presetId);
    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (newConfig) {
        state = state.copyWith(
          activePresetId: presetId,
          isLoading: false,
        );
        // Sync filterProvider state
        _ref.read(filterProvider.notifier).updateKelvin(newConfig.kelvin);
        _ref.read(filterProvider.notifier).updateAlpha(newConfig.alpha);
        _ref.read(filterProvider.notifier).updateBrightness(newConfig.brightness);
      },
    );
  }

  Future<void> saveCustomPreset({
    required String name,
    required int kelvin,
    required int red,
    required int green,
    required int blue,
    required int alpha,
    required int brightness,
  }) async {
    final presetRepo = _ref.read(presetRepositoryProvider);
    final newId = DateTime.now().millisecondsSinceEpoch % 100000;
    final newPreset = FilterPreset(
      id: newId,
      nameKey: name,
      kelvin: kelvin,
      red: red,
      green: green,
      blue: blue,
      alpha: alpha,
      brightness: brightness,
      iconIdentifier: 'custom',
      isCustom: true,
      isProOnly: false,
    );

    await presetRepo.savePreset(newPreset);
    await loadPresets();
    await selectPreset(newId);
  }

  Future<void> deletePreset(int presetId) async {
    final presetRepo = _ref.read(presetRepositoryProvider);
    await presetRepo.deletePreset(presetId);
    await loadPresets();
  }

  Future<void> resetToDefaults() async {
    final presetRepo = _ref.read(presetRepositoryProvider);
    await presetRepo.resetToDefaultPresets();
    await loadPresets();
    await selectPreset(0);
  }
}

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  final applyUseCase = ref.watch(applyPresetUseCaseProvider);
  return PresetNotifier(
    applyUseCase,
    ref,
  );
});
