/// Monetization product catalog (P3-5a). The LOCKED single subscription tier +
/// premium cosmetic-currency bundles (brief §5, GAMEPLAY_AND_PROGRESSION_BIBLE
/// §9, ADR-007/RevenueCat). SKUs mirror the App Store / Play Console products a
/// founder provisions (REQUIRED_ENVIRONMENTS.md §5).
///
/// **Ethical wall, enforced by the type system (§18, D-047):** [Grant] can only
/// express **cosmetic / quality-of-life** benefits — there is deliberately NO
/// grant that touches the Bond, Care Meters, life stage, memory, or the
/// no-death floor. Pay-to-win is therefore *unexpressible* here, and a unit test
/// pins that every catalogued product's grants stay within
/// [kAllowedMonetizationGrants].
library;

/// Where a monetization event originates (the `monetizationEvent.stream` param).
enum MonetizationStream { rewardedAd, iap, subscription, bundle }

/// What a purchase confers — cosmetic / QoL ONLY (never gameplay advantage).
enum Grant {
  /// Quality-of-life: a calmer, ad-light experience (never gates content).
  removeInterstitials,

  /// A small daily Kibble top-up (soft delight currency; buys only cosmetics).
  dailyKibbleBonus,

  /// Monthly premium cosmetic currency.
  monthlyHeartstones,

  /// Monthly impact currency (representation of pooled real giving — not power).
  monthlyCompassionCoins,

  /// A rotating exclusive cosmetic piece.
  cosmeticDrip,

  /// A one-time premium cosmetic-currency grant (Heartstone bundles).
  heartstones,
}

/// The ONLY grants monetization may confer. Adding a gameplay-advantage grant
/// would require deliberately enrolling it here — surfacing the ethical-wall
/// violation in review. Pinned by `monetization_test.dart`.
const Set<Grant> kAllowedMonetizationGrants = {
  Grant.removeInterstitials,
  Grant.dailyKibbleBonus,
  Grant.monthlyHeartstones,
  Grant.monthlyCompassionCoins,
  Grant.cosmeticDrip,
  Grant.heartstones,
};

/// One purchasable product.
class Product {
  const Product({
    required this.sku,
    required this.displayName,
    required this.priceUsd,
    required this.stream,
    required this.grants,
    this.donationSliceUsd = 0.0,
  });

  /// Store product id (must match App Store Connect / Play Console).
  final String sku;
  final String displayName;
  final double priceUsd;
  final MonetizationStream stream;

  /// What this product grants — must be ⊆ [kAllowedMonetizationGrants].
  final List<Grant> grants;

  /// For Rescue Bundles: the **disclosed** portion of [priceUsd] routed to the
  /// impact pool (shown pre-purchase + on the receipt). 0 for other products.
  /// A Rescue Bundle is a *commercial* cosmetic purchase with a transparent
  /// giving split — NOT a charitable-donation IAP (brief §9, D-047).
  final double donationSliceUsd;

  bool get isSubscription => stream == MonetizationStream.subscription;
  bool get isRescueBundle =>
      stream == MonetizationStream.bundle && donationSliceUsd > 0;
}

/// Forever Friends — the single subscription tier (LOCKED: $5.99/mo, $39.99/yr).
/// Grants are cosmetic/QoL only; cancelling never harms the pet (§18).
const Product kForeverFriendsMonthly = Product(
  sku: 'forever_friends_monthly',
  displayName: 'Forever Friends (Monthly)',
  priceUsd: 5.99,
  stream: MonetizationStream.subscription,
  grants: [
    Grant.removeInterstitials,
    Grant.dailyKibbleBonus,
    Grant.monthlyHeartstones,
    Grant.monthlyCompassionCoins,
    Grant.cosmeticDrip,
  ],
);

const Product kForeverFriendsAnnual = Product(
  sku: 'forever_friends_annual',
  displayName: 'Forever Friends (Annual)',
  priceUsd: 39.99,
  stream: MonetizationStream.subscription,
  grants: [
    Grant.removeInterstitials,
    Grant.dailyKibbleBonus,
    Grant.monthlyHeartstones,
    Grant.monthlyCompassionCoins,
    Grant.cosmeticDrip,
  ],
);

/// Heartstone bundles — one-time premium **cosmetic** currency (no power).
///
/// **LAUNCH-EXCLUDED (KP-007).** Nothing in the game accepts Heartstones yet
/// (`Wallet` has no `spendHeartstones`; no item carries a Heartstone price),
/// and Apple 3.1.1 treats a purchasable currency with no redemption as a
/// broken purchase. These SKUs stay defined for the Heartstone storefront
/// (KP-037) but are NOT in [kProductCatalog] until that sink ships.
const List<Product> kHeartstoneBundles = [
  Product(
    sku: 'heartstone_100',
    displayName: '100 Heartstones',
    priceUsd: 1.99,
    stream: MonetizationStream.iap,
    grants: [Grant.heartstones],
  ),
  Product(
    sku: 'heartstone_280',
    displayName: '280 Heartstones',
    priceUsd: 4.99,
    stream: MonetizationStream.iap,
    grants: [Grant.heartstones],
  ),
  Product(
    sku: 'heartstone_600',
    displayName: '600 Heartstones',
    priceUsd: 9.99,
    stream: MonetizationStream.iap,
    grants: [Grant.heartstones],
  ),
  Product(
    sku: 'heartstone_1300',
    displayName: '1300 Heartstones',
    priceUsd: 19.99,
    stream: MonetizationStream.iap,
    grants: [Grant.heartstones],
  ),
];

/// Rescue Bundles — commercial cosmetic purchases with a **disclosed** donation
/// slice (≈70% to the impact pool). NOT donation IAPs; the cosmetic is the
/// product, the giving split is transparent (brief §9, D-047). The Coins they
/// represent are minted server-side after receipt validation (see
/// `MonetizationController.mintCompassionCoins`), never client-self-minted.
///
/// **LAUNCH-EXCLUDED (KP-006).** The Impact Pledge is a v0.1 draft: no signed
/// intermediary, no partner shelters, no live ledger — so the giving split
/// these bundles advertise cannot yet be performed (Apple 3.2.1 + consumer
/// protection). They stay defined for the founder's donation
/// operationalization (FOUNDER_ACTIONS_TODO.md F-6) and rejoin
/// [kProductCatalog] only when every claim is literally true.
const List<Product> kRescueBundles = [
  Product(
    sku: 'rescue_bundle_meal',
    displayName: 'Rescue Meal Bundle',
    priceUsd: 4.99,
    stream: MonetizationStream.bundle,
    grants: [Grant.cosmeticDrip],
    donationSliceUsd: 3.49, // ~70% disclosed
  ),
  Product(
    sku: 'rescue_bundle_shelter',
    displayName: 'Rescue Shelter Bundle',
    priceUsd: 9.99,
    stream: MonetizationStream.bundle,
    grants: [Grant.cosmeticDrip],
    donationSliceUsd: 6.99, // ~70% disclosed
  ),
];

/// The full **launch** catalogue: what the paywall offers and what the store
/// consoles must list. Heartstone bundles rejoin via KP-037 (spend sink);
/// Rescue Bundles rejoin when the founder operationalizes donations (F-6).
const List<Product> kProductCatalog = [
  kForeverFriendsMonthly,
  kForeverFriendsAnnual,
];

/// True iff [p] confers only allowed (cosmetic/QoL) grants — the ethical wall.
bool grantsOnlyCosmeticOrQoL(Product p) =>
    p.grants.every(kAllowedMonetizationGrants.contains);
