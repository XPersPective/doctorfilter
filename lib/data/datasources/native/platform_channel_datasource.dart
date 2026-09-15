import 'dart:async';
import 'package:flutter/services.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/entities/schedule_rule.dart';

/// An installed app, as shown in the exclusion picker.
final class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.label,
    this.icon,
  });

  final String packageName;
  final String label;

  /// A small PNG, or null where the icon could not be rendered. One bad icon
  /// should cost its own row, not the whole list.
  final Uint8List? icon;
}

/// Bridge to the native overlay service, notification and scheduler.
///
/// The native side is told the *composite* colour and alpha rather than the
/// three axes, because drawing is all it does — the meaning of the axes stays in
/// the domain layer where it can be tested without a device.
class PlatformChannelDataSource {
  static const MethodChannel _channel = MethodChannel('com.crazypenguin.doctorfilter');

  final StreamController<NativeFilterEvent> _events =
      StreamController<NativeFilterEvent>.broadcast();

  PlatformChannelDataSource() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  /// Changes originating on the native side: notification buttons, the
  /// scheduler firing, the service being killed.
  Stream<NativeFilterEvent> get events => _events.stream;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    final args = call.arguments;
    switch (call.method) {
      case 'onFilterStateChanged':
        _events.add(NativeFilterToggled(_boolArg(args, 'isEnabled')));
      case 'onPresetSelected':
        _events.add(NativePresetSelected(_intArg(args, 'presetId', 0)));
      case 'onAxisChanged':
        _events.add(NativeAxisChanged(
          kelvin: _nullableIntArg(args, 'kelvin'),
          densityPercent: _nullableIntArg(args, 'densityPercent'),
          extraDimPercent: _nullableIntArg(args, 'extraDimPercent'),
        ));
    }
    return null;
  }

  static bool _boolArg(dynamic args, String key) =>
      args is Map && args[key] is bool ? args[key] as bool : false;

  static int _intArg(dynamic args, String key, int fallback) =>
      args is Map && args[key] is int ? args[key] as int : fallback;

  static int? _nullableIntArg(dynamic args, String key) =>
      args is Map && args[key] is int ? args[key] as int : null;

  Future<bool> checkOverlayPermission() =>
      _invokeBool('checkOverlayPermission');

  Future<void> requestOverlayPermission() async {
    await _invokeBool('requestOverlayPermission');
  }

  Future<bool> startOverlay(FilterConfig config) =>
      _invokeBool('startOverlay', _payload(config));

  Future<bool> updateOverlay(FilterConfig config) =>
      _invokeBool('updateOverlay', _payload(config));

  Future<bool> stopOverlay() => _invokeBool('stopOverlay');

  Future<bool> isFilterRunning() => _invokeBool('isFilterRunning');

  Future<bool> setSchedule(ScheduleRule rule) => _invokeBool('setSchedule', {
        'isEnabled': rule.isEnabled,
        'startHour': rule.startHour,
        'startMinute': rule.startMinute,
        'stopHour': rule.stopHour,
        'stopMinute': rule.stopMinute,
        'targetPresetId': rule.targetPresetId,
        'transitionMinutes': rule.transitionMinutes,
      });

  /// Mirrors the preset list to the native side.
  ///
  /// The notification is often built by a service with no Flutter engine alive,
  /// so it cannot read the database or the translations. It gets a flattened
  /// copy instead, refreshed whenever the list or the user's entitlement changes.
  Future<bool> setPresetCatalog({
    required String presetsJson,
    required bool isPro,
  }) =>
      _invokeBool('setPresetCatalog', {
        'presets': presetsJson,
        'isPro': isPro,
      });

  /// Minutes the filter was on, per `yyyy-MM-dd`, for the last week.
  ///
  /// Recorded natively, because the filter spends most of its life with no
  /// Flutter engine alive. Empty where the platform does not keep it.
  Future<Map<String, int>> usageMinutes() async {
    try {
      final result = await _channel.invokeMapMethod<String, int>('getUsageMinutes');
      return result ?? const {};
    } on PlatformException {
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }

  /// Whether the user has granted usage access, needed to name the app in
  /// front. Revocable at any time, so it is asked rather than remembered.
  Future<bool> hasUsageAccess() => _invokeBool('hasUsageAccess');

  Future<void> requestUsageAccess() async {
    await _invokeBool('requestUsageAccess');
  }

  /// Every app with a launcher entry: package, label and a small PNG icon.
  Future<List<InstalledApp>> launchableApps() async {
    try {
      final result = await _channel.invokeListMethod<Object?>('getLaunchableApps');
      return [
        for (final entry in result ?? const [])
          if (entry is Map)
            InstalledApp(
              packageName: entry['package'] as String? ?? '',
              label: entry['label'] as String? ?? '',
              icon: entry['icon'] as Uint8List?,
            ),
      ];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  Future<bool> setAppExclusions({
    required bool isEnabled,
    required List<String> packages,
  }) =>
      _invokeBool('setAppExclusions', {
        'isEnabled': isEnabled,
        'packages': packages,
      });

  /// Turns ambient-light adaptation on or off on the native side.
  Future<bool> setAmbientAdaptation({required bool isEnabled}) =>
      _invokeBool('setAmbientAdaptation', {'isEnabled': isEnabled});

  /// Arms or disarms the 20-20-20 break reminder.
  Future<bool> setBreakReminder({
    required bool isEnabled,
    required int intervalMinutes,
  }) =>
      _invokeBool('setBreakReminder', {
        'isEnabled': isEnabled,
        'intervalMinutes': intervalMinutes,
      });

  /// Whether the OS may still doze this app, killing the filter overnight.
  Future<bool> isBatteryOptimised() => _invokeBool('isBatteryOptimised');

  /// Opens the system battery-optimisation list so the user can exempt the app.
  Future<void> openBatterySettings() async {
    await _invokeBool('openBatterySettings');
  }

  /// Whether the OS will honour exact alarms (Android 12+ can refuse).
  Future<bool> canScheduleExactAlarms() => _invokeBool('canScheduleExactAlarms');

  Future<void> requestExactAlarmPermission() async {
    await _invokeBool('requestExactAlarmPermission');
  }

  static Map<String, dynamic> _payload(FilterConfig config) {
    final colour = config.overlayColor;
    return {
      'red': colour.r,
      'green': colour.g,
      'blue': colour.b,
      'alpha': config.overlayAlpha,
      'kelvin': config.kelvin,
      'densityPercent': config.densityPercent,
      'extraDimPercent': config.extraDimPercent,
      'activePresetId': config.activePresetId,
      'isNotificationEnabled': config.isNotificationEnabled,
    };
  }

  /// Platform calls fail on desktop and in tests, where there is no host
  /// implementation. That is expected, not an error worth surfacing.
  Future<bool> _invokeBool(String method, [Map<String, dynamic>? arguments]) async {
    try {
      return await _channel.invokeMethod<bool>(method, arguments) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  void dispose() => _events.close();
}

/// A change that originated on the native side.
sealed class NativeFilterEvent {
  const NativeFilterEvent();
}

final class NativeFilterToggled extends NativeFilterEvent {
  const NativeFilterToggled(this.isEnabled);
  final bool isEnabled;
}

final class NativePresetSelected extends NativeFilterEvent {
  const NativePresetSelected(this.presetId);
  final int presetId;
}

final class NativeAxisChanged extends NativeFilterEvent {
  const NativeAxisChanged({this.kelvin, this.densityPercent, this.extraDimPercent});
  final int? kelvin;
  final int? densityPercent;
  final int? extraDimPercent;
}
