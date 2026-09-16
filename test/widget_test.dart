import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctorfilter/main.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';
import 'package:doctorfilter/presentation/screens/home_screen.dart';
import 'package:doctorfilter/presentation/screens/onboarding_screen.dart';
import 'package:doctorfilter/presentation/widgets/brand_lockup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.crazypenguin.doctorfilter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'checkOverlayPermission') return true;
      if (call.method == 'isFilterRunning') return false;
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    // rootBundle caches the *future* for each asset, and a future created inside
    // a finished test's fake-async zone never completes. Without this clear, the
    // localisation delegate in every test after the first waits forever and
    // Localizations renders an empty tree.
    rootBundle.clear();

    // getInstance() caches its result for the whole process, so without this a
    // later test silently gets the previous test's preferences.
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues(prefs);
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        // A fresh key forces a new State: without it Flutter reuses the previous
        // test's DoctorFilterApp state and initState never re-reads preferences.
        child: DoctorFilterApp(key: UniqueKey()),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('a first-time user lands on onboarding', (tester) async {
    await pumpApp(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    // The brand mark, not a generic icon: the first thing a new user sees
    // should be the icon they just tapped.
    expect(
      find.image(const AssetImage('assets/images/brand_mark.png')),
      findsOneWidget,
    );
  });

  testWidgets('a returning user goes straight to the app', (tester) async {
    await pumpApp(tester, prefs: {'flutter.df_onboarding_done': true});

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('finishing onboarding is remembered within the session',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the home screen renders in both themes', (tester) async {
    // Catches the class of bug where a widget is styled for one brightness and
    // throws or vanishes in the other.
    for (final isDark in [true, false]) {
      await pumpApp(tester, prefs: {
        'flutter.df_onboarding_done': true,
        'flutter.df_app_is_dark_mode': isDark,
      });

      expect(find.byType(HomeScreen), findsOneWidget,
          reason: isDark ? 'dark theme' : 'light theme');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the home screen fits a small phone without overflowing',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester, prefs: {'flutter.df_onboarding_done': true});

    expect(tester.takeException(), isNull);
  });

  testWidgets('the home screen survives a right-to-left locale',
      (tester) async {
    await pumpApp(tester, prefs: {
      'flutter.df_onboarding_done': true,
      'flutter.df_app_locale': 'ar',
    });

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(HomeScreen))),
        TextDirection.rtl);
    // Kelvin readouts must be isolated as left-to-right, or "2700 K" renders
    // as "K 2700" in a right-to-left paragraph.
    expect(find.textContaining(RegExp(r'\u2066\d+ K\u2069')), findsWidgets);
  });

  Finder proBadge() => find.descendant(
        of: find.byType(BrandLockup),
        matching: find.text('PRO'),
      );

  testWidgets('a free user sees the logo without PRO', (tester) async {

    await pumpApp(tester, prefs: {'flutter.df_onboarding_done': true});
    expect(find.byType(BrandLockup), findsOneWidget);
    expect(proBadge(), findsNothing);
  });

  testWidgets('an owner sees PRO on the logo', (tester) async {
    await pumpApp(tester, prefs: {
      'flutter.df_onboarding_done': true,
      'flutter.df_pro_lifetime': true,
    });
    expect(proBadge(), findsOneWidget);
  });

  testWidgets('the Pro logo fits a small phone beside the app bar actions',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester, prefs: {
      'flutter.df_onboarding_done': true,
      'flutter.df_pro_lifetime': true,
    });

    expect(tester.takeException(), isNull);
  });

  testWidgets('the power switch reads once and stays tappable for screen readers',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, prefs: {'flutter.df_onboarding_done': true});

    // Exactly one node: before the fix the label was read twice, once from
    // the Semantics wrapper and once from the visible text beneath it.
    final power = find.bySemanticsLabel('Filter off');
    expect(power, findsOneWidget);
    expect(
      tester.getSemantics(power),
      matchesSemantics(
        label: 'Filter off',
        isButton: true,
        hasTapAction: true,
        hasToggledState: true,
      ),
    );
    semantics.dispose();
  });
}
