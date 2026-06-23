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

## 5. Deferred to P3-5b

Compassion Coins mint flow (append to the impact ledger, `validated` anti-fraud
gating), `compassionCoinMint` telemetry, and Rescue Bundles (commercial purchase
with a disclosed donation split — **not** a donation IAP).
