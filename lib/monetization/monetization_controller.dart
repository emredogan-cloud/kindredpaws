/// Monetization subsystem entry point (P3-5a). Orchestrates the [BillingService]
/// seam + observability: it owns the current [Entitlements] and emits the
/// `monetizationEvent` telemetry (P3-1 taxonomy; G4/G6 ARPDAU + conversion KPIs)
/// when a purchase resolves — the single, PII-free emit point for monetization.
///
/// It never confers gameplay advantage: entitlements are cosmetic/QoL only
/// (see [Entitlements]) and the catalogue is pinned to [kAllowedMonetizationGrants].
library;

import 'package:flutter/foundation.dart';

import '../services/analytics_service.dart';
import '../services/observability.dart';
import 'billing_service.dart';
import 'entitlements.dart';
import 'product_catalog.dart';

class MonetizationController extends ChangeNotifier {
  MonetizationController({required this.billing, required this.observability});

  final BillingService billing;
  final ObservabilityFacade observability;

  Entitlements _entitlements = Entitlements.none;
  Entitlements get entitlements => _entitlements;

  /// Loads current entitlements (e.g. on launch).
  Future<void> load() async {
    _entitlements = await billing.entitlements();
    notifyListeners();
  }

  /// Attempts to purchase [product]. On success, refreshes entitlements and
  /// emits `monetizationEvent {stream, sku, value}`. A cancelled/failed attempt
  /// emits nothing.
  Future<PurchaseResult> purchase(Product product) async {
    final result = await billing.purchase(product);
    if (result.success) {
      _entitlements = await billing.entitlements();
      observability.event(AnalyticsEvent.monetizationEvent, {
        'stream': product.stream.name,
        'sku': product.sku,
        'value': product.priceUsd,
      });
      notifyListeners();
    }
    return result;
  }

  /// Restores prior purchases (store-side) and refreshes entitlements.
  Future<void> restore() async {
    _entitlements = await billing.restore();
    notifyListeners();
  }
}
