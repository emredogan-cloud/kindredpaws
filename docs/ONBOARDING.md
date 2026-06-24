# ONBOARDING.md — KindredPaws Rescue Day (P5-1)

The 60–90s emotional cold-open that turns an install into an attached player.
**Emotional-first, not instructional** (GAMEPLAY_BIBLE §13): empathy → care →
attachment → ADOPT → name + first memory. No account wall, no tutorial wall, no
monetization surface. Authority: §13, brief §13, roadmap §9.

## The flow

`lib/game/ui/rescue_day_screen.dart`:
1. **Three beats** (tap-paced, player controls the speed) — rainy night → reach
   out → a hopeful wag.
2. **Choose species** — puppy or kitten.
3. **Name + adopt** — the name field is **pre-filled with the species default**,
   so a one-tap "Welcome home" is a valid, friction-free path. The single
   free-text field is PII/profanity-filtered (`NameInputValidator`).
4. On adopt: the pet is created, the first memories seeded, the first Keepsake
   captured, warm notifications scheduled, and the pet greets you — spinner-free
   (the dialogue is pre-gen + on-device).

## Friction reduction + recovery + progressive disclosure

- **Progressive disclosure** — one decision at a time (beats → species → name);
  no UI clutter, no upfront forms.
- **Friction reduction** — the default name makes naming optional; nothing blocks
  the player from reaching the pet quickly.
- **Skip / recovery** — there is intentionally **no skip** of the emotional beats
  (the attachment IS the onboarding), but the flow is **fully resumable**: an
  install that quits mid-onboarding has no save, so the next launch simply
  restarts Rescue Day from the top — no broken/half state, no orphaned pet.

## Instrumentation (the activation funnel)

Every step emits `onboardingStep {step, ms_since_start}` via the controller (the
single, PII-free emit point), so per-step drop-off + time-to-complete are
measurable against the §13.4 targets:

| Step | Fires when | Target |
|---|---|---|
| `reach_out` | first beat shown (onboarding start) | — |
| `choose_species` | species screen reached | — |
| `species_selected` | a species tapped | — |
| (`rescueDayComplete`) | adopt confirmed | **≥80% of installs** |

`AnalyticsMetrics.onboardingCompletionRate` derives the funnel; the Rescue Day
widget test pins that each step fires in order. First-memory-created and
first-care-interaction (the other §13.4 targets) follow from `rescueDayComplete`
+ `careAction`.
