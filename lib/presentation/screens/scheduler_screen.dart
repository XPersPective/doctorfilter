import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/domain/entities/schedule_rule.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';
import 'package:doctorfilter/presentation/providers/preset_provider.dart';
import 'package:doctorfilter/presentation/providers/schedule_provider.dart';
import 'package:doctorfilter/presentation/widgets/preset_grid.dart';

/// Runs the filter on a schedule.
class SchedulerScreen extends ConsumerStatefulWidget {
  const SchedulerScreen({super.key});

  @override
  ConsumerState<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends ConsumerState<SchedulerScreen> {
  bool? _exactAlarmsAllowed;

  @override
  void initState() {
    super.initState();
    _checkExactAlarms();
  }

  Future<void> _checkExactAlarms() async {
    final allowed = await ref
        .read(platformChannelDataSourceProvider)
        .canScheduleExactAlarms();
    if (mounted) setState(() => _exactAlarmsAllowed = allowed);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final rule = ref.watch(scheduleProvider);
    final notifier = ref.read(scheduleProvider.notifier);
    final presets = ref.watch(presetProvider).presets;

    return Scaffold(
      appBar: AppBar(title: Text(loc?.translate('schedule_title') ?? 'Schedule')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              value: rule.isEnabled,
              onChanged: (enabled) async {
                await notifier.toggleSchedule(enabled);
                if (enabled) await _checkExactAlarms();
              },
              title: Text(
                loc?.translate('schedule_enable') ?? 'Run on a schedule',
                style: context.texts.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                loc?.translate('schedule_subtitle') ??
                    'Let the filter follow your evening.',
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colours.onSurfaceVariant),
              ),
            ),
          ),

          // Only worth raising once the schedule is actually on, and only where
          // the OS has refused: an exact alarm is the difference between the
          // filter arriving at bedtime and arriving whenever the system feels
          // like it.
          if (rule.isEnabled && _exactAlarmsAllowed == false)
            _ExactAlarmNotice(
              onOpen: () async {
                await ref
                    .read(platformChannelDataSourceProvider)
                    .requestExactAlarmPermission();
                await _checkExactAlarms();
              },
            ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _TimeCard(
                  label: loc?.translate('start_time') ?? 'Starts',
                  time: TimeOfDay(hour: rule.startHour, minute: rule.startMinute),
                  enabled: rule.isEnabled,
                  onPick: (picked) => notifier.updateTimes(
                    startHour: picked.hour,
                    startMinute: picked.minute,
                    stopHour: rule.stopHour,
                    stopMinute: rule.stopMinute,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeCard(
                  label: loc?.translate('stop_time') ?? 'Ends',
                  time: TimeOfDay(hour: rule.stopHour, minute: rule.stopMinute),
                  enabled: rule.isEnabled,
                  onPick: (picked) => notifier.updateTimes(
                    startHour: rule.startHour,
                    startMinute: rule.startMinute,
                    stopHour: picked.hour,
                    stopMinute: picked.minute,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          _DurationSummary(rule: rule),

          const SizedBox(height: 20),
          Text(
            loc?.translate('schedule_preset') ?? 'Preset to use',
            style: context.texts.labelLarge
                ?.copyWith(color: context.colours.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          PresetGrid(
            presets: presets,
            activePresetId: rule.targetPresetId,
            onSelected: notifier.setTargetPreset,
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.label,
    required this.time,
    required this.enabled,
    required this.onPick,
  });

  final String label;
  final TimeOfDay time;
  final bool enabled;
  final ValueChanged<TimeOfDay> onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled
            ? () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (picked != null) onPick(picked);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.texts.labelMedium
                    ?.copyWith(color: context.colours.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                // Formatted by Flutter from the locale and the device's 12/24h
                // setting. Writing "PM" by hand produced a suffix that does not
                // exist in Turkish and several other languages.
                time.format(context),
                style: context.texts.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: enabled
                      ? context.colours.onSurface
                      : context.colours.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How long the filter will be on, so an overnight window reads as sensible
/// rather than looking like the times are the wrong way round.
class _DurationSummary extends StatelessWidget {
  const _DurationSummary({required this.rule});

  final ScheduleRule rule;

  @override
  Widget build(BuildContext context) {
    final start = rule.startHour * 60 + rule.startMinute;
    final stop = rule.stopHour * 60 + rule.stopMinute;
    // A window that ends "before" it starts simply crosses midnight.
    final minutes = stop > start ? stop - start : (24 * 60) - start + stop;

    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 15,
          color: context.colours.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m',
          style: context.texts.bodySmall
              ?.copyWith(color: context.colours.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ExactAlarmNotice extends StatelessWidget {
  const _ExactAlarmNotice({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Card(
        margin: EdgeInsets.zero,
        color: context.colours.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc?.translate('schedule_exact_alarm_title') ??
                    'Allow exact alarms',
                style: context.texts.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colours.onErrorContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loc?.translate('schedule_exact_alarm_desc') ??
                    'Without this permission the schedule can run several minutes late.',
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colours.onErrorContainer),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colours.error,
                  foregroundColor: context.colours.onError,
                  minimumSize: const Size(48, 40),
                ),
                child: Text(loc?.translate('permission_grant_btn') ?? 'Grant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
