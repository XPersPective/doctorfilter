import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctorfilter/domain/entities/circadian_mode.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/entities/pro_status.dart';
import 'package:doctorfilter/domain/entities/schedule_rule.dart';

/// Key-value persistence for settings.
///
/// Reads and writes whole records only. The previous version exposed per-field
/// updates, which invited callers into a read-modify-write cycle — and while a
/// slider was being dragged, concurrent cycles read the same stale record and
/// overwrote each other's fields. That is what made settings appear to reset
/// themselves. The in-memory notifier now owns current state and hands a
/// complete record down; this class never merges.
class PreferencesDataSource {
  PreferencesDataSource(this._prefs);

  final SharedPreferences _prefs;

  /// Bumped whenever the stored shape changes, so [_migrate] knows what it is
  /// looking at. Absent means "written before versioning existed".
  static const int _schemaVersion = 2;
  static const _keySchemaVersion = 'df_schema_version';

  static const _keyIsEnabled = 'df_filter_enabled';
  static const _keyPresetId = 'df_active_preset_id';
  static const _keyKelvin = 'df_filter_kelvin';
  static const _keyDensity = 'df_filter_density_percent';
  static const _keyExtraDim = 'df_filter_extra_dim_percent';
  static const _keyNotificationEnabled = 'df_notification_enabled';
  static const _keyScheduleEnabled = 'df_schedule_enabled';

  static const _keyScheduleStartHour = 'df_schedule_start_hour';
  static const _keyScheduleStartMinute = 'df_schedule_start_minute';
  static const _keyScheduleStopHour = 'df_schedule_stop_hour';
  static const _keyScheduleStopMinute = 'df_schedule_stop_minute';
  static const _keyScheduleMode = 'df_schedule_mode';
  static const _keySchedulePresetId = 'df_schedule_preset_id';

  static const _keyProLifetime = 'df_pro_lifetime';
  static const _keyProPassExpiry = 'df_pro_pass_expiry';

  static const _keyLocale = 'df_app_locale';
  static const _keyIsDarkMode = 'df_app_is_dark_mode';

  // v1 keys, read once by the migration and then removed.
  static const _legacyKeyAlpha = 'df_filter_alpha';
  static const _legacyKeyBrightness = 'df_filter_brightness';
  static const _legacyKeyRed = 'df_filter_red';
  static const _legacyKeyGreen = 'df_filter_green';
  static const _legacyKeyBlue = 'df_filter_blue';

  FilterConfig getFilterConfig() {
    return FilterConfig(
      isEnabled: _prefs.getBool(_keyIsEnabled) ?? false,
      activePresetId: _prefs.getInt(_keyPresetId) ?? 0,
      kelvin: _prefs.getInt(_keyKelvin) ?? 3200,
      densityPercent: _prefs.getInt(_keyDensity) ?? 30,
      extraDimPercent: _prefs.getInt(_keyExtraDim) ?? 20,
      isNotificationEnabled: _prefs.getBool(_keyNotificationEnabled) ?? true,
      isScheduleEnabled: _prefs.getBool(_keyScheduleEnabled) ?? false,
    );
  }

  Future<void> saveFilterConfig(FilterConfig config) async {
    await Future.wait([
      _prefs.setBool(_keyIsEnabled, config.isEnabled),
      _prefs.setInt(_keyPresetId, config.activePresetId),
      _prefs.setInt(_keyKelvin, config.kelvin),
      _prefs.setInt(_keyDensity, config.densityPercent),
      _prefs.setInt(_keyExtraDim, config.extraDimPercent),
      _prefs.setBool(_keyNotificationEnabled, config.isNotificationEnabled),
      _prefs.setBool(_keyScheduleEnabled, config.isScheduleEnabled),
    ]);
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
      targetPresetId: _prefs.getInt(_keySchedulePresetId) ?? 5,
    );
  }

  Future<void> saveScheduleRule(ScheduleRule rule) async {
    await Future.wait([
      _prefs.setBool(_keyScheduleEnabled, rule.isEnabled),
      _prefs.setInt(_keyScheduleStartHour, rule.startHour),
      _prefs.setInt(_keyScheduleStartMinute, rule.startMinute),
      _prefs.setInt(_keyScheduleStopHour, rule.stopHour),
      _prefs.setInt(_keyScheduleStopMinute, rule.stopMinute),
      _prefs.setInt(_keyScheduleMode, rule.mode.index),
      _prefs.setInt(_keySchedulePresetId, rule.targetPresetId),
    ]);
  }

  ProStatus getProStatus() {
    if (_prefs.getBool(_keyProLifetime) ?? false) return ProStatus.lifetime();
    final expiryMillis = _prefs.getInt(_keyProPassExpiry);
    if (expiryMillis == null) return ProStatus.free();
    return ProStatus.pass(DateTime.fromMillisecondsSinceEpoch(expiryMillis));
  }

  Future<void> setProStatus(ProStatus status) async {
    await _prefs.setBool(_keyProLifetime, status.isLifetime);
    final expiry = status.passExpiry;
    if (expiry == null) {
      await _prefs.remove(_keyProPassExpiry);
    } else {
      await _prefs.setInt(_keyProPassExpiry, expiry.millisecondsSinceEpoch);
    }
  }

  String? getLocale() => _prefs.getString(_keyLocale);
  Future<void> setLocale(String languageCode) => _prefs.setString(_keyLocale, languageCode);

  bool isDarkMode() => _prefs.getBool(_keyIsDarkMode) ?? true;
  Future<void> setDarkMode(bool isDark) => _prefs.setBool(_keyIsDarkMode, isDark);

  /// Brings settings written by an older version forward.
  ///
  /// Called once at startup, before anything reads. Someone updating the app
  /// must find their screen exactly as they left it; silently resetting their
  /// settings is the kind of thing that costs a five-star review.
  Future<void> migrate() async {
    final stored = _prefs.getInt(_keySchemaVersion) ?? 1;
    if (stored >= _schemaVersion) return;

    if (_prefs.containsKey(_legacyKeyAlpha) || _prefs.containsKey(_legacyKeyBrightness)) {
      // v1 stored tint strength as an 0-255 alpha, and a brightness the overlay
      // service never actually applied. Brightness was still the only record of
      // the user's dimming intent, so it is read as its inverse.
      final alpha = _prefs.getInt(_legacyKeyAlpha) ?? 64;
      final brightness = _prefs.getInt(_legacyKeyBrightness) ?? 255;

      await _prefs.setInt(_keyDensity, (alpha / 255 * 100).round());
      await _prefs.setInt(_keyExtraDim, ((255 - brightness) / 255 * 100).round());

      // Colour is derived from kelvin now; the stored RGB is dead weight, and
      // in v1 it disagreed with the kelvin beside it anyway.
      for (final key in [_legacyKeyRed, _legacyKeyGreen, _legacyKeyBlue,
        _legacyKeyAlpha, _legacyKeyBrightness]) {
        await _prefs.remove(key);
      }
    }

    // v1 allowed 1000-7000 K; the engine's honest range is narrower, and
    // FilterConfig would clamp on read anyway. Normalise the stored value so the
    // clamp does not silently disagree with what is on disk.
    final storedKelvin = _prefs.getInt(_keyKelvin);
    if (storedKelvin != null) {
      await _prefs.setInt(_keyKelvin, getFilterConfig().kelvin);
    }

    await _prefs.setInt(_keySchemaVersion, _schemaVersion);
  }
}
