# RETENTION.md — KindredPaws retention systems (P5-2)

How KindredPaws keeps players coming back — **warmly, never by guilt or
punishment** (Risk R6, GAMEPLAY_BIBLE §11/§5.7/§6.3). The whole posture is
"longing, not guilt": the pet is unconditionally fine; absence creates a happy
welcome-back, never a debt. Authority: §11, §5.7, §6.3, brief §10, roadmap §9 (G4).

## The systems (extends existing seams)

### Comeback / long-absence recovery
On a real session start, `resolveOnResume` applies offline catch-up with an
**8-hour grace window at 50% decay** ("the pet napped"), never below the no-death
floor (15). After a real absence (≥ grace) the pet greets with the **`returning`**
intent — a warm, longing welcome ("you're back! I had a nice nap and thought of
you"), **never** sulking or guilt. A test pins the returning line against the same
never-guilt SSOT the corpus uses.

### Care Streak + Streak Warmth (forgiveness)
The streak rewards consistency but **never punishes absence**: a missed day is
auto-protected by a banked **Streak Warmth** freeze ("your streak stayed warm 🔥",
never "STREAK LOST"); a lapse is repairable once. A broken streak never harms the
pet or the Bond.

### Gotcha Day (adoption anniversary)
On the adoption anniversary (and yearly after), the pet celebrates **how far you've
come together** — a `milestone` beat (pride + joy, never obligation), surfaced in
`_recordRetentionBeats`. A `retentionMilestone {day: 365}` signal marks it.

### Dynamic encouragement
Line selection is parameterized by the **evolving personality dials** + the **Bond
stage** (Stranger → Soulmate), so the pet's voice deepens as the relationship
grows — earned over real calendar time (the Bond is monotonic; absence only slows
*gain*, never reverses a tier or "forgets" a fact).

### Seasonal moments
Delivered via **Remote Config content top-ups** (the Content OS `mergeRemoteContent`
path + the LiveOps content version), not a hardcoded calendar — so a seasonal
flavor ships without an app update and stays inside the validated, never-guilt
content gate. (Live-Ops Events are Deferred; the infra is built — R8.)

## Instrumentation

`_recordRetentionBeats` (in `_resumeSession`) emits `retentionMilestone {day}` on
**D1 / D3 / D7 / D14 / D30** returns (and anniversaries) — feeding the G4
**D1 ≥42% · D7 ≥20% · D30 ≥10%** gates via `AnalyticsMetrics.retentionMilestonesByDay`
(the dashboard counts distinct returning users per day). The leading-churn
indicators (`emptySessionRate`, `aiRepetitionRate`, `guiltRate`) are the early
warning that retention is about to dip.

## Forbidden (hard ethical wall)

Never guilt-frame absence · never punish a broken streak · never tie the pet's
wellbeing to money/donations · never weaponize attachment (no FOMO, no
"your pet is sad without you"). These are enforced in the corpus + notification
SSOT (the never-guilt validator) and pinned by tests.
