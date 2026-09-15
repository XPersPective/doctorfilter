import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';

FilterConfig config({
  int kelvin = 3200,
  int density = 30,
  int dim = 20,
}) =>
    FilterConfig(
      isEnabled: true,
      activePresetId: 0,
      kelvin: kelvin,
      densityPercent: density,
      extraDimPercent: dim,
      isNotificationEnabled: true,
      isScheduleEnabled: false,
    );

void main() {
  group('the screen can never be blacked out', () {
    test('every reachable combination leaves the screen visible', () {
      for (var d = 0; d <= 100; d += 5) {
        for (var k = 0; k <= 100; k += 5) {
          final c = config(density: d, dim: k);
          expect(c.compositeAlpha, lessThanOrEqualTo(FilterConfig.maxCompositeAlpha),
              reason: 'density $d%, dim $k% produced ${c.compositeAlpha}');
        }
      }
    });

    test('the worst case still transmits at least 8% of the screen', () {
      final worst = config(kelvin: KelvinEngine.minKelvin, density: 100, dim: 100);
      expect(1 - worst.compositeAlpha, closeTo(0.08, 0.0001));
    });
  });

  group('axes are clamped at construction, not in the UI', () {
    test('density above the cap is clamped', () {
      expect(config(density: 999).densityPercent, FilterConfig.maxDensityPercent);
    });

    test('extra dim above the cap is clamped', () {
      expect(config(dim: 999).extraDimPercent, FilterConfig.maxExtraDimPercent);
    });

    test('negative values are clamped to zero', () {
      final c = config(density: -50, dim: -50);
      expect(c.densityPercent, 0);
      expect(c.extraDimPercent, 0);
    });

    test('kelvin outside the engine range is clamped', () {
      expect(config(kelvin: 500).kelvin, KelvinEngine.minKelvin);
      expect(config(kelvin: 40000).kelvin, KelvinEngine.maxKelvin);
    });

    test('copyWith clamps too — it does not bypass the constructor', () {
      expect(config().copyWith(densityPercent: 999).densityPercent,
          FilterConfig.maxDensityPercent);
    });
  });

  group('composite model', () {
    test('no filter at all is fully transparent', () {
      expect(config(density: 0, dim: 0).compositeAlpha, 0.0);
    });

    test('the two axes stack without ever summing past 1', () {
      final c = config(density: 80, dim: 70);
      expect(c.compositeAlpha, lessThanOrEqualTo(1.0));
      expect(c.compositeAlpha, greaterThan(config(density: 80, dim: 0).compositeAlpha));
    });

    test('dimming darkens the overlay colour toward black', () {
      final bright = config(dim: 0).overlayColor;
      final dark = config(dim: 70).overlayColor;
      expect(dark.r, lessThan(bright.r));
      expect(dark.g, lessThan(bright.g));
    });

    test('overlay alpha is expressed in the 0-255 the platform layer wants', () {
      expect(config(density: 0, dim: 0).overlayAlpha, 0);
      expect(config(density: 80, dim: 70).overlayAlpha, lessThanOrEqualTo(255));
    });
  });

  group('honest reporting', () {
    test('a colour-only setup is flagged as the weak configuration it is', () {
      expect(config(density: 50, dim: 0).isColourOnly, isTrue);
      expect(config(density: 50, dim: 30).isColourOnly, isFalse);
    });

    test('dimming increases blue reduction even at an unchanged tint', () {
      final noDim = config(kelvin: 2700, density: 40, dim: 0).blueLightReduction;
      final dimmed = config(kelvin: 2700, density: 40, dim: 60).blueLightReduction;
      expect(dimmed, greaterThan(noDim));
    });

    test('a neutral tint with no dimming claims essentially nothing', () {
      final c = config(kelvin: KelvinEngine.neutralDaylightKelvin, density: 80, dim: 0);
      expect(c.blueLightReduction, lessThan(0.05));
    });
  });
}
