# ADS.md — KindredPaws child-safe ads (P4-6)

Rewarded-first, **child-safe**, **no dark patterns** ads — the F2P floor that also
funds free players' real-world impact (every rewarded watch mints Compassion
Coins). Authority: brief §5, `GAME_TECHNICAL_SYSTEMS §7.1/§7.4`, Risk R1.

## Child-safe by construction

The SDK request is built from `AdConfig.fromCompliance(...)` (P3-6a), which for
the shipped default (unknown ⇒ under-13 band, D-007) sets:

- **No behavioral targeting** anywhere — `personalizedAdsAllowed = false` (the
  Data Safety form declares this).
- **COPPA** `tagForChildDirectedTreatment` + **GDPR-K** `tagForUnderAgeOfConsent`
  **on**, ad-content rating clamped to **G**.

`AdService` always takes this config, so a request can't go out without the kids
flags.

## The ethical rules (`AdsController`)

| Rule | Enforcement |
|---|---|
| **Rewarded is opt-in** | only shown when the player chooses it |
| **Daily rewarded cap** | `ads.rewarded_daily_cap` (~4–6, Remote Config) — the 7th is `unavailable` |
| **Interstitials are sparse** | max **1 / session** (`maxInterstitialsPerSession`) |
| **NEVER mid-emotion** | `canShowInterstitial(duringEmotionalBeat: true)` → false |
| **Subscriber ad-light** | `removesInterstitials` (Forever Friends) → no interstitials |
| **Killable live** | `LiveOps.isKilled(LiveFeature.rewardedAds)` (P4-3) disables all ads |
| **No dark patterns** | no forced/surprise ads; no "watch to keep your pet"; rewarded only credits cosmetic/impact currency, never the pet's wellbeing |

## Rewarded → Compassion Coins (anti-fraud)

On a completed rewarded watch the client emits `monetizationEvent
{stream: rewardedAd}` and **does not self-mint**. The ad network sends a **signed
S2S postback** to our server, which validates it (+ device attestation + per-user
daily cap) and mints the Compassion Coins to the append-only impact ledger
(`MonetizationController.mintCompassionCoins`, validated-only — §7.4). The client
credits the wallet *display* optimistically; the ledger is the source of truth.
**Impact never requires payment** — free players generate real giving via ads
(the hard ethical wall).

## Activation (founder/credentialed)

`NoopAdService` (simulated completion, offline) is the default; `AdMobAdService`
is the **inert gated seam** until provisioned (REQUIRED_ENVIRONMENTS §6): add
`google_mobile_ads`, set the AdMob app/ad-unit ids, push the TFCD/TFUA + G-rating
request config from `AdConfig`, and wire the rewarded/interstitial load+show +
the server-side S2S postback validator. Then `AdsController` drives real ads with
the same rules above.
