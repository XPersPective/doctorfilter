import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctorfilter/data/datasources/local/database_helper.dart';
import 'package:doctorfilter/data/datasources/local/preferences_datasource.dart';
import 'package:doctorfilter/data/datasources/native/platform_channel_datasource.dart';
import 'package:doctorfilter/data/repositories/filter_repository_impl.dart';
import 'package:doctorfilter/data/repositories/preset_repository_impl.dart';
import 'package:doctorfilter/data/repositories/schedule_repository_impl.dart';
import 'package:doctorfilter/domain/repositories/i_filter_repository.dart';
import 'package:doctorfilter/domain/repositories/i_preset_repository.dart';
import 'package:doctorfilter/domain/repositories/i_schedule_repository.dart';
import 'package:doctorfilter/domain/usecases/apply_preset_usecase.dart';
import 'package:doctorfilter/domain/usecases/manage_schedule_usecase.dart';
import 'package:doctorfilter/domain/usecases/toggle_filter_usecase.dart';
import 'package:doctorfilter/domain/usecases/update_filter_params_usecase.dart';

/// SharedPreferences instance provider, overridden at app bootstrap.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden at startup');
});

final preferencesDataSourceProvider = Provider<PreferencesDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesDataSource(prefs);
});

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final platformChannelDataSourceProvider = Provider<PlatformChannelDataSource>((ref) {
  final ds = PlatformChannelDataSource();
  ref.onDispose(ds.dispose);
  return ds;
});

final filterRepositoryProvider = Provider<IFilterRepository>((ref) {
  final prefsDs = ref.watch(preferencesDataSourceProvider);
  final nativeDs = ref.watch(platformChannelDataSourceProvider);
  final repo = FilterRepositoryImpl(
    preferencesDataSource: prefsDs,
    platformChannelDataSource: nativeDs,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final presetRepositoryProvider = Provider<IPresetRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return PresetRepositoryImpl(dbHelper);
});

final scheduleRepositoryProvider = Provider<IScheduleRepository>((ref) {
  final prefsDs = ref.watch(preferencesDataSourceProvider);
  final nativeDs = ref.watch(platformChannelDataSourceProvider);
  return ScheduleRepositoryImpl(
    preferencesDataSource: prefsDs,
    platformChannelDataSource: nativeDs,
  );
});

// Use Cases
final toggleFilterUseCaseProvider = Provider<ToggleFilterUseCase>((ref) {
  final repo = ref.watch(filterRepositoryProvider);
  return ToggleFilterUseCase(repo);
});

final applyPresetUseCaseProvider = Provider<ApplyPresetUseCase>((ref) {
  final filterRepo = ref.watch(filterRepositoryProvider);
  final presetRepo = ref.watch(presetRepositoryProvider);
  return ApplyPresetUseCase(filterRepo, presetRepo);
});

final updateFilterParamsUseCaseProvider = Provider<UpdateFilterParamsUseCase>((ref) {
  final repo = ref.watch(filterRepositoryProvider);
  return UpdateFilterParamsUseCase(repo);
});

final manageScheduleUseCaseProvider = Provider<ManageScheduleUseCase>((ref) {
  final repo = ref.watch(scheduleRepositoryProvider);
  return ManageScheduleUseCase(repo);
});
