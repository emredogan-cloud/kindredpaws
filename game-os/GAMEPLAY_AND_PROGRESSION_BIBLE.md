# KindredPaws — Gameplay & Progression Bible

> **Document role / canonical for:** This is the definitive design document for KindredPaws's **gameplay loops, simulation model (with numbers), progression, economy, monetization, donation loop, retention, onboarding, virality, pacing, and player-wellbeing ethics**. It is the single canonical home for *how the game plays and is balanced*. It does **not** redefine project-level scope, naming, phases, or tech — those live in the **CANONICAL DECISION BRIEF** (the SSOT) and the sibling docs. Where any number here would conflict with the brief, the brief wins and this doc must be corrected.
>
> **Status:** v1.0 (derived from Canonical Decision Brief v1.0 LOCKED) · **Date:** 2026-06-22
>
> **Cross-links (do not duplicate their content):**
> - **KINDREDPAWS_CANONICAL_DECISION_BRIEF.md** — project SSOT: naming, feature classification, phases/gates, KPIs, risks.
> - **GAME_TECHNICAL_SYSTEMS.md** — engine, BaaS, LLM proxy, save/sync, widgets, moderation pipeline, RevenueCat, ads SDK; Heartmind dialogue-bank + memory-extraction architecture, persona-dial implementation, child-safety prompt design; Impact-Pool ledger, intermediary integration, anti-fraud backend.
> - **GAME_CONTENT_FACTORY.md** — Live2D rig spec, life-stage skins, emotion motions, props, cosmetics, FX, audio, asset cap; dialogue-bank content production; localization; live-ops content cadence, Care Pass + seasonal-event content.
> - **GAME_DECISION_LOG.md** — locked FPD verdicts, ADRs, donation-ethics decisions, reconciled conflicts, open decisions.
> - **GAME_MASTER_EXECUTION_ROADMAP.md** — phases/gates, critical path, KPI-by-phase, deferred-feature drop schedule, ASO/UA growth sequencing.
> - **GAME_EXECUTION_MASTER_SYSTEM.md** — frameworks, classification definitions, consolidation rules, AI-agent playbook, `current_state.json` schema.
> - **current_state.json** — machine-readable mirror of live project state (created Phase 0; SSOT for live state).
>
> **Reading note:** Every major feature below is tagged with its canonical FPD verdict: **MVP**, **MVP\*** (cheapest emotionally-intact form), **MVP (forced)** (dependency/legal, FPD irrelevant), **Deferred**, **Removed**, **North-Star**. These tags are reproduced verbatim from the brief's Master Table (§2).

---

## Table of Contents

1. [Design Pillars & Core Feelings](#1-design-pillars--core-feelings)
2. [Core Verbs & Interaction Model](#2-core-verbs--interaction-model)
3. [Core Gameplay Loop](#3-core-gameplay-loop)
4. [Meta Loop & Long-Term Progression](#4-meta-loop--long-term-progression)
5. [Needs / Mood / Affection Simulation Model](#5-needs--mood--affection-simulation-model)
6. [Growth & Life Stages](#6-growth--life-stages)
7. [Bond / Relationship & AI-Memory-Driven Affection System](#7-bond--relationship--ai-memory-driven-affection-system)
8. [Economy Design](#8-economy-design)
9. [Monetization Design](#9-monetization-design)
10. [Donation / Real-World Impact Loop](#10-donation--real-world-impact-loop)
11. [Retention & Engagement Systems](#11-retention--engagement-systems)
12. [Session Design & Player Journeys](#12-session-design--player-journeys)
13. [Onboarding & First-Time Experience](#13-onboarding--first-time-experience)
14. [Virality & Sharing Design](#14-virality--sharing-design)
15. [Difficulty, Pacing & Anti-Frustration](#15-difficulty-pacing--anti-frustration)
16. [Live-Service Content Loop](#16-live-service-content-loop)
17. [Telemetry-Driven Balancing Plan](#17-telemetry-driven-balancing-plan)
18. [Ethics & Player Wellbeing](#18-ethics--player-wellbeing)

---

## 1. Design Pillars & Core Feelings

### 1.1 Core Feelings (priority order — canonical)
The entire simulation is balanced to maximize these feelings, **in this order**:

1. **Attachment** — the bond with one specific, named, remembered creature.
2. **Care** — the satisfying, tactile act of tending.
3. **Responsibility** — "this little one depends on me" (never weaponized into guilt — see §18).
4. **Comfort** — the game is a calm place to return to.
5. **Empathy** — the pet has feelings; the player practices noticing them.
6. **Pride** — "look how far we've come" (growth, milestones, before/after).
7. **Meaningfulness** — real animals are helped because I played.

> **Pillar conflict resolution rule:** When two design options trade off, the one that better serves the *higher-priority* feeling wins. Concretely: **emotional attachment beats graphical fidelity, content volume, and monetization yield** (hard constraint #10). A feature that raises ARPDAU but damages Attachment/Comfort is rejected or reworked.

### 1.2 Design Pillars

| Pillar | Statement | What it forbids |
|---|---|---|
| **P-1 One pet, deeply known** | Depth over breadth. A single creature the player names, that remembers them, beats a zoo of shallow pets. | No pet-collecting pressure in MVP; 2 species max (brief §1). |
| **P-2 Cozy, never punitive** | The game can never make you feel like a bad person. Absence creates *longing*, never damage. | No death, no illness (Removed, brief §2 #29), no streak punishment. |
| **P-3 The magic is memory** | The defining wow is "it remembered me." Reliability beats breadth. | No flaky/hallucinated recall; ≥95% callback reliability gate (G2). |
| **P-4 Premium feel on indie cost** | Polish lives in motion, sound, timing, and copy — not asset count. | No AAA scope; ~140 unique assets cap (brief §4). |
| **P-5 Real impact, honestly told** | Donations are real, transparent, and never tied to the pet's wellbeing. | No charity-washing; no guilt-framed donation asks (brief §9). |
| **P-6 Buildable solo + AI** | Every system must ship and be maintained by one founder + AI agents in 12–18 months. | No system that needs a team to operate live. |

### 1.3 The Player Fantasy (north star sentence)
> *"I rescued a tiny abandoned animal, raised it with love, became emotionally attached to it, and together we made the real world a better place."*

Every loop in this doc exists to deliver one clause of that sentence: **rescued** (§13 Rescue Day), **raised** (§6 Growth), **love/attached** (§7 Bond + Memory), **better place** (§10 Donation).

---

## 2. Core Verbs & Interaction Model

### 2.1 Canonical verb set
The brief lists thirteen aspirational verbs: *adopt, feed, clean, play, talk, comfort, decorate, train, grow, donate, care, bond, share.* For MVP we implement the emotionally load-bearing subset and classify the rest:

| Verb | MVP status | Surface | Notes |
|---|---|---|---|
| **adopt** | **MVP** | Rescue Day (once) | The cold-open. Feature #1, FPD 3.33. |
| **feed** | **MVP** | Tap food prop | One of 3 core interactions (Feature #3, FPD 2.67). |
| **clean** | **MVP** | Tap/swipe bath prop | Core interaction #2. |
| **play** | **MVP** | Tap toy prop | Core interaction #3. |
| **talk** | **MVP\*** | Heartmind tap-to-chat (hybrid) | Feature #6, FPD 1.29. Pre-gen bank + memory; no live free-form at MVP. |
| **comfort** | **MVP** | Emerges from mood + talk + touch | Not a separate button; surfaces when mood is low (drives Virality moment #1). |
| **decorate** | **MVP\*** | The Nest | Feature #19, FPD 1.20. 1 room + modular palette kit. |
| **train / tricks** | **Deferred** | — | Feature #20, FPD 1.00. Animation-expensive; live-ops drop. |
| **grow** | **MVP** | Passive + milestone | Feature #5, FPD 1.80. Player witnesses, doesn't grind. |
| **donate** | **MVP\*** | Rescue Wall / ad-mint / bundles | Feature #11/#12. Never an IAP "donation"; see §10. |
| **care** | **MVP** | Umbrella of feed/clean/play/talk | The aggregate verb. |
| **bond** | **MVP** | The Bond meter (emergent) | Feature #4, FPD 4.50 (highest). Output of all verbs. |
| **share** | **MVP** | Keepsake Cards | Feature #24, FPD 2.67. 1-tap native share. |

### 2.2 Interaction model — "tap + prop + reaction"
The brief mandates **3 core interactions only**, each built as the same cheap pattern (honors asset discipline, brief §4):

```
[player tap] -> [prop appears / animates] -> [pet emotion-motion reaction (Live2D param blend, 0 new art)]
            -> [Care Meter delta] -> [Kibble micro-reward] -> [Bond micro-gain] -> [optional pet vocalization/line]
```

| Interaction | Input | Prop asset | Pet reaction (param blend) | Primary meter | Feel |
|---|---|---|---|---|---|
| **Feed** | Tap bowl, drag treat | 1 bowl + 3 food swaps (palette) | "eat" + "happy" blend | Hunger +35 | Nurture |
| **Clean** | Swipe sponge / tap bath | 1 tub + sponge + bubbles FX | "wet" + "shake-off" + "fresh" | Hygiene +40 | Tending |
| **Play** | Tap/drag toy | 1 ball + 1 feather wand (kitten) / rope (puppy) | "pounce/chase" + "tired-happy" | Happiness +30, Energy −10 | Joy / activity |
| **Touch (petting)** | Press-and-hold on pet | none (rig only) | "lean-in" + purr/tail-wag | Happiness +5, Bond +small | Affection (free) |
| **Talk** | Tap speech bubble | UI panel | mood-matched idle + chosen line | mood-gated | Connection |

> **Design rule — every tap rewards.** No interaction is ever a no-op. Even at full meters, a tap yields a happy reaction + tiny Bond/petting gain (capped, see §5.6). This is the *tactile dopamine floor* that makes the pet feel alive (Maya persona: zero tolerance for dead taps).

### 2.3 Interaction frequency budget (per session)
A healthy core session uses **5–9 interactions** in **60–180 seconds**. We do not gate interactions behind energy bars that lock the player out (anti-frustration, §15). Diminishing returns (§5.6) gently signal "you're done for now" instead of a hard wall.

---

## 3. Core Gameplay Loop

> **Canonical loop (brief):** receive notification → open game → check pet mood/needs → interact (feed/play/talk) → gain affection+rewards → unlock growth/customization → strengthen emotional bond → return later.

### 3.1 Second-to-second (in-session moment design)
The unit of fun is the **reaction beat**: tap → animation + sound + meter feedback within **≤150 ms** of input. Targets:

- **First frame of feedback:** ≤150 ms (perceived instant).
- **Full reaction motion:** 0.8–1.6 s, interruptible (player can tap again; we queue/blend, never block).
- **Idle "alive" tick:** every 6–12 s the pet performs an ambient micro-motion (blink, ear-twitch, look-at-camera, stretch) — Ambient Interactions (Feature #18, FPD 1.75, **MVP**).
- **Look-at-player:** on app foreground, the pet orients toward the camera within 1 s (the "you're home!" beat).

### 3.2 Per-session loop (the 60–180 s visit)

```
0:00  App opens -> pet notices player (look-at, greeting motion + 1 voiced/lined greeting)
0:03  Mood read: face + ambient posture + Care Meter ring glance (no numbers shouted at player)
0:08  Player addresses the most-wanted need (the pet "asks" softly via animation/icon, never nag)
0:20  2-4 care interactions (feed/clean/play) -> meters fill -> Kibble + Bond micro-gains
0:50  Optional: tap to talk -> Heartmind line (often a memory callback) -> emotional beat
1:30  Optional: visit The Nest / Cosmetics / Rescue Wall
1:50  Soft exit cue: pet settles, "see you soon" beat; Care Streak ticked; no FOMO popup
```

**Two valid session shapes** (we design for both):
- **Quick-check (30–60 s):** glance mood, top up the one low meter, one petting, done. (David, busy adult.)
- **Cozy-dwell (3–8 min):** all of the above + talk + decorate + share. (Maya/Tom on a lazy evening.)

### 3.3 Detailed loop with system hooks

| Step | Player action | System response | Doc reference |
|---|---|---|---|
| Trigger | Receives pet-voiced notification | Local-scheduled, 1–2/day cap, warm tone | §11; GAME_TECHNICAL_SYSTEMS.md |
| Open | Foregrounds app | Offline-catch-up sim resolves elapsed time; pet greets | §5.7 |
| Read | Glances at pet | Mood state shown via face/posture/ring; Memory Book badge if new memory | §5.5, §7 |
| Interact | Feed/clean/play/touch | Meter deltas, Kibble drip, Bond micro-gain, emotion reaction | §2.2, §5 |
| Talk | Taps speech bubble | Heartmind selects state+memory-aware line from bank | §7; GAME_TECHNICAL_SYSTEMS.md |
| Reward | (passive) | Kibble accrues; milestone checks fire | §8 |
| Unlock | Reaches threshold | New Bond stage / life stage / cosmetic / Memory Book entry | §6, §7 |
| Strengthen | (emergent) | Bond number rises; personality dials nudge | §7 |
| Return | Backgrounds app | Streak Warmth banked; next notification scheduled | §11 |

### 3.4 The "no empty session" guarantee
Every open must deliver **at least one** of: a fresh greeting line, a memory callback, a met need, a Kibble tick toward a visible goal, or a new ambient behavior. The session-quality telemetry event (`session_quality`, §17) fires `empty=true` if none occurred — a leading churn indicator we actively balance against.

---

## 4. Meta Loop & Long-Term Progression

> **Canonical meta loop (brief):** daily care → relationship growth → pet evolves/matures → unlock stories/memories → earn donation currency → help real shelters → feel meaningful impact → continue caring.

### 4.1 The three nested loops

| Loop | Cadence | Driver | Payoff feeling |
|---|---|---|---|
| **Micro (session)** | minutes | Care Meters, taps, Kibble | Care, comfort |
| **Meso (days/weeks)** | days | The Bond stages, Care Streak, cosmetics | Attachment, pride |
| **Macro (weeks/months)** | weeks–months | Life Stages, Memory Book, Compassion Coins / real impact | Meaningfulness, pride |

### 4.2 Progression spine (what unlocks, when, why)

| Time horizon | Unlock | Gating system | Emotional purpose |
|---|---|---|---|
| Minute 0 | The pet (Rescue Day) | onboarding | Attachment ignition |
| Hour 1 | Naming, first room, first 3 care verbs | tutorialized | Ownership |
| Day 1–3 | Bond: **Stranger → Friend**; first Memory Book entries | Bond points | "It's warming to me" |
| Day 3–7 | **Pup/Kit → Young One** life-stage; first cosmetics | Bond + days elapsed | "It's growing" (pride) |
| Week 2–4 | Bond: **Friend → Companion**; personality dials become noticeable | Bond + interaction variety | "It has a personality" |
| Week 4–8 | **Young One → Grown**; before/after Keepsake unlock | Bond + days elapsed | "Look how far we've come" |
| Week 4+ | First real disbursement reflected on Rescue Wall | Compassion Coins → Impact Pool cadence | "We helped real animals" |
| Month 2–3 | Bond: **Companion → Kindred** | sustained bond | Deep attachment (title moment) |
| Month 3+ | Bond: **Kindred → Soulmate**; Gotcha Day anniversary | long-term retention | Pride, ritual, WOM |

### 4.3 Progression philosophy
- **Time-and-care gated, not grind-gated.** Major beats (life stages, top Bond tiers) require *both* a Bond threshold *and* real elapsed days. You cannot whale your way to a Soulmate in a weekend — attachment is earned in calendar time. This protects the fantasy and naturally paces content for a solo dev.
- **No power progression, no fail states.** Progression unlocks *expression, story, and depth*, never combat power. There is nothing to "lose."
- **Growth is witnessed, not ground.** See §6 — the player's job is to *be present*, not to optimize a stat.

---

## 5. Needs / Mood / Affection Simulation Model

> Features: **Care Meters** (#2, FPD 2.67, **MVP**), **The Bond** (#4, FPD 4.50, **MVP**). The simulation runs **client-side, deterministic, elapsed-time-based, server-validatable** (brief §6). All numbers below are **launch defaults**, tuned via telemetry (§17). Stored as floats; displayed as soft visuals, not raw numbers.

### 5.1 The four Care Meters

| Meter | Range | Decay rate (per real hour) | Restore per interaction | Natural recovery |
|---|---|---|---|---|
| **Hunger** | 0–100 | −5.0/h | Feed +35 | none (must feed) |
| **Energy / Sleep** | 0–100 | −3.5/h (awake) | Play −10 (costs energy); rest +20/h while pet sleeps | regenerates during pet sleep window |
| **Hygiene** | 0–100 | −2.5/h | Clean +40 | none (must clean) |
| **Happiness** | 0–100 | −4.0/h | Play +30, Feed +10, Touch +5, good Talk +8 | small passive +1/h if other 3 meters > 60 |

**Decay design intent:** at default rates, a pet left fully topped (all 100) reaches the **"sad but safe" floor** in roughly **12–18 hours of total neglect**, i.e. one missed day brings it to longing, not crisis. A single ~90-second session fully restores all meters.

### 5.2 The no-death floor (hard constraint, Risk R4)
> **HARD RULE:** No meter ever falls below the **"sad but safe" floor** of **15**. The pet can become sad, sleepy, mopey, or wistful — it can **NEVER** become sick, suffer, or die (Health/Illness/Vet = **Removed**, brief §2 #29).

- Floor value: **15** (configurable via remote config).
- Below ~30 on any meter, the pet shows gentle "I miss you / I could use some care" body language — *invitational, never accusatory*.
- The floor means a returning lapsed player **always** finds a pet that's happy to see them, not a guilt-bomb. This directly protects the David and Leo-&-Parent personas.

### 5.3 Mood state machine (4 states)
Mood is a **derived** value, not stored independently. Computed each tick from meters + recent interaction history + Bond + personality dials.

```
mood_score = 0.30*Happiness + 0.25*Hunger + 0.20*Energy + 0.15*Hygiene + 0.10*recent_attention_bonus
recent_attention_bonus = clamp(minutes_since_last_positive_interaction mapped to 0..100, decaying)
```

| Mood state | mood_score band | Pet behavior | Bond gain modifier |
|---|---|---|---|
| **Joyful** | 75–100 | bouncy idles, seeks play, frequent happy lines | ×1.15 |
| **Content** | 50–74 | relaxed, ambient life, normal | ×1.00 |
| **Wistful** | 30–49 | softer, looks toward door, gentle sighs | ×1.00 (never penalize for the pet being low) |
| **Low / Needs comfort** | 15–29 | curled up, slow blinks, quiet | ×1.00; **unlocks the Comfort moment** (Virality #1) |

> **Critical balance rule:** Low mood **dampens Bond *gain* only never reverses Bond** (brief §5). A sad pet you then comfort yields a *higher-quality* emotional beat (and a shareable moment), so low mood is an opportunity, not a punishment.

### 5.4 The Bond (the single most important number)
The Bond is a monotonically **non-decreasing** lifetime relationship score. **It never goes down.** (Brief: "only dampen Bond *gain*, never reverse it.")

**Bond point sources (per action, launch defaults):**

| Source | Bond points | Daily soft cap | Notes |
|---|---|---|---|
| First daily greeting / app open | +5 | 1/day | Rewards returning |
| Feed (when hungry) | +2 | — | Diminishing (§5.6) |
| Clean (when dirty) | +2 | — | Diminishing |
| Play (when willing) | +3 | — | Diminishing |
| Petting/touch | +0.5 | cap 10/session | The free affection drip |
| Talk — ordinary line | +2 | — | |
| Talk — **memory callback** lands | +8 | — | The highest per-tap Bond beat |
| Comfort a Low-mood pet | +10 | 1/low-episode | The signature beat |
| Care Streak day completed | +6 | 1/day | Habit reinforcement |
| Life-stage milestone | +50 | per stage | Macro payoff |

**Daily Bond ceiling:** ~**45–60 points/day** from routine play (soft-capped via diminishing returns) so the player can't binge to the top tier; calendar time is required (see §5.6, §7.2).

### 5.5 How the player perceives state (no naked numbers)
We **do not** show "Hunger: 43%." Instead:
- A single subtle **Care ring** around the pet whose segments dim as needs drop.
- The pet's **face, posture, and ambient behavior** are the primary read (empathy practice — Pillar feeling #5).
- A soft **need icon** floats up only when a meter is low (invitational).
- The Bond is shown as a **filling heart / stage label** ("Friend"), not "Bond: 1,240."

This keeps the experience cozy and "premium" (not a spreadsheet) and makes the player *read the animal*, which deepens empathy.

### 5.6 Diminishing returns (anti-grind, anti-spam)
To prevent meaningless tap-spam and to gently signal "you're done," each interaction type applies a within-session decay:

```
effective_gain = base_gain * (0.6 ^ n)   // n = number of times this interaction used this session, capped
```
- 1st feed: full. 2nd: ×0.6. 3rd: ×0.36. After meter hits 100, gain → tiny "petting-equivalent" Bond only.
- This is **invisible** to the player (no scary "diminished!" text) — the pet just gets visibly satisfied/full, a natural stop cue.

### 5.7 Offline catch-up & elapsed-time resolution
On foreground, the client computes elapsed real time since last close and resolves decay deterministically (server-validatable). Rules:
- **Grace window:** first **8 hours** of absence decays at **50%** rate ("the pet napped / was content"), softening the return.
- Beyond 8h, full decay applies but **never below floor 15**.
- The returning pet **always greets warmly**; if absence was long, it shows *longing-then-joy* ("I missed you — you're back!"), never sulking. (Risk R6 mitigation; David/Leo personas.)
- Edge cases (clock tampering, timezone shifts) handled server-side; see GAME_TECHNICAL_SYSTEMS.md.

### 5.8 Tuning table (remote-config keys)
All values above are remote-config-driven for live balancing without a client update:

| Key | Launch default | Safe range |
|---|---|---|
| `decay.hunger_per_h` | 5.0 | 3–8 |
| `decay.energy_per_h` | 3.5 | 2–6 |
| `decay.hygiene_per_h` | 2.5 | 1.5–5 |
| `decay.happiness_per_h` | 4.0 | 2–7 |
| `meter.floor` | 15 | 10–20 (never 0) |
| `offline.grace_hours` | 8 | 4–24 |
| `offline.grace_decay_mult` | 0.5 | 0.25–0.75 |
| `bond.daily_soft_cap` | 55 | 40–80 |
| `bond.memory_callback_pts` | 8 | 5–12 |

---

## 6. Growth & Life Stages

> Feature **Growth / Life-Stages** (#5, FPD 1.80, **MVP**). The brief flags this as the **#1 art-cost lever**, hard-capped at **3 stages × 2 species** (brief §4). Stages are achieved via **rig parameter / scale changes, NOT new rigs** (Risk R7).

### 6.1 The three life stages (canonical names)

| Stage | Canonical name | Real-time to reach | Bond gate | Visual delta (rig param/scale, 0 new rig) |
|---|---|---|---|---|
| 1 | **Pup/Kit (infancy)** | Day 0 (Rescue Day) | — | Smallest scale, big eyes/head ratio, wobbly idles |
| 2 | **Young One (juvenile)** | ~Day 5–7 | Bond ≥ "Friend" + ≥5 active days | Mid scale, more confident motion |
| 3 | **Grown (adult)** | ~Day 28–35 | Bond ≥ "Companion" + ≥28 active days | Full scale, calm/assured idles |

> **Dual gate:** advancement requires **both** a Bond stage **and** elapsed *active* days (days with ≥1 session). This guarantees the "I raised it over time" fantasy and prevents pay-to-skip (you cannot buy a Grown pet — it must be lived).

### 6.2 What changes per stage
- **Scale + proportions:** driven by Live2D rig deformer params (cheap; see GAME_CONTENT_FACTORY.md). 6 life-stage skins total (2 species × 3) — counted in the ~140 asset cap.
- **Behavior:** idle motion set shifts (clumsy → playful → composed). Reuses the same 12 emotion motions, re-timed/blended (0 new art).
- **Voice/line tone:** Heartmind persona dials shift slightly older/calmer (parameter only, no new model).
- **Capabilities:** more Nest decoration slots unlock; new cosmetic categories become wearable.

### 6.3 The growth payoff moments (pride + virality)
- **Stage-up ceremony:** a short (8–12 s) celebratory beat, +50 Bond, a new Memory Book page, and an auto-offered **Before/After Keepsake Card** (Virality #3) showing the scared Rescue-Day pup vs. the thriving current stage with elapsed-day count.
- **Gotcha Day:** the adoption anniversary (Rescue Day + 365d, and minor monthly markers) triggers a special ceremony + Keepsake. (Virality #4.)

### 6.4 What is explicitly NOT in growth (scope guard)
- ❌ No breeding, no offspring, no aging-to-death, no decline. Growth is **one-directional and terminal at "Grown"** — the pet then lives happily as an adult indefinitely.
- ❌ No per-stage new rigs (would blow the budget; Risk R7).
- ❌ **More species/breeds beyond 2** = **Deferred** (#28); breed palette-swaps come first in live-ops, new rig later.

---

## 7. Bond / Relationship & AI-Memory-Driven Affection System

> Features: **The Bond** (#4, **MVP**), **Heartmind dialogue HYBRID** (#6, FPD 1.29, **MVP\***), **AI Memory / Memory Book** (#7, FPD 1.67, **MVP**), **Evolving Personality** (#8, FPD 1.75, **MVP**), **Child-Safety Moderation** (#9, **MVP forced**). Live free-form chat (#6b) = **Deferred**. Detailed dialogue/memory/safety implementation lives in **GAME_TECHNICAL_SYSTEMS.md**; this section covers the *gameplay/affection* design only.

### 7.1 The five Bond stages (canonical)

| Stage | Bond points to enter | Approx. real-time (typical) | What it unlocks emotionally |
|---|---|---|---|
| **Stranger** | 0 | Rescue Day | Cautious pet, short lines, learning your name |
| **Friend** | 250 | ~Day 2–3 | Warmer greetings, first proactive affection |
| **Companion** | 1,200 | ~Week 2–4 | Personality clearly emerged; proactive comfort; deeper callbacks |
| **Kindred** | 4,000 | ~Month 2–3 | Trust language; remembers many facts; inside jokes |
| **Soulmate** | 10,000 | ~Month 4–6+ | Fullest expression; richest memory tapestry; ritual moments |

> Stage thresholds are intentionally spaced so that, at the ~45–60 Bond/day soft cap, top tiers require **months** of real relationship — this is the retention engine and the "earned, not bought" guarantee. Tuned via `bond.stage_thresholds` remote config.

### 7.2 The "it remembered me" system (the load-bearing magic — Risk R3)
This is the **single most important differentiator** and the most-watched risk. Design rules:

- **Hybrid, not live (MVP).** The pet's lines come from an **offline-pre-generated, human-reviewed dialogue bank**, selected at runtime by pet-state + Bond stage + personality dials, with **structured memory facts injected** into the chosen line via templating. (Brief Resolution #1.) Live free-form LLM chat is **Deferred (#6b)**, age-gated + subscriber-only post-soft-launch.
- **Narrow + reliable beats broad + flaky.** We store **10–30 durable facts** per player (e.g., "favorite color = blue," "has a real dog named Rex," "had a hard week on Apr 3"). A *few* facts surfaced *reliably* beat many surfaced flakily. (Brief §6; Risk R3.)
- **≥95% callback reliability** with **zero hallucinated facts** is a hard gate at **G2** (brief §10). A callback that invents a fact is a P0 bug.
- **The Memory Book** (Feature #7) is the player-visible journal artifact — a tangible, scrollable record of remembered facts and milestones. It is the **provable trust signal** (per the My Talking Tom / Tom-persona mandate): the player can *see* that the memory is real, which converts "AI theater" skepticism into delight.
- **Anti-repetition rotation:** the bank tracks recently-used lines per player and rotates; "noticed AI repetition" is an instrumented leading churn indicator (§17, brief §10). Target: a player should not see the same non-callback line twice within a rolling 14-day window.

### 7.3 Memory → Affection coupling
- Landing a **memory callback** is the single highest per-tap Bond beat (**+8**, §5.4) and the #1 viral trigger (Virality #2).
- Memory entries are *earned by talking*; the more (safely) the player shares, the richer the Memory Book, the more callbacks, the deeper the Bond. This is a virtuous, non-coercive loop.
- **Under-13 handling:** templated/non-generative only; **no free-text storage from minors** (Risk R1; GAME_TECHNICAL_SYSTEMS.md). The Memory Book for kids is built from *gameplay events* (milestones, favorites chosen via taps), not typed input.

### 7.4 Evolving personality (Feature #8)
- The pet has **prompt-parameterized personality dials** (e.g., playfulness, shyness, talkativeness, sweetness) that **drift slowly** based on how the player interacts (lots of play → more playful; lots of quiet petting → more mellow).
- ~0 marginal cost (parameters, not assets). Deepens the D30 bond and feeds Virality #7 ("only MY pet would say this").
- Drift is **slow and bounded** (max small delta per week) so the pet stays recognizably *itself* — identity stability is part of attachment.

### 7.5 Bond never punishes
Reiterating the hard rule across systems: **Bond is monotonic non-decreasing.** Absence, low mood, and lapses can slow *gain* but never reduce the number, never drop a stage, never "forget" facts. (Risk R6.)

---

## 8. Economy Design

> Three currencies (brief §5). Features: **Cosmetics Shop** (#21, FPD 1.50, **MVP**), **Subscription** (#22, **MVP\***), **Ads** (#23, **MVP**), **Donation engine** (#11, **MVP\***). **NO gacha / loot boxes** (brief §5). Detailed monetization in §9; donation specifics in §10; donation ledger/anti-fraud backend in GAME_TECHNICAL_SYSTEMS.md.

### 8.1 The three currencies (canonical)

| Currency | Type | How earned | What it buys | Gameplay power? |
|---|---|---|---|---|
| **Kibble** | Soft, abundant | Care actions, daily login, streaks, rewarded ads | Delight items, common Nest decor, treats | **None** — buys *delight only* |
| **Heartstones** | Premium, scarce | IAP purchase + milestone grants | Premium cosmetics, Nest sets, cosmetic-only | **None** — horizontal cosmetics only |
| **Compassion Coins** | Impact | Rewarded-ad watch, purchases, subscription, milestones | Nothing purchasable; maps 1:1 to real outcomes | **Zero** — non-tradeable, non-convertible |

> **Anti-pay-to-win guarantee:** No currency buys the Bond, life stages, memory, or any progression. All purchases are **horizontal cosmetic** or **representational impact**. This is non-negotiable (Pillar P-2, P-5).

### 8.2 Kibble economy (soft)

**Sources (launch defaults, per day for an engaged player):**

| Source | Kibble | Cap |
|---|---|---|
| Daily first-open bonus | 50 | 1/day |
| Care interactions | ~3–5 each | soft via diminishing returns |
| Care Streak day | 25 | 1/day |
| Streak milestone (7/30/100 days) | 100/300/1000 | per milestone |
| Rewarded ad (Kibble option) | 30 | shares the 4–6/day ad cap |
| Watching pet hit a Care goal | 20 | a few/day |

Typical engaged daily Kibble income: **~180–280**.

**Sinks:**

| Sink | Cost (Kibble) | Purpose |
|---|---|---|
| Common treats (cosmetic food) | 10–30 | micro-delight |
| Common Nest decor | 150–600 | expression |
| Common cosmetic pieces | 200–800 | expression |
| Streak Warmth repair (small) | 100 | forgiving catch-up (§11) |

**Balance intent:** a free player earns a meaningful common cosmetic roughly every **2–4 days** — steady delight without trivializing premium. Kibble is *abundant by design*; it is the "you always have something to spend" floor that keeps F2P players feeling rewarded.

### 8.3 Heartstones economy (premium)

**Sources:**
- **IAP** (see §9 pricing).
- **Milestone grants:** life-stage ups (+15 each), Bond-stage ups (+25 each), Gotcha Day (+50). These let non-payers occasionally taste premium cosmetics → conversion nudge done *generously*, never coercively.
- **Subscription drip:** Forever Friends grants monthly Heartstones (§9.3).

**Sinks:** premium cosmetics, premium Nest sets, special-event cosmetics. **~30 cosmetic pieces at launch** (brief §4); priced **20–120 Heartstones**.

### 8.4 Compassion Coins economy (impact)
Covered in depth in §10. Key economy facts:
- Earned via **rewarded-ad watch** (every watch mints Coins — even free players generate real impact), purchases, subscription, milestones.
- **Maps 1:1 to real outcomes** (e.g., **50 Coins = 1 real meal**) — illustrative, always rounded **DOWN** (brief §9, under-promise/over-deliver).
- **Non-tradeable, non-convertible, zero gameplay power** — this also kills laundering (anti-fraud, brief §5).
- **Server-side mint-gating** (S2S postbacks + receipt validation + attestation) — Anti-fraud platform-native is **MVP (forced)** (#13); see GAME_TECHNICAL_SYSTEMS.md.

### 8.5 Economy balance guardrails
- **No currency can be exchanged into another** (no Kibble→Heartstone, no Coin conversion).
- **No timers-as-paywalls** that block the core loop (no "wait 4h or pay" on feeding).
- **No FOMO bundles that exploit attachment** (e.g., never "buy this or your pet stays sad").
- Daily faucet/sink modeled in a spreadsheet (`economy_model.xlsx`, maintained alongside `current_state.json`); re-tuned via remote config and §17 telemetry.

---

## 9. Monetization Design

> **Hybrid F2P:** ads + subscription + cosmetic IAP + donation-linked bundles. Gross-revenue mix and LTV assumptions are canonical (brief §5). **Premium feel, never predatory** (Pillar P-4, P-2). All placements honor child-safety (Risk R1, R10).

### 9.1 Revenue mix (canonical targets, brief §5)

| Stream | Design | Est. % gross | Verdict |
|---|---|---|---|
| Rewarded + sparse interstitial ads | Rewarded-first, opt-in, ~4–6/day cap; ≤1 interstitial/session at natural breaks; **never mid-emotion**; kids see contextual-only or none; every watch mints Compassion Coins | **45–55%** | #23 **MVP** |
| Subscription (**Forever Friends**) | $5.99/mo · $39.99/yr; removes interstitials, daily Kibble, monthly Heartstones + Coins, cosmetic drip, higher donation match | **30–40%** (LTV anchor) | #22 **MVP\*** |
| Cosmetic IAP (Heartstone bundles + packs) | Horizontal cosmetics only; direct purchase; **NO gacha/loot boxes** | **10–20%** | #21 **MVP** |
| Donation-linked **Rescue Bundles** | Stated split (e.g., 70% donation / 30% cosmetic+fee), disclosed pre-purchase + receipt | **5–10%** (outsized trust/virality) | #11 **MVP\*** |

### 9.2 Ads — placement & ethics (Feature #23, MVP)
- **Rewarded-first.** The default and dominant format. Player *opts in* for a clear benefit (Kibble, a cosmetic try-on, a Compassion Coin mint, a Streak Warmth top-up).
- **Cap:** **4–6 rewarded/day**; **≤1 interstitial per session**, only at **natural breaks** (e.g., after closing the Nest, never mid-care, never mid-Heartmind line).
- **Never mid-emotion:** no ad ever interrupts a comfort beat, a memory callback, a stage-up, or Rescue Day.
- **Kids:** under-13 see **contextual-only or no ads**; **no behavioral targeting** (COPPA/GDPR-K; Risk R1). Mediation SDK runs with COPPA/kids flags (GAME_TECHNICAL_SYSTEMS.md).
- **Every rewarded watch mints Compassion Coins** → even purely-free players generate real impact (the "ad-funded daily kind act," brief §9).

### 9.3 Subscription — Forever Friends (Feature #22, MVP\*)
- **Single tier** (no confusing ladder). **$5.99/mo · $39.99/yr** (~44% annual discount). Final price validated in soft launch (G4, Open Decision #8).
- **Benefits (all cozy/QoL/cosmetic — never pay-to-win):**
  - Removes interstitials (calm, ad-light experience — David's stated willingness to pay).
  - Daily Kibble bonus + **monthly Heartstones + Compassion Coins** grant.
  - Cosmetic drip (a rotating exclusive piece monthly).
  - **Higher donation match** (subscriber dollars carry a larger Impact Pledge slice — turns paying into pride, not guilt).
  - (Post-soft-launch) access to **gated live Heartmind chat** for verified adults (#6b Deferred).
- **Financial role:** the **LTV anchor and the lever that funds LLM OPEX** (Risk R2). Sub cohort LTV **$30–80+**. Conversion target **1–3% MAU**; gate G6 ≥2%.
- **Ethics:** cancel any time, no dark-pattern retention, no "your pet will be sad if you cancel." The pet is unaffected by subscription status (hard ethical wall, §18).

### 9.4 Cosmetic IAP (Feature #21, MVP)
- **Heartstone bundles** (currency) + occasional **direct cosmetic packs**.
- **Horizontal only:** outfits, Nest sets, accessories, color variants — overlay sprites + palette-swaps (~30 pieces at launch, brief §4). **No gacha, no loot boxes, no randomized purchases** (brief §5).
- ARPPU target **$8–20** (brief §5).

**Indicative Heartstone bundle pricing (validate in soft launch):**

| Bundle | Price | Heartstones | Bonus |
|---|---|---|---|
| Pawful | $1.99 | 100 | — |
| Basket | $4.99 | 280 | +12% |
| Hearts | $9.99 | 600 | +20% |
| Devoted | $19.99 | 1,300 | +30% |

### 9.5 Donation-linked Rescue Bundles (Feature #11, MVP\*)
- **Commercial purchases**, NOT charitable donation IAP (brief Resolution #4; store-policy compliant).
- Each bundle shows an **explicit split** pre-purchase (e.g., **70% donation / 30% cosmetic + fee**) and issues a **receipt** with the disclosed split.
- Pairs a cosmetic (so it's a legitimate purchase) with a disclosed donation slice flowing to the **Impact Pool** → intermediary → vetted shelter.
- Outsized **trust + virality** per dollar (Priya/David personas). See §10; ledger/anti-fraud backend in GAME_TECHNICAL_SYSTEMS.md.

### 9.6 Monetization ethics commitments (hard)
- ✅ No pay-to-win (no currency buys Bond/growth/memory).
- ✅ No gacha/loot boxes.
- ✅ No FOMO that exploits the pet's wellbeing or the player's attachment.
- ✅ No ads mid-emotion; no kid behavioral targeting.
- ✅ All bundle splits disclosed pre-purchase.
- ✅ Subscription cancellation never harms the pet.
- Full anti-dark-pattern list in §18.

---

## 10. Donation / Real-World Impact Loop

> Features: **Donation/Impact Engine** (#11, FPD 1.33, **MVP\***), **Rescue Wall** (#12, FPD 2.33, **MVP**), **Anti-fraud platform-native** (#13, **MVP forced**). Policy and trust pillars are canonical in the brief §9; the ledger/intermediary/anti-fraud backend is detailed in **GAME_TECHNICAL_SYSTEMS.md** and the locked donation-ethics decisions in **GAME_DECISION_LOG.md**. This section covers the **player-facing experience** only.

### 10.1 The model in one line (player-facing)
> "A percentage of the money KindredPaws earns goes to real, vetted animal shelters — and you can watch it add up."

Mechanically (brief §9, Resolution #4): **% of NET revenue → segregated Impact Pool ledger → disbursed on a fixed cadence through an established giving-platform intermediary (PayPal Giving Fund / Percent / Benevity) to 1–3 vetted partners.** Compassion Coins are an **in-app representation of that pooled real allocation** — **NOT** tax-deductible player donations. **No donation IAP. No player tax-deductible donations in MVP.**

### 10.2 The player-facing impact loop

```
play (free or paid) -> mint Compassion Coins (ad watch / purchase / sub / milestone)
   -> Coins accrue on the Rescue Wall, mapped 1:1 to real outcomes (e.g., 50 Coins = 1 meal)
   -> on fixed cadence, real NET-revenue % is disbursed via intermediary to named shelters
   -> Rescue Wall updates with dated receipts + partner acknowledgments
   -> player feels meaningful impact -> shares Real-Impact Keepsake -> continues caring
```

### 10.3 The Rescue Wall (Feature #12, "Our Impact" tab)
A data-driven dashboard (cheap to build, high felt-trust). Shows:
- **Personal contribution:** "Your play has helped fund **X meals / Y vaccinations**" (outcome-based, always rounded **DOWN**).
- **Community total:** lifetime real impact across all players (the only MVP multiplayer-adjacent feature — community counter, not social).
- **Live campaign bars:** current shelter campaign progress.
- **Dated, downloadable receipts** + partner acknowledgments.
- **"Impact verified through <date>"** third-party badge (past a volume threshold; trust pillar #7).

### 10.4 Compassion Coins (player experience)
- Minted on **rewarded-ad watch** (free players included), purchases, subscription, milestones.
- **Server-side mint-gated** (S2S signed ad postbacks + receipt validation + App Attest/Play Integrity) — only **network-PAID impressions** mint Coins; **clawback on refund/chargeback**; disburse only after settlement window (anti-fraud MVP, brief §5). **Non-transferable/non-convertible** kills laundering.
- Display: a gentle counter on the Rescue Wall and a small celebratory beat when a real-outcome threshold is crossed (Virality #5).

### 10.5 The HARD ETHICAL WALL (non-negotiable — Risk R5)
> **NEVER tie the virtual pet's wellbeing or survival to real donations. NEVER guilt-frame a donation ask.** The pet is *always* fine regardless of whether the player ever spends a cent (no-death floor, §5.2). Donations are framed as **shared pride** ("look what *we* did"), never **obligation** ("your pet needs you to donate").

- Free players still generate **real impact** via ad-funded daily "kind act" Coins — so the meaningfulness fantasy is available to *everyone*, not just payers.
- All impact claims are **outcome-based, rounded down, under-promise/over-deliver** (brief §9 trust pillar #4).
- Single **version-stamped Impact Pledge** doc is the SSOT for all "X% of revenue" claims (always stated **net**).

### 10.6 Open decisions affecting this loop (resolve per brief §12)
- Donation **intermediary** + initial 1–3 partner shelters → decide **before G4** (#4).
- Exact **donation % per revenue type** (net) → finalize with accounting/legal **before G4** (#5).

---

## 11. Retention & Engagement Systems

> Features: **Care Streak + Streak Warmth** (#17, FPD 3.50, **MVP**), **Notifications (pet-voiced)** (#16, FPD 3.50, **MVP**), **Home-Screen Widget** (#14, FPD 1.60, **MVP**), **Ambient Interactions** (#18, **MVP**), **Companion Presence** umbrella. Lock-Screen Widget / Live Activities (#15) = **Deferred**. **Ethical FOMO only** — warm/invitational, never punitive (Risk R6).

### 11.1 Care Streak (Feature #17) — forgiving by design
- A **Care Streak** increments on any day the player completes at least one meaningful care action.
- **Rewards** at 3/7/30/100 days (Kibble + Heartstone grants + a Memory Book milestone page + an optional Keepsake).
- **NEVER punitive:** a broken streak does **not** harm the pet, reduce the Bond, or scold. The pet is just happy you're back.

### 11.2 Streak Warmth (the forgiveness layer — Risk R6 mitigation)
- **Streak Freeze:** the streak auto-protects on a missed day, up to a bank (e.g., **2 freezes/week**, regenerating). The player sees "Your streak stayed warm 🔥" not "STREAK LOST."
- **Streak Repair:** a recently-broken streak can be restored for a small Kibble cost (100) or a rewarded-ad — once per lapse. Frames a return as a *welcome back*, not a penalty.
- Philosophy: streaks exist to **reward consistency**, not to **punish absence**. The highest-LTV personas (David, busy adult) churn instantly from punitive streaks (Risk R6).

### 11.3 Notifications (Feature #16) — pet-voiced, capped, warm
- **Local-scheduled** in MVP (no push cost; brief §6). FCM/APNs for templated lines as a later option.
- **Cap: 1–2/day.** Tone is **warm/invitational, never guilt** ("Mochi found a sunbeam and thought of you ☀️"), never "Your pet is starving!"
- Timing personalized to the player's habitual session window (computed client-side).
- **Best lines reference memory/personality** ("Biscuit is still thinking about the walk you mentioned") — turns a notification into a micro-memory-callback (highest retention lever, FPD 3.50).
- **Kids/parents:** notification frequency respects parental settings; never manipulative.

### 11.4 Home-Screen Widget (Feature #14, Companion Presence)
- The centerpiece of "my pet lives with me." Shows a **pre-rendered mood image** (not live rig render — cheap; brief §6), pet name, and a tiny status (mood + maybe Care ring).
- Driven by a **single shared "pet status snapshot" payload** that also feeds the notification scheduler (one payload, two surfaces — asset/eng discipline).
- The widget **is the ambient ad** (Virality #6: "Widget Candids" — players screenshot endearing widget moments directly).
- **Lock-Screen Widget / Live Activities (#15) = Deferred** — incremental over the home widget; fast-follow in live-ops (P6) once the pipeline is proven.

### 11.5 Ambient Interactions (Feature #18) — the pet has a life
- Idle micro-behaviors (§3.1) + scheduled "candids" (napping in a sunbeam, chasing a leaf) that make the pet feel autonomous.
- Pure **sequencing of existing assets** (0 new art; FPD 1.75). Feeds widget candids and in-app delight.

### 11.6 Daily/return structure (ethical FOMO)
- **Daily first-open bonus** (50 Kibble) — a gentle reason to return, not a punishment for not.
- **Rotating tiny daily delight** (a new ambient moment, a seasonal prop) — *curiosity* pull, not *loss aversion* push.
- **No timed-loss mechanics** (no "log in within 24h or lose your reward"). All "FOMO" is **opportunity-framed** (something nice waiting), never **loss-framed** (something taken away).

### 11.7 Retention targets (canonical, brief §7 & §10)

| Metric | Target | Gate |
|---|---|---|
| D1 | ~45% (40–48) | G3 ≥40%, G4 ≥42% |
| D7 | ~20–22% (18–25) | G3 ≥18%, G4 ≥20% |
| D30 | ~10–12% (8–14) | G4 ≥10%, G6 hold ≥10% |
| Worst case (AI memory disappoints) | D30 → ~5–6% (genre median) | — |

**Mandatory leading churn indicators to instrument** (brief §10): **"noticed AI repetition"** and **"felt guilt-tripped about the pet."** These predict D7/D30 collapse before raw numbers move. See §17.

---

## 12. Session Design & Player Journeys

> Tied to the five canonical playtest personas (brief §7). Each journey converts findings into concrete design (AI Playtester mandate).

### 12.1 Session archetypes

| Archetype | Length | Trigger | Core content |
|---|---|---|---|
| **Glance** | 10–30 s | Widget / notification | Read mood, one care action, petting |
| **Quick-care** | 30–90 s | Habit / notification | Top meters, daily bonus, one talk |
| **Cozy-dwell** | 3–8 min | Evening wind-down | Full care + talk + Nest + share |
| **Milestone** | 1–3 min | Stage-up / Gotcha Day | Ceremony, Keepsake, Memory Book |

### 12.2 D1 journey (first day — must hook)

| Persona | D1 experience | Design guarantees |
|---|---|---|
| **Maya** (Gen-Z TikTok) | Rescue Day cold-open lands in <90 s; first comfort/cute moment; **zero latency on first AI line** (G2) | Spinner-free first Heartmind line (pre-gen); shareable comfort beat |
| **David** (busy adult) | Adopts, names, sets up widget, gets low-pressure first session | Widget setup prompt D1; no guilt; quick-care path works |
| **Leo & Parent** | Parent vets safety; child does Rescue Day + first care | Visible child-safe framing; templated dialogue for under-13 |
| **Tom** (nostalgic) | Notices the pet *learns his name*; first memory seed planted | First Memory Book entry created D1 (the seed of the magic) |
| **Priya** (donor) | Sees the Rescue Wall exists + honest framing, even at $0 | "Even free play helps" message; no donation hard-sell D1 |

**D1 success target:** D1 ≥40% (G3) / ≥42% (G4). The Rescue Day hook + first memory seed are the D1 retention levers.

### 12.3 D7 journey (the habit + first growth)

- By D7 the pet has typically reached **Young One** (life stage 2) and **Friend** (Bond stage 2).
- The player has a **Care Streak** going (with Streak Warmth catching any miss).
- First **before/after potential** is seeding (Rescue-Day image stored for the eventual Keepsake).
- **Tom's "would I tell a friend?" test** must pass here: at least one memory callback has landed reliably.
- **D7 target:** ≥18% (G3) / ≥20% (G4).

### 12.4 D30 journey (the payoff — the make-or-break)

- Pet approaching/at **Grown** (life stage 3); Bond at **Companion** trending to **Kindred**.
- The **Memory Book** now holds weeks of facts → **long-memory callbacks** (Virality #2) fire → the defining "it remembered me" moment.
- **Before/After Keepsake** (scared rescue → thriving Grown) becomes available — the highest-WOM share for David's cohort.
- First **real disbursement** reflected on the Rescue Wall → Priya/David meaningfulness payoff.
- **D30 target:** ≥10% (G4). **This is bimodal** (brief §7): hinges on (a) AI-memory authenticity and (b) the forgiving-absence model. If memory disappoints → D30 collapses to ~5–6%. Hence Risk R3 is Critical and gated at G2.

### 12.5 Persona-to-design conversion table (every finding → a change)

| Persona friction risk | Design change in this doc |
|---|---|
| Maya: latency/repetition = instant churn | Pre-gen first line (0 spinner, §7.2); anti-repetition rotation (§7.2); instrumented "noticed AI repetition" (§17) |
| David: guilt/punishment = churn | No-death floor (§5.2); Streak Warmth (§11.2); longing-not-sulking return (§5.7) |
| Tom: "AI theater" skepticism | Tangible Memory Book (§7.2); ≥95% callback reliability gate (G2); narrow+reliable design |
| Priya: charity-washing cynicism | Honest Rescue Wall, rounded-down outcomes, hard ethical wall (§10.5) |
| Leo & Parent: safety = one-strike | Under-13 templated-only, no free-text storage, no behavioral ads (§7.3, §9.2); moderation forced-MVP (#9) |

---

## 13. Onboarding & First-Time Experience

> Feature **Rescue Day** (#1, FPD **3.33**, **MVP**) — the highest-fun, cheapest hook; "the player fantasy in one 60–90 s scene; reuses the rig." This is the **cold-open**. The anniversary is **Gotcha Day**.

### 13.1 The Rescue Day cold-open (60–90 seconds)
A tightly authored, emotionally front-loaded sequence. Asset-cheap (reuses the one rig, param-driven emotions, 0 new rig):

```
Beat 1 (0:00–0:15)  Quiet, rainy/cold ambient scene. A small shape (Pup/Kit) alone, scared.
                    Soft music. No UI clutter. (Empathy ignition.)
Beat 2 (0:15–0:35)  The player is invited to reach out (a single gentle tap/hold to approach).
                    The animal flinches, then cautiously responds. (Care + responsibility.)
Beat 3 (0:35–0:55)  First touch -> the animal warms. First tiny happy reaction.
                    Bond = Stranger begins. (Attachment ignition.)
Beat 4 (0:55–1:15)  "Will you give it a forever home?" -> player confirms adoption.
                    (The fantasy verb: ADOPT.)
Beat 5 (1:15–1:30)  Naming moment: player names the pet. Pet "learns" the name (Memory seed #1).
                    Cut to The Nest (home). Soft warm shift. "Welcome home, <name>."
```

### 13.2 Onboarding goals (in priority order)
1. **Ignite attachment** before teaching any mechanic. The first 90 s are *emotional*, not instructional.
2. **Establish the name** (ownership) and **seed the first memory** (the magic begins immediately — Tom persona D1 hook).
3. **Teach the 3 core verbs** via *needs*, not menus: the pet is hungry → the feed prop glows → player feeds → reaction. (Diegetic tutorial.)
4. **Introduce the widget early** (David: "my pet lives with me" requires the widget on D1).
5. **Set the honest impact frame** lightly: "Even just playing helps real animals" (Priya), with **no donation hard-sell**.

### 13.3 Onboarding anti-patterns (forbidden)
- ❌ No long tutorial wall, no forced account creation before the player is attached (guest mode first; cloud save offered after the bond starts — Feature #25 **MVP forced**).
- ❌ No monetization surface in the first session beyond a gentle widget prompt.
- ❌ No "your pet will be sad if you don't…" framing, ever.
- ❌ No spinner on the first Heartmind line (pre-gen guarantees this; G2 criterion).

### 13.4 First-session success criteria (instrumented)
- ≥80% of installs complete Rescue Day (name the pet).
- First memory entry created in ≥95% of completed onboardings.
- First care interaction within the session in ≥90%.
- Widget prompt shown to 100%, accepted by target ≥25% (D1; grows over D7).

---

## 14. Virality & Sharing Design

> Feature **Keepsake Cards** (#24, FPD **2.67**, **MVP**) — the K-factor engine. All shares are **player-initiated off genuinely felt moments**; **NO forced popups, NO guilt, NO transactional referral** (brief §8). Discovery must **emerge from emotion and authenticity**, not gimmicks (Discovery Analysis mandate).

### 14.1 The seven canonical viral moments (brief §8) → Keepsake mapping

| # | Moment | Trigger | Card content | Primary persona |
|---|---|---|---|---|
| 1 | **Unprompted Comfort** | Pet notices low *player* mood / comforts unasked | "An AI pet comforted me" + the actual line | Maya |
| 2 | **Long Memory Callback** | Surfaces a weeks-old personal fact | "It remembered" + the recalled fact + elapsed time | Tom (highest WOM) |
| 3 | **Before/After Growth** | Life-stage up | Auto split-card: scared Rescue-Day pup vs. thriving Grown + elapsed days | David (native transformation format) |
| 4 | **Rescue/Gotcha-Day Milestone** | Adoption / anniversary ceremony | "Forever home" ceremony card at peak pride | All |
| 5 | **Real-Impact Celebration** | Verified shelter impact threshold | Named-shelter badge "I helped real animals" | Priya, David |
| 6 | **Widget Candid** | Endearing widget moment | Screenshotted directly; widget IS the ambient ad | Maya |
| 7 | **Naming/Personality Reveal** | A line "only MY pet would say" | Singular per-player line + pet name | Tom, Maya |

### 14.2 Keepsake Card build spec (cheap, templated)
- **Templated composition** (background + pet pose snapshot + text overlay + watermark) — generated client-side, ~0 marginal asset cost.
- **Tasteful watermark:** small KindredPaws mark + pet name + the actual line/fact (authenticity is the share-driver, not branding).
- **Light CTA:** "Adopt your own 🐾" — soft, never spammy.
- **1-tap native share** to platform share sheet (TikTok/IG/iMessage/etc.).
- **Distinct artifact per persona** (the comfort card ≠ the impact badge ≠ the before/after) so each cohort shares *its* flavor.

### 14.3 Virality principles (brief §8)
- **Emerge, don't manufacture.** Cards are *offered* at genuine emotional peaks, never popped up at random.
- **Many small authentic moments > one engineered spectacle** (also Risk R10 mitigation: avoids a single tone-deaf viral screenshot defining the brand).
- **No referral bribery** (no "share to get Heartstones") — keeps shares authentic and store-policy/child-safe clean.

### 14.4 K-factor & ASO levers (summary; growth sequencing in GAME_MASTER_EXECUTION_ROADMAP.md)
- **K-factor levers:** before/after format (inherently shareable), "it remembered me" (novel, screenshot-bait), real-impact badge (pride + cause WOM).
- **ASO angles:** "AI pet that remembers you," "rescue a pet, help real shelters," "cozy virtual pet," "AI Tamagotchi." Validated at G3/soft-launch.
- **CAC near-zero at launch** (brief §5) — growth **must** be organic/viral; paid UA only after sub LTV > CAC is proven.

---

## 15. Difficulty, Pacing & Anti-Frustration

> Cozy genre: difficulty is **near-zero by design**. "Difficulty" here means *pacing and friction management*, not challenge. Anti-frustration is a retention requirement (Risk R6).

### 15.1 No-fail design
- **No death, no illness, no loss** (no-death floor §5.2; Health/Vet **Removed** #29). The player cannot "lose."
- **No skill gate** on core care (taps always succeed).
- The only "difficulty" is the gentle decay that invites return — capped so a returning player is never punished.

### 15.2 Pacing curve (the deliberate slow-burn)

| Window | Pace intent | Mechanism |
|---|---|---|
| D0–D1 | High-density emotional hooks | Rescue Day, naming, first memory, first stage glimpses |
| D2–D7 | Steady warm progression | Bond→Friend, Young One stage, streak forming, first callbacks |
| W2–W4 | Deepening, slower beats | Companion stage, personality emerges, cosmetics |
| M2–M3 | Long-horizon payoff | Grown, Kindred, before/after, real impact |
| M3+ | Ritual + live-ops | Soulmate, Gotcha Day, seasonal moments |

**Intent:** front-load emotion, then *slow down* so content lasts months on a tiny solo+AI asset budget. The Bond/memory loop sustains retention without a content treadmill (Risk R8).

### 15.3 Anti-frustration checklist

- [ ] No interaction is ever a no-op (every tap rewards — §2.2).
- [ ] No hard lockouts on core care (no "wait/pay to feed").
- [ ] No punitive streaks (Streak Warmth — §11.2).
- [ ] No guilt notifications (§11.3).
- [ ] First AI line is spinner-free (pre-gen — §7.2).
- [ ] Returning lapsed player meets a happy, not-sulking pet (§5.7).
- [ ] No naked numbers shouted at the player (soft visuals — §5.5).
- [ ] No FOMO that exploits attachment (§9.6, §18).
- [ ] Memory never hallucinates a fact (≥95% reliability, 0 hallucination — G2).
- [ ] Diminishing returns are invisible (natural satiation cue — §5.6).

### 15.4 Accessibility & comfort
- Large tap targets; single-hand portrait play; reduced-motion option; colorblind-safe Care ring states; readable copy; optional sound. (Premium-feel-on-low-cost extends to comfort/accessibility.)

---

## 16. Live-Service Content Loop

> **Live-Ops Events** (#27) = **Deferred** (inherently post-launch) but **MUST architect remote-config now**. Phase **P6 — Live ops** is the home for deferred-feature drops. Cadence detail lives in **GAME_CONTENT_FACTORY.md** (content cadence) and **GAME_MASTER_EXECUTION_ROADMAP.md** (P6 drop schedule); this section sets the gameplay framing and the honest cadence promise.

### 16.1 Honest cadence (Risk R8 — the treadmill trap)
- **Launch cadence promise: 1 small live moment every 6–8 weeks** (NOT weekly). The solo+AI team cannot sustain a weekly treadmill, and the brief explicitly mandates honesty here.
- **The core loop retains via Bond + memory, NOT new content.** Live-ops is *seasoning*, not the meal. This is the key reason the bimodal D30 depends on memory (§12.4), not content volume.

### 16.2 Deferred-feature drop schedule (P6, from brief §3)
Live-ops is where Deferred features land (each was Deferred precisely so it can be a post-launch drop):

| Drop | Feature | Brief verdict |
|---|---|---|
| Fast-follow | **Lock-Screen Widget / Live Activities** (#15) | Deferred |
| Post-launch | **Voice Mimic Layer** (#10, on-device DSP only, audio never leaves device) | Deferred |
| Post-launch | **Training / Tricks** (#20) | Deferred |
| Post-launch | **Care Pass** (4–6 wk, cosmetic/impact only) | Deferred |
| Post-launch | **Live free-form Heartmind chat** (#6b, adult-verified + subscriber-gated) | Deferred |
| Post-launch | **2nd species** (if cut at G2) + **breed palette-swaps** (#28) | Deferred |
| When volume justifies | **Bespoke anomaly/ML anti-fraud** (#13b) | Deferred |

### 16.3 Seasonal events (data-driven)
- Cosmetic + impact-themed only (e.g., "Winter Warmth" shelter drive). **No power, no gacha.**
- Delivered via **remote config / data-driven event infra** built in MVP (Risk R8 mitigation) — so a new event is *data*, not a client update.
- Each event reuses existing assets (palette-swap props, seasonal Nest tints via shader — brief §4) to honor the asset cap.

### 16.4 Care Pass (Deferred)
- **Care Pass** (canonical name): a 4–6-week pass, **cosmetic/impact only** (no power). Free + premium track. Pricing validated post-launch (Open Decision #8).
- Designed so the **free track** still yields delight + Compassion Coins (impact for everyone).

### 16.5 Live-ops gate
- **G6 (recurring quarterly):** D30 holding ≥10%; sub conversion ≥2%; IAP-payer ≥1.5%; donation volume up + **quarterly Impact Report published**; content cadence **sustainable solo+AI** (brief §3, §10).

---

## 17. Telemetry-Driven Balancing Plan

> Analytics: managed (Firebase/GameAnalytics), **~15 events mapped to funnel gates**, privacy-by-design, **no PII** (brief §6). Telemetry is how a solo founder balances a live game without a data team. Pipeline/implementation in **GAME_TECHNICAL_SYSTEMS.md**.

### 17.1 The ~15 canonical events (mapped to gates)

| # | Event | Key params | Gate / KPI it serves |
|---|---|---|---|
| 1 | `rescue_day_complete` | named (bool), duration_s | Onboarding (§13.4) |
| 2 | `session_start` | source (notif/widget/organic) | D1/D7/D30 retention |
| 3 | `session_quality` | empty (bool), interactions_n, duration_s | "No empty session" (§3.4) |
| 4 | `care_action` | type, meter_before/after | Loop balance (§5) |
| 5 | `bond_change` | delta, new_total, source | Bond pacing (§7.1) |
| 6 | `bond_stage_up` | stage | Progression (§7.1) |
| 7 | `life_stage_up` | stage, days_elapsed | Growth pacing (§6) |
| 8 | `memory_callback` | landed (bool), age_days | **R3 / G2 ≥95% reliability** |
| 9 | `ai_repetition_flag` | (player-reported or detected) | **Leading churn indicator (brief §10)** |
| 10 | `guilt_flag` | (survey/proxy) | **Leading churn indicator (brief §10)** |
| 11 | `streak_event` | type (tick/freeze/repair/break) | Retention (§11) |
| 12 | `monetization_event` | stream, sku, value | ARPDAU, sub conv (§9) |
| 13 | `compassion_coin_mint` | source, amount, validated (bool) | Donation/anti-fraud (§10) |
| 14 | `keepsake_share` | moment_type, platform | K-factor / virality (§14) |
| 15 | `llm_cost_event` | tokens, cost, model | **R2 / G4 cost-per-DAU <35% ARPDAU** |

> Privacy: no free-text from minors logged; no PII; aggregate-first. Child-safety logging is separate/audited (GAME_TECHNICAL_SYSTEMS.md).

### 17.2 Balancing dashboards (solo-operable)

| Dashboard | Watches | Action trigger |
|---|---|---|
| Retention funnel | D1/D7/D30 vs. gate thresholds | Below gate → investigate loop/onboarding |
| Loop health | `session_quality.empty` rate, avg interactions | Empty rate up → re-tune greeting/needs surfacing |
| Memory authenticity | `memory_callback.landed` ratio | <95% → P0; freeze rollout (R3) |
| Repetition/guilt | events #9, #10 trending | Up → rotate bank / soften copy *before* D7 moves |
| Economy | faucet/sink balance, Kibble/Heartstone flow | Inflation/starvation → remote-config decay/cost |
| Unit economics | ARPDAU, LLM cost/DAU ratio | Ratio ≥35% → tighten caps/caching (R2, G4) |
| Virality | shares/DAU-week by moment type | <1 share/DAU-week → improve moment trigger (G4) |

### 17.3 Balancing methodology
- **All core numbers are remote-config** (§5.8, §8) → balance live without client updates.
- **Change one lever at a time**, observe 7-day cohort, keep a changelog in `current_state.json`.
- **Gate-driven:** never advance a phase until that phase's KPI thresholds (brief §10) are met; regressions below a gate trigger rollback of the last config change.
- **Leading indicators over lagging:** act on `ai_repetition_flag` / `guilt_flag` *before* D7/D30 numbers move (brief §10 mandate).

---

## 18. Ethics & Player Wellbeing

> The cozy/safe core is a brand and a legal requirement, not a nicety. This section is binding. Related risks: **R1 (kids compliance), R5 (donation), R6 (neglect-guilt), R10 (negative virality).** Child-safety moderation (#9) is **MVP (forced)** — FPD irrelevant, legally non-negotiable.

### 18.1 Emotional-attachment ethics
The game *deliberately* cultivates attachment (it is the core fantasy). With that power comes binding limits:
- **Attachment is never weaponized for monetization or retention.** No mechanic ever threatens the pet to drive spend or return (no-death floor §5.2; hard ethical wall §10.5).
- **The pet is unconditionally fine.** Regardless of payment, absence, or subscription status, the pet is always safe and happy to see the player. Cancelling Forever Friends never harms the pet (§9.3).
- **Longing, not guilt.** Absence creates a warm "missed you," never a "you neglected me" (§5.7, §11.3).

### 18.2 Kids & child-safety (Risk R1 — existential)
- **Build to a child-safe standard for ALL users** (brief R1): hybrid dialogue, **no free-text storage from minors**, templated/non-generative dialogue for under-13.
- **No behavioral ad targeting**; under-13 see contextual-only or no ads (§9.2).
- **Two-sided moderation** (input + output) on all AI, hard system-prompt constraints, fixed safe-fallback line, **self-harm → static safe message**, full audit logging (GAME_TECHNICAL_SYSTEMS.md).
- **Mandatory budgeted pre-launch legal review** — gate **G3** (brief §3). Under-13 handling (neutral age gate vs. fully child-safe-for-all) resolved at G3 legal review (Open Decision #9).
- **One-strike safety gate** for the Leo & Parent persona: a single unsafe AI screenshot can define the brand (Risk R10) — hence guardrails + per-turn moderation + child-safe persona lock.

### 18.3 Anti-dark-pattern commitments (binding checklist)

- [ ] **No pay-to-win** — no currency buys Bond, growth, memory, or any progression.
- [ ] **No gacha / loot boxes** (brief §5).
- [ ] **No predatory FOMO** — no loss-framed timers, no attachment-exploiting bundles.
- [ ] **No guilt mechanics** — pet never punishes absence; notifications never guilt.
- [ ] **No ads mid-emotion** — never interrupt comfort, callbacks, stage-ups, Rescue Day.
- [ ] **No kid behavioral targeting** (COPPA/GDPR-K).
- [ ] **No charity-washing** — % NET via vetted intermediary, named partners, dated receipts, rounded-down outcome claims, verification badge (brief §9).
- [ ] **No tying real donations to the pet's wellbeing** (hard ethical wall §10.5).
- [ ] **No forced/transactional referral** — shares are authentic, emotion-driven (§14.3).
- [ ] **No memory hallucination** — fabricating a "remembered" fact is a P0 trust violation.
- [ ] **Easy, no-friction subscription cancellation** — no dark-pattern retention.
- [ ] **Cloud save protects the pet** — no update may orphan a pet (Feature #25 **MVP forced**; Risk R4).

### 18.4 Donation ethics (Risk R5 — recap, binding)
- % of **NET** revenue (stated net to avoid misleading), via established intermediary, to 1–3 vetted partners (Charity Navigator/GuideStar-rated, audited).
- **NO donation IAP, NO player tax-deductible donations in MVP.** Compassion Coins represent pooled intent, not personal deductible gifts (brief §9, Resolution #4).
- Single version-stamped **Impact Pledge** doc = SSOT; **quarterly co-signed Impact Report** (G6).
- **Free players still generate real impact** — meaningfulness is universal, not paywalled (§10.5).

### 18.5 Player wellbeing posture
- The game is a **comfort object**, not an engagement trap. Healthy short daily sessions are the design target (the quick-check is a *valid, encouraged* session — §3.2).
- We do **not** optimize for maximum time-on-app; we optimize for **attachment quality and long-term retention via genuine emotional payoff** (Pillar P-1, P-2).
- If a wellbeing metric (e.g., guilt_flag) and an engagement metric conflict, **wellbeing wins** — consistent with the core-feeling priority order (§1.1) and hard constraint #10.

---

## Appendix A — Feature → Section Index (FPD verdicts at a glance)

| # | Feature | Verdict | Primary section |
|---|---|---|---|
| 1 | Rescue Day | MVP | §13 |
| 2 | Care Meters | MVP | §5 |
| 3 | Core care (feed/clean/play) | MVP | §2, §3 |
| 4 | The Bond | MVP | §5.4, §7 |
| 5 | Growth / Life-Stages | MVP | §6 |
| 6 | Heartmind dialogue (hybrid) | MVP\* | §7 |
| 6b | Heartmind live free-form chat | Deferred | §7.2, §16.2 |
| 7 | AI Memory (Memory Book) | MVP | §7.2 |
| 8 | Evolving Personality | MVP | §7.4 |
| 9 | Child-Safety Moderation | MVP (forced) | §18.2 |
| 10 | Voice Mimic Layer | Deferred | §16.2 |
| 11 | Donation/Impact Engine | MVP\* | §10 |
| 12 | Rescue Wall | MVP | §10.3 |
| 13 | Anti-fraud (platform-native) | MVP (forced) | §10.4 |
| 13b | Anti-fraud (bespoke ML) | Deferred | §16.2 |
| 14 | Home-Screen Widget | MVP | §11.4 |
| 15 | Lock-Screen Widget / Live Activities | Deferred | §11.4, §16.2 |
| 16 | Notifications (pet-voiced) | MVP | §11.3 |
| 17 | Care Streak (+ Streak Warmth) | MVP | §11.1–11.2 |
| 18 | Ambient Interactions | MVP | §11.5 |
| 19 | The Nest (decoration) | MVP\* | §2, §8 |
| 20 | Training / Tricks | Deferred | §16.2 |
| 21 | Cosmetics Shop | MVP | §9.4 |
| 22 | Subscription (Forever Friends) | MVP\* | §9.3 |
| 23 | Ads | MVP | §9.2 |
| 24 | Keepsake Cards | MVP | §14 |
| 25 | Cloud Save / Account | MVP (forced) | §13.3, §18.3 |
| 26 | Localization (static UI) | MVP\* | (see GAME_TECHNICAL_SYSTEMS.md / GAME_CONTENT_FACTORY.md) |
| 27 | Live-Ops Events | Deferred | §16 |
| 28 | More Species / Breeds | Deferred | §6.4, §16.2 |
| 29 | Health / Illness / Vet | Removed | §5.2, §6.4 |
| 30 | Multiplayer / Social | North-Star | §10.3 (community counter proxy) |
| 31 | UGC / Custom Pet Creation | North-Star | §9.4 (curated cosmetics meet need) |

## Appendix B — Canonical numbers quick-reference

| Item | Value | Source |
|---|---|---|
| Care Meters | 4 (hunger, energy, hygiene, happiness) | brief §5 |
| Meter floor (no-death) | 15 | §5.2 |
| Bond stages | Stranger→Friend→Companion→Kindred→Soulmate | brief §1 |
| Bond stage thresholds | 0 / 250 / 1,200 / 4,000 / 10,000 | §7.1 |
| Life stages | Pup-Kit → Young One → Grown | brief §1 |
| Daily Bond soft cap | ~45–60 | §5.4 |
| Memory facts stored | 10–30 durable | brief §6 |
| Memory callback reliability gate | ≥95%, 0 hallucination (G2) | brief §10 |
| Subscription | Forever Friends $5.99/mo · $39.99/yr | brief §1, §5 |
| Compassion Coin mapping | 50 Coins = 1 real meal (illustrative, rounded down) | brief §5, §9 |
| Revenue mix | ads 45–55% · sub 30–40% · cosmetic 10–20% · bundles 5–10% | brief §5 |
| ARPDAU target | $0.03–0.06 | brief §5 |
| LLM cost/DAU ceiling | <35% of ARPDAU (G4) | brief §5, §10 |
| Retention targets | D1 ~45% · D7 ~20–22% · D30 ~10–12% | brief §7 |
| Unique authored assets cap | ~140 (≈65 newly-drawn) | brief §4 |
| Art/audio budget | $3,500–$7,550 (plan ~$5,500) | brief §4 |
| Notification cap | 1–2/day, warm/invitational | brief §2, §6 |
| Ad cap | 4–6 rewarded/day, ≤1 interstitial/session | brief §5 |
| Live-ops cadence (honest) | 1 small moment / 6–8 weeks | brief §11 (R8) |

---

*End of GAMEPLAY_AND_PROGRESSION_BIBLE.md — v1.0. All numbers are launch defaults, remote-config-tunable, and subordinate to the `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md` (SSOT). Update `current_state.json` on every balance decision.*
