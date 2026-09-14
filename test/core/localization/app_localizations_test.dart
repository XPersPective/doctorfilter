import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppLocalizations translates fallback modern keys', () {
    final loc = AppLocalizations(const Locale('en'));
    expect(loc.translate('nav_home'), 'Home');
    expect(loc.translate('subzero_brightness'), 'Extra Dim / Sub-Zero');
    expect(
      loc.translate('kelvin_gauge', args: {'kelvin': '3200'}),
      '3200 K',
    );
  });

  test('AppLocalizations supported locales contains tr, en, de, fr', () {
    final codes = AppLocalizations.supportedLanguages.map((l) => l.code).toSet();
    expect(codes.contains('tr'), isTrue);
    expect(codes.contains('en'), isTrue);
    expect(codes.contains('de'), isTrue);
    expect(codes.contains('fr'), isTrue);
  });
}
