import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._ref) : super(ThemeMode.dark) {
    _init();
  }

  final Ref _ref;

  void _init() {
    final prefs = _ref.read(preferencesDataSourceProvider);
    final isDark = prefs.isDarkMode();
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    final prefs = _ref.read(preferencesDataSourceProvider);
    await prefs.setDarkMode(newMode == ThemeMode.dark);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = _ref.read(preferencesDataSourceProvider);
    await prefs.setDarkMode(mode == ThemeMode.dark);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._ref) : super(const Locale('en')) {
    _init();
  }

  final Ref _ref;

  void _init() {
    final prefs = _ref.read(preferencesDataSourceProvider);
    final code = prefs.getLocale();
    state = Locale(code);
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    final prefs = _ref.read(preferencesDataSourceProvider);
    await prefs.setLocale(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});
