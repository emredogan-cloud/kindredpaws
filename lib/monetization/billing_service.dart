/// Billing seam (P3-5a). Abstracts the store/RevenueCat purchase flow so the
/// game + analytics stay decoupled from the native SDK — the same gated-seam
/// pattern as the backend / share / renderer seams.
///
/// The default [NoopBillingService] simulates purchases in memory (no native
/// dependency → CI/tests/dev stay offline + deterministic, and `purchases_flutter`
/// is NOT a dependency yet). The real `RevenueCatBillingService` is a
/// post-provisioning swap once store products + SDK keys exist
/// (REQUIRED_ENVIRONMENTS.md §5). Receipt validation is the SDK's job, server-side.
library;

import 'entitlements.dart';
import 'product_catalog.dart';

/// The outcome of a purchase attempt. Implementations must never throw into the
/// caller — return a failed/cancelled result instead.
class PurchaseResult {
  const PurchaseResult({
    required this.success,
    this.sku,
    this.cancelled = false,
  });

  final bool success;
  final String? sku;

  /// True when the user dismissed the purchase sheet (not an error).
  final bool cancelled;

  static const PurchaseResult cancelledResult = PurchaseResult(
    success: false,
    cancelled: true,
  );
}

abstract interface class BillingService {
  /// The player's current entitlements (from the store/RevenueCat, or local
  /// in the Noop impl).
  Future<Entitlements> entitlements();

  /// Attempts to purchase [product]. Returns the result; on success the
  /// entitlements reflect it on the next [entitlements] call.
  Future<PurchaseResult> purchase(Product product);

  /// Restores prior purchases (store-side), returning the resolved entitlements.
  Future<Entitlements> restore();
}

/// In-memory billing for CI/dev: a subscription purchase flips Forever Friends
/// on; one-time bundles succeed without changing the subscription. Deterministic
/// and offline. The real store/RevenueCat impl drops in via provisioning.
class NoopBillingService implements BillingService {
  Entitlements _entitlements = Entitlements.none;

  @override
  Future<Entitlements> entitlements() async => _entitlements;

  @override
  Future<PurchaseResult> purchase(Product product) async {
    if (product.isSubscription) {
      _entitlements = _entitlements.copyWith(foreverFriends: true);
    }
    return PurchaseResult(success: true, sku: product.sku);
  }

  @override
  Future<Entitlements> restore() async => _entitlements;
}
