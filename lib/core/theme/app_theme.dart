import 'package:flutter/material.dart';

/// Colours that carry meaning rather than decoration.
///
/// A [ThemeExtension] rather than static constants, because the same meaning
/// needs a different colour in each theme: a green that reads as "safe" on a
/// near-black background is washed out on white. Widgets that referenced the
/// constants directly are exactly why text went invisible in light mode.
@immutable
class CircadianColors extends ThemeExtension<CircadianColors> {
  const CircadianColors({
    required this.sleepFriendly,
    required this.evening,
    required this.balanced,
    required this.blueRisk,
    required this.onBand,
  });

  /// Below 2700 K — safe for bedtime.
  final Color sleepFriendly;

  /// 2700–4000 K.
  final Color evening;

  /// 4000–5000 K.
  final Color balanced;

  /// Above 5000 K — significant short-wavelength content.
  final Color blueRisk;

  /// Text drawn on top of any band colour.
  final Color onBand;

  static const dark = CircadianColors(
    sleepFriendly: Color(0xFF66BB6A),
    evening: Color(0xFFFFCA28),
    balanced: Color(0xFFFF8A65),
    blueRisk: Color(0xFFEF5350),
    onBand: Color(0xFF0F141C),
  );

  /// Darker and more saturated than the dark-theme set: these sit on white and
  /// must stay legible as text, not just as a dot.
  static const light = CircadianColors(
    sleepFriendly: Color(0xFF2E7D32),
    evening: Color(0xFFB26A00),
    balanced: Color(0xFFD84315),
    blueRisk: Color(0xFFC62828),
    onBand: Color(0xFFFFFFFF),
  );

  @override
  CircadianColors copyWith({
    Color? sleepFriendly,
    Color? evening,
    Color? balanced,
    Color? blueRisk,
    Color? onBand,
  }) {
    return CircadianColors(
      sleepFriendly: sleepFriendly ?? this.sleepFriendly,
      evening: evening ?? this.evening,
      balanced: balanced ?? this.balanced,
      blueRisk: blueRisk ?? this.blueRisk,
      onBand: onBand ?? this.onBand,
    );
  }

  @override
  CircadianColors lerp(ThemeExtension<CircadianColors>? other, double t) {
    if (other is! CircadianColors) return this;
    return CircadianColors(
      sleepFriendly: Color.lerp(sleepFriendly, other.sleepFriendly, t)!,
      evening: Color.lerp(evening, other.evening, t)!,
      balanced: Color.lerp(balanced, other.balanced, t)!,
      blueRisk: Color.lerp(blueRisk, other.blueRisk, t)!,
      onBand: Color.lerp(onBand, other.onBand, t)!,
    );
  }
}

/// Convenience accessors so widgets never reach for a raw constant.
extension ThemeColours on BuildContext {
  ColorScheme get colours => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;

  CircadianColors get bands =>
      Theme.of(this).extension<CircadianColors>() ?? CircadianColors.dark;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// The app's Material 3 themes.
///
/// Both are produced by one builder, so a control styled in one theme cannot
/// silently go unstyled in the other — the previous version themed switches,
/// outlined buttons and text fields in dark mode only.
abstract final class AppTheme {
  /// Warm amber for dark, a deeper orange for light. Two values because the
  /// same amber that glows on near-black is unreadable on white.
  static const Color _darkAccent = Color(0xFFFF9E43);
  static const Color _lightAccent = Color(0xFFB4500A);

  static const Color _nightBackground = Color(0xFF0F141C);
  static const Color _nightSurface = Color(0xFF161E28);
  static const Color _nightCard = Color(0xFF1E2836);
  static const Color _nightBorder = Color(0xFF2B384A);

  static const Color _dayBackground = Color(0xFFF8F9FA);
  static const Color _daySurface = Color(0xFFFFFFFF);
  static const Color _dayBorder = Color(0xFFE2E8F0);

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        accent: _darkAccent,
        onAccent: Colors.black,
        background: _nightBackground,
        surface: _nightSurface,
        card: _nightCard,
        border: _nightBorder,
        bands: CircadianColors.dark,
      );

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        accent: _lightAccent,
        onAccent: Colors.white,
        background: _dayBackground,
        surface: _daySurface,
        card: _daySurface,
        border: _dayBorder,
        bands: CircadianColors.light,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color accent,
    required Color onAccent,
    required Color background,
    required Color surface,
    required Color card,
    required Color border,
    required CircadianColors bands,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      surface: surface,
      // The filter already tints the whole screen; Material's elevation tint on
      // top of that makes surfaces drift colour for no reason.
      surfaceTint: Colors.transparent,
    );

    final radius = BorderRadius.circular(16);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: card,
      dividerColor: border,
      extensions: [bands],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: accent.withValues(alpha: 0.24),
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.12),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withValues(alpha: 0.18),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // 48dp is the accessible minimum touch target, and this app is used
          // half-asleep in the dark.
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(48, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? card : _dayBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
