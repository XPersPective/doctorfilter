import 'package:flutter/material.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import 'filter_provider.dart';

/// Light / dark preference.
///
/// Defaults to dark: this app is used at night, by people who have just been
/// told to reduce their screen's light output. Opening a white screen at them
/// would be an odd first impression.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._ref) : super(ThemeMode.dark) {
    state = _ref.read(preferencesDataSourceProvider).isDarkMode()
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  final Ref _ref;

  Future<void> toggle() =>
      setThemeMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _ref.read(preferencesDataSourceProvider).setDarkMode(mode == ThemeMode.dark);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

/// Whether the dark theme should be true black.
///
/// Separate from [themeModeProvider] because it is a property of the dark theme
/// rather than a third mode: someone on "light" who turns this on should get
/// AMOLED black the next time they switch to dark, not immediately.
class AmoledNotifier extends StateNotifier<bool> {
  AmoledNotifier(this._ref)
      : super(_ref.read(preferencesDataSourceProvider).isAmoled());

  final Ref _ref;

  Future<void> toggle() async {
    state = !state;
    await _ref.read(preferencesDataSourceProvider).setAmoled(state);
  }
}

final amoledProvider = StateNotifierProvider<AmoledNotifier, bool>((ref) {
  return AmoledNotifier(ref);
});

/// The dark theme actually in use: AMOLED if the user asked for it.
final darkThemeProvider = Provider<ThemeData>((ref) {
  return ref.watch(amoledProvider) ? AppTheme.amoledTheme : AppTheme.darkTheme;
});

/// Whether the app's own theme should go dark while the filter is running.
///
/// A bright white app on top of a warm dimmed screen is the one thing in the
/// app that undoes what the filter just did.
class ThemeFollowsFilterNotifier extends StateNotifier<bool> {
  ThemeFollowsFilterNotifier(this._ref)
      : super(_ref.read(preferencesDataSourceProvider).themeFollowsFilter());

  final Ref _ref;

  Future<void> toggle() async {
    state = !state;
    await _ref.read(preferencesDataSourceProvider).setThemeFollowsFilter(state);
  }
}

final themeFollowsFilterProvider =
    StateNotifierProvider<ThemeFollowsFilterNotifier, bool>((ref) {
  return ThemeFollowsFilterNotifier(ref);
});

/// The theme mode actually in use.
///
/// The user's own choice, except while the filter is running and they have asked
/// the app to follow it. Their stored preference is never overwritten — switch
/// the filter off and light mode comes straight back.
final effectiveThemeModeProvider = Provider<ThemeMode>((ref) {
  final chosen = ref.watch(themeModeProvider);
  if (chosen == ThemeMode.dark) return chosen;
  if (!ref.watch(themeFollowsFilterProvider)) return chosen;
  return ref.watch(filterConfigProvider).isEnabled ? ThemeMode.dark : chosen;
});

/// Selected language, or null to follow the device.
///
/// Null is the default and matters: a user whose phone is in Turkish should see
/// Turkish on first launch without going hunting for a setting. Storing 'en' as
/// a default, as the previous version did, meant everyone started in English
/// regardless of their device.
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._ref) : super(null) {
    final saved = _ref.read(preferencesDataSourceProvider).getLocale();
    if (saved != null) state = Locale(saved);
  }

  final Ref _ref;

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    await _ref.read(preferencesDataSourceProvider).setLocale(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref);
});
