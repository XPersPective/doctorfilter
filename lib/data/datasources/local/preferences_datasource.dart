import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctorfilter/domain/entities/circadian_mode.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/entities/schedule_rule.dart';

class PreferencesDataSource {
  PreferencesDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _keyIsEnabled = 'df_filter_enabled';
  static const _keyPresetId = 'df_active_preset_id';
  static const _keyKelvin = 'df_filter_kelvin';
  static const _keyRed = 'df_filter_red';
  static const _keyGreen = 'df_filter_green';
  static const _keyBlue = 'df_filter_blue';
  static const _keyAlpha = 'df_filter_alpha';
  static const _keyBrightness = 'df_filter_brightness';
  static const _keyNotificationEnabled = 'df_notification_enabled';
  static const _keyScheduleEnabled = 'df_schedule_enabled';

  static const _keyScheduleStartHour = 'df_schedule_start_hour';
  static const _keyScheduleStartMinute = 'df_schedule_start_minute';
  static const _keyScheduleStopHour = 'df_schedule_stop_hour';
  static const _keyScheduleStopMinute = 'df_schedule_stop_minute';
  static const _keyScheduleMode = 'df_schedule_mode';
  static const _keySchedulePresetId = 'df_schedule_preset_id';

  static const _keyLocale = 'df_app_locale';
  static const _keyIsDarkMode = 'df_app_is_dark_mode';

  FilterConfig getFilterConfig() {
    return FilterConfig(
      isEnabled: _prefs.getBool(_keyIsEnabled) ?? false,
      activePresetId: _prefs.getInt(_keyPresetId) ?? 0,
      kelvin: _prefs.getInt(_keyKelvin) ?? 5500,
      red: _prefs.getInt(_keyRed) ?? 255,
      green: _prefs.getInt(_keyGreen) ?? 219,
      blue: _prefs.getInt(_keyBlue) ?? 186,
      alpha: _prefs.getInt(_keyAlpha) ?? 25,
      brightness: _prefs.getInt(_keyBrightness) ?? 195,
      isNotificationEnabled: _prefs.getBool(_keyNotificationEnabled) ?? true,
      isScheduleEnabled: _prefs.getBool(_keyScheduleEnabled) ?? false,
    );
  }

  Future<void> saveFilterConfig(FilterConfig config) async {
    await _prefs.setBool(_keyIsEnabled, config.isEnabled);
    await _prefs.setInt(_keyPresetId, config.activePresetId);
    await _prefs.setInt(_keyKelvin, config.kelvin);
    await _prefs.setInt(_keyRed, config.red);
    await _prefs.setInt(_keyGreen, config.green);
    await _prefs.setInt(_keyBlue, config.blue);
    await _prefs.setInt(_keyAlpha, config.alpha);
    await _prefs.setInt(_keyBrightness, config.brightness);
    await _prefs.setBool(_keyNotificationEnabled, config.isNotificationEnabled);
    await _prefs.setBool(_keyScheduleEnabled, config.isScheduleEnabled);
  }

  ScheduleRule getScheduleRule() {
    final modeIndex = _prefs.getInt(_keyScheduleMode) ?? 0;
    return ScheduleRule(
      id: 1,
      isEnabled: _prefs.getBool(_keyScheduleEnabled) ?? false,
      startHour: _prefs.getInt(_keyScheduleStartHour) ?? 22,
      startMinute: _prefs.getInt(_keyScheduleStartMinute) ?? 0,
      stopHour: _prefs.getInt(_keyScheduleStopHour) ?? 7,
      stopMinute: _prefs.getInt(_keyScheduleStopMinute) ?? 0,
      mode: CircadianMode.values[modeIndex.clamp(0, CircadianMode.values.length - 1)],
      targetPresetId: _prefs.getInt(_keySchedulePresetId) ?? 3,
    );
  }

  Future<void> saveScheduleRule(ScheduleRule rule) async {
    await _prefs.setBool(_keyScheduleEnabled, rule.isEnabled);
    await _prefs.setInt(_keyScheduleStartHour, rule.startHour);
    await _prefs.setInt(_keyScheduleStartMinute, rule.startMinute);
    await _prefs.setInt(_keyScheduleStopHour, rule.stopHour);
    await _prefs.setInt(_keyScheduleStopMinute, rule.stopMinute);
    await _prefs.setInt(_keyScheduleMode, rule.mode.index);
    await _prefs.setInt(_keySchedulePresetId, rule.targetPresetId);
  }

  String getLocale() => _prefs.getString(_keyLocale) ?? 'en';
  Future<void> setLocale(String languageCode) => _prefs.setString(_keyLocale, languageCode);

  bool isDarkMode() => _prefs.getBool(_keyIsDarkMode) ?? true;
  Future<void> setDarkMode(bool isDark) => _prefs.setBool(_keyIsDarkMode, isDark);
}
