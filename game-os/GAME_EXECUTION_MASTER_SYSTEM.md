# KindredPaws — Execution Master System (the OS)

> **Document role:** This is the **operating system** of the KindredPaws game-os — a transparent reconstruction of the governing master prompt that produced the project. It defines the frameworks, gates, classification system, consolidation rules, operating cadence, AI-agent playbook, the `current_state.json` schema/update protocol, and how to re-run or extend the entire system.
>
> **Canonical for:** the *meta-process* — frameworks (FPD, Founder-Fit, AI Playtester, Discovery, Asset-Budget), gate validation rules, classification definitions, consolidation/DRY rules, operating cadence, AI-agent playbook, `current_state.json` schema + update protocol, Definition-of-Done, re-run/extend procedure.
>
> **NOT canonical for:** product decisions. Every feature classification, FPD score, phase name, gate criterion, currency name, KPI threshold, asset count, and dollar figure originates in **`KINDREDPAWS_CANONICAL_DECISION_BRIEF.md`** (the single source of truth for *what we are building*). This OS governs *how we execute*; the brief governs *what we ship*. Where this OS quotes a number, it is mirroring the brief verbatim — if they ever diverge, **the brief wins** and this OS is corrected.
>
> **Status:** v1.0 · **Date:** 2026-06-22 · **Phase context:** Pre-Phase-0 (greenfield; `game-os/` empty except this file). First Phase 0 action remains: create `current_state.json`.

---

## Table of Contents

1. [Purpose of the game-os](#1-purpose-of-the-game-os)
2. [Transparency Note — Reconstructing the Master Prompt](#2-transparency-note--reconstructing-the-master-prompt)
3. [Document Map & Ownership](#3-document-map--ownership)
4. [Framework: Fun-Per-Dollar (FPD)](#4-framework-fun-per-dollar-fpd)
5. [Framework: Founder-Fit Audit](#5-framework-founder-fit-audit)
6. [Framework: AI Playtester Simulation](#6-framework-ai-playtester-simulation)
7. [Framework: Discovery Analysis](#7-framework-discovery-analysis)
8. [Framework: Asset-Budget Discipline](#8-framework-asset-budget-discipline)
9. [The Gate System & Validation Rules](#9-the-gate-system--validation-rules)
10. [The Classification System](#10-the-classification-system)
11. [Consolidation Rules](#11-consolidation-rules)
12. [Operating Cadence](#12-operating-cadence)
13. [AI-Agent Operating Playbook](#13-ai-agent-operating-playbook)
14. [current_state.json — Schema & Update Protocol](#14-current_statejson--schema--update-protocol)
15. [Definition of Done per Deliverable](#15-definition-of-done-per-deliverable)
16. [How to Re-Run & Extend the System](#16-how-to-re-run--extend-the-system)
17. [Glossary](#17-glossary)

---

## 1. Purpose of the game-os

The **game-os** is the durable, version-controlled brain of Project KindredPaws. It exists because the project has an unusual constraint profile: **one founder + heavy AI-agent assistance**, a **12–18 month** runway to global launch, a **bootstrapped indie budget**, and a product whose differentiators (LLM dialogue, real-world donation, daily-life integration) are individually capable of exploding scope, cost, or legal risk. Human memory and ad-hoc decision-making cannot hold this together across 16 months. The game-os can.

### 1.1 What the game-os is for

| Goal | How the OS delivers it |
|---|---|
| **Prevent scope creep** | Every feature must pass the **Fun-Per-Dollar (FPD)** framework and carry a verdict (MVP / Deferred / Removed / North-Star). No feature enters the build without a recorded verdict. |
| **Prevent cost blowups** | The single make-or-break sensitivity — **LLM cost/DAU must stay < 35% of ARPDAU** — is enforced at gates G3 and G4. Asset spend is hard-capped at **~140 unique assets / ~$5,500**. |
| **Prevent legal catastrophe** | Child-safety moderation is a **forced MVP** (FPD irrelevant); a budgeted **legal review is a gate condition at G3**. |
| **Preserve emotional core under cost pressure** | FPD demands the *cheapest viable version that preserves the emotional core* for every feature, never the cheapest version full-stop. |
| **Keep one human + AI agents in sync** | A machine-readable single source of truth (`current_state.json`) plus a documented AI-agent playbook make the project executable by a solo operator who delegates to agents. |
| **Make virality emerge, not bolt on** | The **Discovery Analysis** framework forces every shareable moment to originate from genuine emotion (comfort, memory, growth, impact). |

### 1.2 What the game-os is NOT

- It is **not** the game design doc, the technical spec, or the art bible — those are sibling documents (see §3).
- It is **not** a place to re-derive product decisions. Those are locked in `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md`.
- It is **not** aspirational. North-Star items live here only as *classification*, never as committed work.

### 1.3 The product in one paragraph (context only — canonical in the brief)

KindredPaws is a cozy-sim virtual-pet mobile game (iOS + Android) where the player adopts a **rescued puppy or kitten** and raises it from infancy (**Pup/Kit → Young One → Grown**) while building **The Bond** (Stranger → Friend → Companion → Kindred → Soulmate). It fuses My-Talking-Tom-style accessibility, an LLM-powered companion layer (**Heartmind**, hybrid — not free-form chat in MVP), daily-life integration (**Companion Presence**: widgets, notifications, **Care Streak**), and real-world animal-welfare impact (**The Impact Pledge** + **Rescue Wall**). The OS's job is to make all of that shippable by one founder + AI agents without violating any hard constraint.

---

## 2. Transparency Note — Reconstructing the Master Prompt

### 2.1 Why this section exists

The KindredPaws documentation set was generated by a governing meta-prompt referred to as **"GAME EXECUTION ROADMAP GENERATOR — ULTRA MASTER PROMPT v2.0."** That original prompt artifact is **not present in the repository** — it was the instruction given to a chain of specialist analysts and a Lead Game Director, but it was never itself committed as a file. This OS document is a **transparent, good-faith reconstruction** of that master prompt's *governing logic*, inferred from its outputs: the canonical decision brief, the framework definitions, the phase/gate skeleton, and the classification table.

This matters for trust and reproducibility. A solo founder leaning on AI agents must be able to answer: *"Why is the system shaped this way? Can I re-run it? Can I correct it if it's wrong?"* This section makes the governing prompt legible and correctable rather than a black box.

### 2.2 Reconstructed structure of the master prompt

The v2.0 master prompt, as evidenced by its outputs, instructed an AI system to:

1. **Ingest** a raw GAME IDEA, a set of ASSUMPTIONS & HARD CONSTRAINTS, and five FRAMEWORKS (FPD, Founder-Fit, AI Playtester, Discovery, Asset-Budget).
2. **Run each major feature** through the FPD framework, producing a FUN score, a DOLLAR score, an FPD ratio, a verdict band, and a *cheapest-viable-version* note.
3. **Audit each system** for solo+AI Buildability and Maintainability (Founder-Fit).
4. **Simulate** persona cohorts (Maya, David, Priya, Tom, Leo & Parent) through D1/D7/D30 sessions and convert every finding into a design change.
5. **Map** organic discovery and virality (K-factor, ASO, shareable moments).
6. **Enforce** asset-budget discipline (hard cap, reuse, palette-swaps, AI-generation).
7. **Reconcile** conflicting specialist outputs into a single LOCKED brief, with every conflict resolution recorded.
8. **Emit** a phase/gate skeleton (P0–P6 with gates G0–G6), a master feature-classification table, an asset budget, an economy model, a tech stack, persona definitions, virality mechanics, a donation trust model, KPI targets, a risk register, and open decisions.
9. **Mandate consolidation:** one fact per canonical document, cross-links not duplication, `current_state.json` as machine-readable SSOT, no contradictions.
10. **Produce six downstream documents** plus this OS, each cross-linking the canonical brief.

### 2.3 How to correct the reconstructed master prompt

Because the original prompt is reconstructed, it may contain inference errors. Correction protocol:

1. **Detect the discrepancy.** If an output cannot be explained by the reconstructed logic above, or if a downstream doc contradicts the brief, flag it.
2. **Locate the canonical owner.** Determine whether the error is in the *process* (this OS) or the *product decision* (the brief). See §3.
3. **Correct the canonical owner first**, then propagate cross-links. Never patch a symptom in a downstream doc.
4. **Record the correction** in `current_state.json` under `decision_log` with a timestamp, the old value, the new value, and the rationale. (Schema in §14.)
5. **Re-version** the affected document (bump its `version` and update its `last_updated` date).
6. **Re-run affected frameworks** if the correction changes a feature's cost, fun, or risk profile (e.g., re-score FPD; re-run Founder-Fit). See §16.

> **Golden rule of correction:** the brief is the source of truth for *what*; this OS is the source of truth for *how*. A correction to a product fact (a number, a verdict, a name) belongs in the brief. A correction to a method (a rubric, a cadence, an agent prompt) belongs here.

---

## 3. Document Map & Ownership

The game-os is a **DRY documentation system**: each fact has exactly **one canonical home**; every other document **cross-links** rather than duplicates. This table is the authoritative map of ownership.

| # | Document (filename) | Canonical for (owns these facts) | Must cross-link to |
|---|---|---|---|
| 0 | **`KINDREDPAWS_CANONICAL_DECISION_BRIEF.md`** | **EVERYTHING product-level**: feature classifications & FPD scores, phase/gate names + durations + criteria, currency names, KPI targets, asset counts & budget, economy/monetization splits, persona definitions, virality shortlist, donation trust model, risk register, open decisions, terminology table. **The SSOT. The brief wins all conflicts.** | — (it is the root) |
| 1 | **`GAME_EXECUTION_MASTER_SYSTEM.md`** *(this file)* | The *meta-process*: frameworks, gate validation rules, classification definitions, consolidation rules, operating cadence, AI-agent playbook, `current_state.json` schema + update protocol, Definition-of-Done, re-run/extend procedure, glossary of process terms. | the brief (for all numbers) |
| 2 | **`GAMEPLAY_AND_PROGRESSION_BIBLE.md`** | Core loop & meta loop detail, Care Meters tuning (decay rates, mood thresholds), The Bond progression curve, life-stage transition triggers, Care Streak / Streak Warmth rules, The Nest / customization rules, ambient-interaction sequencing, onboarding (Rescue Day) beat sheet; currency sinks/sources (Kibble, Heartstones, Compassion Coins), Forever Friends subscription detail, Rescue Bundles, ads cadence, LTV/ARPDAU model, Impact Pledge net-% math; Heartmind affection/dialogue *design intent*, evolving-personality gameplay; donation player-facing loop, Rescue Wall UI, trust pillars, ethical-wall framing; personas, virality/Keepsake mechanics. | the brief; `GAME_TECHNICAL_SYSTEMS.md` |
| 3 | **`GAME_TECHNICAL_SYSTEMS.md`** | Engine choice, BaaS architecture, LLM strategy (hybrid pre-gen + memory), moderation pipeline, save/sync schema + migration, widget/notification payload, RevenueCat integration, ads SDK config, analytics event list (~15 events); Heartmind *implementation* (persona-dial wiring, dialogue-bank selection runtime, Memory Book fact-store schema [10–30 facts], callback rotation/anti-repetition, child-safety prompt constraints, live-chat gating); anti-fraud mechanics, Impact Pool ledger, intermediary integration, LLM/infra cost model. | the brief; `GAMEPLAY_AND_PROGRESSION_BIBLE.md`; `GAME_CONTENT_FACTORY.md` |
| 4 | **`GAME_CONTENT_FACTORY.md`** | Live2D rig spec, life-stage skinning via param/scale, emotion-motion blends, environment shader tints, cosmetic overlay/palette-swap kit, the ~140-asset manifest, AI-concept → rig-commission pipeline; dialogue-bank *content production* + Tone & Safety Bible authoring; audio plan; localization production; live-ops content cadence (Care Pass, seasonal events). | the brief; `GAMEPLAY_AND_PROGRESSION_BIBLE.md`; `GAME_TECHNICAL_SYSTEMS.md` |
| 5 | **`GAME_DECISION_LOG.md`** | The auditable decision record: locked FPD verdicts + rationale, Founder-Fit audit results, AI-Playtester findings→decisions, Architecture Decision Records (ADRs), donation-ethics decisions, reconciled conflicts, numbered decision entries (D-001…), open decisions, reversal/change log. | the brief; all sibling docs |
| 6 | **`GAME_MASTER_EXECUTION_ROADMAP.md`** | The phased execution plan: phase structure + durations, gate IDs + pass criteria, the critical path, milestone definitions, KPI-by-phase, the solo-founder weekly operating cadence, the master risk register, deferred-feature drop schedule, ASO/UA growth sequencing. | the brief; `GAME_DECISION_LOG.md`; `GAME_TECHNICAL_SYSTEMS.md` |
| 7 | **`GAME_EXECUTION_MASTER_SYSTEM.md`** *(this file)* | (Listed as row 1 above — the meta-process OS.) | the brief |
| — | **`current_state.json`** | **Machine-readable mirror** of live project state: current phase, gate status, feature verdicts, open decisions, decision log, KPI actuals vs targets, asset/cost ledger. The runtime SSOT. | the brief (human-readable counterpart) |

> Document count note: the brief references **six downstream document authors** plus the brief itself. On disk those six are exactly the files in rows 1–6 above (this OS is one of them); `current_state.json` is the machine-readable mirror. The filenames above are the **real on-disk names** and are the canonical cross-link targets — every sibling doc references these exact names. If a future doc is created or renamed, this map is corrected to match reality (per §2.3), and every cross-link is updated to match (Consistency Auditor, §13).

### 3.1 Single-source-of-truth rules

1. **One fact, one home.** Before writing any number, name, or decision into a document, check this map for its canonical owner. If you are not in the owner, **link, don't copy**.
2. **`current_state.json` mirrors the brief**, not the other way around. When a decision changes, update the brief (human) and `current_state.json` (machine) in the same commit.
3. **No document may contradict another.** Contradiction is a defect; resolve by §11.4.
4. **Cross-link by filename** (e.g., "see `GAME_TECHNICAL_SYSTEMS.md` §LLM strategy"), never by re-stating the linked content.

---

## 4. Framework: Fun-Per-Dollar (FPD)

FPD is the primary triage gate. **No feature enters the build without an FPD verdict on record.**

### 4.1 Formula

```
FPD = FUN / DOLLAR
```

Where **FUN** ∈ [1,10] and **DOLLAR** ∈ [1,10]. Higher FPD = more emotional/retention value per unit of cost and risk.

### 4.2 Scoring rubric — FUN (1–10)

FUN aggregates four sub-signals. Score each mentally, then synthesize a single 1–10:

| Sub-signal | Question | Weight bias |
|---|---|---|
| **Emotional impact** | Does it deepen attachment, care, comfort, empathy, pride, meaningfulness? | Highest — emotion > fidelity per hard constraint #10. |
| **Retention power** | Does it pull the player back (D1/D7/D30)? | High. |
| **Differentiation** | Does it make KindredPaws *not* a Tom clone? | High. |
| **Virality** | Does it generate a shareable, authentic moment? | Medium-high. |

### 4.3 Scoring rubric — DOLLAR (1–10)

DOLLAR aggregates five cost/risk sub-signals (higher = more expensive/risky):

| Sub-signal | Question |
|---|---|
| **Build effort** | Solo-founder + AI agent hours to ship the cheapest viable version. |
| **Unique-asset cost** | New Live2D rigs, art, audio drawn against the ~140-asset / ~$5,500 cap. |
| **Ongoing / LLM / infra cost** | Per-DAU OPEX — *the* sensitivity. LLM cost/DAU must stay < 35% ARPDAU. |
| **Technical risk** | Likelihood of failure or rework; novel/unproven tech. |
| **Maintenance load** | Recurring solo+AI burden after launch (live-ops treadmill risk). |

### 4.4 Verdict bands

| FPD | Band | Action |
|---|---|---|
| **≥ 1.5** | Strong MVP | Build it in MVP. |
| **1.0 – 1.49** | Conditional MVP (`MVP*`) | MVP **only** in its cheapest emotionally-intact form. Document that form. |
| **0.6 – 0.99** | Defer | Post-launch / live-ops. |
| **< 0.6** | Remove / North-Star | Cut entirely, or relegate to long-term vision (not committed). |

**Override rule — Forced MVP:** features that are legal/architectural prerequisites are MVP **regardless of FPD**. In KindredPaws these are: **Child-Safety Moderation** (FPD 0.80), **Anti-fraud platform-native** (FPD —), **Cloud Save / Account** (FPD 0.60). FPD does not get a vote on a legal gate or a save-loss catastrophe.

### 4.5 The cheapest-viable-version mandate

For **every** feature, FPD must name *the cheapest version that preserves the emotional core* — never the cheapest version full-stop. Examples drawn from the brief:

- **Heartmind dialogue** (FPD 1.29, `MVP*`): cheapest emotionally-intact form = **hybrid pre-generated bank + structured memory injection**, NOT live free-form chat. The "it remembers" magic comes from the memory store + curated callbacks.
- **The Nest** (FPD 1.20, `MVP*`): **1 room + modular palette-swap kit**, not a furniture catalog.
- **Donation/Impact Engine** (FPD 1.33, `MVP*`): **% of NET revenue pledge to ONE vetted intermediary**, not bespoke charity infrastructure.
- **Subscription / Forever Friends** (FPD 1.25, `MVP*`): **single tier**, no multi-tier matrix.
- **Localization** (FPD 1.25, `MVP*`): **AI-translated static UI**, dialogue stays EN(+1–2).

### 4.6 Canonical FPD verdicts (mirror of brief §2 — do not edit here)

This OS references these to make framework usage concrete; the **brief owns the table**. Key rows:

| # | Feature | FPD | Verdict |
|---|---|---|---|
| 4 | The Bond | 4.50 | **MVP** (highest FPD) |
| 16 | Notifications (pet-voiced) | 3.50 | **MVP** |
| 17 | Care Streak (+ Streak Warmth) | 3.50 | **MVP** |
| 1 | Rescue Day | 3.33 | **MVP** |
| 2 | Care Meters | 2.67 | **MVP** |
| 3 | Core care (feed/clean/play) | 2.67 | **MVP** |
| 24 | Keepsake Cards | 2.67 | **MVP** |
| 12 | Rescue Wall | 2.33 | **MVP** |
| 5 | Growth / Life-Stages | 1.80 | **MVP** (capped 3 stages × 2 species) |
| 8 | Evolving Personality | 1.75 | **MVP** |
| 18 | Ambient Interactions | 1.75 | **MVP** |
| 7 | AI Memory (Memory Book) | 1.67 | **MVP** |
| 14 | Home-Screen Widget | 1.60 | **MVP** |
| 21 | Cosmetics Shop | 1.50 | **MVP** |
| 11 | Donation/Impact Engine | 1.33 | **MVP\*** |
| 23 | Ads | 1.33 | **MVP** |
| 6 | Heartmind dialogue (hybrid) | 1.29 | **MVP\*** |
| 22 | Subscription (Forever Friends) | 1.25 | **MVP\*** |
| 26 | Localization (static UI) | 1.25 | **MVP\*** |
| 19 | The Nest (decoration) | 1.20 | **MVP\*** |
| 27 | Live-Ops Events | 1.17 | **Deferred** |
| 15 | Lock-Screen Widget / Live Activities | 1.00 | **Deferred** |
| 20 | Training / Tricks | 1.00 | **Deferred** |
| 6b | Heartmind LIVE free-form chat | 1.29 | **Deferred** (age + sub gated) |
| 10 | Voice Mimic Layer | 0.88 | **Deferred** |
| 9 | Child-Safety Moderation | 0.80 | **MVP (forced)** |
| 29 | Health / Illness / Vet | 0.80 | **Removed** |
| 28 | More Species / Breeds (beyond 2) | 0.75 | **Deferred** |
| 30 | Multiplayer / Social Visiting | 0.67 | **North-Star** |
| 13b | Anti-fraud (bespoke anomaly/ML) | 0.60 | **Deferred** |
| 25 | Cloud Save / Account | 0.60 | **MVP (forced)** |
| 31 | UGC / Custom Pet Creation | 0.56 | **North-Star** |
| 13 | Anti-fraud (platform-native) | — | **MVP (forced)** |

### 4.7 FPD gate usage

- **At P0:** every proposed MVP feature must have a recorded FPD verdict before entering the build backlog. (G0 condition: brief ratified.)
- **At any phase:** a new feature idea cannot be scheduled until scored. Score it, classify it, log it in `current_state.json`.
- **At G2:** if rig pipeline runs hot, the **2nd species** is the #1 cut lever (its expansion cousin, "More Species," is FPD 0.75 / Deferred — the in-MVP 2nd species is budgeted but cut-first).
- **Re-score trigger:** any time a feature's cost, fun, or risk profile materially changes (e.g., LLM pricing shifts), re-run FPD and update the verdict.

---

## 5. Framework: Founder-Fit Audit

FPD asks *"is it worth it?"* Founder-Fit asks *"can one person + AI agents actually build and keep it alive in 12–18 months?"* A feature can pass FPD and still fail Founder-Fit — in which case it must be **simplified, deferred, or removed**.

### 5.1 Scoring

| Axis | Scale | Meaning |
|---|---|---|
| **Buildability** | 1–5 | Can the solo founder + AI agents *ship* it within the timeline? (5 = trivial; 1 = needs a team.) |
| **Maintainability** | 1–5 | Can they *keep it running* post-launch without a treadmill? (5 = set-and-forget; 1 = constant babysitting.) |

A feature must be **buildable AND maintainable** (both axes acceptable, target ≥3 each) to remain MVP as-is. Anything failing either axis routes to simplify/defer/remove.

### 5.2 Required output per audited system

For each system, the audit names:

1. **Buildability score** (1–5) + one-line justification.
2. **Maintainability score** (1–5) + one-line justification.
3. **The key risk** (the single thing most likely to break solo+AI).
4. **The AI-agent leverage point** (where an agent multiplies the founder — see §13).
5. **A concrete mitigation** (specific, actionable).

### 5.3 Worked examples (illustrative — consistent with brief risk register)

| System | Build | Maint | Key risk | AI-agent leverage | Mitigation |
|---|---|---|---|---|---|
| **Heartmind (hybrid)** | 3 | 3 | Unbounded LLM OPEX scaling with engagement (R2). | Agents pre-generate + human-review the large dialogue bank offline; agents scaffold the memory-extraction job. | Hybrid pre-gen + structured memory; token + daily-turn caps; live chat subscriber-only & age-gated; gate G4 on cost/DAU < 35% ARPDAU. |
| **AI Memory / Memory Book** | 3 | 4 | Flaky recall reads as "theater" (R3). | Agents write the fact-extraction + callback-rotation logic and test harness. | Narrow + reliable over broad + flaky; ≥95% callback reliability gate at G2; tangible Memory Book artifact. |
| **Cloud Save / Account** | 3 | 3 | Save loss = refund + 1-star (R4). | Agents scaffold versioned schema + automated migration + restore flow. | Authoritative versioned cloud save; no-death decay floor; restore proven at G3. |
| **Live2D rig pipeline** | 2 | 4 | Rig + life-stage art cost explosion (R7). | Agents generate concept art (Midjourney) to lock design before paying for the rig. | 1 rig/species; 3 stages via param/scale; cut 2nd species at G2 if hot; never under-budget the rig. |
| **Live-Ops Events** | 2 | 2 | Content treadmill exceeds solo+AI capacity (R8). → **Deferred.** | Agents author event content from templates against remote-config. | Architect remote-config in MVP; honest low launch cadence (1 small moment / 6–8 wks); core loop retains via bond/memory, not new content. |

### 5.4 When Founder-Fit overrides FPD

If FPD says MVP but Founder-Fit Buildability or Maintainability < 3 and no mitigation lands it ≥3, **simplify to a form that does**, or **defer**. This is exactly how the brief resolved the *second-species* and *anti-fraud* conflicts (budget for 2 species, ship 1 if hot; platform-native anti-fraud MVP, bespoke ML deferred).

---

## 6. Framework: AI Playtester Simulation

A protocol for stress-testing the design against target personas *before* and *during* build, since a solo founder cannot run large human playtests early.

### 6.1 Persona cohorts (canonical in brief §7 — do not redefine)

| Persona | One-line | Role in simulation |
|---|---|---|
| **Maya** — Gen-Z TikTok Casual | 19, 60–120s bursts, screenshot-first, zero cringe/latency tolerance | Highest K-factor; tests delight + share-ability + zero repetition. |
| **David** — Busy Adult Pet-Lover | 37, real rescue dog, widget-anchored, pays for calm+ad-free | Highest LTV; tests low-guilt, widget, before/after, donation. |
| **Priya** — Socially-Conscious Donor | 29, nonprofit, scrutinizes donation mechanics | Trust shield; tests donation transparency or finds the cynicism trap. |
| **Tom** — Lapsed Tamagotchi Nostalgic | 34, stress-tests AI-memory authenticity | Depth advocate or harsh critic; tests "it remembered me." |
| **Leo & Parent** — Kid Under Supervision | 9 + cautious parent | One-strike safety gate; tests child-safety + parent referral. |

### 6.2 Protocol

For each persona, simulate three sessions:

| Session | What to simulate | What to capture |
|---|---|---|
| **D1** | First-touch: Rescue Day cold-open → first care interactions → first AI line → first notification setup. | Fun moments; friction; first drop-off risk; "first AI line spinner-free?" |
| **D7** | Habit-forming: Care Streak active, Bond climbing, first memory callbacks, first widget glance. | Repetition fatigue ("noticed AI repetition"); guilt ("felt guilt-tripped"); is the loop still cozy? |
| **D30** | Attachment payoff: life-stage transition, long-memory callback, before/after growth, first donation impact. | Does the emotional payload land? Would they tell a friend? Is the bond real? |

### 6.3 The mandatory conversions

**Every finding MUST convert into a concrete design change** (or an explicit "no change, accepted risk" with rationale). A simulation that produces observations but no changes is incomplete.

Two **leading churn indicators** are mandatory instrumentation outputs of every simulation and must be tracked live:
- **"noticed AI repetition"** — predicts D7/D30 collapse before raw numbers move.
- **"felt guilt-tripped about the pet"** — violates cozy brand + churns highest-LTV personas (David).

### 6.4 The "would I tell a friend?" test

Each persona session ends with a binary: *would this persona tell a friend?* This is the qualitative pass criterion for **G2**. The persona-specific share trigger must fire:
- Maya → comfort moment (D1) / memory payoff (D30)
- David → donation impact + before/after
- Priya → verified impact (or a public warning if it feels fake)
- Tom → "it remembered me" (Reddit/Discord)
- Leo & Parent → parent-to-parent "safe & kind" referral

### 6.5 When to run

- **P0/P1:** paper/prototype simulation to validate the loop before heavy build.
- **P2 (gate G2):** full hand-test of Maya/Tom/David — "would tell a friend" must pass; AI memory callback must land reliably.
- **P3+:** simulation supplements (does not replace) real closed-beta data.

---

## 7. Framework: Discovery Analysis

Maps how players find KindredPaws and how it spreads. **Virality must emerge from genuine emotion and authenticity — never bolt-on gimmicks, forced popups, guilt, or transactional referral.**

### 7.1 The four levers

1. **Organic discovery + viral loops** — map the path from emotional moment → Keepsake Card → social post → install.
2. **Shareable emotional moments** — the virality shortlist (brief §8), all player-*initiated*.
3. **K-factor levers** — what raises invites-per-user and conversion.
4. **ASO angles** — store positioning (rescue + AI companion + real impact + cozy).

### 7.2 Virality mechanics shortlist (canonical in brief §8 — referenced)

All funnel into **Keepsake Cards** (1-tap share, tasteful watermark + pet name + actual line, light "Adopt your own" CTA). Distinct shareable artifact per persona:

| # | Moment | Primary persona |
|---|---|---|
| 1 | **Unprompted Comfort** — pet notices low mood, comforts unasked | Maya |
| 2 | **Long Memory Callback** — surfaces weeks-old personal fact | Tom (highest WOM) |
| 3 | **Before/After Growth** — auto split-card, scared rescue vs. thriving Grown | David |
| 4 | **Rescue/Gotcha-Day Milestones** — "forever home" ceremony card | all |
| 5 | **Real-Impact Celebration** — verified named-shelter badge | Priya, David |
| 6 | **Widget Candids** — endearing widget moment screenshotted; widget IS the ambient ad | David |
| 7 | **Naming/Personality Reveal** — "only MY pet would say this" | all |

### 7.3 Rules

- **No forced share popups.** The card is offered at the peak of a felt moment; the player chooses.
- **No guilt, no transactional referral.** (Honors hard ethical wall + cozy brand.)
- **Authenticity over spectacle** — many small genuine moments beat one engineered viral stunt (R10 mitigation).
- **KPI:** **≥1 viral Keepsake share per DAU-week** is a soft-launch gate condition (G4).

---

## 8. Framework: Asset-Budget Discipline

The hard economic spine of the project. **Honors hard constraints #2 (aggressively minimize asset cost), #3 (no AAA scope), #8 (no custom-3D pipeline), #11 (premium feel on low cost).**

### 8.1 The hard caps (canonical in brief §4 — referenced)

| Cap | Value |
|---|---|
| **Style** | Live2D Cubism, **1 rig per species**. Fallback: Spine 2D-skeletal. **NO custom 3D.** |
| **Hero spend** | 2 commissioned Live2D rigs @ **$1,200–$2,000 each**; +15–20% revision contingency. Lock design with AI concept (Midjourney) **before** paying. |
| **Total unique authored assets (MVP)** | **~140** (2 rigs + 6 life-stage skins; 12 emotion motions [0 new art]; 4 environments; 25 props; 30 cosmetics; ~52 UI/icons/widgets; 12 FX; ~48 audio; 5 music). **Truly newly-drawn ≈ 65.** |
| **Total art/audio budget** | **$3,500–$7,550; plan at ~$5,500.** Excludes engine/LLM/infra/store fees/founder time. |

### 8.2 Discipline rules

1. **Cap 2 species** (1 puppy + 1 kitten); 2nd species is cut-first at G2 if the rig pipeline runs hot.
2. **3 life-stages via scale/param**, not new rigs (Pup/Kit → Young One → Grown).
3. **Emotions = param blends** (free; 0 new art for the 12 emotion motions).
4. **Day/night/weather = shader tints** on the same 4 background environments.
5. **Cosmetics = overlay sprites + palette-swap** (~30 pieces at launch).
6. **Reallocate from music/SFX before EVER cutting rig quality** — the rig is the emotional vessel.
7. **Every art request is justified against FPD.** No asset enters the manifest without it.

### 8.3 AI-assisted generation leverage

- **Concept lock** before commissioning a rig (Midjourney concept → contractor rig) — de-risks the single biggest line item.
- **Palette-swaps + modular kits** generated/iterated by AI tooling.
- **UI/icon** drafts AI-generated, founder-curated.
- **Audio:** prefer royalty-free + AI-assisted before commissioning.

> The discipline test for any new asset: *"Can this be a param blend, a palette-swap, a shader tint, or a reuse of an existing asset instead of new art?"* If yes, it is not authored.

---

## 9. The Gate System & Validation Rules

Every phase ends with an explicit **Go/No-Go gate**. A gate is **all-or-nothing**: you pass only if **ALL** pass-criteria are met. Failing one criterion = No-Go = the phase is not complete.

### 9.1 Phase & gate skeleton (canonical in brief §3 — referenced verbatim)

| Phase | Duration | Primary goal | Gate | Pass criteria (ALL required) |
|---|---|---|---|---|
| **P0 — Pre-production** | 6 wks | Lock design, tech, legal frame, asset style | **G0** | Brief ratified; rig contractor secured; LLM cost/DAU model shows < ARPDAU at projected mix; legal review booked. |
| **P1 — Core-loop prototype** | 8 wks | Prove daily loop is fun on cheap assets | **G1** | Loop "feels alive & cozy" (qualitative); deterministic sim + offline-catch-up tested; **zero neglect-guilt**. |
| **P2 — Vertical slice** | 10 wks | One polished, emotionally complete experience incl. AI | **G2** | Personas (Maya/Tom/David) hit "would tell a friend"; AI memory callback reliability **≥95%** (no hallucinated facts); **spinner-free first AI line**; rig cost on-budget (else cut 2nd species). |
| **P3 — MVP / Closed beta** | 12 wks | Feature-complete, store-compliant, instrumented | **G3** | **D1 ≥40% / D7 ≥18%**; 0 child-safety incidents; cloud-save restore proven; LLM cost/DAU within model; crash-free **≥99%**; **legal green-light**. |
| **P4 — Soft launch** | 8 wks | Validate retention + unit economics in 2–3 markets | **G4** | **D1 ≥42% / D7 ≥20% / D30 ≥10%**; **ARPDAU ≥ $0.03**; **LLM cost/DAU < 35% of ARPDAU**; **≥1 viral Keepsake share / DAU-week**; clean donation reconciliation. |
| **P5 — Global launch** | 4 wks | Worldwide release | **G5** | Soft-launch KPIs held at scale 4 wks; infra cost/DAU stable; crash-free **≥99.5%**; donation transparency badge live. |
| **P6 — Live ops** | Ongoing | Sustainable cadence; deferred-feature drops | **G6 (recurring quarterly)** | D30 **≥10%**; sub conversion **≥2%**; IAP-payer **≥1.5%**; donation volume up + quarterly Impact Report shipped; "noticed AI repetition" & "felt guilt-tripped" within bounds; sustainable cadence. |

Baseline total: **~16 months**.

### 9.2 Gate validation rules

1. **Binary, conjunctive.** Every listed criterion must pass. There is no "mostly passed."
2. **Evidence-backed.** Each criterion needs an artifact: a metrics dashboard reading, a test-run log, a legal sign-off email, a reconciliation report, a persona-test write-up. "I think it's fine" is not evidence.
3. **Recorded in `current_state.json`.** Gate status (`pending` / `passed` / `failed`) + per-criterion result + evidence pointer is written to the `gates` block.
4. **No-Go branches** to one of: (a) extend the phase, (b) apply the pre-defined cut lever (e.g., cut 2nd species at G2), or (c) re-run the relevant framework and re-classify. Record the branch in `decision_log`.
5. **Forced criteria cannot be waived.** Child-safety (G3), cloud-save restore (G3), LLM cost/DAU < 35% ARPDAU (G4), donation reconciliation (G4) are non-negotiable; failing them is a hard stop, never a "ship anyway."

### 9.3 KPI targets per phase (canonical in brief §10 — referenced)

| Gate | Headline thresholds |
|---|---|
| **G1** | Loop "fun" qualitative pass; deterministic sim + offline-catch-up green; zero neglect-guilt. |
| **G2** | Persona "tell a friend" pass; AI memory callback reliability ≥95%; first-AI-line latency = 0 spinner; rig cost on-budget. |
| **G3** | D1 ≥40% · D7 ≥18%; 0 child-safety incidents; cloud-restore proven; LLM cost/DAU within model; crash-free ≥99%. |
| **G4** | D1 ≥42% · D7 ≥20% · D30 ≥10%; ARPDAU ≥ $0.03; LLM cost/DAU < 35% ARPDAU; ≥1 viral share/DAU-week; clean reconciliation. |
| **G5** | Soft KPIs held 4 wks at scale; infra cost/DAU stable; crash-free ≥99.5%; transparency badge live. |
| **G6** | D30 ≥10%; sub conversion ≥2%; IAP-payer ≥1.5%; donation volume up + quarterly Impact Report; churn indicators in bounds; sustainable cadence. |

Blended retention targets (brief §7): **D1 ~45% (40–48) · D7 ~20–22% (18–25) · D30 ~10–12% (8–14).** Worst case if AI memory disappoints: D30 → ~5–6% (genre median).

---

## 10. The Classification System

Every major feature carries exactly one of four classifications. Definitions are canonical here (this OS owns the *definitions*; the brief owns the *assignments*).

| Class | Definition | Commitment | Examples (from brief §2) |
|---|---|---|---|
| **MVP** | In the **first shippable game**. Passed FPD (≥1.5, or `MVP*` 1.0–1.49 in cheapest emotionally-intact form, or forced). | Committed. | The Bond (4.50), Rescue Day (3.33), Care Meters (2.67), Heartmind hybrid (1.29, MVP\*), Memory Book (1.67), Home Widget (1.60), Notifications (3.50), Care Streak (3.50), Keepsake Cards (2.67), Rescue Wall (2.33). |
| **MVP (forced)** | MVP regardless of FPD — a legal or architectural prerequisite. | Committed, non-negotiable. | Child-Safety Moderation (0.80), Cloud Save (0.60), Anti-fraud platform-native (—). |
| **Deferred** | Planned for **post-launch / live-ops**. FPD 0.6–0.99, or a fast-follow over a proven pipeline. | Planned, not in first ship. | Live free-form chat (6b), Voice Mimic (0.88), Lock-Screen Widget (1.00), Training (1.00), Live-Ops Events (1.17), More Species (0.75), bespoke anti-fraud ML (0.60). |
| **Removed** | **Cut entirely.** Contradicts the cozy/safe core or fails FPD < 0.6 with no emotional case. | Not built. | Health/Illness/Vet (0.80) — "comfort when sad" folds into mood instead. |
| **North-Star** | **Long-term vision** — inspiring, but **NOT committed for launch**. Often hard-constraint-excluded. | Aspirational only. | Multiplayer/Social Visiting (0.67), UGC/Custom Pet Creation (0.56). |

### 10.1 Classification rules

1. **One class per feature**, recorded in `current_state.json.features[].verdict`.
2. **`MVP*`** (conditional MVP) must carry a `cheapest_viable_version` note.
3. **Hard-constraint compliance is checked on every classification.** No multiplayer (North-Star), no UGC (North-Star), no open world, no full-voice conversation (live chat Deferred), no custom-3D (Live2D only), voice mimic Deferred.
4. **Reclassification** is a logged decision (`decision_log`), e.g., a Deferred feature promoted to a live-ops drop at G6.

---

## 11. Consolidation Rules

The DRY discipline that keeps a multi-document, solo-run system internally consistent.

### 11.1 One fact, one canonical home

Each fact lives in **exactly one** document (per the Document Map §3). All other documents **cross-link**. Duplication is a defect because it creates drift — two copies that disagree after one is edited.

### 11.2 `current_state.json` is the machine-readable SSOT for live state

The brief is the human-readable SSOT for *decisions*; `current_state.json` is the machine-readable SSOT for *live project state* (current phase, gate status, KPI actuals, cost ledger, open decisions). They must agree. On any major decision, update **both in the same commit**.

### 11.3 No document may contradict another

Contradiction is treated as a bug with a fix workflow, not a difference of opinion.

### 11.4 Contradiction-resolution workflow

```
1. Detect contradiction (manual review, or AI Consistency Auditor agent — §13).
2. Identify the canonical owner of the disputed fact (Document Map §3).
3. The canonical owner's value is correct by definition. The brief outranks all.
4. Correct every non-canonical copy to a cross-link (delete the duplicated value).
5. Log the resolution in current_state.json.decision_log.
6. Bump version + last_updated on every edited document.
```

### 11.5 Update protocol (every major decision)

On any major decision (verdict change, gate pass/fail, open-decision resolution, cost re-forecast):

- [ ] Update the **canonical owner** document (usually the brief).
- [ ] Update **`current_state.json`** to mirror it.
- [ ] Append a **`decision_log`** entry (timestamp, owner, old → new, rationale).
- [ ] Propagate **cross-links** in dependent docs (no value duplication).
- [ ] Bump **`version` + `last_updated`** on edited docs.
- [ ] If the decision changes a cost/fun/risk profile, **re-run the affected framework** (§16).

---

## 12. Operating Cadence

Rituals that keep a solo founder + AI agents moving without losing the thread. Calibrated for **one human delegating to agents** over **~16 months**.

### 12.1 Daily (founder, ~15 min ritual + work blocks)

- [ ] **Open `current_state.json`** — read `current_phase`, the active gate's pending criteria, and `open_decisions` due this phase.
- [ ] **Pick the day's deliverable** from the active phase's backlog (the one nearest a gate criterion).
- [ ] **Delegate to AI agents** the parallelizable sub-tasks (scaffolding, content generation, test harnesses — see §13). Make all independent agent calls together.
- [ ] **Log** any decision made today into `decision_log` (even small ones, if they change a number).
- [ ] **Watch the two churn indicators** once live: "noticed AI repetition," "felt guilt-tripped."

### 12.2 Weekly (founder, ~1–2 hr review)

- [ ] **Gate-progress review:** which gate criteria moved this week? Update `gates` block.
- [ ] **Cost check:** art/audio spend vs. ~$5,500 cap; LLM cost/DAU model vs. < 35% ARPDAU target (once measurable).
- [ ] **Consistency sweep:** run the **AI Consistency Auditor** (§13) across all docs; resolve any contradiction via §11.4.
- [ ] **Asset-budget review:** any new asset requested this week — did it pass the §8.2 "param/swap/tint/reuse instead?" test?
- [ ] **Risk register glance:** any of R1–R10 escalating? (Especially R1 kids-compliance, R2 LLM OPEX, R3 memory authenticity.)

### 12.3 Per-phase (at every gate)

- [ ] **Run the gate validation** (§9.2): collect evidence for every criterion.
- [ ] **AI Playtester Simulation** at the phase-appropriate depth (§6.5) — full at G2.
- [ ] **Go/No-Go decision**, recorded in `gates` + `decision_log`.
- [ ] **Resolve the phase's open decisions** (brief §12) that are due (e.g., engine at G0; 2nd species ship-or-cut at G2; donation intermediary before G4).
- [ ] **Re-forecast** cost and timeline; update `current_state.json`.
- [ ] **Snapshot:** tag the repo / archive `current_state.json` at each passed gate for auditability.

### 12.4 Phase-specific anchor rituals

| Phase | Anchor ritual |
|---|---|
| **P0** | Lock engine (Unity vs Flutter+Live2D) by **fastest solo+AI shipping path**; book legal review; build LLM unit-economics model v1; AI-concept the rig before commissioning; **create `current_state.json`**. |
| **P1** | Daily loop-feel check — "alive & cozy," zero neglect-guilt; verify deterministic sim + offline catch-up. |
| **P2** | Hand-test Maya/Tom/David weekly; track AI-memory callback reliability toward ≥95%; watch rig burn vs. 2nd-species cut lever. |
| **P3** | Closed-beta retention dashboard daily; child-safety incident watch (must be 0); cloud-restore drills; legal sign-off. |
| **P4** | Daily ARPDAU + LLM cost/DAU ratio; donation reconciliation weekly; gated adult live-chat pilot monitoring. |
| **P5** | Crash-free + infra cost/DAU watch; transparency badge live. |
| **P6** | Quarterly G6: D30, sub conversion, IAP-payer, Impact Report, sustainable-cadence honesty check; ship one Deferred feature per quarter at most. |

---

## 13. AI-Agent Operating Playbook

The force-multiplier that makes solo+AI viable. Agents are **named roles**, not freeform chats — each has a trigger, an input contract, and an output contract. The founder orchestrates; agents execute.

> **Orchestration rule:** when dispatching multiple agents with no dependency between them, fire all calls together. Only serialize when one agent's output is another's input.

### 13.1 The agent roster

| Agent | When to run | Input | Output |
|---|---|---|---|
| **FPD Scorer** | Any new feature idea; any cost/fun/risk change. | Feature description + current cost assumptions. | FUN (1–10), DOLLAR (1–10), FPD ratio, verdict band, `cheapest_viable_version`. Writes to `features[]`. |
| **Founder-Fit Auditor** | After FPD says MVP; at each phase planning. | Feature + solo+AI capacity. | Buildability + Maintainability (1–5 each), key risk, AI-leverage point, mitigation. |
| **Playtester Simulator** | P0/P1 (paper), G2 (full), supplement P3+. | Persona set + current build/spec. | D1/D7/D30 findings per persona, "tell a friend" verdict, **each finding → a design change**. |
| **Discovery/ASO Analyst** | P2–P5; before store submission. | Virality shortlist + store metadata. | K-factor levers, ASO angles, share-funnel map. |
| **Asset-Budget Warden** | Every art request. | Asset request. | Pass/reject vs. ~140-asset / ~$5,500 cap; "can it be param/swap/tint/reuse?" verdict. |
| **Consistency Auditor** | Weekly + before every gate. | All docs + `current_state.json`. | Contradiction list + canonical-owner resolution per §11.4. |
| **Dialogue-Bank Generator** | P2 onward (Heartmind hybrid build). | Persona dials + pet-state taxonomy + safety constraints. | Pre-generated, **human-reviewed** dialogue bank entries keyed by pet-state. Content production feeds `GAME_CONTENT_FACTORY.md`; runtime selection/schema in `GAME_TECHNICAL_SYSTEMS.md`. |
| **Memory-Logic Engineer** | P2 (Memory Book). | Fact-store schema (10–30 facts) + callback rules. | Fact-extraction job, callback-rotation/anti-repetition logic, ≥95%-reliability test harness. |
| **Save/Migration Engineer** | P1–P3 (Cloud Save, forced MVP). | Save schema versions. | Versioned schema, automated migration, restore-flow + drill harness. |
| **Moderation Engineer** | P2–P3 (Child-Safety, forced MVP). | Safety policy + age-gating rules. | Two-sided (input+output) moderation pipeline, safe-fallback line, self-harm static path, audit logging. |
| **Localization Agent** | P3 (static UI loc, MVP\*). | UI/copy strings. | AI-translated static UI for 4–6 launch languages; dialogue stays EN(+1–2). |
| **State Scribe** | Every major decision. | The decision. | `decision_log` entry + mirror updates to brief + `current_state.json`. |

### 13.2 Prompt patterns

**FPD Scorer pattern:**
```
You are the FPD Scorer for KindredPaws. Score this feature.
FEATURE: <description>
Constraints in force: solo+AI, ~$5,500 asset cap, no multiplayer/UGC/open-world/full-voice/custom-3D in MVP, LLM cost/DAU < 35% ARPDAU.
Output: FUN(1-10) with the 4 sub-signals, DOLLAR(1-10) with the 5 sub-signals, FPD=FUN/DOLLAR, verdict band, and the CHEAPEST VIABLE VERSION that preserves the emotional core.
Do NOT contradict KINDREDPAWS_CANONICAL_DECISION_BRIEF.md.
```

**Founder-Fit Auditor pattern:**
```
Audit <feature> for ONE founder + AI agents over 12-18 months.
Output: Buildability(1-5), Maintainability(1-5), key risk, AI-agent leverage point, concrete mitigation.
If either score <3 with no mitigation to >=3, recommend simplify/defer/remove.
```

**Playtester Simulator pattern:**
```
Simulate <persona> through D1, D7, D30 of the current KindredPaws build.
Capture: fun moments, friction, drop-off risk, "would I tell a friend?".
Track leading indicators: "noticed AI repetition", "felt guilt-tripped".
EVERY finding MUST convert to a concrete design change (or explicit accepted-risk).
```

**Consistency Auditor pattern:**
```
Read all game-os docs + current_state.json.
List every contradiction. For each: name the canonical owner (Document Map),
state the correct value, and the cross-link fix. The brief outranks all.
```

### 13.3 Agent guardrails

- Agents **never invent product facts** — they reference the brief. New facts require a logged decision.
- Agent output that touches a canonical fact must be reconciled into the canonical owner + `current_state.json` by the **State Scribe** before it's "real."
- **Human-in-the-loop is mandatory** for: the dialogue bank (review every line for wholesome/child-safe tone), moderation policy, donation/legal claims, and any gate Go/No-Go.

---

## 14. current_state.json — Schema & Update Protocol

`current_state.json` is the **machine-readable single source of truth for live project state**. It mirrors the brief and is updated on **every major decision**. It is the first artifact created in Phase 0.

### 14.1 Schema

```jsonc
{
  "schema_version": "1.0",
  "project": "KindredPaws",
  "last_updated": "2026-06-22",
  "canonical_brief": "KINDREDPAWS_CANONICAL_DECISION_BRIEF.md",
  "brief_status": "v1.0 LOCKED",

  "current_phase": {
    "id": "P0",                       // P0..P6
    "name": "Pre-production",
    "duration_weeks": 6,
    "started": "2026-06-22",
    "active_gate": "G0"
  },

  "gates": [
    {
      "id": "G0",
      "status": "pending",            // pending | passed | failed
      "criteria": [
        { "text": "Brief ratified", "met": false, "evidence": null },
        { "text": "Rig contractor secured", "met": false, "evidence": null },
        { "text": "LLM cost/DAU model < ARPDAU at projected mix", "met": false, "evidence": null },
        { "text": "Legal review booked", "met": false, "evidence": null }
      ],
      "decided_on": null
    }
    // G1..G6 stubs with their canonical criteria from brief §3/§10
  ],

  "features": [
    {
      "id": 4,
      "name": "The Bond",
      "fun": 9, "dollar": 2, "fpd": 4.50,
      "verdict": "MVP",               // MVP | MVP* | MVP(forced) | Deferred | Removed | North-Star
      "cheapest_viable_version": null,
      "owner_doc": "GAMEPLAY_AND_PROGRESSION_BIBLE.md",
      "status": "not_started"         // not_started | in_progress | done
    }
    // ...all 31+ rows from brief §2 master table
  ],

  "open_decisions": [
    { "id": 1, "text": "Engine: Unity vs Flutter+Live2D", "resolve_by_gate": "G0", "status": "open", "resolution": null },
    { "id": 2, "text": "2nd species ship-or-cut", "resolve_by_gate": "G2", "status": "open", "resolution": null }
    // ...all 10 from brief §12
  ],

  "kpis": {
    "targets": { "D1": 0.45, "D7": 0.21, "D30": 0.11, "ARPDAU": 0.03, "llm_cost_over_arpdau_max": 0.35 },
    "actuals": { "D1": null, "D7": null, "D30": null, "ARPDAU": null, "llm_cost_over_arpdau": null },
    "churn_indicators": { "noticed_ai_repetition": null, "felt_guilt_tripped": null }
  },

  "asset_ledger": {
    "unique_assets_cap": 140,
    "unique_assets_used": 0,
    "art_audio_budget_usd": 5500,
    "art_audio_spent_usd": 0,
    "rigs_commissioned": 0
  },

  "risk_register_status": [
    { "id": "R1", "name": "Kids-compliance", "severity": "Critical", "state": "open" },
    { "id": "R2", "name": "Unbounded LLM OPEX", "severity": "Critical", "state": "open" },
    { "id": "R3", "name": "AI-memory authenticity", "severity": "Critical", "state": "open" }
    // ...R4..R10 from brief §11
  ],

  "decision_log": [
    {
      "ts": "2026-06-22T00:00:00Z",
      "owner_doc": "KINDREDPAWS_CANONICAL_DECISION_BRIEF.md",
      "decision": "Brief v1.0 LOCKED",
      "old": null,
      "new": "v1.0",
      "rationale": "Reconciled all specialist conflicts; canonical seed."
    }
  ]
}
```

### 14.2 Update protocol

1. **Trigger:** any major decision — verdict change, gate pass/fail, open-decision resolution, KPI reading, cost re-forecast, risk state change.
2. **Same-commit rule:** update `current_state.json` **and** the canonical owner doc in the same commit (§11.2).
3. **Append, never silently overwrite, `decision_log`:** every change leaves an audit trail (`ts`, `owner_doc`, `decision`, `old`, `new`, `rationale`).
4. **`last_updated`** is bumped on every write.
5. **Validation before commit:** run the Consistency Auditor — `current_state.json` must not contradict the brief.
6. **Gate snapshots:** archive a copy at every passed gate for auditability.

### 14.3 Invariants (must always hold)

- `kpis.targets` exactly match brief §7/§10.
- `asset_ledger.unique_assets_used ≤ 140` and `art_audio_spent_usd ≤ 7550` (plan ≤ 5500).
- Every `features[].verdict` matches the brief §2 master table unless a logged reclassification exists.
- `current_phase.id` ∈ {P0…P6}; `active_gate` matches the phase.
- No `gates[].status == "passed"` unless **all** its `criteria[].met == true` with non-null `evidence`.

---

## 15. Definition of Done per Deliverable

A deliverable is "done" only when its checklist is fully satisfied. Generic DoD applies to all; specific DoDs layer on top.

### 15.1 Generic DoD (all deliverables)

- [ ] Has a recorded **FPD verdict** (or is explicitly forced/North-Star).
- [ ] Passed/recorded **Founder-Fit** (Buildability + Maintainability ≥3, or mitigated).
- [ ] Lives under its **canonical owner doc**; other docs cross-link (no duplication).
- [ ] Reflected in **`current_state.json`** (`features[].status` updated; `decision_log` entry if a decision changed).
- [ ] Honors **all hard constraints** (solo+AI, asset cap, no multiplayer/UGC/open-world/full-voice/custom-3D in MVP, emotion > fidelity, premium-on-low-cost).
- [ ] Does **not contradict** any other document (Consistency Auditor clean).

### 15.2 Document deliverable DoD

- [ ] Starts with an H1 title + "Document role / canonical for" note.
- [ ] Cross-links siblings by filename; duplicates no canonical fact.
- [ ] Numbers match the brief verbatim (phases, gates, currencies, KPIs, asset counts, costs).
- [ ] `version` + `last_updated` set.

### 15.3 Feature deliverable DoD (build)

- [ ] Cheapest-viable-version (for `MVP*`) is the form shipped.
- [ ] Instrumented for the relevant analytics events (~15-event set; see `GAME_TECHNICAL_SYSTEMS.md`).
- [ ] Passes the **gate criterion** it maps to (e.g., AI memory → ≥95% callback reliability at G2).
- [ ] No new asset added without **Asset-Budget Warden** approval.
- [ ] If it touches AI/dialogue: **human-reviewed** for wholesome/child-safe tone; moderation path covered.

### 15.4 Gate deliverable DoD

- [ ] Every gate criterion has **evidence** attached.
- [ ] Go/No-Go recorded in `gates` + `decision_log`.
- [ ] Open decisions due at that gate are **resolved**.
- [ ] Cost + timeline re-forecast; `current_state.json` updated.
- [ ] Gate snapshot archived.

### 15.5 Critical-feature-specific DoD

| Feature | Done means |
|---|---|
| **Heartmind hybrid (MVP\*)** | Pre-gen bank live + structured memory injects facts; **first AI line spinner-free**; LLM cost/DAU within model; under-13 = templated/non-generative only. |
| **AI Memory / Memory Book (MVP)** | Callback reliability **≥95%**, zero hallucinated facts; tangible Memory Book artifact visible; anti-repetition rotation active. |
| **Cloud Save (MVP forced)** | Versioned schema + automated migration + **restore proven**; no update can orphan a pet. |
| **Child-Safety Moderation (MVP forced)** | Two-sided moderation; safe-fallback line; self-harm static path; audit logging; **legal green-light at G3**. |
| **Donation/Impact (MVP\*)** | % NET-revenue pledge to ONE vetted intermediary; Rescue Wall shows dated receipts; **clean reconciliation at G4**; hard ethical wall enforced (never tie pet wellbeing to real donations). |
| **Care Meters (MVP)** | **No-death floor** ("sad but safe," never below); only dampen Bond gain, never reverse it; zero neglect-guilt. |
| **Care Streak (MVP)** | Forgiving; **Streak Warmth** (freeze/repair) present; never punitive. |
| **Keepsake Cards (MVP)** | 1-tap native share; tasteful watermark + pet name + actual line; no forced popup. |

---

## 16. How to Re-Run & Extend the System

The game-os is a **re-runnable pipeline**, not a one-shot. Use this when adding a feature, correcting a mistake, responding to new data (cost shifts, retention surprises), or planning a live-ops drop.

### 16.1 Re-run the full system (major pivot)

1. **Re-ingest** the GAME IDEA + HARD CONSTRAINTS + FRAMEWORKS (they are stable inputs).
2. **Re-run FPD** on the changed feature set (FPD Scorer agent).
3. **Re-run Founder-Fit** on anything whose build/maintain profile shifted.
4. **Re-run AI Playtester Simulation** for affected personas.
5. **Re-run Discovery Analysis** if the virality surface changed.
6. **Re-run Asset-Budget Discipline** if assets changed.
7. **Reconcile** conflicts into the brief (the brief wins); bump brief version.
8. **Mirror** into `current_state.json`; log every decision.
9. **Re-run Consistency Auditor** across all docs.

### 16.2 Extend with a new feature (common path)

```
[FPD Scorer] -> [Founder-Fit Auditor] -> classify (MVP/MVP*/Deferred/Removed/North-Star)
   -> [Asset-Budget Warden] if it needs art
   -> add to brief §2 master table (canonical) -> mirror to current_state.json.features[]
   -> assign to a phase + a gate criterion
   -> [State Scribe] logs the decision
   -> [Consistency Auditor] verifies no contradiction
```

A new feature **cannot be scheduled until it has an FPD verdict and a classification.**

### 16.3 Correct a mistake (per §2.3)

1. Decide: is it a **process** error (this OS) or a **product** error (the brief)?
2. Fix the **canonical owner** first.
3. Mirror to `current_state.json`; append `decision_log`.
4. Re-run affected frameworks (§16.1 steps 2–6 as relevant).
5. Bump versions; run Consistency Auditor.

### 16.4 Plan a live-ops drop (P6 / G6)

- Pull a **Deferred** feature (e.g., Lock-Screen Widget, Voice Mimic on-device, Training, 2nd species if cut at G2, breed palette-swaps).
- Re-confirm FPD + Founder-Fit at current scale; reclassify Deferred → MVP-of-this-drop.
- Respect the **honest low cadence** (≤ one Deferred feature per quarter; core retention rides on bond/memory, not new content — R8).
- Gate it through the recurring **G6** quarterly check.

### 16.5 Extension guardrails

- **Never** add a feature that violates a hard constraint to "MVP" (multiplayer, UGC, open world, full-voice conversation, custom-3D pipeline → North-Star/Deferred only).
- **Never** raise the asset cap to fit a feature; cut or simplify the feature instead (reallocate from music/SFX before touching rig quality).
- **Never** ship live free-form LLM chat to under-13 or unverified users — it stays Deferred behind age-verify + subscriber + caps + moderation (R1, R2).
- **Never** tie the pet's wellbeing/survival to real donations (hard ethical wall, R5).

---

## 17. Glossary

*Process/meta terms owned by this OS. Product terms (in **bold-italic**) are owned by the brief and listed for cross-reference.*

| Term | Meaning |
|---|---|
| **game-os** | The version-controlled documentation + state system that governs KindredPaws execution. |
| **SSOT** | Single Source of Truth. Decisions → the brief; live state → `current_state.json`. |
| **FPD** | Fun-Per-Dollar = FUN(1–10) / DOLLAR(1–10). Verdict bands: ≥1.5 strong MVP; 1.0–1.49 `MVP*`; 0.6–0.99 Defer; <0.6 Remove/North-Star. |
| **FUN** | Emotional impact + retention power + differentiation + virality (1–10). |
| **DOLLAR** | Build effort + unique-asset cost + ongoing/LLM/infra cost + technical risk + maintenance load (1–10). |
| **Cheapest viable version** | The lowest-cost form of a feature that still preserves its emotional core. Mandatory for `MVP*`. |
| **Founder-Fit Audit** | Buildability(1–5) + Maintainability(1–5) for one founder + AI agents in 12–18 months, plus key risk / AI-leverage / mitigation. |
| **AI Playtester Simulation** | Persona D1/D7/D30 walkthrough; every finding → a concrete design change; ends with "would I tell a friend?" |
| **Discovery Analysis** | Mapping of organic discovery, viral loops, K-factor levers, ASO; virality must emerge from emotion, not gimmicks. |
| **Asset-Budget Discipline** | Hard cap ~140 unique assets / ~$5,500; reuse, palette-swap, param-blend, shader-tint, AI-generation over new art. |
| **Gate (G0–G6)** | Conjunctive Go/No-Go checkpoint at each phase end; all criteria must pass with evidence. |
| **Classification** | MVP / MVP(forced) / MVP\* / Deferred / Removed / North-Star (§10). |
| **MVP (forced)** | MVP regardless of FPD — legal/architectural prerequisite (Child-Safety, Cloud Save, platform-native Anti-fraud). |
| **Consolidation / DRY rules** | One fact, one canonical home; cross-link not duplicate; no contradictions; update protocol on every decision. |
| **`current_state.json`** | Machine-readable mirror of live project state; updated on every major decision; first Phase-0 artifact. |
| **decision_log** | Append-only audit trail of every major decision (ts, owner, old→new, rationale). |
| **State Scribe / Consistency Auditor / FPD Scorer / etc.** | Named AI agents in the operating playbook (§13). |
| ***KindredPaws*** | The game (brief-owned). |
| ***The Bond*** | Affection/relationship system, 5 stages: Stranger → Friend → Companion → Kindred → Soulmate. FPD 4.50, MVP. |
| ***Heartmind*** | The AI companion layer (dialogue + memory + personality). Hybrid in MVP (FPD 1.29, MVP\*); live free-form chat Deferred. |
| ***Memory Book*** | Player-visible memory store; the load-bearing viral feature. FPD 1.67, MVP; ≥95% callback reliability. |
| ***Care Meters*** | 4 needs (hunger, energy/sleep, hygiene, happiness); no-death floor. FPD 2.67, MVP. |
| ***Care Streak / Streak Warmth*** | Forgiving habit loop with freeze/repair; never punitive. FPD 3.50, MVP. |
| ***Companion Presence*** | Daily-life integration: widgets + notifications + streaks. Home widget FPD 1.60 MVP; lock-screen FPD 1.00 Deferred. |
| ***Kibble / Heartstones / Compassion Coins*** | Soft / premium / impact currencies. Compassion Coins are non-tradeable, non-convertible, map 1:1 to real outcomes. |
| ***Forever Friends*** | Subscription (~$5.99/mo, $39.99/yr). FPD 1.25, MVP\*, single tier. |
| ***The Impact Pledge / Rescue Wall*** | Donation policy (% of NET revenue via vetted intermediary) + in-app impact UI. FPD: engine 1.33 MVP\*, wall 2.33 MVP. |
| ***Keepsake Cards*** | Auto-generated shareable artifacts; the K-factor engine. FPD 2.67, MVP. |
| ***Rescue Day / Gotcha Day*** | Adoption cold-open / anniversary. Rescue Day FPD 3.33, MVP. |
| ***The Nest*** | The pet's room (customization). FPD 1.20, MVP\* (1 room + palette-swap kit). |
| **Life stages** | Pup/Kit → Young One → Grown (3 stages via param/scale). Growth FPD 1.80, MVP. |
| **Personas** | Maya, David, Priya, Tom, Leo & Parent (brief §7). |
| **Churn indicators** | "noticed AI repetition" + "felt guilt-tripped" — mandatory leading metrics. |

---

*End of `GAME_EXECUTION_MASTER_SYSTEM.md`. This OS governs how KindredPaws is executed. For every product number, name, verdict, phase, or KPI, defer to `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md` — the brief wins all conflicts.*
