# LIVEOPS.md — KindredPaws live operations (P4-3)

How the founder changes product behavior **without shipping a new app** — the
mitigation for the live-ops content treadmill + incident response (Risk R8).
Authority: `GAME_TECHNICAL_SYSTEMS.md §9`, brief §11 R8, `GAME_CONTENT_FACTORY §11`.
Everything routes through **Firebase Remote Config** (the `RemoteConfigService`
seam), with safe local defaults so the app behaves correctly before the first
fetch and if Remote Config is unreachable.

## The four live levers

### 1. Live balancing (already wired)
Every balance number (decay rates, the no-death floor, Bond thresholds + soft
cap, offline grace, caps) is a Remote Config key consumed by
`SimConfig.fromRemoteConfig`. Tune them live; the canonical defaults are the safe
fallback (`DefaultRemoteConfig.defaults`).

### 2. Emergency kill-switches (`LiveOps.isKilled`)
`killswitch.<feature>` (default `false`). Flipping one to `true` immediately
disables that feature for everyone — the incident "off switch", no app update.
Controlled features: `live_chat`, `rewarded_ads`, `keepsake_share`,
`notifications`, `beta_feedback`, `rescue_bundles` (`LiveFeature` enum).

### 3. Percentage rollout (`LiveOps.isInRollout`)
`rollout.<feature>.pct` (0..100, default `100`). A canary lever: a stable
`unitId` (the account id) is hashed (FNV-1a, salted per-feature) into a sticky
`0..99` bucket; the feature is in-rollout when `bucket < pct`. **Sticky** — a
user never flip-flops between sessions — and **decorrelated** — different
features roll out to different slices. `LiveOps.isLive(f, unitId:)` = *not killed*
**and** *in rollout*.

### 4. Content hotfix (already wired)
`mergeRemoteContent` (Content OS) validates + merges a Remote Config dialogue
top-up into the live bank — a safe, per-entry, fail-closed way to add/fix lines
without an app update. `liveops.content_version` coordinates the expected bank
version. The bundled bank is always the safe floor.

### 5. A/B experiments (`Experiments.expose`, P5-3)
The safe way to run a soft-launch experiment. An `Experiment` (`paywall_copy`,
`onboarding_pace`, `notification_cadence`, …) is **OFF by default** — everyone is
`control` (the safe baseline *and* the emergency-rollback state). The founder
flips `experiment.<key>.enabled` in Remote Config to start it; users then split
**deterministically + evenly** across `control` + N treatment arms by a
per-experiment salted bucket (sticky, no flip-flop). `Experiments.expose(exp,
unitId:)` returns the variant **and** emits `experimentExposure {experiment,
variant}` (once per user) — joined to any outcome event for lift analysis.
**Emergency rollback** = set `enabled` back to false → everyone returns to
control instantly, no app update. **Feature/content cohorts** are the existing
`%-rollout` + `contentVersion` keyed by the same deterministic bucket.

## Wiring

`LiveOps` is registered in `bootstrap()` over `DefaultRemoteConfig` and re-bound
over `FirebaseRemoteConfigAdapter` in `registerFirebaseServices` once provisioned.
Consumers (ads, notifications, share, beta UX) gate on
`liveOps.isLive(LiveFeature.x, unitId: accountId)`.

## Safety

- Defaults are conservative + canonical (the brief/bible). A missing or
  unreachable Remote Config never breaks the app — it falls back to defaults.
- Kill-switches default to *off* (features live); the founder opts into a kill.
- Rollouts default to 100% (fully shipped); the founder dials a canary down.
- Pure, deterministic bucketing (no RNG) → reproducible, testable, no PII (the
  unit id is the existing anonymous account id, hashed).
