# Store privacy labels — App Store Nutrition + Play Data Safety (P4-8)

The **honest** data-disclosure source of truth for both stores. Mirrors the
engineered posture (GAME_TECHNICAL_SYSTEMS §11, `docs/COMPLIANCE.md`): minimal
PII, **no behavioral ad targeting**, on-device-only voice (deferred), and a
right-to-be-forgotten deletion path. Fill the store forms from this; do not
overclaim or underclaim.

## Data collected

| Data | Purpose | Linked to identity | Used for tracking |
|---|---|---|---|
| Account identifier (Apple/Google sign-in or guest id) | App functionality (cloud save, entitlements, impact ledger) | Yes | **No** |
| Game progress / save data (pet state, Bond, closed-set memory facts) | App functionality (cloud save + restore) | Yes | **No** |
| Coarse product analytics (~15 funnel events, **no PII**) | Analytics / app improvement | No | **No** |
| Purchase history (subscription/IAP via RevenueCat receipts) | App functionality, fraud prevention | Yes | **No** |
| Crash + performance diagnostics | App stability / performance | No | **No** |

## Data NOT collected

- **No precise or coarse location.**
- **No contacts, photos, messages, browsing history, or health data.**
- **No audio is collected** — the (deferred) voice-mimic layer is **on-device DSP
  only; audio never leaves the device.**
- **No free-text from minors** is stored (the one name field is filtered; closed-set
  memory only).

## Key declarations

- **No behavioral / cross-app ad targeting.** Ads (when present) are
  contextual-only with COPPA/GDPR-K kids flags. **No data is used to track users
  across apps or websites.**
- **No data sold.** No data shared with data brokers.
- **Data is encrypted in transit** (TLS 1.2+).
- **Deletion:** users can request account deletion in-app (right-to-be-forgotten,
  §8.3) — wipes the save + resets analytics ids; ledger entries are anonymized
  (financial fact retained, personal link dropped).
- **Children:** built child-safe for all users; the binding child-directedness
  legal determination (Open Decision #9) is a **G3 counsel sign-off** that must
  land before public listing, and may adjust the "Made for Kids" / age-rating
  selection + the App Store Kids Category decision.

## Age rating inputs

- No violence, no sexual content, no profanity (the one free-text field is
  PII/profanity filtered), no gambling/loot boxes (cosmetics are direct-purchase),
  no user-to-user communication, no unrestricted web access.
- Expected: low age rating; final rating + Kids-category placement pending the G3
  legal determination.
