import 'dart:async';

import 'package:flutter/services.dart';
import 'package:doctorfilter/core/errors/failure.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/pro_status.dart';
import 'package:doctorfilter/domain/repositories/i_purchase_repository.dart';

/// Pro through the Microsoft Store, via `Windows.Services.Store`.
///
/// Matched on the add-on's Product ID ([ProProduct.lifetimeId]) — the name the
/// developer gives the add-on in Partner Center — rather than the Store ID
/// Microsoft assigns. That keeps one product name across all three stores and
/// means nothing here depends on an identifier that only exists after
/// registration.
///
/// Legacy ids are not queried: 1.x was never sold on Windows, so there is no
/// earlier Windows purchase to honour.
class MicrosoftStorePurchaseRepository implements IPurchaseRepository {
  MicrosoftStorePurchaseRepository({MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel('com.crazypenguin.doctorfilter/store');

  final MethodChannel _channel;
  final StreamController<ProStatus> _entitlement =
      StreamController<ProStatus>.broadcast();

  Map<String, Object?> get _arguments => {'productId': ProProduct.lifetimeId};

  /// True in the packaged Store build. An unpackaged debug build has no Store
  /// identity; its calls fail, and the paywall reports the store as
  /// unavailable rather than hiding Pro from a developer testing it.
  @override
  bool get isAvailable => true;

  @override
  Future<Result<ProOffer>> loadOffer() async {
    try {
      final offer = await _channel.invokeMapMethod<String, Object?>(
        'loadOffer',
        _arguments,
      );
      if (offer == null) {
        return const Result.failure(PlatformFailure('store_unavailable'));
      }
      return Result.success(
        ProOffer(
          id: offer['id'] as String? ?? ProProduct.lifetimeId,
          title: offer['title'] as String? ?? '',
          description: offer['description'] as String? ?? '',
          formattedPrice: offer['price'] as String? ?? '',
        ),
      );
    } on PlatformException catch (error) {
      return Result.failure(PlatformFailure(error.code));
    } on MissingPluginException {
      return const Result.failure(PlatformFailure('store_unavailable'));
    }
  }

  @override
  Future<Result<PurchaseOutcome>> buyLifetime() async {
    try {
      final name = await _channel.invokeMethod<String>('buy', _arguments);
      final outcome = _outcomeFrom(name);

      // The Store reports ownership synchronously with the purchase result, so
      // entitlement can be announced here rather than waiting for a listener.
      if (outcome == PurchaseOutcome.purchased ||
          outcome == PurchaseOutcome.restored) {
        _entitlement.add(ProStatus.lifetime());
      }
      return Result.success(outcome);
    } on PlatformException {
      return const Result.success(PurchaseOutcome.unavailable);
    } on MissingPluginException {
      return const Result.success(PurchaseOutcome.unavailable);
    }
  }

  @override
  Future<Result<PurchaseOutcome>> restorePurchases() async {
    try {
      final owned =
          await _channel.invokeMethod<bool>('isOwned', _arguments) ?? false;
      if (!owned) return const Result.success(PurchaseOutcome.nothingToRestore);

      _entitlement.add(ProStatus.lifetime());
      return const Result.success(PurchaseOutcome.restored);
    } on PlatformException {
      return const Result.success(PurchaseOutcome.unavailable);
    } on MissingPluginException {
      return const Result.success(PurchaseOutcome.unavailable);
    }
  }

  @override
  Stream<ProStatus> get entitlementUpdates => _entitlement.stream;

  @override
  Future<void> dispose() => _entitlement.close();

  /// Names match those sent by `store_purchases.cpp`. Anything unrecognised is
  /// treated as the store being unavailable — never as a purchase.
  static PurchaseOutcome _outcomeFrom(String? name) => switch (name) {
        'purchased' => PurchaseOutcome.purchased,
        'restored' => PurchaseOutcome.restored,
        'cancelled' => PurchaseOutcome.cancelled,
        _ => PurchaseOutcome.unavailable,
      };
}
