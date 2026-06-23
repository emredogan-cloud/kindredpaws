# COMPLIANCE.md — KindredPaws child-safety & privacy (P3-6a)

How KindredPaws stays **child-safe for ALL users by default**. Authority:
`GAME_TECHNICAL_SYSTEMS.md §11.1/§11.2/§11.3` + `§4.5` + `§8.3`,
`KINDREDPAWS_CANONICAL_DECISION_BRIEF.md §11 (R1, the existential risk)`,
`docs/LEGAL_CHILD_DIRECTEDNESS_SCOPING.md`, `GAME_DECISION_LOG.md`
D-007 / D-019 / D-047, ADR-011. These are LOCKED — do not loosen without counsel
sign-off (the G3 legal gate).

## 1. The posture (locked): protective default for everyone

The product's working assumption — and what the engineering builds to — is
**child-safe for ALL users** (D-007). We do **not** assume an adult until an age
band has been affirmatively established. Concretely, every user starts treated
as a child until proven otherwise:

- **No free-text storage from minors; under-13 = templated / non-generative
  dialogue only** (§11.1, §4.5).
- **No behavioral ad targeting anywhere** — contextual-only, with COPPA/GDPR-K
  kids flags set; declared honestly on the store Data Safety / privacy nutrition
  labels (§11.1, §11.3).
- **Minimal PII:** sign-in is Apple / Google / guest, no email-password; we store
  **no birthdate** — only a coarse age *band* (§11.2, §8.3).

## 2. The fail-safe model (`lib/core/compliance_config.dart`)

`ComplianceConfig` is the single source of truth. Every protective flag is
*derived* from a coarse `AgeBand` + `ConsentState`, so callers never re-derive
COPPA/GDPR-K logic ad hoc.

`AgeBand { unknown, under13, teen, adult }` — never a precise age. The key
property is **fail-safe by construction**: `unknown` is treated *identically* to
`under13` (`AgeBand.requiresChildSafeTreatment`). A user whose age we have not
established gets the **most** locked-down experience, not the least.

| Derived flag | unknown | under13 | teen | adult |
|---|---|---|---|---|
| `isChildSafe` | ✅ | ✅ | — | — |
| `freeTextInputAllowed` | ❌ | ❌ | ✅ | ✅ |
| `mayUseGenerativeDialogue`¹ | ❌ | ❌ | ✅ *iff VPC* | ✅ |
| `behavioralAdsAllowed` | ❌ | ❌ | ❌ | ❌ |

¹ Gated by the **global** live-chat flag too (`AppConfig.heartmindLiveChatEnabled`,
**off for everyone in MVP**). `effectiveLiveChatEnabled(globalLiveChatFlag:)` ANDs
the two, so an under-13 / unknown user can never reach generative dialogue even
if the flag flips on. Live chat itself is a Deferred (P4), subscriber + adult
path (§4.6).

`ConsentState { parentalConsentVerified, personalizedDataAllowed }` is a **data
holder only**. Defaults are "nothing granted yet," so an un-onboarded user is
never assumed to have consented. `parentalConsentVerified` (COPPA VPC) gates the
*teen* generative path; under-13 stays templated-only even with it (§4.5).

## 3. Advertising kids-config (`lib/monetization/ad_config.dart`)

`AdConfig.fromCompliance(ComplianceConfig)` is a **pure function** of the policy —
no AdMob/mediation dependency lives in the app (the real SDK reads these fields at
provisioning, REQUIRED_ENVIRONMENTS.md §5). It maps the posture to concrete
mediation flags:

| Field | child-safe (unknown/under13) | teen/adult |
|---|---|---|
| `tagForChildDirectedTreatment` (COPPA TFCD) | ✅ | ❌ |
| `tagForUnderAgeOfConsent` (GDPR-K TFUA) | ✅ | ❌ |
| `personalizedAdsAllowed` | ❌ | ❌ (MVP contextual-only) |
| `maxAdContentRating` | G | PG |

Behavioral targeting is off for **every** band as defense in depth: even a future
loosening of `behavioralAdsAllowed` for adults could never silently enable
personalized ads for an unknown/under-13 user, because the kids tags are keyed to
the band independently.

## 4. Wired at startup (`lib/core/bootstrap.dart`)

`bootstrap()` registers the fully-protective default — `ComplianceConfig()`
(unknown band, nothing consented) — and the `AdConfig` derived from it, as
singletons. This is what ships: until the age model lands, every user is treated
as a child. `config_and_bootstrap_test.dart` pins that the registered default is
fully child-safe.

## 5. What is deliberately NOT built here (the G3 gate)

The *flow* that establishes a real age band — a neutral age-gate vs. a
fully-child-safe-for-all model, and any verifiable-parental-consent UI — is
**Open Decision #9**, resolved at the **mandatory pre-launch legal review (G3)**,
a founder + counsel deliverable (`docs/LEGAL_CHILD_DIRECTEDNESS_SCOPING.md`,
ADR-011). This subsystem is the downstream **enforcement** of whatever that
determination yields, not the gate itself. Until it ships, the band stays
`unknown` and the protective default above is in force.

Related deletion / right-to-be-forgotten path (GDPR/COPPA §8.3) and the free-text
PII/profanity filter land in **P3-6b**.
