import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LanguageItem {
  const LanguageItem({
    required this.code,
    required this.englishName,
    required this.nativeName,
  });

  final String code;
  final String englishName;
  final String nativeName;
}

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

  /// Supported 71 languages matching assets/Localizations/*.json
  static const List<LanguageItem> supportedLanguages = [
    LanguageItem(code: 'en', englishName: 'English', nativeName: 'English'),
    LanguageItem(code: 'tr', englishName: 'Turkish', nativeName: 'Türkçe'),
    LanguageItem(code: 'de', englishName: 'German', nativeName: 'Deutsch'),
    LanguageItem(code: 'fr', englishName: 'French', nativeName: 'Français'),
    LanguageItem(code: 'es', englishName: 'Spanish', nativeName: 'Español'),
    LanguageItem(code: 'it', englishName: 'Italian', nativeName: 'Italiano'),
    LanguageItem(code: 'pt', englishName: 'Portuguese', nativeName: 'Português'),
    LanguageItem(code: 'ru', englishName: 'Russian', nativeName: 'Русский'),
    LanguageItem(code: 'ja', englishName: 'Japanese', nativeName: '日本語'),
    LanguageItem(code: 'ko', englishName: 'Korean', nativeName: '한국어'),
    LanguageItem(code: 'zh', englishName: 'Chinese', nativeName: '中文'),
    LanguageItem(code: 'ar', englishName: 'Arabic', nativeName: 'العربية'),
    LanguageItem(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी'),
    LanguageItem(code: 'nl', englishName: 'Dutch', nativeName: 'Nederlands'),
    LanguageItem(code: 'pl', englishName: 'Polish', nativeName: 'Polski'),
    LanguageItem(code: 'sv', englishName: 'Swedish', nativeName: 'Svenska'),
    LanguageItem(code: 'da', englishName: 'Danish', nativeName: 'Dansk'),
    LanguageItem(code: 'fi', englishName: 'Finnish', nativeName: 'Suomi'),
    LanguageItem(code: 'az', englishName: 'Azerbaijani', nativeName: 'Azərbaycan'),
    LanguageItem(code: 'id', englishName: 'Indonesian', nativeName: 'Bahasa Indonesia'),
    LanguageItem(code: 'ms', englishName: 'Malay', nativeName: 'Bahasa Melayu'),
    LanguageItem(code: 'vi', englishName: 'Vietnamese', nativeName: 'Tiếng Việt'),
    LanguageItem(code: 'th', englishName: 'Thai', nativeName: 'ไทย'),
    LanguageItem(code: 'uk', englishName: 'Ukrainian', nativeName: 'Українська'),
    LanguageItem(code: 'el', englishName: 'Greek', nativeName: 'Ελληνικά'),
    LanguageItem(code: 'he', englishName: 'Hebrew', nativeName: 'עברית'),
    LanguageItem(code: 'hu', englishName: 'Hungarian', nativeName: 'Magyar'),
    LanguageItem(code: 'cs', englishName: 'Czech', nativeName: 'Čeština'),
    LanguageItem(code: 'ro', englishName: 'Romanian', nativeName: 'Română'),
    LanguageItem(code: 'bg', englishName: 'Bulgarian', nativeName: 'Български'),
    LanguageItem(code: 'fa', englishName: 'Persian', nativeName: 'فارسی'),
    LanguageItem(code: 'ur', englishName: 'Urdu', nativeName: 'اردو'),
  ];

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
