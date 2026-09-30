import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/domain/entities/pro_status.dart';
import 'package:doctorfilter/domain/repositories/i_purchase_repository.dart';

void main() {
  test('the published 1.x product is recognised during Pro restoration', () {
    expect(ProProduct.allIds, contains('doctorfilterpro'));
    expect(ProProduct.allIds, isNot(contains('doctorfilter_proversion')));
    expect(ProProduct.allIds, isNot(contains('testconsumable')));
  });

  group('ProStatus', () {
    test('a free user is not entitled', () {
      expect(ProStatus.free().isActive, isFalse);
      expect(ProStatus.free().passRemaining, isNull);
    });

    test('a lifetime purchase is entitled and never expires', () {
      final status = ProStatus.lifetime();
      expect(status.isActive, isTrue);
      expect(status.isLifetime, isTrue);
      expect(status.passRemaining, isNull);
    });

    test('a live pass is entitled', () {
      final status = ProStatus.pass(DateTime.now().add(const Duration(hours: 5)));
      expect(status.isActive, isTrue);
      expect(status.passRemaining, isNotNull);
    });

    test('an expired pass is not entitled — this is why it is not a boolean', () {
      final status = ProStatus.pass(DateTime.now().subtract(const Duration(minutes: 1)));
      expect(status.isActive, isFalse);
      expect(status.passRemaining, isNull);
    });

    test('a pass expiring exactly now has lapsed', () {
      expect(ProStatus.pass(DateTime.now()).isActive, isFalse);
    });
  });
}
