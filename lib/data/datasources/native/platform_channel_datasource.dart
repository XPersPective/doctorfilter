import 'dart:async';
import 'package:flutter/services.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/entities/schedule_rule.dart';

class PlatformChannelDataSource {
  static const MethodChannel _channel = MethodChannel('com.crazypenguin.doctorfilter');

  final StreamController<bool> _filterStateController = StreamController<bool>.broadcast();
  final StreamController<int> _densityController = StreamController<int>.broadcast();

  PlatformChannelDataSource() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Stream<bool> get onFilterStateChanged => _filterStateController.stream;
  Stream<int> get onDensityChanged => _densityController.stream;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onFilterStateChanged':
        final isEnabled = call.arguments['isEnabled'] as bool? ?? false;
        _filterStateController.add(isEnabled);
        break;
      case 'onDensityChanged':
        final alpha = call.arguments['alpha'] as int? ?? 25;
        _densityController.add(alpha);
        break;
    }
  }

  Future<bool> checkOverlayPermission() async {
    try {
      final isGranted = await _channel.invokeMethod<bool>('checkOverlayPermission');
      return isGranted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod<void>('requestOverlayPermission');
    } catch (_) {}
  }

  Future<bool> startOverlay(FilterConfig config) async {
    try {
      final result = await _channel.invokeMethod<bool>('startOverlay', {
        'red': config.red,
        'green': config.green,
        'blue': config.blue,
        'alpha': config.alpha,
        'brightness': config.brightness,
        'kelvin': config.kelvin,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateOverlay(FilterConfig config) async {
    try {
      final result = await _channel.invokeMethod<bool>('updateOverlay', {
        'red': config.red,
        'green': config.green,
        'blue': config.blue,
        'alpha': config.alpha,
        'brightness': config.brightness,
        'kelvin': config.kelvin,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stopOverlay() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopOverlay');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isFilterRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isFilterRunning');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setSchedule(ScheduleRule rule) async {
    try {
      final result = await _channel.invokeMethod<bool>('setSchedule', {
        'isEnabled': rule.isEnabled,
        'startHour': rule.startHour,
        'startMinute': rule.startMinute,
        'stopHour': rule.stopHour,
        'stopMinute': rule.stopMinute,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _filterStateController.close();
    _densityController.close();
  }
}
