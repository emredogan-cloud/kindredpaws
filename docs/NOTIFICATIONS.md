# NOTIFICATIONS.md — KindredPaws pet-voiced notifications (P4-4)

Warm, **local-scheduled** (no push cost), pet-voiced re-engagement — capped at
**1–2/day**, **never guilt / shame / punish-absence** (Risk R6, GAMEPLAY_BIBLE
§11.3, brief §6). The single most cost-effective retention lever (FPD 3.50).

## The five kinds (`NotificationKind`)

| Kind | When | Example copy |
|---|---|---|
| `reEngagement` | ~evening, since-last-session | "{name} found a sunbeam and thought of you ☀️" |
| `daypart` | ~morning habit anchor | "{name} is keeping your cozy spot warm 🏡" |
| `memory` | a stored fact resurfaces (the "it remembers" lever) | "{name} was just thinking about something you shared 💛" |
| `celebration` | a milestone (Bond/life-stage up, Gotcha Day) | "{name} and you reached a special moment together! 🎉" |
| `streakWarmth` | after a missed day — **reassurance, never loss** | "Your care streak stayed warm with {name} 🔥 Welcome back any time 💛" |

## Caps + safety (non-negotiable)

- **Hard ceiling: 2 notifications / calendar day** (`InMemoryNotificationScheduler.dailyCap`).
  Daily presence honors `dailyCap` (1–2); `scheduleEvent` **drops** an event on a
  day that is already full (never stacks into spam).
- **Never loss-framed.** Streak-warmth says "stayed warm / welcome back," never
  "you lost your streak" / "don't break it." Every template is opportunity-framed.
- **Same SSOT as dialogue.** A test scans *every* template against
  `ContentValidator.forbiddenGuiltLanguage` — the identical never-guilt word list
  the dialogue corpus is gated on. A guilt-framed notification can't ship.
- **No PII.** Only the pet name substitutes into a template; no player data.

## Wiring

- `GameController.adopt` schedules the next few days of warm presence
  (`scheduleDailyPresence`).
- A **bond-stage-up** schedules a `celebration` event (a warm "come celebrate"
  nudge for later, capped).
- The controller's scheduling is **gated on the LiveOps notifications
  kill-switch** (`!liveOps.isKilled(LiveFeature.notifications)`, P4-3): the
  founder can silence all notifications live, no app update. `scheduleEvent` is
  the seam memory nudges / streak warmth call.
- The native delivery binding (`flutter_local_notifications`) is a thin platform
  step (REQUIRED_ENVIRONMENTS.md); the in-memory scheduler computes exactly what
  would be delivered, fully testable with zero native dependency.
