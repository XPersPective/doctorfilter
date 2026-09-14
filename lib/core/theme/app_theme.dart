import 'package:flutter/material.dart';

/// Central Material 3 theming system for DoctorFilter.
/// Crafted specifically for minimal eye strain in both light and dark environments.
abstract final class AppTheme {
  // Brand & Filter Palette
  static const Color amberPrimary = Color(0xFFFF9E43);
  static const Color amberSecondary = Color(0xFFFFB74D);
  static const Color warmAmber = Color(0xFFFFA726);
  static const Color deepNightBackground = Color(0xFF0F141C);
  static const Color deepNightSurface = Color(0xFF161E28);
  static const Color deepNightCard = Color(0xFF1E2836);
  static const Color deepNightBorder = Color(0xFF2B384A);

  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1F4F8);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Safety rating semantic colors
  static const Color safetySafe = Color(0xFF4CAF50);
  static const Color safetyRelaxed = Color(0xFFFFB300);
  static const Color safetyModerate = Color(0xFFFF7043);
  static const Color safetyRisk = Color(0xFFE53935);

  /// Generates the Dark Material 3 theme optimized for nighttime eye protection.
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: amberPrimary,
      brightness: Brightness.dark,
      primary: amberPrimary,
      onPrimary: Colors.black,
      secondary: amberSecondary,
      surface: deepNightSurface,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: deepNightBackground,
      canvasColor: deepNightBackground,
      cardColor: deepNightCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: deepNightBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: deepNightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: deepNightBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: amberPrimary,
        inactiveTrackColor: amberPrimary.withValues(alpha: 0.24),
        thumbColor: amberPrimary,
        overlayColor: amberPrimary.withValues(alpha: 0.12),
        trackHeight: 6.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return amberPrimary;
          }
          return Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return amberPrimary.withValues(alpha: 0.38);
          }
          return Colors.grey.shade800;
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: amberPrimary,
          foregroundColor: Colors.black,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: amberPrimary,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: amberPrimary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: deepNightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: deepNightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: deepNightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: amberPrimary, width: 1.5),
        ),
      ),
    );
  }

  /// Generates the Light Material 3 theme.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE67E22),
      brightness: Brightness.light,
      primary: const Color(0xFFD35400),
      onPrimary: Colors.white,
      secondary: const Color(0xFFE67E22),
      surface: lightSurface,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      canvasColor: lightBackground,
      cardColor: lightSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: Color(0xFF1E293B),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFFE67E22),
        inactiveTrackColor: const Color(0xFFE67E22).withValues(alpha: 0.24),
        thumbColor: const Color(0xFFE67E22),
        overlayColor: const Color(0xFFE67E22).withValues(alpha: 0.12),
        trackHeight: 6.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE67E22),
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
