import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';

void main() {
  group('KelvinEngine - kelvinToRgb', () {
    test('1000K candle flame gives deep red/amber with zero blue', () {
      final rgb = KelvinEngine.kelvinToRgb(1000);
      expect(rgb.r, 255);
      expect(rgb.g, inInclusiveRange(50, 80));
      expect(rgb.b, 0);
    });

    test('2200K bedtime gives warm amber with very low blue', () {
      final rgb = KelvinEngine.kelvinToRgb(2200);
      expect(rgb.r, 255);
      expect(rgb.g, inInclusiveRange(130, 160));
      expect(rgb.b, inInclusiveRange(10, 40));
    });

    test('3200K incandescent bulb gives warm white', () {
      final rgb = KelvinEngine.kelvinToRgb(3200);
      expect(rgb.r, 255);
      expect(rgb.g, inInclusiveRange(170, 200));
      expect(rgb.b, inInclusiveRange(90, 130));
    });

    test('6500K standard daylight gives neutral white', () {
      final rgb = KelvinEngine.kelvinToRgb(6500);
      expect(rgb.r, inInclusiveRange(250, 255));
      expect(rgb.g, inInclusiveRange(245, 255));
      expect(rgb.b, inInclusiveRange(245, 255));
    });
  });

  group('KelvinEngine - Safety level classification', () {
    test('Classifies safety levels correctly', () {
      expect(KelvinEngine.getSafetyLevel(1400), MelatoninSafetyLevel.safeBedtime);
      expect(KelvinEngine.getSafetyLevel(2200), MelatoninSafetyLevel.safeBedtime);
      expect(KelvinEngine.getSafetyLevel(3200), MelatoninSafetyLevel.relaxingEvening);
      expect(KelvinEngine.getSafetyLevel(5000), MelatoninSafetyLevel.balancedDaylight);
      expect(KelvinEngine.getSafetyLevel(6500), MelatoninSafetyLevel.highBlueLightRisk);
    });
  });

  group('KelvinEngine - rgbToKelvin CCT estimation', () {
    test('calculates reasonable CCT for warm and cool colors', () {
      // 3200K RGB test
      final rgb3200 = KelvinEngine.kelvinToRgb(3200);
      final estimated = KelvinEngine.rgbToKelvin(rgb3200.r, rgb3200.g, rgb3200.b);
      expect(estimated, isNotNull);
      // Empirical McCamy approximation margin of error is typically within ±200K
      expect(estimated!, inInclusiveRange(2900, 3500));
    });

    test('returns null for pure black (0, 0, 0)', () {
      expect(KelvinEngine.rgbToKelvin(0, 0, 0), isNull);
    });
  });

  group('KelvinEngine - Blue light blocked calculation', () {
    test('Lower kelvin yields higher blue light blockage', () {
      final block1400 = KelvinEngine.calculateBlueLightBlockedPercentage(1400, 50);
      final block6000 = KelvinEngine.calculateBlueLightBlockedPercentage(6000, 50);
      expect(block1400, greaterThan(block6000));
    });
  });
}
