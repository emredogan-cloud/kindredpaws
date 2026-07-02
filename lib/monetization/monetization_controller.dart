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
import '../services/backend_service.dart';
import '../services/observability.dart';
import 'billing_service.dart';
import 'entitlements.dart';
import 'product_catalog.dart';

class MonetizationController extends ChangeNotifier {
  MonetizationController({
    required this.billing,
    required this.observability,
    required this.backend,
  });

  final BillingService billing;
  final ObservabilityFacade observability;

  /// The authoritative store — the append-only impact ledger lives here.
  final BackendService backend;

  /// The append-only stream name for the Impact Pool ledger (§7).
  static const String impactLedgerStream = 'impact_ledger';

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

  /// Mints Compassion Coins to the Impact Pool ledger (§7, §9). This is the seam
  /// the production server-postback / rewarded-ad reward calls — and the
  /// **anti-fraud gate**: only a `validated` mint (signed S2S ad postback, or a
  /// server-validated receipt) actually appends to the ledger + returns coins;
  /// an unvalidated request is rejected (records a `validated:false` event for
  /// fraud monitoring, mints nothing). Always emits `compassionCoinMint`
  /// {source, amount, validated} (PII-free). Free players still mint via `ad`
  /// — impact never requires payment (hard ethical wall).
  ///
  /// Returns the coins actually minted (0 if rejected). The caller credits the
  /// player's wallet display; the ledger is the source of truth for real giving.
  Future<int> mintCompassionCoins({
    required String source,
    required int amount,
    required bool validated,
  }) async {
    if (validated && amount > 0) {
      await backend.append(impactLedgerStream, {
        'source': source,
        'amount': amount,
        'validated': true,
      });
      observability.event(AnalyticsEvent.compassionCoinMint, {
        'source': source,
        'amount': amount,
        'validated': true,
      });
      return amount;
    }
    // Rejected (untrusted/empty): record the attempt, mint nothing.
    observability.event(AnalyticsEvent.compassionCoinMint, {
      'source': source,
      'amount': 0,
      'validated': false,
    });
    return 0;
  }
}
