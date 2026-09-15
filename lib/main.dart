import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctorfilter/core/config/env_config.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/data/datasources/local/preferences_datasource.dart';
import 'package:doctorfilter/presentation/ads/ad_consent.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';
import 'package:doctorfilter/presentation/providers/pro_provider.dart';
import 'package:doctorfilter/presentation/providers/theme_and_locale_provider.dart';
import 'package:doctorfilter/presentation/screens/home_screen.dart';
import 'package:doctorfilter/presentation/screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.init();

  final sharedPreferences = await SharedPreferences.getInstance();

  // Before anything reads settings. Someone updating the app must find their
  // screen exactly as they left it.
  await PreferencesDataSource(sharedPreferences).migrate();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const DoctorFilterApp(),
    ),
  );
}

class DoctorFilterApp extends ConsumerStatefulWidget {
  const DoctorFilterApp({super.key});

  @override
  ConsumerState<DoctorFilterApp> createState() => _DoctorFilterAppState();
}

class _DoctorFilterAppState extends ConsumerState<DoctorFilterApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding =
        !ref.read(preferencesDataSourceProvider).isOnboardingDone();
    _initialiseAds();
  }

  Future<void> _finishOnboarding() async {
    await ref.read(preferencesDataSourceProvider).setOnboardingDone();
    if (mounted) setState(() => _showOnboarding = false);
  }

  /// Starts the ad stack, in the one order that is allowed.
  ///
  /// Consent first, always: requesting an ad before UMP has resolved breaches
  /// AdMob policy in the EEA and gets the app cut off from serving entirely.
  /// And for a Pro user the SDK is never initialised at all — not initialised
  /// and then told to stay quiet, but never started.
  Future<void> _initialiseAds() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (ref.read(isProProvider)) return;

    await AdConsent.gather();
    if (!mounted) return;
    await MobileAds.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'DoctorFilter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: ref.watch(darkThemeProvider),
      themeMode: themeMode,
      // Null follows the device, which is what someone whose phone is in Turkish
      // expects to see on first launch.
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _showOnboarding
          ? OnboardingScreen(onFinished: _finishOnboarding)
          : const HomeScreen(),
    );
  }
}
