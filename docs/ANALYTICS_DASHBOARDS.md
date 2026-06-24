# ANALYTICS_DASHBOARDS.md — KindredPaws product-health dashboards (P5-0)

How the founder reads product health for soft launch (G4). The telemetry is
**privacy-by-design (no PII)**, emitted at one point (`ObservabilityFacade.event`,
contract-enforced by `Telemetry.sanitize`), and the dashboard math is a tested
module (`lib/services/analytics_metrics.dart`) so the definitions are reviewable.
Authority: `GAME_TECHNICAL_SYSTEMS.md §10`, brief §10, roadmap §9 (G4).

## The event taxonomy (20 events)

The 15 core events (`docs/TELEMETRY.md`) + the 5 P5 soft-launch additions:

| Event | Gate | Feeds |
|---|---|---|
| `onboardingStep {step, ms_since_start?}` | onboarding | activation funnel + drop-off |
| `retentionMilestone {day}` | retention | D1/D3/D7/D14/D30 returns |
| `notificationOpened {kind}` | retention | re-engagement effectiveness |
| `paywallStep {step, surface?}` | monetization | conversion funnel |
| `experimentExposure {experiment, variant}` | experiment | A/B lift analysis |

## Dashboards (each KPI → the events + the `AnalyticsMetrics` accessor)

### 1. Retention (the G4 headline)
- **D1 ≥42% · D7 ≥20% · D30 ≥10%** — cohort = installs (first `rescueDayComplete`);
  return = `retentionMilestone {day}` / `sessionStart`. `retentionMilestonesByDay`.
- **Empty-session rate** (`sessionQuality.empty`) — the leading daily-retention
  lever. `emptySessionRate`.

### 2. Leading-churn alarms (mandatory, wired from G3)
- **"Noticed AI repetition"** — `aiRepetitionFlag` / `sessionStart`. `aiRepetitionRate`.
- **"Felt guilt-tripped"** — `guiltFlag` / `sessionStart` (≈0 by design). `guiltRate`.
- **Composite churn-risk** — `churnRiskScore` (0..1) blends the two indicators +
  empty-session rate; predicts D7/D30 collapse *before* raw retention moves. Alert
  when it trends up.

### 3. Onboarding funnel (activation)
- `onboardingStep` (reach_out → warmed → choose_species → name_entered) →
  `rescueDayComplete`. Target ≥80% complete (§13.4). `onboardingCompletionRate` +
  per-step drop-off.

### 4. Memory authenticity (the differentiator)
- `memoryCallback {landed}` — "it remembered me" land rate. `memoryCallbackLandedRate`.
  The hard G2 reliability gate is ≥95%.

### 5. Monetization funnel
- `paywallStep {shown→dismissed/start}` → `monetizationEvent` (purchase) →
  `compassionCoinMint`. ARPDAU, sub-conversion (≥2% target), IAP-payer (≥1.5%).
  `paywallConversionRate`.

### 6. Notifications + virality
- `notificationOpened {kind}` open-rate by kind. `notificationOpensByKind`.
- `keepsakeShare` — ≥1 viral share / DAU-week (G4).

### 7. Cost (the make-or-break)
- `llmCostEvent {tokens, cost, model}` — LLM cost/DAU < 35% ARPDAU (R2/G4). $0 on
  the MVP bank path (the live-chat pilot is the cost-risk moment).

## Implementation note

In production these definitions run server-side (Firebase Analytics → BigQuery)
over the warehoused events. `AnalyticsMetrics` is the same math, tested
host-side, so a dashboard can never silently drift from the intended definition;
A/B experiments join `experimentExposure.variant` to any outcome event for lift.
All events are PII-free — `Telemetry.sanitize` drops PII keys and (on open-schema
events) free-text values before anything leaves the device.
