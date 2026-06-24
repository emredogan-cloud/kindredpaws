# SOFT_LAUNCH_READINESS.md — KindredPaws (P5-7)

The operational playbook for the soft launch: the go/no-go checklist, the
incident + support runbooks, the launch dashboards, and the rollback procedures.
Authority: `GAME_MASTER_EXECUTION_ROADMAP` (G4 soft launch),
`KINDREDPAWS_CANONICAL_DECISION_BRIEF.md §10/§11`, `GAME_TECHNICAL_SYSTEMS.md §10`.
Cross-refs: `LIVEOPS.md` (levers), `BETA_FEEDBACK_LOOP.md`, `PERFORMANCE.md`,
`MONETIZATION.md`, `ANALYTICS_DASHBOARDS.md`, `COMPLIANCE.md`.

---

## 1. Soft launch checklist (go / no-go)

Launch only when **every** box is green. Owner in brackets.

### Product / quality
- [ ] `just verify` green on `main` (analyze + content-validate + tests, coverage ≥ 85%). [eng]
- [ ] All 9 CI checks green on the release commit (analyze, test, build-android, integration-android, secret-scan, dependency-scan, osv-scanner, sbom, workflow-hardening). [eng]
- [ ] Crash-free sessions ≥ 99.5% across the last closed-beta build (Crashlytics). [eng]
- [ ] Cold start < 2.5 s on a mid-tier device (`PerfBudget.coldStart`, `PERFORMANCE.md`). [eng]
- [ ] No open P1 in the beta queue (`BETA_FEEDBACK_LOOP.md`). [founder]

### Telemetry / KPIs wired
- [ ] All telemetry gates emitting (the `Telemetry` registry totality test passes; events visible in the console). [eng]
- [ ] Leading-churn indicators live: `aiRepetitionFlag`, `guiltFlag` (must read ~0). [eng]
- [ ] The G4 KPI dashboard renders D1/D7/D30, ARPDAU, crash-free, LLM-cost/DAU, share/DAU-week, donation reconciliation (§4). [founder]

### Monetization
- [ ] Store products live + mapped in RevenueCat (`forever_friends_monthly/annual`, `heartstone_*`, `rescue_bundle_*`) — `MONETIZATION.md` activation checklist. [founder]
- [ ] Paywall funnel emitting (`paywallStep`), restore tested on a real account. [eng]
- [ ] Ethical wall intact: no pay-to-win grant added (the `Grant` pin test passes); pricing experiment varies copy only, never price. [eng]

### Legal / compliance / safety
- [ ] Age-gate / compliance posture correct for the launch geos (`COMPLIANCE.md`, child-safe default). [legal]
- [ ] Privacy policy + data-deletion path live (right-to-be-forgotten resets analytics ids). [legal]
- [ ] No PII in telemetry (sanitize tests pass; `secret-scan` green). [eng]

### Live-ops armed
- [ ] Remote Config published with the canonical defaults; kill-switches reachable. [eng]
- [ ] Rollback levers verified (§5) — at least one kill-switch toggled in staging and observed. [eng]
- [ ] On-call rotation + this doc shared; founder reachable for the launch window. [founder]

---

## 2. Incident runbooks

General shape: **detect → assess → mitigate (live, no app update) → verify →
post-mortem.** Mitigation almost always = a Remote Config lever (§5), because an
app-store update takes hours-to-days and soft launch needs minutes.

### 2.1 Crash spike / stability (crash-free < 99.5%)
1. **Detect:** Crashlytics alert, or a rise in P1 `crashReport` beta items (`had_crash=true`).
2. **Assess:** which build/feature? The beta item's diagnostic snapshot pins env + flags + versions; group by Crashlytics signature.
3. **Mitigate:** if a single feature is implicated, flip its kill-switch (`killswitch.<feature>` → true) — e.g. `rewarded_ads`, `keepsake_share`, `notifications`, `live_chat`, `beta_feedback`, `rescue_bundles`. If config-driven, roll the offending value back to its default.
4. **Verify:** crash-free recovers; the breadcrumb trail (`event:*`, `perf:*`) confirms the path is gone.
5. **Post-mortem:** add a regression test at the lowest layer; ship the real fix; re-enable.

### 2.2 KPI collapse (D1/D7 drop, empty-session spike)
1. **Detect:** retention dashboard; `sessionQuality.empty` ratio climbing; `aiRepetitionFlag` / `guiltFlag` non-zero.
2. **Assess:** correlate with the last content/config change or an active experiment.
3. **Mitigate:** disable the suspect experiment (`experiment.<key>.enabled` → false ⇒ everyone returns to control); revert the content top-up (`liveops.content_version`); dial a rollout back (`rollout.<feature>.pct`).
4. **Verify:** the leading-churn flags return to ~0; empty-session ratio normalizes.

### 2.3 LLM / unit-cost overrun (cost/DAU > 35% ARPDAU)
1. **Detect:** `llmCostEvent` dashboard breaches the gate.
2. **Mitigate:** the MVP Heartmind is on-device ($0 runtime) — a breach implies a provisioned live-chat path; kill `live_chat`. Confirm `heartmindLiveChatEnabled` is off for the launch cohort.
3. **Verify:** cost/DAU falls back under the gate.

### 2.4 Ethical / child-safety breach (hard stop)
1. **Detect:** any guilt/parasocial/romantic line reported, a pay-to-win grant, behavioral-ad flag, or PII in telemetry.
2. **Mitigate immediately:** kill the offending surface (`killswitch.*`); if dialogue, the bundled bank is the safe floor — drop the bad Remote Config top-up. **This is a launch-blocker, not a degrade** — halt rollout (`rollout.*.pct` → 0) if systemic.
3. **Verify + post-mortem:** add a guard test (these are pinned: no-pay-to-win `Grant` test, dialogue safety filter, sanitize PII tests). No re-launch until the guard is green.

### 2.5 Donation reconciliation mismatch
1. **Detect:** the impact ledger (`impact_ledger`) total ≠ expected from `compassionCoinMint{validated:true}` events.
2. **Assess:** check the anti-fraud gate — only `validated` mints append; `validated:false` events are the fraud-monitor trail.
3. **Mitigate:** pause `rescue_bundles` if the commercial split is implicated; reconcile server-side before resuming. Impact is never tied to pet wellbeing, so play is unaffected.

---

## 3. Support runbooks (tester-facing)

Every PII-free; a tester can attach `BetaDiagnostics.exportText()` to any ticket.

| Symptom | First response | Root-cause path |
|---|---|---|
| "My purchase didn't go through" | Confirm no charge (failed/cancelled ≠ charged). Ask them to retry; try **Restore purchases**. | `paywallStep` funnel: `purchase_failed` vs `cancelled`; entitlement state in diagnostics. |
| "I paid but don't have my perks" | **Restore purchases** in the paywall. | `restore_success` vs `restore_empty`; RevenueCat entitlement. |
| "Notifications aren't arriving" | Check OS notification permission; confirm `notifications` isn't killed. | `notificationOpened` absent; `killswitch.notifications`. |
| "Is my pet gone?" (reinstall) | Reassure: the pet is never orphaned; sign in to restore the cloud save. | Save schema/version in diagnostics; backend read. |
| "Delete my data" | Trigger in-app data deletion (right-to-be-forgotten); analytics ids reset. | `COMPLIANCE.md §11.2`. |
| "The app feels broken/slow" | Get a diagnostic export; ask what they were doing. | `perf:*` breadcrumbs; `had_crash` on their beta item. |

Triage feeds the same queue as §2 via `BETA_FEEDBACK_LOOP.md` (worst-first).

---

## 4. Launch dashboards (what to watch)

See `ANALYTICS_DASHBOARDS.md` for the full spec; the soft-launch must-watch set:

**Day-1 war room (hourly):**
- Crash-free sessions (target ≥ 99.5%) · P1 `crashReport` count.
- Cold-start p50/p95 (`cold_start_ms` vs 2500) · `perf:*:over` breadcrumb rate.
- Activation funnel: `onboardingStep` completion (≥ 80%) → `rescueDayComplete`.
- `aiRepetitionFlag` / `guiltFlag` — **must be ~0** (hard ethical signal).

**Week-1 (daily):**
- D1 ≥ 42% / D7 ≥ 20% (D30 ≥ 10% as it matures).
- ARPDAU ≥ $0.03 · paywall sub-conversion (`paywallStep` funnel) · experiment lift (`experimentExposure` joins).
- LLM cost/DAU < 35% ARPDAU (`llmCostEvent`).
- ≥ 1 viral share / DAU-week (`keepsakeShare`).
- Beta sentiment mix + detractor share (`betaFeedback`).
- Donation reconciliation clean (`impact_ledger` vs validated mints).

Each metric names the event that feeds it, so a dark dashboard = a wiring bug, caught pre-launch by the checklist (§1).

---

## 5. Rollback procedures

The ladder, **fastest first**. All but the last need **no app update**.

1. **Kill-switch (seconds).** `killswitch.<feature>` → true disables one feature for everyone. The incident off-switch. (`LiveFeature`: `live_chat`, `rewarded_ads`, `keepsake_share`, `notifications`, `beta_feedback`, `rescue_bundles`.)
2. **Experiment rollback (seconds).** `experiment.<key>.enabled` → false ⇒ everyone returns to `control` (the safe baseline). For `paywall_copy`, `onboarding_pace`, `notification_cadence`.
3. **Rollout dial-down (seconds).** `rollout.<feature>.pct` → 0 (or a smaller %) un-ships a canary feature for the cohort above the cut.
4. **Config revert (minute).** Restore a balance/flag Remote Config value to its canonical default (`DefaultRemoteConfig.defaults` is the safe fallback the app already ships).
5. **Content revert (minute).** Drop a bad dialogue top-up; the **bundled bank is always the safe floor** (`liveops.content_version`).
6. **Halt rollout (minute).** In the store console, pause the staged rollout % so no new users get the bad build.
7. **App rollback (hours, last resort).** Promote the previous build / ship a hotfix through CI. Releases are automated (Release Please) — never hand-edit versions/tags.

**Verification after any rollback:** confirm the relevant dashboard metric recovers and the breadcrumb/flag trail goes quiet before standing down. Log the action + outcome for the post-mortem.

---

## 6. Readiness sign-off

Soft launch is **GO** when §1 is fully green, §2–§5 are shared with on-call, and a
rollback lever has been exercised in staging at least once. Otherwise: **NO-GO** —
fix the red box, re-run the checklist.
