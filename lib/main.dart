import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctorfilter/core/config/env_config.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/data/datasources/local/preferences_datasource.dart';
import 'package:doctorfilter/presentation/ads/ad_consent.dart';
import 'package:doctorfilter/presentation/ads/app_open_ad_manager.dart';
import 'package:doctorfilter/presentation/providers/ad_providers.dart';
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

class _DoctorFilterAppState extends ConsumerState<DoctorFilterApp>
    with WidgetsBindingObserver {
  late bool _showOnboarding;
  bool _firstFrameReady = false;
  bool _startingAds = false;
  Timer? _adRetry;

  bool get _mayStartAds =>
      mounted &&
      _firstFrameReady &&
      (Platform.isAndroid || Platform.isIOS) &&
      !const bool.fromEnvironment('STORE_SCREENSHOTS') &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
      !ref.read(isProProvider);

  @override
  void initState() {
    super.initState();
    _showOnboarding = !ref
        .read(preferencesDataSourceProvider)
        .isOnboardingDone();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(isProProvider, (_, _) => _syncAds());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _firstFrameReady = true;
      _syncAds(coldStart: true);
    });
  }

  Future<void> _finishOnboarding() async {
    await ref.read(preferencesDataSourceProvider).setOnboardingDone();
    if (mounted) setState(() => _showOnboarding = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(proStatusProvider.notifier).refresh();
    }
    _syncAds();
  }

  void _syncAds({bool coldStart = false}) {
    _adRetry?.cancel();
    _adRetry = null;
    if (_mayStartAds && !_startingAds) {
      unawaited(_initialiseAds(coldStart: coldStart));
    }
  }

  Future<void> _initialiseAds({required bool coldStart}) async {
    _startingAds = true;
    try {
      await ref
          .read(proStatusProvider.notifier)
          .initialRestore
          .timeout(const Duration(seconds: 15), onTimeout: () {});
      if (!_mayStartAds) return;
      final ready = await AdConsent.initialize(isEligible: () => _mayStartAds);
      if (!_mayStartAds) return;
      if (!ready) {
        _adRetry = Timer(const Duration(minutes: 1), _syncAds);
        return;
      }

      // Recovery, resume and Pro expiry must not show a late app-open ad.
      if (!coldStart || _showOnboarding) return;
      final policy = ref.read(adPolicyProvider.notifier);
      if (policy.mayShowAppOpen &&
          await AppOpenAdManager.loadAndShow(isEligible: () => _mayStartAds)) {
        if (mounted) policy.recordAppOpenShown();
      }
    } finally {
      _startingAds = false;
    }
  }

  @override
  void dispose() {
    _adRetry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(effectiveThemeModeProvider);
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
