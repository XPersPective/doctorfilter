import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/domain/entities/schedule_rule.dart';

void main() {
  group('transition', () {
    test('a value from outside is clamped to the offered range', () {
      final rule = ScheduleRule.defaultBedtime();

      expect(rule.copyWith(transitionMinutes: 999).transitionMinutes,
          ScheduleRule.maxTransitionMinutes);
      expect(rule.copyWith(transitionMinutes: -5).transitionMinutes, 0);
    });

    test('zero is kept, not treated as absent', () {
      // copyWith's `?? this` idiom is exactly where an explicit "instant"
      // silently becomes the 30-minute default.
      expect(
        ScheduleRule.defaultBedtime().copyWith(transitionMinutes: 0).transitionMinutes,
        0,
      );
    });
  });
}
