# BETA_FEEDBACK_LOOP.md — KindredPaws closed-beta operations (P5-5)

The complete loop that turns a tester's "how's it going?" tap into a **routed,
prioritized, context-rich** item the founder can act on — without ever shipping
PII off-device. Authority: `GAME_MASTER_EXECUTION_ROADMAP` G3 (closed beta),
`GAME_TECHNICAL_SYSTEMS.md §10`, `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md §10`
(leading-churn signals).

## The pass (one call)

`BetaFeedbackPipeline.ingest(rating:, comment:)` runs five steps in order and
returns a `TriagedFeedback`:

1. **Ingestion.** `BetaFeedback` normalizes the input — rating clamped 1–5, note
   trimmed + rune-capped to 280 (so a boundary emoji is never split), blank →
   null. PII-minimized by construction.
2. **Sentiment tagging** (`sentiment.dart`). A transparent **on-device lexicon**
   + the star rating → `positive | neutral | negative | mixed`. Deterministic,
   $0, child-safe, no LLM (MVP forbids live free-form model calls). Both
   polarities present ⇒ `mixed`; no signal words ⇒ trust the stars. **Only the
   label leaves the device — the note text never rides telemetry.**
3. **Crash correlation** (`session_health.dart`). `ObservabilityFacade.recordError`
   is the single error funnel; it bumps a per-session `SessionHealthMonitor`. So
   the pipeline knows whether *this* session errored (and the last error's
   PII-free context label) the moment feedback arrives.
4. **Diagnostic correlation** (`BetaDiagnostics.snapshot()`). The PII-free build
   snapshot (env · backend · billing · renderer · compliance posture · killed
   features · schema/content versions) is attached, so an item carries the
   context to reproduce it — no back-and-forth with the tester.
5. **Triage** (`beta_triage.dart`) + **emit/persist**. The item is routed +
   prioritized (below), the PII-free `betaFeedback` event is emitted for the
   dashboard, and the raw feedback is best-effort appended to the `beta_feedback`
   backend stream.

## Triage rules (worst-first)

`triageFeedback(rating, sentiment, hadCrash, hasComment)` is pure + deterministic:

| Condition | Category | Severity |
|---|---|---|
| Session crashed/errored | `crashReport` | **P1** |
| ≤2★ **or** negative sentiment | `detractor` | **P2** |
| Mixed sentiment at an OK rating | `detractor` | P3 |
| ≥4★ **or** positive sentiment | `praise` | P3 |
| Neutral **with** a note | `suggestion` | P3 |
| Neutral, no note | `neutral` | P3 |

**Crash correlation wins** — a 5★ "loved it!" that crashed is still a P1 stability
item. Detractors are the churn-risk queue (pairs with the leading-churn flags in
`ObservabilityFacade`: noticed AI repetition / felt guilt-tripped).

## Telemetry (PII-free)

`betaFeedback {rating, category, severity, sentiment, had_crash}` — gate
`TelemetryGate.betaOps`. No note text, no identifiers; schema-enforced at the
single emit point (`Telemetry.sanitize`). This is what the founder's beta
dashboard counts: P1 crash rate, detractor share, sentiment mix, rating
distribution — the daily pulse of the beta.

## Founder workflow

1. **Daily pulse** — watch the `betaFeedback` dashboard: any `crashReport`? is the
   `detractor` share rising? what's the sentiment mix vs yesterday?
2. **Work the queue worst-first** — P1 crash reports, then P2 detractors. For an
   individual item, `TriagedFeedback.exportText()` is a copy-paste bundle: the
   triage header + the note + the correlated diagnostics (the internal triage
   console — the note is shown here to the founder, never shipped as analytics).
3. **Correlate a crash** — a `crashReport` item's diagnostics pin the build +
   flag state; cross-reference Crashlytics for the stack. If it's a live-config
   issue, the LiveOps kill-switch / rollback levers (`LIVEOPS.md`) are the
   no-app-update fix.
4. **Close the loop** — fix or file, then watch the next day's pulse for the
   category to shrink.

## Wiring

`BetaFeedbackPipeline` is registered in `bootstrap()` over the Noop feedback seam
(dev/CI offline) and **re-bound in `registerFirebaseServices`** over the
backend-backed `beta_feedback` stream once provisioned. `GameController`
.`submitBetaFeedback` routes through it when wired (else falls back to the raw
seam), so the existing in-app feedback sheet (`beta_feedback_sheet.dart`) gets
the full pass for free. All components are pure/seam-isolated → fully unit-tested
without a device.
