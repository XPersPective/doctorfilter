import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/core/math/ios_color_filter.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';

void main() {
  group('slider positions', () {
    test('a warm target lands in the orange part of the hue wheel', () {
      // Orange is 20–45 degrees; as a fraction of the full wheel that is
      // roughly 0.055 to 0.125. Anything outside means the user would be told
      // to set a tint that is not warm at all.
      for (final kelvin in [1700, 2200, 2700, 3400, 4300]) {
        final position = IosColourFilter.forKelvin(kelvin);
        expect(
          position.hueFraction,
          inInclusiveRange(20 / 360, 45 / 360),
          reason: '$kelvin K',
        );
      }
    });

    test('warmer means a stronger tint', () {
      final candle = IosColourFilter.forKelvin(1850);
      final evening = IosColourFilter.forKelvin(3400);

      expect(candle.intensityFraction, greaterThan(evening.intensityFraction));
    });

    test('the neutral end asks for almost no tint', () {
      final daylight = IosColourFilter.forKelvin(KelvinEngine.maxKelvin);
      expect(daylight.intensityFraction, lessThan(0.1));
    });

    test('density scales the intensity without moving the hue', () {
      final full = IosColourFilter.forKelvin(2700);
      final half = IosColourFilter.forKelvin(2700, densityPercent: 50);

      expect(half.hueFraction, closeTo(full.hueFraction, 1e-9));
      expect(half.intensityFraction, closeTo(full.intensityFraction / 2, 1e-9));
    });

    test('every fraction is a real slider position', () {
      for (var kelvin = KelvinEngine.minKelvin;
          kelvin <= KelvinEngine.maxKelvin;
          kelvin += 100) {
        final position = IosColourFilter.forKelvin(kelvin);
        expect(position.hueFraction, inInclusiveRange(0.0, 1.0));
        expect(position.intensityFraction, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('honesty', () {
    test('the quoted temperature is rounded to what a numberless slider allows', () {
      expect(IosColourFilter.achievableKelvin(2713), 2700);
      expect(IosColourFilter.achievableKelvin(2740), 2750);
    });

    test('reduce white point carries the extra-dim axis across unchanged', () {
      expect(IosColourFilter.reduceWhitePointFraction(0), 0);
      expect(IosColourFilter.reduceWhitePointFraction(70), closeTo(0.7, 1e-9));
    });
  });
}
