import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/core/localization/supported_languages.dart';

/// Guards the localisation contract.
///
/// English is the canonical key set and the fallback every other language falls
/// back to, so a key that is missing there does not degrade — it surfaces to the
/// user as a raw identifier like `pro_upgrade_btn`. These tests catch that at
/// build time rather than in a screenshot from an angry review.
void main() {
  final localizations = Directory('assets/Localizations');

  Map<String, dynamic> load(String code) => json.decode(
        File('${localizations.path}/$code.json').readAsStringSync(),
      ) as Map<String, dynamic>;

  late Map<String, dynamic> english;

  setUpAll(() {
    english = load('en');
  });

  test('every key the code asks for exists in English', () {
    final used = <String, String>{};
    final pattern = RegExp(r"translate\(\s*'([a-zA-Z0-9_]+)'");

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final match in pattern.allMatches(entity.readAsStringSync())) {
        used[match.group(1)!] = entity.path;
      }
    }

    expect(used, isNotEmpty, reason: 'the scan itself should find keys');

    final missing = used.entries
        .where((entry) => !english.containsKey(entry.key))
        .map((entry) => '${entry.key}  (${entry.value})')
        .toList()
      ..sort();

    expect(missing, isEmpty,
        reason: 'these keys would render as raw identifiers:\n${missing.join('\n')}');
  });

  test('Turkish covers the English key set', () {
    // Turkish is the other hand-reviewed language; the remaining locales are
    // allowed to be incomplete and fall back.
    final turkish = load('tr');
    final missing = english.keys
        .where((key) => !turkish.containsKey(key))
        // Two dead 1.x theme-name keys that were never in the Turkish file.
        .where((key) => !key.startsWith('app_nametheme'))
        .toList()
      ..sort();

    expect(missing, isEmpty, reason: 'untranslated: ${missing.join(', ')}');
  });

  test('placeholders match between English and Turkish', () {
    final turkish = load('tr');
    final placeholder = RegExp(r'\{(\w+)\}');

    final mismatched = <String>[];
    for (final entry in english.entries) {
      final other = turkish[entry.key];
      if (other is! String) continue;

      final expected = placeholder
          .allMatches(entry.value.toString())
          .map((m) => m.group(1))
          .toSet();
      final actual = placeholder.allMatches(other).map((m) => m.group(1)).toSet();

      // A dropped placeholder shows the user a sentence with a hole in it.
      if (expected.difference(actual).isNotEmpty ||
          actual.difference(expected).isNotEmpty) {
        mismatched.add('${entry.key}: expected $expected, got $actual');
      }
    }

    expect(mismatched, isEmpty, reason: mismatched.join('\n'));
  });

  test('the language list and the translation files agree', () {
    // A listed code with no file falls back to English silently; a file with no
    // listing is unreachable. Either way the user loses their language.
    final files = localizations
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .map((file) => file.uri.pathSegments.last.replaceAll('.json', ''))
        .toSet();
    final listed = kSupportedLanguages.map((language) => language.code).toSet();

    expect(listed.difference(files), isEmpty, reason: 'listed but no file');
    expect(files.difference(listed), isEmpty, reason: 'file but not offered');
  });

  test('language codes are unique', () {
    final codes = kSupportedLanguages.map((language) => language.code).toList();
    expect(codes.length, codes.toSet().length);
  });

  test('every shipped locale file is valid JSON', () {
    final broken = <String>[];
    for (final entity in localizations.listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        json.decode(entity.readAsStringSync());
      } catch (error) {
        broken.add('${entity.path}: $error');
      }
    }
    expect(broken, isEmpty, reason: broken.join('\n'));
  });
}
