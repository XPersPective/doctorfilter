import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/circadian_mode.dart';
import 'package:doctorfilter/domain/entities/schedule_rule.dart';
import 'package:doctorfilter/domain/usecases/manage_schedule_usecase.dart';
import 'core_providers.dart';

class ScheduleNotifier extends StateNotifier<ScheduleRule> {
  ScheduleNotifier(
    this._manageScheduleUseCase,
  ) : super(ScheduleRule.defaultBedtime()) {
    loadSchedule();
  }

  final ManageScheduleUseCase _manageScheduleUseCase;

  Future<void> loadSchedule() async {
    final result = await _manageScheduleUseCase.getSchedule();
    if (result is Success<ScheduleRule>) {
      state = result.data;
    }
  }

  Future<void> toggleSchedule(bool isEnabled) async {
    final updated = state.copyWith(isEnabled: isEnabled);
    final result = await _manageScheduleUseCase.updateSchedule(updated);
    if (result is Success<ScheduleRule>) {
      state = result.data;
    }
  }

  Future<void> updateTimes({
    required int startHour,
    required int startMinute,
    required int stopHour,
    required int stopMinute,
  }) async {
    final updated = state.copyWith(
      startHour: startHour,
      startMinute: startMinute,
      stopHour: stopHour,
      stopMinute: stopMinute,
    );
    final result = await _manageScheduleUseCase.updateSchedule(updated);
    if (result is Success<ScheduleRule>) {
      state = result.data;
    }
  }

  Future<void> setTargetPreset(int presetId) async {
    final updated = state.copyWith(targetPresetId: presetId);
    final result = await _manageScheduleUseCase.updateSchedule(updated);
    if (result is Success<ScheduleRule>) {
      state = result.data;
    }
  }

  /// Rebuilds the schedule around a bedtime the user picked.
  Future<void> applyBedtime({required int hour, required int minute}) async {
    final updated = state.forBedtime(bedHour: hour, bedMinute: minute);
    final result = await _manageScheduleUseCase.updateSchedule(updated);
    if (result is Success<ScheduleRule>) {
      state = result.data;
    }
  }

  Future<void> setTransition(int minutes) async {
    final updated = state.copyWith(transitionMinutes: minutes);
    final result = await _manageScheduleUseCase.updateSchedule(updated);
    if (result is Success<ScheduleRule>) {
      state = result.data;
    }
  }

  Future<void> setMode(CircadianMode mode) async {
    final updated = state.copyWith(mode: mode);
    final result = await _manageScheduleUseCase.updateSchedule(updated);
    if (result is Success<ScheduleRule>) {
      state = result.data;
    }
  }
}

final scheduleProvider = StateNotifierProvider<ScheduleNotifier, ScheduleRule>((ref) {
  final manageUseCase = ref.watch(manageScheduleUseCaseProvider);
  return ScheduleNotifier(manageUseCase);
});
