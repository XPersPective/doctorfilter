import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:doctorfilter/main.dart' as app;

/// Captures the App Store screenshots on a real iOS simulator.
///
/// Run with `--dart-define=STORE_SCREENSHOTS=true` so no consent form, tracking
/// prompt or test-ad label ends up in the images.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screenshots', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('01_welcome');

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('02_home');

    final tabs = find.byType(NavigationDestination);
    for (var i = 1; i < 4; i++) {
      await tester.tap(tabs.at(i));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('0${i + 2}_tab$i');
    }
  });
}
