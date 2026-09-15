import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';

void main() {
  group('kelvinToRgb', () {
    test('tint is normalised — the brightest channel is always saturated', () {
      for (var k = KelvinEngine.minKelvin; k <= KelvinEngine.maxKelvin; k += 100) {
        final rgb = KelvinEngine.kelvinToRgb(k);
        final peak = [rgb.r, rgb.g, rgb.b].reduce((a, b) => a > b ? a : b);
        expect(peak, 255, reason: '${k}K peaked at $peak instead of 255');
      }
    });

    test('blue content rises monotonically with temperature', () {
      var previous = -1;
      for (var k = KelvinEngine.minKelvin; k <= KelvinEngine.maxKelvin; k += 100) {
        final blue = KelvinEngine.kelvinToRgb(k).b;
        expect(blue, greaterThanOrEqualTo(previous), reason: 'blue dipped at ${k}K');
        previous = blue;
      }
    });

    test('1850K candle flame is deep amber with almost no blue', () {
      final rgb = KelvinEngine.kelvinToRgb(1850);
      expect(rgb.r, 255);
      expect(rgb.b, lessThan(15));
    });

    test('6500K D65 is neutral white', () {
      final rgb = KelvinEngine.kelvinToRgb(6500);
      expect(rgb.r, inInclusiveRange(245, 255));
      expect(rgb.g, inInclusiveRange(245, 255));
      expect(rgb.b, inInclusiveRange(245, 255));
    });

    test('out-of-range input is clamped, not extrapolated', () {
      expect(KelvinEngine.kelvinToRgb(500), KelvinEngine.kelvinToRgb(1667));
      expect(KelvinEngine.kelvinToRgb(40000), KelvinEngine.kelvinToRgb(25000));
    });
  });

  group('round trip — the Kelvin we show the user must be the Kelvin we render', () {
    test('kelvin -> rgb -> kelvin stays within 2%', () {
      for (var k = KelvinEngine.minKelvin; k <= KelvinEngine.maxKelvin; k += 100) {
        final rgb = KelvinEngine.kelvinToRgb(k);
        final back = KelvinEngine.rgbToKelvin(rgb.r, rgb.g, rgb.b);
        expect(back, isNotNull, reason: '${k}K produced an unmeasurable colour');
        // 2% is the 8-bit quantisation floor, not an engine limit: near D65 all
        // three channels sit within a few codes of 255.
        final error = (back! - k).abs() / k;
        expect(error, lessThan(0.02),
            reason: '${k}K round-tripped to ${back}K (${(error * 100).toStringAsFixed(1)}%)');
      }
    });

    test('rgbToKelvin returns null for black', () {
      expect(KelvinEngine.rgbToKelvin(0, 0, 0), isNull);
    });
  });

  group('safetyLevel', () {
    test('bands match the documented thresholds', () {
      expect(KelvinEngine.safetyLevel(1850), MelatoninSafetyLevel.sleepFriendly);
      expect(KelvinEngine.safetyLevel(2699), MelatoninSafetyLevel.sleepFriendly);
      expect(KelvinEngine.safetyLevel(2700), MelatoninSafetyLevel.evening);
      expect(KelvinEngine.safetyLevel(3999), MelatoninSafetyLevel.evening);
      expect(KelvinEngine.safetyLevel(4000), MelatoninSafetyLevel.balanced);
      expect(KelvinEngine.safetyLevel(4999), MelatoninSafetyLevel.balanced);
      expect(KelvinEngine.safetyLevel(5000), MelatoninSafetyLevel.blueLightRisk);
    });
  });

  group('blueLightReduction', () {
    test('no overlay removes nothing', () {
      expect(
        KelvinEngine.blueLightReduction(tintKelvin: 2200, compositeAlpha: 0),
        0.0,
      );
    });

    test('warmer tint removes more blue at equal strength', () {
      final warm =
          KelvinEngine.blueLightReduction(tintKelvin: 1850, compositeAlpha: 0.5);
      final cool =
          KelvinEngine.blueLightReduction(tintKelvin: 6000, compositeAlpha: 0.5);
      expect(warm, greaterThan(cool));
    });

    test('stronger overlay removes more blue at equal tint', () {
      final weak =
          KelvinEngine.blueLightReduction(tintKelvin: 2200, compositeAlpha: 0.2);
      final strong =
          KelvinEngine.blueLightReduction(tintKelvin: 2200, compositeAlpha: 0.8);
      expect(strong, greaterThan(weak));
    });

    test('a neutral tint removes essentially no blue however strong it is', () {
      // 6500K is the screen's own white point: covering white with white does nothing.
      final reduction = KelvinEngine.blueLightReduction(
        tintKelvin: KelvinEngine.neutralDaylightKelvin,
        compositeAlpha: 0.8,
      );
      expect(reduction, lessThan(0.05));
    });

    test('never exceeds the physically possible 100%', () {
      expect(
        KelvinEngine.blueLightReduction(tintKelvin: 1700, compositeAlpha: 1.0),
        inInclusiveRange(0.0, 1.0),
      );
    });
  });

  group('luminanceReduction', () {
    test('dimming dominates: a strong warm overlay cuts luminance substantially', () {
      final reduction =
          KelvinEngine.luminanceReduction(tintKelvin: 1850, compositeAlpha: 0.8);
      expect(reduction, greaterThan(0.3));
    });

    test('no overlay dims nothing', () {
      expect(
        KelvinEngine.luminanceReduction(tintKelvin: 2200, compositeAlpha: 0),
        0.0,
      );
    });
  });
}
