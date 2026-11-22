import 'dart:async';

import 'package:doctorfilter/data/repositories/store_purchase_repository.dart';
import 'package:doctorfilter/domain/repositories/i_purchase_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class _FakeStore implements InAppPurchase {
  final events = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => events.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PurchaseDetails _restored(String product) => PurchaseDetails(
  productID: product,
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: '',
    source: 'test',
  ),
  transactionDate: null,
  status: PurchaseStatus.restored,
);

void main() {
  test('unrelated events do not settle Lifetime Pro restore', () async {
    final store = _FakeStore();
    final repo = StorePurchaseRepository(store: store);
    addTearDown(() async {
      await repo.dispose();
      await store.events.close();
    });

    var completed = false;
    final restore = repo.restorePurchases().then((result) {
      completed = true;
      return result;
    });
    await Future<void>.delayed(Duration.zero);
    store.events.add([_restored('testsubscription')]);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    store.events.add([_restored(ProProduct.lifetimeId)]);
    expect((await restore).dataOrNull, PurchaseOutcome.restored);
  });
}
