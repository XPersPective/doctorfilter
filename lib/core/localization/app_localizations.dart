import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'supported_languages.dart';

export 'supported_languages.dart' show LanguageItem, kSupportedLanguages;

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};
  Map<String, String> _fallbackStrings = {};

  /// Loads localized JSON file from assets.
  Future<bool> load() async {
    // 1. Load fallback (English)
    try {
      final fallbackJson =
          await rootBundle.loadString('assets/Localizations/en.json');
      final Map<String, dynamic> fallbackMap = json.decode(fallbackJson);
      _fallbackStrings = fallbackMap.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      _fallbackStrings = {};
    }

    // 2. Load current locale
    try {
      final jsonString = await rootBundle
          .loadString('assets/Localizations/${locale.languageCode}.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      _localizedStrings = _fallbackStrings;
    }

    return true;
  }

  /// Translates given key. If not present in locale, falls back to English, then default keys.
  String translate(String key, {Map<String, String>? args}) {
    String text = _localizedStrings[key] ?? _fallbackStrings[key] ?? _modernDefaults[key] ?? key;
    if (args != null) {
      args.forEach((placeholder, value) {
        text = text.replaceAll('{$placeholder}', value);
      });
    }
    return text;
  }

  /// Modern defaults for newly introduced UI features in 2.0
  static const Map<String, String> _modernDefaults = {
    'nav_home': 'Home',
    'nav_presets': 'Presets',
    'nav_schedule': 'Schedule',
    'nav_education': 'Eye Health',
    'nav_settings': 'Settings',
    'filter_active': 'Eye Filter Active',
    'filter_inactive': 'Filter Inactive',
    'subzero_brightness': 'Extra Dim / Sub-Zero',
    'density_label': 'Filter Density',
    'kelvin_label': 'Color Temperature',
    'kelvin_gauge': '{kelvin} K',
    'blue_light_blocked': '{percent}% Blue Light Blocked',
    'preset_gunes': 'Sunlight (5500K)',
    'preset_florasan': 'Fluorescent (4200K)',
    'preset_lamba': 'Incandescent (3200K)',
    'preset_ay': 'Bedtime Moonlight (2200K)',
    'preset_mum': 'Candle Flame (1400K)',
    'preset_kitap': 'Reading Sepia (2700K)',
    'preset_agac': 'Forest Relaxation (3500K)',
    'preset_custom': 'Custom Mode',
    'save_preset': 'Save Preset',
    'delete_preset': 'Delete Preset',
    'schedule_title': 'Circadian Auto-Schedule',
    'schedule_subtitle': 'Automatically protect your eyes around sleep hours',
    'start_time': 'Start Time',
    'stop_time': 'End Time',
    'permission_overlay_title': 'Display Over Other Apps',
    'permission_overlay_desc': 'DoctorFilter requires permission to draw the protective tint over other applications and the lock screen.',
    'permission_grant_btn': 'Grant Permission',
    'pro_title': 'DoctorFilter Pro',
    'pro_subtitle': 'Lifetime eye protection without ads and with unlimited custom profiles',
    'pro_upgrade_btn': 'Upgrade to Pro',
    'pro_restore_btn': 'Restore Purchases',
    'search_language': 'Search languages...',
  };

  /// Languages with a translation file. Defined in `supported_languages.dart`.
  static const List<LanguageItem> supportedLanguages = kSupportedLanguages;

  static List<Locale> get supportedLocales =>
      supportedLanguages.map((lang) => Locale(lang.code)).toList();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLanguages
        .any((lang) => lang.code == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
