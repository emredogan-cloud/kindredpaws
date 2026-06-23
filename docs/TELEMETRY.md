# TELEMETRY.md — KindredPaws telemetry & observability taxonomy (P3-1)

The single source of truth for **what we measure, why, and the privacy rules**.
The machine-readable contract is [`lib/services/telemetry.dart`](../lib/services/telemetry.dart)
(`Telemetry.specs`); this doc is the human-readable companion. A unit test pins
the two together (every `AnalyticsEvent` has exactly one `EventSpec`).

**Authority:** `game-os/GAME_TECHNICAL_SYSTEMS.md §10`, `GAMEPLAY_AND_PROGRESSION_BIBLE.md §17`,
`KINDREDPAWS_CANONICAL_DECISION_BRIEF.md §10`, `GAME_MASTER_EXECUTION_ROADMAP.md §8/§14`.
Never violate SSOT — if this doc and a higher doc disagree, the higher doc wins.

## 1. Privacy first (Risk R1 — binding, non-negotiable)

Telemetry is **coarse and non-identifying by construction**. The forbidden keys
are the single set [`LogRecord.blockedKeys`](../lib/services/logger.dart) —
`name, petName, email, userText, message, freeText, dialogue, fact, factText` —
and they are stripped from **every** signal (logs, crash keys, analytics params).

Enforcement is layered (defense in depth):

1. **`Telemetry.sanitize(event, params)`** runs at the single emit point
   (`ObservabilityFacade.event` / the leading-churn helpers): it drops PII keys
   **and**, for an event with a declared schema, any key outside its contract —
   so a typo'd or newly-added param can never silently ship.
2. **Both sinks** (`InMemoryAnalyticsService`, `FirebaseAnalyticsAdapter`) also
   drop `blockedKeys` independently, so even a direct `analytics.log` is safe.
3. **`InMemoryLogger`** stores already-sanitized fields (no PII ever rests in the
   breadcrumb buffer).

**Child-safety constraints (COPPA / GDPR-K — G3 legal gate, `docs/LEGAL_CHILD_DIRECTEDNESS_SCOPING.md`):**
no free-text from minors is ever stored or logged; **no behavioral ad targeting**
(under-13 → contextual-only or none); analytics identifiers reset on account
deletion (right-to-be-forgotten). **Hard ethical walls** (`GAMEPLAY_AND_PROGRESSION_BIBLE.md §18`):
never tie the pet's wellbeing to real donations; never guilt-frame; observability
must never need dialogue/facts to be useful.

## 2. The canonical event taxonomy (15 events)

`Trigger` = where it fires. `Params` = the contract (required **bold**, optional
_italic_). `Emit` = wired now (✅) or owned by a later subsystem (⏳ — schema is
ready; emission lands with that system, by design / scope discipline).

| Event | Gate | Trigger | Params | Emit |
|---|---|---|---|---|
| `rescueDayComplete` | onboarding | Rescue Day finished (adopt + name) | **species** | ✅ |
| `sessionStart` | retention | Session began (after offline catch-up) | **offline_hours** | ✅ |
| `sessionQuality` | retention | Session end summary (`empty=false` ⇒ ≥1 meaningful beat) | **empty, interactions_n, duration_s** | ⏳ P3-7 (lifecycle); `recordSessionQuality()` ready |
| `careAction` | engagement | A feed/clean/play | **verb, bond_awarded, needed** | ✅ |
| `bondChange` | progression | Bond total changed | **value** | ✅ |
| `bondStageUp` | progression | Bond crossed a stage boundary | **stage** | ✅ |
| `lifeStageUp` | progression | Pet grew a life stage | **stage** | ✅ |
| `memoryCallback` | aiReliability | "It remembered me" beat fired | **facts**, _landed_ | ✅ |
| `aiRepetitionFlag` | leadingChurn | Player noticed AI repetition | _(open coarse context; non-String values only)_ | ✅ `flagAiRepetition()` |
| `guiltFlag` | leadingChurn | Player felt guilt-tripped (~0 by design) | _(open coarse context; non-String values only)_ | ✅ `flagGuilt()` |
| `streakEvent` | engagement | Care-streak advanced | **count** | ✅ |
| `monetizationEvent` | monetization | Purchase / restore / subscription | **stream, sku, value** | ⏳ P3-5 (RevenueCat) |
| `compassionCoinMint` | impact | Compassion Coins minted | **source, amount, validated** | ⏳ impact ledger |
| `keepsakeShare` | virality | Keepsake card shared | **moment_type, platform** | ⏳ P3-3 (share flow) |
| `llmCostEvent` | cost | Metered LLM turn | **tokens, cost, model** | ⏳ P4 live-chat (pre-gen reads are $0) |

> **No silent gaps:** the 5 ⏳ events are intentionally not emitted yet — their
> source systems are later P3/P4 subsystems. Their schemas exist now so those
> subsystems only call a typed, validated helper. This table is the checklist.

## 3. KPIs / funnel gates the events feed

Retention targets (blended, authoritative — brief §10; `GAME_TECHNICAL_SYSTEMS.md §10.3`):

| Metric | G3 (closed beta) | G4 (soft launch) | G5/G6 (hold) | Fed by |
|---|---|---|---|---|
| **D1** | ≥40% | ≥42% | hold ≥42% | `sessionStart` cohorts |
| **D7** | ≥18% | ≥20% | hold ≥20% | `sessionStart` cohorts |
| **D30** | — | ≥10% | hold ≥10% | `sessionStart` cohorts |
| **AI callback reliability** | **≥95% (hard G2)** | hold | hold | `memoryCallback` (landed ratio) |
| **Crash-free sessions** | ≥99% | ≥99% | ≥99.5% (G5) | Crashlytics (not an analytics event) |
| **LLM cost / DAU** | within model | **<35% of ARPDAU (hard)** | hold | `llmCostEvent` vs `monetizationEvent` |
| **Viral shares** | — | ≥1 / DAU-week | hold | `keepsakeShare` |
| **Leading churn** | trend ↓ | trend ↓ | within bounds | `aiRepetitionFlag`, `guiltFlag` |

**Activation (D1):** install → complete Rescue Day → adopt + name → return Day 2.
**Session quality:** a session is *non-empty* if it has ≥1 of: fresh greeting,
memory callback, a met care need, a Kibble tick toward a goal, or a new ambient
behavior. Non-empty sessions are the daily-retention lever — watch `sessionQuality.empty`.

**Leading-churn mandate (brief §10):** `aiRepetitionFlag` and `guiltFlag` predict
D7/D30 collapse *before* raw retention moves. Wire both to dashboards from G3;
rising trend ⇒ rotate the dialogue bank / soften copy *before* D7 dips.

## 4. Observability beyond analytics

| Signal | Sink | Notes / budget |
|---|---|---|
| **Structured logs** | `Logger` (`debug…wtf`), PII-sanitized on write | context-tagged; min-level gate per sink |
| **Non-fatal errors** | `CrashReporter.recordError` (+ breadcrumb) | coarse keys only (lifeStage, bondStage, screen) |
| **Breadcrumbs** | crash buffer | `event:<name>` / `churn:<name>` trail before a crash |
| **Perf traces** | `PerformanceMonitor` | `cold_start` ~2s soft target; `sim_resolve` ≤150 ms reaction-beat budget |
| **Remote Config** | `RemoteConfigService` | sim params, dialogue top-ups, donation rates, live-chat gate |

In production these route to Firebase Analytics / Crashlytics / Performance /
Remote Config — gated behind `KP_FIREBASE_PROVISIONED` (see
`lib/services/firebase/firebase_services.dart`, `REQUIRED_ENVIRONMENTS.md §1`).
The default (CI/test) build uses the in-memory sinks and never touches the network.

## 5. Adding or changing an event

1. Add the value to `AnalyticsEvent` (`analytics_service.dart`).
2. Add its `EventSpec` to `Telemetry.specs` (gate + description + param contract).
   The totality test fails until you do.
3. Emit via `observability.event(...)` (never call a sink directly).
4. Update this table and, if it feeds a KPI/gate, §3.
5. PII keys are forbidden everywhere — if a param could carry identity, it doesn't
   belong in telemetry.
