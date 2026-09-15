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

  group('bedtime', () {
    test('the wind-down starts three hours before bed and fills the window', () {
      final rule = ScheduleRule.defaultBedtime()
          .forBedtime(bedHour: 23, bedMinute: 30);

      expect(rule.startHour, 20);
      expect(rule.startMinute, 30);
      expect(rule.transitionMinutes, ScheduleRule.windDownHours * 60);
      expect(rule.isEnabled, isTrue);
    });

    test('an early bedtime wraps back to the previous evening', () {
      // Bed at 01:00 means the descent starts at 22:00 the day before, not at
      // minus two o'clock.
      final rule = ScheduleRule.defaultBedtime()
          .forBedtime(bedHour: 1, bedMinute: 0);

      expect(rule.startHour, 22);
      expect(rule.startMinute, 0);
    });
  });
}
