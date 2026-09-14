import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/domain/entities/circadian_mode.dart';
import 'package:doctorfilter/presentation/providers/schedule_provider.dart';

class SchedulerScreen extends ConsumerWidget {
  const SchedulerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleRule = ref.watch(scheduleProvider);
    final scheduleNotifier = ref.read(scheduleProvider.notifier);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('schedule_title') ?? 'Circadian Schedule'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card with Master Toggle
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.amberPrimary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: AppTheme.amberPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bedtime Protection',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc?.translate('schedule_subtitle') ??
                              'Automatically activates warm filter during night hours',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: scheduleRule.isEnabled,
                    onChanged: (val) => scheduleNotifier.toggleSchedule(val),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Schedule Mode Selector
          SegmentedButton<CircadianMode>(
            segments: const [
              ButtonSegment(
                value: CircadianMode.manualTime,
                icon: Icon(Icons.access_time_rounded),
                label: Text('Custom Time'),
              ),
              ButtonSegment(
                value: CircadianMode.sunsetToSunrise,
                icon: Icon(Icons.wb_twilight_rounded),
                label: Text('Sunset / Sunrise'),
              ),
            ],
            selected: {scheduleRule.mode},
            onSelectionChanged: (set) => scheduleNotifier.setMode(set.first),
          ),

          const SizedBox(height: 20),

          // Start / Stop Time Pickers (if Manual Time)
          if (scheduleRule.mode == CircadianMode.manualTime) ...[
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.bedtime_outlined, color: AppTheme.amberPrimary),
                title: Text(loc?.translate('start_time') ?? 'Start Time'),
                subtitle: const Text('Filter turns on'),
                trailing: Text(
                  scheduleRule.startTimeFormatted,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.amberPrimary,
                  ),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: scheduleRule.startHour,
                      minute: scheduleRule.startMinute,
                    ),
                  );
                  if (picked != null) {
                    scheduleNotifier.updateTimes(
                      startHour: picked.hour,
                      startMinute: picked.minute,
                      stopHour: scheduleRule.stopHour,
                      stopMinute: scheduleRule.stopMinute,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.wb_sunny_outlined, color: AppTheme.amberPrimary),
                title: Text(loc?.translate('stop_time') ?? 'End Time'),
                subtitle: const Text('Filter turns off'),
                trailing: Text(
                  scheduleRule.stopTimeFormatted,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.amberPrimary,
                  ),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: scheduleRule.stopHour,
                      minute: scheduleRule.stopMinute,
                    ),
                  );
                  if (picked != null) {
                    scheduleNotifier.updateTimes(
                      startHour: scheduleRule.startHour,
                      startMinute: scheduleRule.startMinute,
                      stopHour: picked.hour,
                      stopMinute: picked.minute,
                    );
                  }
                },
              ),
            ),
          ] else ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.amberPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Automatically shifts screen temperature to bedtime warm amber at dusk and returns to natural daylight at dawn.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Clinical Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.deepNightCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.deepNightBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.health_and_safety_outlined, color: AppTheme.safetySafe, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Clinical studies demonstrate that enabling warm filters at least 2 hours before bedtime reduces sleep latency by an average of 42 minutes.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
