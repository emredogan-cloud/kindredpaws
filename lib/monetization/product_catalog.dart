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
  });

  /// Store product id (must match App Store Connect / Play Console).
  final String sku;
  final String displayName;
  final double priceUsd;
  final MonetizationStream stream;

  /// What this product grants — must be ⊆ [kAllowedMonetizationGrants].
  final List<Grant> grants;

  bool get isSubscription => stream == MonetizationStream.subscription;
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

/// The full catalogue (Rescue Bundles + their disclosed donation slice land in
/// P3-5b, against the impact ledger).
const List<Product> kProductCatalog = [
  kForeverFriendsMonthly,
  kForeverFriendsAnnual,
  ...kHeartstoneBundles,
];

/// True iff [p] confers only allowed (cosmetic/QoL) grants — the ethical wall.
bool grantsOnlyCosmeticOrQoL(Product p) =>
    p.grants.every(kAllowedMonetizationGrants.contains);
