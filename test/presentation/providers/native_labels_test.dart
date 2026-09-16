import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/presentation/providers/notification_sync_provider.dart';

void main() {
  final files = Directory('assets/Localizations')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'));

  for (final file in files) {
    test('native labels are complete and formattable: ${file.uri.pathSegments.last}', () {
      final strings = Map<String, dynamic>.from(
        jsonDecode(file.readAsStringSync()) as Map,
      );
      final labels = nativeLabels((key) {
        final value = strings[key];
        expect(value, isA<String>(), reason: 'missing $key');
        return (value as String).replaceAll('%', '%%');
      });

      for (final entry in labels.entries) {
        // Whatever is left once the known specifiers are removed must hold no
        // stray '%', or String.format on the Android side would throw.
        final leftover = entry.value
            .replaceAll(RegExp(r'%[12]\$d'), '')
            .replaceAll('%%', '');
        expect(leftover.contains('%'), isFalse, reason: entry.key);
        expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      }
    });
  }
}
