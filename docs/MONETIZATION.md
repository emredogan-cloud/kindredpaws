# MONETIZATION.md — KindredPaws (P3-5)

How KindredPaws makes money **without ever betraying the player or the pet**.
Authority: `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md §5/§9`,
`GAMEPLAY_AND_PROGRESSION_BIBLE.md §9/§10/§18`, `GAME_DECISION_LOG.md` D-033/D-047,
ADR-007 (RevenueCat). These are LOCKED decisions — do not change without a brief update.

## 1. The model (locked)

- **One subscription tier — Forever Friends:** **$5.99/mo** or **$39.99/yr**. It is
  the financial keystone that funds LLM/infra OPEX.
- It grants **cosmetic + quality-of-life only**: an ad-light experience
  (`removeInterstitials`), a daily Kibble top-up, a monthly Heartstones +
  Compassion Coins grant, and a rotating cosmetic. (Live Heartmind chat for
  verified adults is a Deferred P4 add-on, not part of the MVP grant.)
- **Heartstone bundles** ($1.99 → $19.99) are one-time **cosmetic** currency.
- **Compassion Coins** represent a slice of *net* revenue routed to vetted
  nonprofits via a giving intermediary — **not** a charitable-donation IAP, and
  free players still mint Coins via ads. (The mint flow + Rescue Bundles are
  P3-5b, against the append-only impact ledger.)

## 2. The hard ethical walls (enforced in code, not just docs)

1. **Never pay-to-win.** Entitlements touch only cosmetics/QoL — never the Bond,
   Care Meters, life stage, memory, or the no-death floor. This is enforced by
   the type system: `Grant` (`product_catalog.dart`) has **no value** that
   confers gameplay advantage, and `monetization_test.dart` pins that every
   catalogued product's grants stay within `kAllowedMonetizationGrants`. Adding a
   power grant would require deliberately enrolling it — surfacing it in review.
2. **The pet is unconditionally fine.** Cancelling Forever Friends never harms
   the pet; subscription status never gates the pet's wellbeing (§18).
3. **Never tie wellbeing to donations.** Compassion Coins / Rescue Bundles never
   gate the pet's mood/health; impact never requires payment.
4. **No guilt-framing, no FOMO, no gacha/loot boxes.** Ads are a rewarded
   benefit, not a punishment; cosmetics are direct-purchase, never randomized.

## 3. Architecture (P3-5a)

- **`product_catalog.dart`** — the locked SKUs + the `Grant` type (cosmetic/QoL
  only) + `grantsOnlyCosmeticOrQoL`.
- **`entitlements.dart`** — `Entitlements` (just `foreverFriends` → ad-light +
  daily bonus). Tiny by design.
- **`billing_service.dart`** — the `BillingService` seam. Default
  `NoopBillingService` simulates purchases in memory (offline/deterministic; no
  `purchases_flutter` dependency). The real **RevenueCat** impl is a
  post-provisioning swap — same gated-seam pattern as backend/share/renderer.
- **`monetization_controller.dart`** — the subsystem entry point: owns
  `Entitlements`, runs purchase/restore through the seam, and emits
  `monetizationEvent {stream, sku, value}` (the single PII-free emit point) on a
  successful purchase. Feeds the G4/G6 ARPDAU + conversion KPIs.

## 4. Provisioning (founder/store — not buildable in CI)

Per `REQUIRED_ENVIRONMENTS.md §5`: create a RevenueCat project, configure the
store products (`forever_friends_monthly/annual`, `heartstone_*`) in App Store
Connect / Play Console, obtain `REVENUECAT_PUBLIC_SDK_KEY_IOS/_ANDROID`, then add
`purchases_flutter` + a `RevenueCatBillingService` and register it in place of
the Noop. Receipt validation is the SDK's (server-side) job. Until then the Noop
seam keeps the app fully functional offline.

## 5. Impact / Compassion Coins (P3-5b)

- **`MonetizationController.mintCompassionCoins({source, amount, validated})`** is
  the mint seam + **anti-fraud gate**: only a `validated` mint (a signed S2S
  rewarded-ad postback, or a server-validated receipt) appends to the append-only
  `impact_ledger` stream and returns coins; an unvalidated request is rejected
  (records a `validated:false` `compassionCoinMint` for fraud monitoring, mints
  nothing). In production this is driven server-side; the client never self-mints.
- **Free players mint via `ad`** — impact never requires payment (hard ethical wall).
- **Rescue Bundles** (`kRescueBundles`) are commercial cosmetic purchases with a
  **disclosed** `donationSliceUsd` (≈70%, shown pre-purchase + on the receipt) —
  **not** a charitable-donation IAP (D-047). Buying one emits `monetizationEvent`;
  the represented Coins are minted server-side after receipt validation.
- The exact USD→Coin rate and the net-revenue % split are illustrative and **to
  finalize before G4** (brief §9); the ledger is the source of truth for real
  giving, and the player's wallet `compassionCoins` is a display credited from it.

## Activation (P4-5) — RevenueCat + premium gating

The billing **seam** + the orchestration are fully wired offline; activation is a
founder/credentialed step (REQUIRED_ENVIRONMENTS.md §5).

- **`BillingService` seam** — `NoopBillingService` (offline, simulates purchases)
  is the default; `RevenueCatBillingService` is selected by
  `--dart-define=KP_BILLING=revenuecat`. The RevenueCat impl is an **inert gated
  seam** (no `purchases_flutter` dependency yet) that degrades gracefully —
  `isProvisioned=false`, no entitlements, every purchase reports unavailable — so
  selecting it without the SDK never breaks the game. Its docstring lists the
  exact `Purchases.*` calls that replace each body once provisioned.
- **`MonetizationController`** is registered in `bootstrap()` (P4-5): it owns the
  current `Entitlements`, drives **premium gating**, and is the single PII-free
  emit point for `monetizationEvent` / `compassionCoinMint`.
- **Premium gating, proven by tests:** purchasing Forever Friends flips
  `entitlements.foreverFriends` → `removesInterstitials` + `dailyKibbleBonus`
  (cosmetic/QoL only — never the Bond/pet, §18). `restore()` re-resolves the
  active subscription. The unprovisioned RevenueCat seam grants nothing.

**Founder activation checklist:** `flutter pub add purchases_flutter` · create the
Forever Friends subscription + Heartstone/Rescue-Bundle products in App Store
Connect + Play Console + map them in RevenueCat · set
`REVENUECAT_PUBLIC_SDK_KEY_IOS`/`_ANDROID` · `Purchases.configure(...)` at startup
· replace the three `RevenueCatBillingService` bodies with the SDK calls · build
with `--dart-define=KP_BILLING=revenuecat`.
