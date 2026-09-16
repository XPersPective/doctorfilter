import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/presentation/providers/filter_provider.dart';
import 'package:doctorfilter/presentation/providers/pro_provider.dart';
import 'package:doctorfilter/presentation/providers/theme_and_locale_provider.dart';
import 'package:doctorfilter/presentation/providers/ambient_provider.dart';
import 'package:doctorfilter/presentation/providers/break_reminder_provider.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';
import 'package:doctorfilter/presentation/providers/preset_provider.dart';
import 'package:doctorfilter/presentation/services/app_links.dart';
import 'package:doctorfilter/presentation/services/settings_backup.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'about_screen.dart';
import 'calibration_screen.dart';
import 'exclusions_screen.dart';
import 'language_screen.dart';
import 'paywall_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final isPro = ref.watch(isProProvider);
    final isAmoled = ref.watch(amoledProvider);
    final themeFollowsFilter = ref.watch(themeFollowsFilterProvider);
    final breaks = ref.watch(breakReminderProvider);
    final ambient = ref.watch(ambientProvider);
    final config = ref.watch(filterConfigProvider);

    return Scaffold(
      appBar: AppBar(title: Text(loc?.translate('nav_settings') ?? 'Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (!isPro) _ProCard(onTap: () => _open(context, const PaywallScreen())),
          if (Platform.isAndroid) const _BatteryCard(),

          _SectionLabel(
            loc?.translate('settings_appearance') ?? 'Appearance',
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(loc?.translate('app_language') ?? 'Language'),
                  subtitle: Text(
                    _languageName(
                      locale?.languageCode ??
                          Localizations.localeOf(context).languageCode,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(context, const LanguageScreen()),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: context.colours.primary,
                  ),
                  title: Text(loc?.translate('settings_theme') ?? 'Dark theme'),
                  subtitle: Text(
                    loc?.translate('settings_theme_desc') ??
                        'Easier on the eyes at night.',
                  ),
                  value: isDark,
                  onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                ),
                // Only while the dark theme is actually showing: a "true black"
                // switch under a white screen does nothing visible, and a
                // control that appears to do nothing reads as broken.
                if (isDark) ...[
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: Icon(
                      Icons.contrast_rounded,
                      color: context.colours.primary,
                    ),
                    title: Text(
                      loc?.translate('settings_amoled') ?? 'True black (OLED)',
                    ),
                    subtitle: Text(
                      loc?.translate('settings_amoled_desc') ??
                          'Unlit pixels emit no light at all, and use less battery.',
                    ),
                    value: isAmoled,
                    onChanged: (_) => ref.read(amoledProvider.notifier).toggle(),
                  ),
                ],
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.pause_circle_outline_rounded),
                  title: Text(
                    loc?.translate('exclusions_title') ?? 'Pause in these apps',
                  ),
                  subtitle: Text(
                    loc?.translate('exclusions_desc') ??
                        'Step aside for the camera, the gallery, a video player.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(context, const ExclusionsScreen()),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Icon(
                    ambient
                        ? Icons.brightness_auto_rounded
                        : Icons.brightness_auto_outlined,
                    color: context.colours.primary,
                  ),
                  title: Text(
                    loc?.translate('settings_ambient') ?? 'Adapt to the room',
                  ),
                  subtitle: Text(
                    isPro
                        ? loc?.translate('settings_ambient_desc') ??
                            'Dims a little more in the dark, backs off in daylight.'
                        : loc?.translate('settings_ambient_locked') ??
                            'Included with Pro.',
                  ),
                  value: ambient,
                  onChanged: isPro
                      ? ref.read(ambientProvider.notifier).setEnabled
                      : null,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: Text(
                    loc?.translate('calibration_title') ?? 'Calibrate screen',
                  ),
                  subtitle: Text(
                    loc?.translate('calibration_desc') ??
                        'Match the app to what your panel actually shows.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(context, const CalibrationScreen()),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Icon(
                    Icons.auto_mode_rounded,
                    color: context.colours.primary,
                  ),
                  title: Text(
                    loc?.translate('settings_theme_follows') ??
                        'Go dark with the filter',
                  ),
                  subtitle: Text(
                    loc?.translate('settings_theme_follows_desc') ??
                        'A bright app on a dimmed screen undoes the filter.',
                  ),
                  value: themeFollowsFilter,
                  onChanged: (_) =>
                      ref.read(themeFollowsFilterProvider.notifier).toggle(),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Icon(
                    Icons.notifications_active_outlined,
                    color: context.colours.primary,
                  ),
                  title: Text(
                    loc?.translate('settings_notification') ??
                        'Notification controls',
                  ),
                  subtitle: Text(
                    loc?.translate('settings_notification_desc') ??
                        'Control the filter without opening the app.',
                  ),
                  value: config.isNotificationEnabled,
                  onChanged:
                      ref.read(filterProvider.notifier).setNotificationEnabled,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SectionLabel(loc?.translate('settings_breaks') ?? 'Eye breaks'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.remove_red_eye_outlined,
                    color: context.colours.primary,
                  ),
                  title: Text(
                    loc?.translate('settings_breaks') ?? 'Eye breaks',
                  ),
                  subtitle: Text(
                    loc?.translate('settings_breaks_desc') ??
                        'Every 20 minutes, look 6 metres away for 20 seconds.',
                  ),
                  value: breaks.isEnabled,
                  onChanged: ref.read(breakReminderProvider.notifier).setEnabled,
                ),
                if (breaks.isEnabled) ...[
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: Text(
                      loc?.translate('settings_breaks_interval') ?? 'Remind me every',
                    ),
                    subtitle: !isPro
                        ? Text(
                            loc?.translate('settings_breaks_locked') ??
                                '20 minutes is the interval the evidence is for. '
                                    'Pro can change it.',
                          )
                        : null,
                    trailing: Text(
                      _minutes(loc, breaks.intervalMinutes),
                      style: context.texts.bodyLarge,
                    ),
                    enabled: isPro,
                    onTap: isPro
                        ? () => _pickInterval(context, ref, breaks.intervalMinutes)
                        : null,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          _UsageCard(label: loc?.translate('settings_usage') ?? 'Your week'),

          const SizedBox(height: 16),
          _SectionLabel(loc?.translate('settings_backup') ?? 'Back up settings'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.save_alt_rounded),
                  title: Text(
                    loc?.translate('settings_backup') ?? 'Back up settings',
                  ),
                  subtitle: Text(
                    isPro
                        ? loc?.translate('settings_backup_desc') ??
                            'Save your presets and filter settings as a file.'
                        : loc?.translate('settings_ambient_locked') ??
                            'Included with Pro.',
                  ),
                  trailing: isPro ? null : const Icon(Icons.lock_outline_rounded),
                  // Pro only, at the owner's call: a free backup is a free
                  // way to carry Pro-built settings across reinstalls. Locked
                  // rows open the paywall rather than doing nothing, so the
                  // tap reads as an offer, not a broken button.
                  onTap: isPro
                      ? () => _export(context, ref)
                      : () => _open(context, const PaywallScreen()),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.restore_page_outlined),
                  title: Text(
                    loc?.translate('settings_restore') ?? 'Restore from a file',
                  ),
                  trailing: isPro ? null : const Icon(Icons.lock_outline_rounded),
                  onTap: isPro
                      ? () => _import(context, ref)
                      : () => _open(context, const PaywallScreen()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SectionLabel(loc?.translate('settings_about_section') ?? 'About'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(loc?.translate('app_about') ?? 'About'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(context, const AboutScreen()),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded),
                  title: Text(loc?.translate('app_rate') ?? 'Rate the app'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: AppLinks.requestReview,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: Text(loc?.translate('app_share') ?? 'Share'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => AppLinks.share(
                    loc?.translate('app_share_text') ??
                        'DoctorFilter — a blue light filter that shows you the real numbers.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _minutes(AppLocalizations? loc, int minutes) {
    final template = loc?.translate('duration_minutes');
    return template == null
        ? '$minutes min'
        : template.replaceAll('{minutes}', '$minutes');
  }

  /// A short list rather than a slider: these are the intervals people actually
  /// want, and a free-running number invites fiddling with a value that has one
  /// evidence-backed answer.
  static Future<void> _pickInterval(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final loc = AppLocalizations.of(context);
    const options = [10, 20, 30, 45, 60];

    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final minutes in options)
              ListTile(
                title: Text(_minutes(loc, minutes)),
                trailing: minutes == current
                    ? Icon(Icons.check_rounded, color: context.colours.primary)
                    : null,
                onTap: () => Navigator.pop(sheetContext, minutes),
              ),
          ],
        ),
      ),
    );

    if (chosen != null) {
      await ref.read(breakReminderProvider.notifier).setInterval(chosen);
    }
  }

  static Future<void> _export(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context);
    final ok = await SettingsBackup.export(
      config: ref.read(filterConfigProvider),
      presets: ref.read(presetProvider).presets,
    );
    if (!context.mounted) return;
    _toast(
      context,
      ok
          ? loc?.translate('backup_exported') ?? 'Backup created.'
          : loc?.translate('backup_failed') ?? 'The backup could not be created.',
    );
  }

  static Future<void> _import(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context);
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    final file = picked?.files.singleOrNull;
    if (file == null) return;

    // withData is honoured on Android and iOS; on desktop the bytes can come
    // back null and only the path is set.
    final json = file.bytes != null
        ? String.fromCharCodes(file.bytes!)
        : file.path != null
            ? await File(file.path!).readAsString()
            : null;

    final ok = json != null &&
        await SettingsBackup.import(
          json: json,
          preferences: ref.read(preferencesDataSourceProvider),
          database: ref.read(databaseHelperProvider),
        );

    if (ok) {
      await ref.read(filterProvider.notifier).reload();
      await ref.read(presetProvider.notifier).load();
    }
    if (!context.mounted) return;
    _toast(
      context,
      ok
          ? loc?.translate('backup_imported') ?? 'Settings restored.'
          : loc?.translate('backup_import_failed') ??
              'That file could not be read.',
    );
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  static String _languageName(String code) {
    for (final language in AppLocalizations.supportedLanguages) {
      if (language.code == code) {
        return '${language.nativeName} (${language.englishName})';
      }
    }
    return code.toUpperCase();
  }
}

/// Seven days of filtered screen time, from the device and nowhere else.
///
/// Renders nothing at all until there is something to show: an empty chart on a
/// first launch is just a reminder that the app has done nothing yet.
class _UsageCard extends ConsumerWidget {
  const _UsageCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final usage = ref.watch(usageMinutesProvider).valueOrNull ?? const {};
    final total = usage.values.fold(0, (sum, minutes) => sum + minutes);
    if (total == 0) return const SizedBox.shrink();

    final today = DateTime.now();
    final days = [
      for (var offset = 6; offset >= 0; offset--)
        today.subtract(Duration(days: offset)),
    ];
    final peak = usage.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _duration(loc, total),
                  style: context.texts.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colours.primary,
                  ),
                ),
                Text(
                  loc?.translate('settings_usage_desc') ??
                      'Filtered screen time this week. Kept on this device.',
                  style: context.texts.bodySmall
                      ?.copyWith(color: context.colours.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 72,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final day in days)
                        Expanded(
                          child: _DayBar(
                            minutes: usage[_key(day)] ?? 0,
                            peak: peak,
                            weekday: day.weekday,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _key(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static String _duration(AppLocalizations? loc, int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    final hourText = loc
        ?.translate('duration_hours')
        .replaceAll('{hours}', '$hours');
    final minuteText = loc
        ?.translate('duration_minutes')
        .replaceAll('{minutes}', '$rest');
    if (hours == 0) return minuteText ?? '$rest min';
    return '${hourText ?? '$hours h'} ${minuteText ?? '$rest min'}';
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.minutes,
    required this.peak,
    required this.weekday,
  });

  final int minutes;
  final int peak;
  final int weekday;

  @override
  Widget build(BuildContext context) {
    // A floor of 3px so a day with a few minutes still reads as "some", and an
    // empty day still reads as a day rather than a gap in the chart.
    final fraction = peak == 0 ? 0.0 : minutes / peak;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: fraction.clamp(0.04, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: minutes == 0
                      ? context.colours.outlineVariant
                      : context.colours.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _weekdayInitial(context, weekday),
            style: context.texts.labelSmall
                ?.copyWith(color: context.colours.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Taken from the active locale rather than hard-coded letters: the same chart
  /// has to read correctly in 71 languages, including right-to-left ones.
  static String _weekdayInitial(BuildContext context, int weekday) {
    const reference = [
      'weekday_mon',
      'weekday_tue',
      'weekday_wed',
      'weekday_thu',
      'weekday_fri',
      'weekday_sat',
      'weekday_sun',
    ];
    final loc = AppLocalizations.of(context);
    final name = loc?.translate(reference[weekday - 1]);
    return name ?? reference[weekday - 1].substring(8, 9).toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text,
        style: context.texts.labelLarge?.copyWith(
          color: context.colours.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Card(
      margin: EdgeInsets.zero,
      // primaryContainer / onPrimaryContainer rather than a hand-picked amber:
      // the old card used a fixed dark-mode accent with white text on it, which
      // in light mode was white on pale orange and effectively invisible.
      color: context.colours.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 34,
                color: context.colours.onPrimaryContainer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc?.translate('pro_title') ?? 'DoctorFilter Pro',
                      style: context.texts.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colours.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc?.translate('pro_subtitle') ??
                          'One payment. No subscription.',
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colours.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colours.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown only while Android is battery-optimising the app.
///
/// On many phones that is what quietly stops the filter overnight. The card
/// re-checks when the user comes back from system settings, so it disappears
/// by itself once they have done what it asks.
class _BatteryCard extends ConsumerStatefulWidget {
  const _BatteryCard();

  @override
  ConsumerState<_BatteryCard> createState() => _BatteryCardState();
}

class _BatteryCardState extends ConsumerState<_BatteryCard>
    with WidgetsBindingObserver {
  bool _optimised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final optimised =
        await ref.read(platformChannelDataSourceProvider).isBatteryOptimised();
    if (mounted && optimised != _optimised) {
      setState(() => _optimised = optimised);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_optimised) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.battery_alert_rounded,
              color: context.colours.primary),
          title: Text(
            loc?.translate('permission_battery_title') ??
                'Keep the filter running',
          ),
          subtitle: Text(
            loc?.translate('permission_battery_desc') ??
                'Your device may stop the filter in the background to save '
                    'battery. Excluding DoctorFilter from battery optimisation '
                    'prevents that.',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () =>
              ref.read(platformChannelDataSourceProvider).openBatterySettings(),
        ),
      ),
    );
  }
}
