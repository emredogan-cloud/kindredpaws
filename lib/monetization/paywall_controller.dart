/// Paywall coordinator (P5-4) — the brain behind the monetization UX. It owns
/// the **purchase funnel diagnostics** (every `paywallStep`: shown / dismissed /
/// purchase + restore start→outcome) and the **pricing experiment** (the
/// value-*framing* A/B — the price is LOCKED by the catalogue, we only A/B how
/// the value is presented, never the amount charged, which keeps it
/// non-predatory + child-safe). The widget ([PaywallSheet]) stays dumb: it asks
/// this for copy + calls [buy] / [restore], and the funnel telemetry + ethical
/// wall live here, testably. Authority: brief §5/§9, GAMEPLAY_BIBLE §9, D-047.
library;

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/experiments.dart';
import '../services/live_ops.dart';
import '../services/observability.dart';
import 'billing_service.dart';
import 'entitlements.dart';
import 'monetization_controller.dart';
import 'product_catalog.dart';

/// A step in the monetization funnel — the `paywallStep.step` value. The funnel
/// is the **purchase diagnostics**: start→outcome for both purchase + restore,
/// so support can see exactly where a player dropped or a purchase failed, and
/// analytics can compute sub-conversion (G4/G6) joined to `experimentExposure`.
enum PaywallStep {
  shown('shown'),
  dismissed('dismissed'),
  purchaseStart('purchase_start'),
  purchaseSuccess('purchase_success'),
  purchaseCancelled('purchase_cancelled'),
  purchaseFailed('purchase_failed'),
  restoreStart('restore_start'),
  restoreSuccess('restore_success'),
  restoreEmpty('restore_empty');

  const PaywallStep(this.key);

  /// The stable `step` string shipped on the event (snake_case, analytics-safe).
  final String key;
}

/// The value-*framing* variant for the paywall. The subscription **price is
/// LOCKED** ($5.99/mo · $39.99/yr) — this only varies the headline + which plan
/// leads, never the charged amount (an honest pricing experiment, not a
/// predatory price test). Resolved from [Experiment.paywallCopy].
class PaywallCopy {
  const PaywallCopy({
    required this.headline,
    required this.subline,
    required this.annualFirst,
  });

  final String headline;
  final String subline;

  /// Whether to surface the annual (best-value) plan before the monthly one.
  final bool annualFirst;
}

const Map<ExperimentVariant, PaywallCopy> _copy = {
  // Control — the cozy-delight framing (the baseline + emergency-rollback copy).
  ExperimentVariant.control: PaywallCopy(
    headline: 'Become a Forever Friend',
    subline: 'A little monthly delight for you and your companion. 💛',
    annualFirst: false,
  ),
  // Treatment A — value-forward (lead with the annual best-value plan).
  ExperimentVariant.treatment: PaywallCopy(
    headline: 'Forever Friends — best value yearly',
    subline: 'All the cozy perks, for less per month on the annual plan.',
    annualFirst: true,
  ),
  // Treatment B — impact-forward (the giving framing, for treatments:2 runs).
  ExperimentVariant.treatmentB: PaywallCopy(
    headline: 'Forever Friends, real friends',
    subline: 'Cozy perks for you — and a kinder home for rescues. 💛',
    annualFirst: true,
  ),
};

/// Coordinates the paywall: experiment-driven copy, the purchase/restore funnel
/// telemetry, and the (cosmetic/QoL-only) catalogue. Holds NO mutable UI state —
/// entitlement changes flow through [MonetizationController] (a ChangeNotifier
/// the sheet listens to).
class PaywallController {
  PaywallController({
    required this.monetization,
    required this.experiments,
    required this.observability,
    required this.auth,
  });

  final MonetizationController monetization;
  final Experiments experiments;
  final ObservabilityFacade observability;
  final AuthService auth;

  /// The stable, anonymous bucketing unit (the guest/account id) — never PII.
  String get _unitId => auth.currentUserId ?? 'anon';

  Entitlements get entitlements => monetization.entitlements;

  /// The single subscription tier (LOCKED) + the cosmetic-currency bundles.
  Product get subscriptionMonthly => kForeverFriendsMonthly;
  Product get subscriptionAnnual => kForeverFriendsAnnual;
  List<Product> get heartstoneBundles => kHeartstoneBundles;
  List<Product> get rescueBundles => kRescueBundles;

  /// Resolves the paywall value-framing variant **and** logs the exposure (once
  /// per user) so conversion can be attributed. Call once when the sheet opens.
  PaywallCopy resolveCopy() {
    final variant = experiments.expose(Experiment.paywallCopy, unitId: _unitId);
    return _copy[variant] ?? _copy[ExperimentVariant.control]!;
  }

  void _step(PaywallStep step, String surface) {
    observability.event(AnalyticsEvent.paywallStep, {
      'step': step.key,
      'surface': surface,
    });
  }

  /// The paywall became visible (funnel top). [surface] is where it was opened
  /// from (e.g. `home`, `kibble`) — the only other param the spec allows.
  void recordShown(String surface) => _step(PaywallStep.shown, surface);

  /// The player dismissed the paywall without converting (funnel drop).
  void recordDismissed(String surface) => _step(PaywallStep.dismissed, surface);

  /// Runs a purchase through the funnel: emits `purchase_start`, then exactly
  /// one of `purchase_success` / `purchase_cancelled` / `purchase_failed`. The
  /// revenue event (`monetizationEvent`) is emitted by [MonetizationController]
  /// on success — this only adds the funnel/diagnostic step. Never throws.
  Future<PurchaseResult> buy(Product product, {required String surface}) async {
    _step(PaywallStep.purchaseStart, surface);
    final result = await monetization.purchase(product);
    _step(
      result.success
          ? PaywallStep.purchaseSuccess
          : result.cancelled
          ? PaywallStep.purchaseCancelled
          : PaywallStep.purchaseFailed,
      surface,
    );
    return result;
  }

  /// Restores prior purchases through the funnel: emits `restore_start`, then
  /// `restore_success` if an entitlement is now active, else `restore_empty`.
  /// Returns whether the player ends up entitled. Never throws.
  Future<bool> restore({required String surface}) async {
    _step(PaywallStep.restoreStart, surface);
    await monetization.restore();
    final entitled = monetization.entitlements.foreverFriends;
    _step(
      entitled ? PaywallStep.restoreSuccess : PaywallStep.restoreEmpty,
      surface,
    );
    return entitled;
  }
}
