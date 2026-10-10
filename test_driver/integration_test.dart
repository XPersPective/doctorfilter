import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Writes each screenshot taken by `integration_test/screenshots_test.dart`
/// to `screenshots/en-US/<name>.png`, the layout `fastlane deliver` expects.
Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final file = File('screenshots/en-US/$name.png');
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        return true;
      },
    );
