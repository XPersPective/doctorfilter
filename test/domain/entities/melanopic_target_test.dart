import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/domain/entities/melanopic_target.dart';

void main() {
  group('progress towards the evening guidance', () {
    test('an unfiltered screen is at the start of the ring', () {
      expect(MelanopicTarget.progress(0), 0);
    });

    test('the target fills the ring and nothing overfills it', () {
      expect(MelanopicTarget.progress(MelanopicTarget.eveningReduction), 1.0);
      // Past the target the ring stays full rather than wrapping round again.
      expect(MelanopicTarget.progress(0.95), 1.0);
    });

    test('meeting the guidance is target-inclusive', () {
      expect(MelanopicTarget.meetsEvening(MelanopicTarget.eveningReduction), isTrue);
      expect(
        MelanopicTarget.meetsEvening(MelanopicTarget.eveningReduction - 0.01),
        isFalse,
      );
    });
  });
}
