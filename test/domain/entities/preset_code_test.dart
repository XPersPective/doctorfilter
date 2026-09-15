import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/domain/entities/preset_code.dart';

void main() {
  group('round trip', () {
    test('values survive encoding, to the nearest 50 K step', () {
      for (final kelvin in [1700, 2700, 3450, 5000, 6500]) {
        final code = PresetCode.encode(
          kelvin: kelvin,
          densityPercent: 45,
          extraDimPercent: 30,
        );
        final decoded = PresetCode.decode(code);

        expect(decoded, isNotNull, reason: code);
        expect((decoded!.kelvin - kelvin).abs(), lessThanOrEqualTo(50));
        expect(decoded.densityPercent, 45);
        expect(decoded.extraDimPercent, 30);
      }
    });

    test('a code is always five characters', () {
      expect(
        PresetCode.encode(kelvin: 6500, densityPercent: 80, extraDimPercent: 70).length,
        5,
      );
      expect(
        PresetCode.encode(kelvin: 1700, densityPercent: 0, extraDimPercent: 0).length,
        5,
      );
    });
  });

  group('bad input', () {
    test('a mistyped character is rejected rather than silently wrong', () {
      final code = PresetCode.encode(
        kelvin: 2700,
        densityPercent: 45,
        extraDimPercent: 30,
      );

      // Every single-character substitution that changes the code must either
      // fail the checksum or be caught elsewhere — never decode as if correct.
      var undetected = 0;
      for (var index = 0; index < code.length; index++) {
        for (final replacement in '0123456789ABCDEFGHJKMNPQRSTVWXYZ'.split('')) {
          if (replacement == code[index]) continue;
          final typo = code.replaceRange(index, index + 1, replacement);
          if (PresetCode.decode(typo) != null) undetected++;
        }
      }

      // 4 checksum bits catch ~15 in 16; the assertion is that the check is
      // actually doing something, not that it is perfect.
      expect(undetected / (code.length * 31), lessThan(0.15));
    });

    test('rubbish is rejected', () {
      expect(PresetCode.decode(''), isNull);
      expect(PresetCode.decode('ABC'), isNull);
      expect(PresetCode.decode('ABCDEFG'), isNull);
      expect(PresetCode.decode('!!!!!'), isNull);
    });

    test('a human transcription still works', () {
      final code = PresetCode.encode(
        kelvin: 3000,
        densityPercent: 50,
        extraDimPercent: 40,
      );
      final decoded = PresetCode.decode(code);

      expect(PresetCode.decode(code.toLowerCase()), decoded);
      expect(PresetCode.decode(' $code '), decoded);
    });
  });
}
