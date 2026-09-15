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

/// Overridden at startup, once SharedPreferences has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden at startup');
});

final preferencesDataSourceProvider = Provider<PreferencesDataSource>((ref) {
  return PreferencesDataSource(ref.watch(sharedPreferencesProvider));
});

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final platformChannelDataSourceProvider = Provider<PlatformChannelDataSource>((ref) {
  final dataSource = PlatformChannelDataSource();
  ref.onDispose(dataSource.dispose);
  return dataSource;
});

final filterRepositoryProvider = Provider<IFilterRepository>((ref) {
  final repository = FilterRepositoryImpl(
    preferencesDataSource: ref.watch(preferencesDataSourceProvider),
    platformChannelDataSource: ref.watch(platformChannelDataSourceProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final presetRepositoryProvider = Provider<IPresetRepository>((ref) {
  return PresetRepositoryImpl(ref.watch(databaseHelperProvider));
});

final scheduleRepositoryProvider = Provider<IScheduleRepository>((ref) {
  return ScheduleRepositoryImpl(
    preferencesDataSource: ref.watch(preferencesDataSourceProvider),
    platformChannelDataSource: ref.watch(platformChannelDataSourceProvider),
  );
});

final toggleFilterUseCaseProvider = Provider<ToggleFilterUseCase>((ref) {
  return ToggleFilterUseCase(ref.watch(filterRepositoryProvider));
});

final applyPresetUseCaseProvider = Provider<ApplyPresetUseCase>((ref) {
  return ApplyPresetUseCase(
    ref.watch(filterRepositoryProvider),
    ref.watch(presetRepositoryProvider),
  );
});

final manageScheduleUseCaseProvider = Provider<ManageScheduleUseCase>((ref) {
  return ManageScheduleUseCase(ref.watch(scheduleRepositoryProvider));
});
