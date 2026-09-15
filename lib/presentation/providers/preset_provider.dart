import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';
import 'package:doctorfilter/domain/usecases/apply_preset_usecase.dart';
import 'core_providers.dart';
import 'filter_provider.dart';

final class PresetState {
  const PresetState({
    required this.presets,
    this.isLoading = false,
    this.errorKey,
  });

  final List<FilterPreset> presets;
  final bool isLoading;
  final String? errorKey;

  PresetState copyWith({
    List<FilterPreset>? presets,
    bool? isLoading,
    String? errorKey,
    bool clearError = false,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      isLoading: isLoading ?? this.isLoading,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
    );
  }
}

/// Owns the stored presets — but deliberately *not* which one is active.
///
/// The active preset lives in `FilterConfig.activePresetId` and nowhere else. It
/// used to be tracked here as well, and the two copies drifted: the carousel
/// highlighted one preset while the sliders showed another's values.
class PresetNotifier extends StateNotifier<PresetState> {
  PresetNotifier(this._applyPreset, this._ref)
      : super(const PresetState(presets: [], isLoading: true)) {
    load();
  }

  final ApplyPresetUseCase _applyPreset;
  final Ref _ref;

  Future<void> load() async {
    final result = await _ref.read(presetRepositoryProvider).getAllPresets();
    if (!mounted) return;
    state = state.copyWith(
      presets: result.dataOrNull ?? const [],
      isLoading: false,
      errorKey: result.isFailure ? 'error_presets_load' : null,
      clearError: result.isSuccess,
    );
  }

  Future<void> select(int presetId) async {
    final filter = _ref.read(filterProvider.notifier);
    final result = await _applyPreset(_ref.read(filterProvider).config, presetId);
    if (!mounted) return;

    result.fold(
      (_) => state = state.copyWith(errorKey: 'error_preset_apply'),
      (config) {
        filter.adopt(config);
        state = state.copyWith(clearError: true);
      },
    );
  }

  Future<void> saveCustom({
    required String name,
    required int kelvin,
    required int densityPercent,
    required int extraDimPercent,
    String iconIdentifier = 'custom',
    int? replacingId,
  }) async {
    final db = _ref.read(databaseHelperProvider);
    final id = replacingId ?? await db.nextCustomPresetId();
    final preset = FilterPreset(
      id: id,
      nameKey: name,
      kelvin: kelvin,
      densityPercent: densityPercent,
      extraDimPercent: extraDimPercent,
      iconIdentifier: iconIdentifier,
      isCustom: true,
      sortOrder: state.presets.length,
    );

    await _ref.read(presetRepositoryProvider).savePreset(preset);
    await load();
    await select(id);
  }

  Future<void> delete(int presetId) async {
    await _ref.read(presetRepositoryProvider).deletePreset(presetId);
    await load();
  }

  /// Persists a new home-screen ordering.
  Future<void> reorder(List<int> presetIdsInOrder) async {
    await _ref.read(databaseHelperProvider).updateSortOrder(presetIdsInOrder);
    await load();
  }

  /// Returns a built-in preset to its shipped values.
  Future<void> resetToDefault(int presetId) async {
    final reset =
        await _ref.read(databaseHelperProvider).resetPresetToDefault(presetId);
    if (!reset) return;
    await load();
    if (_ref.read(filterProvider).config.activePresetId == presetId) {
      await select(presetId);
    }
  }

  Future<void> resetAllToDefaults() async {
    await _ref.read(presetRepositoryProvider).resetToDefaultPresets();
    await load();
    await select(0);
  }
}

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  return PresetNotifier(ref.watch(applyPresetUseCaseProvider), ref);
});

/// The preset matching the live configuration, or null when the user has
/// adjusted the axes away from every stored preset.
final activePresetProvider = Provider<FilterPreset?>((ref) {
  final activeId = ref.watch(filterConfigProvider).activePresetId;
  final presets = ref.watch(presetProvider).presets;
  for (final preset in presets) {
    if (preset.id == activeId) return preset;
  }
  return null;
});
