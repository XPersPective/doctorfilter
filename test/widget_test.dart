import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctorfilter/main.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.crazypenguin.doctorfilter'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkOverlayPermission') return true;
        if (methodCall.method == 'isFilterRunning') return false;
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.crazypenguin.doctorfilter'),
      null,
    );
  });

  testWidgets('DoctorFilterApp basic smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const DoctorFilterApp(),
      ),
    );

    await tester.pumpAndSettle();

    // DoctorFilter app bar title
    expect(find.text('DoctorFilter'), findsOneWidget);
  });
}
