import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/domain/entities/pro_status.dart';

/// What the app sells.
///
/// One product, bought once, owned forever. No subscriptions — stated here so
/// that adding one later is a visible decision rather than a quiet drift.
abstract final class ProProduct {
  /// The store product id. Identical on Google Play and the App Store so a user
  /// with both devices is buying the same thing under the same name.
  static const String lifetimeId = 'doctorfilter_pro_lifetime';

  /// Ids the 1.x release sold Pro under.
  ///
  /// Queried alongside the current one during a restore: someone who paid years
  /// ago must not be asked to pay again because the id was renamed. Costs one
  /// extra lookup and buys back a user who would otherwise leave a one-star
  /// review saying the update stole what they bought.
  static const List<String> legacyIds = ['doctorfilter_proversion'];

  static Set<String> get allIds => {lifetimeId, ...legacyIds};
}

/// A product as the store describes it.
///
/// Price is a preformatted string, never a number: the store already knows the
/// user's currency, their tax, and how their locale writes it. Reassembling that
/// in the app gets it wrong somewhere.
final class ProOffer {
  const ProOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.formattedPrice,
  });

  final String id;
  final String title;
  final String description;
  final String formattedPrice;
}

/// Why a purchase attempt did not result in an entitlement.
enum PurchaseOutcome {
  /// Bought, and Pro is now active.
  purchased,

  /// The user already owned it; entitlement restored rather than charged again.
  restored,

  /// The user backed out. Not an error and must not be shown as one.
  cancelled,

  /// Waiting on something outside the app — a parent's approval, a slow
  /// payment method. The user is not entitled yet and has not failed either.
  pending,

  /// Nothing to restore.
  nothingToRestore,

  /// The store itself is unavailable or refused.
  unavailable,
}

/// Buying and restoring Pro.
///
/// Platform-agnostic on purpose: the implementations wrap Google Play, the App
/// Store and the Microsoft Store, and every one of them uses the account and
/// payment method the user already has on that device. The app never sees a card
/// number, never shows a payment form, and never sends the user to a browser —
/// a third-party checkout would both lose most buyers and breach store policy
/// for digital goods.
abstract interface class IPurchaseRepository {
  /// Whether this platform has a store at all. False on desktop Linux, where
  /// the purchase UI is hidden rather than shown broken.
  bool get isAvailable;

  /// Fetches the product as the store describes it, price included.
  Future<Result<ProOffer>> loadOffer();

  /// Starts the platform's own purchase flow.
  ///
  /// Completes when the flow ends, but entitlement arrives through
  /// [entitlementUpdates] — a purchase can also complete later, or on another
  /// device, and the caller must not assume this future is the only signal.
  Future<Result<PurchaseOutcome>> buyLifetime();

  /// Re-applies a purchase the user already made.
  ///
  /// Required by the App Store, and the only way a user who reinstalled or
  /// changed device gets their Pro back.
  Future<Result<PurchaseOutcome>> restorePurchases();

  /// Entitlement as the store reports it, including purchases completed while
  /// the app was closed.
  Stream<ProStatus> get entitlementUpdates;

  /// Releases store listeners.
  Future<void> dispose();
}
