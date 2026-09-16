import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/pro_status.dart';
import 'package:doctorfilter/domain/repositories/i_purchase_repository.dart';
import 'package:doctorfilter/data/repositories/microsoft_store_purchase_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.crazypenguin.doctorfilter/store');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) async => handler(call));
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('always asks for the shared product id', () async {
    final seen = <Object?>[];
    answer((call) {
      seen.add((call.arguments as Map)['productId']);
      return call.method == 'isOwned' ? false : 'cancelled';
    });
    final repository = MicrosoftStorePurchaseRepository();

    await repository.buyLifetime();
    await repository.restorePurchases();

    expect(seen, [ProProduct.lifetimeId, ProProduct.lifetimeId]);
  });

  test('a completed purchase grants lifetime Pro', () async {
    answer((_) => 'purchased');
    final repository = MicrosoftStorePurchaseRepository();
    final entitlement = repository.entitlementUpdates.first;

    final result = await repository.buyLifetime();

    expect((result as Success<PurchaseOutcome>).data, PurchaseOutcome.purchased);
    expect((await entitlement).isLifetime, isTrue);
  });

  test('backing out is a cancellation, not an error, and grants nothing', () async {
    answer((_) => 'cancelled');
    final repository = MicrosoftStorePurchaseRepository();
    final granted = <ProStatus>[];
    repository.entitlementUpdates.listen(granted.add);

    final result = await repository.buyLifetime();
    await Future<void>.delayed(Duration.zero);

    expect((result as Success<PurchaseOutcome>).data, PurchaseOutcome.cancelled);
    expect(granted, isEmpty);
  });

  test('an unrecognised reply is never mistaken for a purchase', () async {
    answer((_) => 'something_new');
    final result = await MicrosoftStorePurchaseRepository().buyLifetime();

    expect((result as Success<PurchaseOutcome>).data, PurchaseOutcome.unavailable);
  });

  test('restore reports nothing when the add-on is not owned', () async {
    answer((_) => false);
    final result = await MicrosoftStorePurchaseRepository().restorePurchases();

    expect(
      (result as Success<PurchaseOutcome>).data,
      PurchaseOutcome.nothingToRestore,
    );
  });

  test('an unpackaged build reports the store unavailable instead of throwing', () async {
    answer((_) => throw PlatformException(code: 'store_unavailable'));
    final repository = MicrosoftStorePurchaseRepository();

    final buy = await repository.buyLifetime();
    final offer = await repository.loadOffer();

    expect((buy as Success<PurchaseOutcome>).data, PurchaseOutcome.unavailable);
    expect(offer, isA<FailureResult<ProOffer>>());
  });
}
