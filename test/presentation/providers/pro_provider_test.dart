import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/pro_status.dart';
import 'package:doctorfilter/domain/repositories/i_purchase_repository.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';
import 'package:doctorfilter/presentation/providers/pro_provider.dart';

class _FakePurchaseRepository implements IPurchaseRepository {
  _FakePurchaseRepository({this.isAvailable = true});

  @override
  final bool isAvailable;

  int restoreCalls = 0;
  PurchaseOutcome restoreResult = PurchaseOutcome.nothingToRestore;

  final _entitlement = StreamController<ProStatus>.broadcast();

  void emit(ProStatus status) => _entitlement.add(status);

  @override
  Stream<ProStatus> get entitlementUpdates => _entitlement.stream;

  @override
  Future<Result<ProOffer>> loadOffer() async => const Result.success(
        ProOffer(
          id: ProProduct.lifetimeId,
          title: 'Pro',
          description: '',
          formattedPrice: '₺149,99',
        ),
      );

  @override
  Future<Result<PurchaseOutcome>> buyLifetime() async =>
      const Result.success(PurchaseOutcome.purchased);

  @override
  Future<Result<PurchaseOutcome>> restorePurchases() async {
    restoreCalls++;
    return Result.success(restoreResult);
  }

  @override
  Future<void> dispose() async => _entitlement.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePurchaseRepository store;

  Future<ProviderContainer> container({
    Map<String, Object> prefs = const {},
    bool storeAvailable = true,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    store = _FakePurchaseRepository(isAvailable: storeAvailable);
    return ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
      purchaseRepositoryProvider.overrideWithValue(store),
    ]);
  }

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('a new user is free', () async {
    final ref = await container();
    expect(ref.read(isProProvider), isFalse);
  });

  test('a stored lifetime purchase is honoured before the store answers', () async {
    // Matters on every cold start: a Pro user must not see a flash of ads while
    // the store is contacted.
    final ref = await container(prefs: {'flutter.df_pro_lifetime': true});
    expect(ref.read(isProProvider), isTrue);
  });

  test('entitlement reported by the store is adopted and persisted', () async {
    final ref = await container();
    ref.read(proStatusProvider);
    await settle();

    store.emit(ProStatus.lifetime());
    await settle();

    expect(ref.read(isProProvider), isTrue);
  });

  test('a silent restore runs at startup so reinstalls keep Pro', () async {
    final ref = await container();
    ref.read(proStatusProvider);
    await settle();

    expect(store.restoreCalls, 1);
  });

  test('no silent restore where there is no store to ask', () async {
    final ref = await container(storeAvailable: false);
    ref.read(proStatusProvider);
    await settle();

    expect(store.restoreCalls, 0);
  });

  test('a rewarded pass grants Pro temporarily', () async {
    final ref = await container();
    await ref.read(proStatusProvider.notifier)
        .grantTemporaryPass(const Duration(hours: 24));

    expect(ref.read(isProProvider), isTrue);
    expect(ref.read(proStatusProvider).isLifetime, isFalse);
  });

  test('a pass never downgrades a lifetime purchase', () async {
    final ref = await container(prefs: {'flutter.df_pro_lifetime': true});
    await ref.read(proStatusProvider.notifier)
        .grantTemporaryPass(const Duration(hours: 1));

    expect(ref.read(proStatusProvider).isLifetime, isTrue);
  });

  test('an expired pass leaves the user free again', () async {
    final expired = DateTime.now()
        .subtract(const Duration(hours: 1))
        .millisecondsSinceEpoch;
    final ref = await container(prefs: {'flutter.df_pro_pass_expiry': expired});

    expect(ref.read(isProProvider), isFalse);
  });
}
