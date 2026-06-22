# KindredPaws — Master Execution Roadmap

> **Document role:** Top-level 12–18 month phased execution roadmap. **Canonical for:** phase structure, durations, gate IDs & pass criteria, the critical path, milestone definitions, KPI-by-phase, the solo-founder weekly operating cadence, and the master risk register.
>
> **Authority & consolidation:** This document derives 100% from, and never contradicts, the **KINDREDPAWS — CANONICAL DECISION BRIEF (`KINDREDPAWS_CANONICAL_DECISION_BRIEF.md`, v1.0 LOCKED, 2026-06-22)**. Where the brief defines a fact (names, numbers, FPD verdicts, gate thresholds), this roadmap reuses it verbatim and cross-links rather than redefining. The machine-readable mirror of live project state is **`current_state.json`** (created as the first action of Phase 0).
>
> **Sibling documents (cross-link, do not duplicate):**
> - `GAME_DECISION_LOG.md` — canonical FPD scores, feature classification rationale, reconciled conflicts, open decisions.
> - `GAME_TECHNICAL_SYSTEMS.md` — engine, BaaS, LLM/Heartmind architecture, memory store, moderation, save/sync, widgets, payments, ads, anti-fraud backend, Impact-Pool ledger.
> - `GAMEPLAY_AND_PROGRESSION_BIBLE.md` — core loop, Care Meters, The Bond, life-stages, Heartmind dialogue/personality design, Nest, ambient life, currencies, revenue streams, LTV model, donation player-facing loop, personas, virality mechanics, Keepsake Cards, Rescue Wall.
> - `GAME_CONTENT_FACTORY.md` — Live2D rig spec, asset budget itemization, palette-swap/param discipline, audio plan, dialogue-bank production, localization, live-ops content cadence.
> - `GAME_EXECUTION_MASTER_SYSTEM.md` — the meta-process: frameworks, gate-validation rules, classification definitions, consolidation rules, operating cadence, AI-agent playbook, `current_state.json` schema.
>
> **Status:** v1.0 · **Date:** 2026-06-22 · **Owner:** Solo Founder (+ AI-agent assistance)

---

## 1. Executive Summary & North-Star Vision

**KindredPaws** is an emotionally intelligent AI virtual-pet mobile game (iOS + Android) in which the player adopts a **RESCUED puppy or kitten** and raises it from infancy to adulthood. It fuses the mass-appeal accessibility of *My Talking Tom*, modern conversational AI, persistent daily-life integration (widgets/notifications/streaks), and real-world animal-welfare impact (a percentage of net revenue funds vetted shelters).

**Player fantasy:** *"I rescued a tiny abandoned animal, raised it with love, became emotionally attached to it, and together we made the real world a better place."*

**Genre:** Cozy Sim + Virtual Pet + Live-Service Casual.
**Core feelings (priority order):** attachment, care, responsibility, comfort, empathy, pride, meaningfulness.
**Core loop:** receive notification → open game → check pet mood/needs → interact (feed/play/talk) → gain affection + rewards → unlock growth/customization → strengthen **The Bond** → return later.
**Meta loop:** daily care → relationship growth → pet matures → unlock memories → earn **Compassion Coins** → help real shelters → feel meaningful impact → continue caring.

### 1.1 The four differentiators (and their roadmap status)

| Differentiator | Roadmap status | Why |
|---|---|---|
| **D1 — AI Companion Layer (Heartmind)** | **MVP\*** (hybrid) | LLM-pre-generated dialogue bank + structured memory + curated callbacks. The "it remembers" magic comes from the **Memory Book**, NOT free-form chat. Live free-form chat is **Deferred** (adult/subscriber-gated, post-soft-launch). |
| **D2 — Voice Mimic Layer** | **Deferred** | Not the emotional core; child-voice privacy minefield. On-device pitch-shift only, post-launch (P6). |
| **D3 — Real-World Impact Layer** | **MVP\*** | Cheapest form = % of NET revenue pledge to ONE vetted intermediary, surfaced via the **Rescue Wall**. Platform-native anti-fraud is forced-MVP; bespoke ML anti-fraud Deferred. |
| **D4 — Daily Life Integration (Companion Presence)** | **MVP** (home widget + local notifications + Care Streak); lock-screen/Live Activities **Deferred** | Home widget is the centerpiece re-engagement surface; lock-screen is a fast-follow once the pipeline is proven. |

### 1.2 North-Star Vision (long-term, NOT committed for launch)

A living companion that millions feel *lives with them*, that demonstrably channels real money to real shelters with verifiable transparency, and that — eventually — supports a gentle social/community layer and player expression. **Multiplayer/social visiting (#30)** and **UGC/custom-pet-creation (#31)** are explicit **North-Star** items, hard-excluded from MVP. The North-Star inspires sequencing; it does not expand MVP scope.

### 1.3 What "success" looks like at global launch (G5)

Soft-launch KPIs **held at scale for 4 weeks** (D1 ≥42%, D7 ≥20%, D30 ≥10%), crash-free ≥99.5%, infra cost/DAU stable, **LLM cost/DAU < 35% of ARPDAU**, a live donation transparency badge, and at least one organically viral **Keepsake Card** format per persona cohort.

---

## 2. Operating Assumptions

| Dimension | Assumption (canonical) |
|---|---|
| **Team** | Solo founder + heavy AI-agent assistance. No employees in the 12–18 month window. |
| **Platform** | Mobile, iOS + Android. Native widget interop required. |
| **Monetization** | Hybrid F2P — rewarded+sparse-interstitial ads (45–55% gross), **Forever Friends** subscription (30–40% gross, LTV anchor), cosmetic IAP (10–20%), donation-linked **Rescue Bundles** (5–10%). NO gacha/loot boxes. |
| **Audience** | Global casual players, pet lovers, Gen Z, socially conscious users. Persona cohorts: Maya, David, Priya, Tom, Leo & Parent (see §7 and `GAMEPLAY_AND_PROGRESSION_BIBLE.md`). |
| **Budget** | Indie / bootstrapped. Art+audio MVP budget **$3,500–$7,550; plan at ~$5,500** (excludes engine/LLM/infra/store fees/founder time). |
| **Timeline** | **~16 months baseline** (12–18 month band) across 7 phases (P0–P6). |
| **Scope philosophy** | Minimum asset count, maximum emotional attachment. Emotion > graphical fidelity. Premium *feel* on low production cost. |
| **CAC** | Near-zero at launch. Growth must be organic/viral; paid UA only after **sub LTV > CAC** is proven. |

### 2.1 Hard constraints (non-negotiable — enforced throughout)

1. Realistically buildable by **solo founder + AI agents** in 12–18 months.
2. Aggressively minimize asset cost.
3. **NO AAA scope.**
4. **NO multiplayer in MVP** (#30 = North-Star).
5. **NO UGC in MVP** (#31 = North-Star).
6. **NO complex open world.**
7. **NO full voice conversation in MVP** (Heartmind live free-form chat #6b = Deferred).
8. **NO custom 3D animation pipeline in MVP** (Live2D Cubism only; Spine 2D fallback).
9. Every major feature **MUST pass Fun-Per-Dollar (FPD)**.
10. **Emotional attachment > graphical fidelity.**
11. The game must **feel premium despite low production cost.**
12. The roadmap must classify every major feature as **MVP / Deferred / Removed / North-Star** (see §16).

---

## 3. Strategic Pillars

These five pillars are the lens for every Go/No-Go decision. Anything that does not serve a pillar is a candidate for cutting.

1. **Attachment is the product.** The single most important number is **The Bond** (Stranger → Friend → Companion → Kindred → Soulmate). Every system either deepens it or earns its keep some other way. The Bond gain can be *dampened* by neglect but **never reversed** — attachment is sacred.
2. **The "it remembered me" miracle, reliably.** AI memory authenticity is the load-bearing differentiator. Ship **narrow + reliable** (10–30 durable facts, ≥95% callback reliability) over **broad + flaky**. The **Memory Book** is the tangible trust artifact.
3. **Cozy, never coercive.** No-death decay floor; forgiving **Care Streak** with **Streak Warmth**; "pet missed you but is okay" longing model. Never guilt-frame, never tie the pet's wellbeing to real money.
4. **Real impact, provable, ethical.** % of NET revenue via a vetted intermediary; named partners + dated receipts + verification badge on the **Rescue Wall**. **HARD ETHICAL WALL:** the virtual pet's survival is never tied to real donations.
5. **Solo-buildable economics.** Hybrid LLM keeps OPEX bounded; managed BaaS removes server ops; minimal modular assets keep art cost ~$5,500; remote-config keeps live-ops sustainable. **LLM cost/DAU < 35% ARPDAU** is the make-or-break number.

---

## 4. Phase Map Overview

**Total baseline: ~16 months** (within the 12–18 month band). Durations are working durations; gates add brief decision/buffer time.

| Phase | Name | Duration | Cumulative | Primary Goal | Exit Gate |
|---|---|---|---|---|---|
| **P0** | Pre-production | 6 wks | wk 6 | Lock design, tech, legal frame, asset style | **G0** |
| **P1** | Core-loop prototype | 8 wks | wk 14 | Prove the daily loop is fun on cheap assets | **G1** |
| **P2** | Vertical slice | 10 wks | wk 24 | One polished, emotionally complete experience incl. AI | **G2** |
| **P3** | MVP / Closed beta | 12 wks | wk 36 | Feature-complete, store-compliant, instrumented | **G3** |
| **P4** | Soft launch | 8 wks | wk 44 | Validate retention + unit economics in 2–3 markets | **G4** |
| **P5** | Global launch | 4 wks | wk 48 | Worldwide release | **G5** |
| **P6** | Live ops | Ongoing | — | Sustainable cadence; deferred-feature drops | **G6** (recurring quarterly) |

```
P0 ████ (6w)
P1     ████████ (8w)
P2             ██████████ (10w)
P3                       ████████████ (12w)
P4                                   ████████ (8w)
P5                                           ████ (4w)
P6                                               ▶▶▶ ongoing
   |----|--------|----------|------------|--------|----|------→
  wk0  6        14         24           36       44   48
```

**Buffer policy:** P3 and P4 each carry an implicit ~10–15% schedule buffer absorbed into their durations (legal review, store-review cycles, soft-launch data collection are inherently lumpy). If the program runs hot, the canonical cut levers are, in order: (1) ship 1 species not 2 (decided at G2); (2) trim cosmetics launch count from ~30; (3) reduce launch localization languages; (4) defer the Rescue Bundle storefront to a fast-follow (keep the % net pledge live). **Never** cut: cloud save, child-safety moderation, no-death floor, donation transparency.

---

## 5. Phase 0 — Pre-production

- **Duration:** 6 weeks (wk 0–6).
- **Primary goal:** Lock design, tech, legal frame, and asset style so that every subsequent phase executes against a stable spine.

### 5.1 Key deliverables
- This roadmap + the 5 sibling docs ratified; **`current_state.json`** created as the machine-readable mirror of the canonical brief (live-state SSOT).
- **Live2D rig design LOCKED via AI concept** (Midjourney concept exploration for puppy + kitten) **before** any rig contractor is paid. See `GAME_CONTENT_FACTORY.md`.
- Rig contractor secured (2 commissioned Live2D rigs @ $1,200–$2,000 each, +15–20% revision contingency).
- Tech stack provisioned: engine decision scoped (Unity 2D **vs** Flutter + Live2D SDK — **Open Decision #1, decide at G0**); managed BaaS (Firebase or Supabase) account; RevenueCat; ad mediation account scaffolded. See `GAME_TECHNICAL_SYSTEMS.md`.
- **LLM unit-economics model v1** built (token caps, hybrid pre-gen ratio, prompt-cache assumptions) showing LLM cost/DAU < ARPDAU at projected mix. See `GAMEPLAY_AND_PROGRESSION_BIBLE.md` (economy) and `GAME_TECHNICAL_SYSTEMS.md` (LLM cost model).
- **Legal child-directedness determination scoped** and pre-launch legal review **booked** (COPPA / GDPR-K / store kids-policy). Risk R1.

### 5.2 Exit gate — **G0** (must pass ALL)
- [ ] Canonical brief ratified; all 6 docs cross-link the brief and `current_state.json` exists.
- [ ] Rig contractor secured with signed scope (2 rigs + contingency).
- [ ] LLM cost/DAU model shows **< ARPDAU** at projected revenue mix.
- [ ] Legal review **booked** (calendar + budget committed).
- [ ] **Open Decision #1 (engine)** resolved; **#3 (LLM provider + model tiers)** modeled.

### 5.3 KPI targets
- Qualitative only: brief ratified; tech/legal/asset frame locked. No live KPIs yet.

### 5.4 Phase asset budget
- **Concept-only spend:** AI concept generation (Midjourney sub ~$30–60) + rig deposit. No production art authored yet. Rig commission ($2,400–$4,000 for two, +contingency) is committed here but invoiced across P1–P2 on milestones.

### 5.5 Top risks (this phase)
- **R7 Asset-cost explosion** — mitigate by locking rig design with cheap AI concepts *before* paying the contractor; never under-budget the rig.
- **R2 Unbounded LLM OPEX** — the cost model must be honest at P0 or the whole economics premise is unproven.
- **R1 Kids-compliance** — booking legal late is the most common solo-founder fatal error; book it now.

---

## 6. Phase 1 — Core-Loop Prototype

- **Duration:** 8 weeks (wk 6–14).
- **Primary goal:** Prove the daily loop is *fun and cozy* on cheap/placeholder assets — before spending on polish or AI.

### 6.1 Key deliverables (MVP features exercised)
- **1 rig (puppy)** integrated (kitten deferred to P2).
- **Care Meters (#2, MVP)** — 4 needs: hunger, energy/sleep, hygiene, happiness (0–100 floats, gentle decay), with the **no-death floor** ("sad but safe," never below; pet can NEVER die/suffer irreversibly). See `GAMEPLAY_AND_PROGRESSION_BIBLE.md`.
- **Core care (#3, MVP)** — feed / clean / play (3 interactions only; tap + prop + reaction).
- **The Bond (#4, MVP, FPD 4.50)** — affection progression; neglect dampens *gain*, never reverses.
- **1 placeholder room** (The Nest, unpolished).
- **Local notifications (#16, MVP)** — pet-voiced, warm, never guilt; 1–2/day cap, local-scheduled (no push cost).
- Deterministic, offline-catch-up simulation (elapsed-time, server-validatable).

### 6.2 Exit gate — **G1** (must pass ALL)
- [ ] Internal playtest: core loop **"feels alive & cozy."**
- [ ] Simulation **deterministic + offline-catch-up tested**.
- [ ] **Zero neglect-guilt present** in the loop.

### 6.3 KPI targets (G1)
- Loop "fun" **qualitative pass**.
- Deterministic sim + offline-catch-up tests **green**.
- **Zero neglect-guilt** confirmed.

### 6.4 Phase asset budget
- Placeholder/derived only: puppy rig milestone payment; 1 placeholder Nest BG; minimal UI; a handful of SFX. Truly newly-drawn assets minimized — emotions are **param blends (free)**.

### 6.5 Top risks (this phase)
- **R6 Neglect-guilt / punitive streaks** — design the "pet missed you but is okay" longing model now; the loop must be cozy at the prototype stage or never.
- **R4 Save loss** — even at prototype, build the deterministic sim so cloud save can be authoritative later.
- **R7 Asset-cost** — resist polishing the placeholder room.

---

## 7. Phase 2 — Vertical Slice

- **Duration:** 10 weeks (wk 14–24).
- **Primary goal:** Deliver ONE polished, emotionally complete experience **including the AI layer** — the slice that proves the magic.

### 7.1 Key deliverables (MVP features exercised)
- **Rescue Day (#1, MVP, FPD 3.33)** — the 60–90s adoption cold-open; the player fantasy in one scene; reuses the rig.
- **Heartmind hybrid (#6, MVP\*, FPD 1.29)** — LLM-pre-generated dialogue bank + structured memory + curated callbacks. **NOT** live free-form. Cost-gated. See `GAME_TECHNICAL_SYSTEMS.md`.
- **AI Memory / Memory Book (#7, MVP, FPD 1.67)** — structured 10–30 durable-fact store; the #1 viral payload.
- **Evolving Personality (#8, MVP, FPD 1.75)** — prompt-parameterized dials; ~0 marginal cost.
- **Growth / Life-Stages (#5, MVP, FPD 1.80)** — 3 stages (Pup/Kit → Young One → Grown) via rig param/scale, **not new rigs**; #1 art-cost lever, capped at 3 stages × ≤2 species.
- **Home-Screen Widget (#14, MVP, FPD 1.60)** — centerpiece of Companion Presence; pre-rendered mood images.
- **Keepsake Cards (#24, MVP, FPD 2.67)** — templated 1-tap share artifacts.
- **2nd species (kitten) OR documented cut decision** — see gate.

### 7.2 Exit gate — **G2** (must pass ALL)
- [ ] Hand-test of personas (Maya / Tom / David) hit **"would tell a friend."**
- [ ] **AI memory callback reliability ≥95%** (no hallucinated facts); the callback lands reliably.
- [ ] **First-AI-line latency = 0 spinner** (spinner-free first line).
- [ ] **Rig pipeline cost on-budget** — **else CUT the 2nd species** (Open Decision #2; budget for 2, ship 1 if hot).

### 7.3 KPI targets (G2)
- Persona "tell a friend" **qualitative pass**.
- **AI memory callback reliability ≥95%**, zero hallucinated facts.
- First-AI-line latency: **0 spinner**.
- Rig cost **on-budget**.

### 7.4 Phase asset budget
- Kitten rig milestone (if not cut); 6 life-stage skins (derived via param/scale); 12 emotion motions (**0 new art** — param blends); Rescue Day staging on existing BG; Keepsake Card templates. This phase consumes the bulk of the **~$5,500** rig/art budget.

### 7.5 Top risks (this phase)
- **R3 AI-memory authenticity** — the load-bearing feature; gate hard at ≥95% callback reliability; ship narrow+reliable; anti-repetition rotation system.
- **R7 Asset-cost explosion** — the 2nd species is the explicit cut lever here.
- **R10 Negative virality** — lock the child-safe persona and per-turn moderation *before* any AI is hand-tested with personas.

---

## 8. Phase 3 — MVP / Closed Beta

- **Duration:** 12 weeks (wk 24–36).
- **Primary goal:** Feature-complete, store-compliant, fully instrumented MVP in a closed beta.

### 8.1 Key deliverables (full MVP feature set — see §16)
- All **MVP rows** of the feature table wired together end-to-end.
- **RevenueCat IAP/subscription** (Forever Friends $5.99/mo · $39.99/yr) + ads SDK in **child-safe config** (COPPA/kids flags; rewarded-first; no personalized ads under-13). See `GAME_TECHNICAL_SYSTEMS.md` / `GAMEPLAY_AND_PROGRESSION_BIBLE.md`.
- **Rescue Wall (#12, MVP, FPD 2.33)** — impact UI; lifetime/personal real-$, live campaign bars, dated receipts.
- **Anti-fraud (platform-native, #13, forced-MVP)** — S2S signed ad postbacks + Apple/Google receipt validation + App Attest/Play Integrity attestation gating Compassion Coin minting.
- **Cloud Save / Account (#25, forced-MVP)** — authoritative versioned cloud save + automated migration + restore flow. No update may orphan a pet.
- **Care Streak + Streak Warmth (#17, MVP, FPD 3.50)**; **Ambient Interactions (#18, MVP)**; **The Nest (#19, MVP\*)** 1 room + modular palette-swap kit; **Cosmetics Shop (#21, MVP, FPD 1.50)** ~30 pieces; **Child-Safety Moderation (#9, forced-MVP)** two-sided input+output; **Localization shell (#26, MVP\*)** static UI AI-translated.
- **Analytics (~15 events)** mapped to funnel gates, privacy-by-design, no PII — including mandatory leading-churn indicators **"noticed AI repetition"** and **"felt guilt-tripped about the pet."**
- **Legal sign-off** (R1) — the booked review completes here.
- Remote-config / data-driven event infra in place (so live-ops #27 is possible later without app updates).

### 8.2 Exit gate — **G3** (must pass ALL)
- [ ] Closed beta **D1 ≥40%** · **D7 ≥18%**.
- [ ] **0 child-safety incidents.**
- [ ] **Cloud-save restore proven.**
- [ ] **LLM cost/DAU within model.**
- [ ] **Crash-free ≥99%.**
- [ ] **Legal green-light** (Open Decision #9 resolved: under-13 handling).
- [ ] Open Decisions due by G3 resolved: **#6 (launch localization languages)**, **#7 (soft-launch geos)**.

### 8.3 KPI targets (G3)
- **D1 ≥40% · D7 ≥18%**; 0 child-safety incidents; cloud-restore proven; LLM cost/DAU within model; **crash-free ≥99%**.

### 8.4 Phase asset budget
- ~30 cosmetics (overlay sprites + palette-swap); ~52 UI/icons/widgets; Rescue Wall dashboard UI; localization string passes (AI-translated). Marginal art cost; mostly engineering + integration time.

### 8.5 Top risks (this phase)
- **R1 Kids-compliance** — the legal gate detonates here if not handled; build to child-safe standard for ALL users.
- **R5 Donation legal/charity-washing** — lawyer reviews the revenue-share claim; named partners + receipts; NO donation IAP.
- **R4 Save loss** — restore flow proven under migration before any external beta tester touches it.
- **R2 LLM OPEX** — cost/DAU must be validated against real beta traffic, not just modeled.

---

## 9. Phase 4 — Soft Launch

- **Duration:** 8 weeks (wk 36–44).
- **Primary goal:** Validate retention + unit economics in 2–3 markets before global spend/exposure.

### 9.1 Key deliverables
- Phased geo rollout (candidate markets CA / PH / NZ — **Open Decision #7, resolved by G3**).
- **Heartmind LIVE free-form chat (#6b, Deferred)** — gated PILOT for **verified adults / subscribers only**, token caps (~60–100 out), daily-turn caps, per-user cost ceiling, full moderation. Decision to expand/hold taken at G4 (Open Decision #10).
- **Donation intermediary live + first disbursement** (PayPal Giving Fund / Percent / Benevity — **Open Decision #4, decided before G4**) to **1–3 vetted partners**; first reconciliation through the **Impact Pledge** ledger. See `GAMEPLAY_AND_PROGRESSION_BIBLE.md` (Rescue Wall, donation loop) + `GAME_TECHNICAL_SYSTEMS.md` (Impact-Pool ledger backend).
- ASO assets prepared (store listing, screenshots emphasizing the rescue + before/after + impact narrative).
- Pricing elasticity instrumentation for **Forever Friends $5.99** (Open Decision #8).

### 9.2 Exit gate — **G4** (must pass ALL)
- [ ] **D1 ≥42%** · **D7 ≥20%** · **D30 ≥10%**.
- [ ] **ARPDAU ≥ $0.03.**
- [ ] **LLM cost/DAU < 35% of ARPDAU.**
- [ ] **≥1 viral Keepsake share / DAU-week.**
- [ ] **Donation reconciliation clean** (ledger matches disbursement).
- [ ] Open Decisions resolved: **#4 (intermediary + partners)**, **#5 (exact donation % per revenue type, net)**, **#10 (live-chat go/no-go for adults)**, **#8 (sub price validated)**.

### 9.3 KPI targets (G4)
- **D1 ≥42% · D7 ≥20% · D30 ≥10%**; **ARPDAU ≥$0.03**; **LLM cost/DAU < 35% ARPDAU**; **≥1 viral share / DAU-week**; clean donation reconciliation.
- Watch **leading churn indicators**: "noticed AI repetition," "felt guilt-tripped about the pet."

### 9.4 Phase asset budget
- ASO/store creative (largely composed from existing rig renders + Keepsake templates → near-zero new art). Minor localization top-ups for soft-launch geos.

### 9.5 Top risks (this phase)
- **R2 Unbounded LLM OPEX** — the live-chat pilot is the highest-cost-risk moment; the G4 cost/DAU gate is the circuit breaker.
- **R5 Donation legal** — first real disbursement must reconcile cleanly; under-promise/over-deliver, round impact claims DOWN.
- **R3 AI-memory authenticity** — soft-launch is the first time real players test "it remembered me" at volume.

---

## 10. Phase 5 — Global Launch

- **Duration:** 4 weeks (wk 44–48).
- **Primary goal:** Worldwide release.

### 10.1 Key deliverables
- Full localization push (static UI; AI-dialogue languages stay EN +1–2, expanding post-launch per-language safety validation).
- PR around the donation / tech-for-good angle; store-featuring pitch (Apple/Google editorial).
- Scaled infra (BaaS auto-scaling validated; ad mediation + RevenueCat at volume).
- **Donation transparency badge live** on the Rescue Wall (third-party "Impact verified through <date>" once volume threshold reached).

### 10.2 Exit gate — **G5** (must pass ALL)
- [ ] **Soft-launch KPIs held at scale for 4 weeks** (D1 ≥42% / D7 ≥20% / D30 ≥10%).
- [ ] **Infra cost/DAU stable.**
- [ ] **Crash-free ≥99.5%.**
- [ ] **Donation transparency badge live.**

### 10.3 KPI targets (G5)
- Soft KPIs **held 4 wks at scale**; infra cost/DAU stable; **crash-free ≥99.5%**; transparency badge live.

### 10.4 Phase asset budget
- Localization completion + store featuring creative. No new gameplay art; reuse Keepsake/rig renders.

### 10.5 Top risks (this phase)
- **R9 Cross-platform native fragmentation** — widgets/notifications/billing must hold across device matrix at scale (RevenueCat + single shared status payload mitigate).
- **R10 Negative virality** — one tone-deaf AI screenshot at launch scale defines the brand; guardrails + under-13 templated-only.
- **R8 Live-ops content treadmill** — set honest expectations: launch cadence is low; retention rides bond/memory, not content.

---

## 11. Phase 6 — Live Ops (post-launch)

- **Duration:** Ongoing.
- **Primary goal:** Sustainable cadence; ship deferred features as live-ops drops without breaking solo+AI capacity.

### 11.1 Key deliverables (Deferred features, sequenced)
- **Lock-Screen Widget / Live Activities (#15, Deferred)** — fast-follow over the home widget.
- **Voice Mimic (#10, Deferred)** — on-device DSP pitch-shift only; audio never leaves device.
- **Training / Tricks (#20, Deferred)** — live-ops drop.
- **Care Pass (seasonal pass, Deferred to live-ops)** — 4–6 wk seasonal, cosmetic/impact only.
- **Live-Ops Events (#27, Deferred)** — via remote-config architected in P3; honest cadence ~1 small moment / 6–8 weeks.
- **2nd species (if cut at G2)** + **breed palette-swaps** (#28, Deferred — palette-swaps first, new rig later).
- **Heartmind live free-form chat** expansion (if G4 go).
- **Bespoke anti-fraud anomaly/ML (#13b, Deferred)** — add when volume/social justify.
- Quarterly **Impact Report** published.

### 11.2 Exit gate — **G6** (recurring quarterly; must pass ALL)
- [ ] **D30 holding ≥10%.**
- [ ] **Sub conversion ≥2%** (MAU).
- [ ] **IAP-payer ≥1.5%.**
- [ ] **Donation volume up** + quarterly **Impact Report shipped**.
- [ ] **Content cadence sustainable solo+AI.**
- [ ] Leading-churn metrics ("noticed AI repetition," "felt guilt-tripped") within bounds.

### 11.3 KPI targets (G6, quarterly)
- D30 ≥10%; sub conversion ≥2%; IAP-payer ≥1.5%; donation volume up + Impact Report shipped; sustainable cadence.

### 11.4 Phase asset budget
- Per-drop incremental: each live-ops moment budgeted as palette-swap/param/overlay first; new rigs only when revenue justifies. Reallocate from music/SFX before EVER cutting rig quality.

### 11.5 Top risks (this phase)
- **R8 Live-ops content treadmill** — the dominant solo-founder failure mode; remote-config + honest low cadence + bond-driven retention.
- **R2 LLM OPEX** — expanding live chat must stay subscriber-funded and under the cost ceiling.
- **R5 Donation trust** — quarterly co-signed Impact Report + verification badge sustain Priya/David trust.

---

## 12. Milestone & Gate Definitions

| Gate | End of | Pass criteria (ALL required) | Resolves Open Decisions |
|---|---|---|---|
| **G0** | P0 | Brief ratified; rig contractor secured; LLM cost/DAU model < ARPDAU; legal review booked. | #1 engine; #3 LLM provider/model (modeled) |
| **G1** | P1 | Core loop "feels alive & cozy"; deterministic sim + offline-catch-up tested; zero neglect-guilt. | — |
| **G2** | P2 | Personas (Maya/Tom/David) "would tell a friend"; **AI memory callback ≥95%**, no hallucinated facts; first-AI-line **0 spinner**; rig cost on-budget (else cut 2nd species). | #2 2nd species ship/cut |
| **G3** | P3 | **D1 ≥40% / D7 ≥18%**; 0 child-safety incidents; cloud-restore proven; LLM cost/DAU within model; crash-free ≥99%; **legal green-light**. | #6 localization langs; #7 soft-launch geos; #9 under-13 handling |
| **G4** | P4 | **D1 ≥42% / D7 ≥20% / D30 ≥10%**; **ARPDAU ≥$0.03**; **LLM cost/DAU < 35% ARPDAU**; ≥1 viral share/DAU-week; clean donation reconciliation. | #4 intermediary+partners; #5 donation %; #8 sub price; #10 live-chat go/no-go |
| **G5** | P5 | Soft KPIs held 4 wks at scale; infra cost/DAU stable; **crash-free ≥99.5%**; transparency badge live. | — |
| **G6** | P6 (quarterly) | D30 ≥10%; sub conversion ≥2%; IAP-payer ≥1.5%; donation volume up + Impact Report shipped; sustainable cadence. | (recurring) |

**Gate discipline:** A gate is **No-Go** if *any* criterion fails. No-Go does not mean "abandon" — it means "do not advance; apply the canonical cut levers (§4) or remediate, then re-test." `current_state.json` records each gate result, date, and any cut-lever invoked.

---

## 13. Critical Path & Dependencies

The critical path runs through **the AI-memory miracle** and **bounded LLM economics** — these are both the differentiator and the largest existential risks (R2, R3).

### 13.1 Critical-path chain
```
Rig design lock (P0)
   └─► Puppy rig integrated (P1) ──► Care Meters + Bond + core care (P1, G1)
          └─► Heartmind hybrid + Memory Book (P2) ──► ≥95% callback reliability (G2)
                 └─► Full MVP integration + cloud save + anti-fraud + legal (P3, G3)
                        └─► Donation intermediary live + LLM cost/DAU validated (P4, G4)
                               └─► Scaled global launch (P5, G5) ──► Live ops (P6, G6)
```

### 13.2 Hard dependencies (blocking)
| Dependency | Blocks | Why |
|---|---|---|
| Live2D rig design lock (AI concept) | Rig contract payment; all life-stages | Never pay for a rig before design is locked (R7). |
| Deterministic offline-catch-up sim (P1) | Authoritative cloud save (P3); widget status payload | Save & widget both read the validated sim state. |
| Structured memory store (P2) | Memory Book; Keepsake "it remembered" card; ≥95% gate | The miracle and the #1 viral card depend on it (R3). |
| Cloud Save / Account (#25, forced-MVP) | AI memory persistence; donation ledger; entitlements | "Losing the pet = catastrophic" — prerequisite for memory/ledger/entitlements (R4). |
| Platform-native anti-fraud (#13, forced-MVP) | Compassion Coin minting; Rescue Wall integrity | Coins must be mint-gated by S2S postbacks + receipt validation + attestation. |
| Child-safety moderation (#9, forced-MVP) | Any AI exposure to users | Non-negotiable legal gate; FPD irrelevant (R1, R10). |
| Legal sign-off (P3) | Global exposure (G3→G4→G5) | Child-directedness determination drives under-13 handling. |
| Donation intermediary live (P4) | First disbursement; transparency badge (G5) | Open Decision #4 must resolve before G4. |
| Remote-config infra (P3) | All live-ops drops (P6) | Architected in MVP so P6 needs no app updates (R8). |

### 13.3 Parallelizable (off critical path)
- Cosmetics (#21) and Nest palette-swap kit (#19) can be authored in parallel by AI-assisted asset generation during P3.
- ASO creative (P4) composes from existing rig renders — no new art dependency.
- Localization string passes (#26) run in parallel once UI strings stabilize (P3).
- Keepsake Card templates (#24) can be designed during P2 alongside Heartmind.

### 13.4 The single most fragile link
**AI-memory authenticity (R3) at the G2 ≥95% callback-reliability gate.** If it fails, D30 collapses to genre median (~5–6%). Mitigation: ship narrow+reliable, make the Memory Book a tangible provable artifact, and treat ≥95% as a true blocker — do not advance to P3 on a "mostly works."

---

## 14. KPI / Success Metrics by Phase

| Phase / Gate | Retention | Economics | Quality / Safety | Differentiator-specific |
|---|---|---|---|---|
| **G1** | — (qualitative "fun") | — | Deterministic sim green; zero neglect-guilt | Loop "feels alive & cozy" |
| **G2** | — (persona "tell a friend") | Rig cost on-budget | First-AI-line 0 spinner | **AI memory callback ≥95%**, no hallucinated facts |
| **G3** | **D1 ≥40% · D7 ≥18%** | LLM cost/DAU within model | 0 child-safety incidents; crash-free ≥99%; cloud-restore proven; legal green-light | Hybrid Heartmind stable at beta scale |
| **G4** | **D1 ≥42% · D7 ≥20% · D30 ≥10%** | **ARPDAU ≥$0.03**; **LLM cost/DAU < 35% ARPDAU** | Clean donation reconciliation | **≥1 viral Keepsake share / DAU-week** |
| **G5** | Soft KPIs **held 4 wks at scale** | Infra cost/DAU stable | **Crash-free ≥99.5%** | Donation transparency badge live |
| **G6** (qtrly) | **D30 ≥10%** | **Sub conversion ≥2%; IAP-payer ≥1.5%** | Sustainable cadence | Donation volume up + Impact Report shipped |

### 14.1 Headline (blended, brief-canonical) retention targets
- **D1 ~45% (40–48) · D7 ~20–22% (18–25) · D30 ~10–12% (8–14).**
- Bimodal — hinges on (a) AI-memory authenticity and (b) the forgiving-absence model.
- **Worst case** if AI memory disappoints: **D30 → ~5–6%** (genre median).

### 14.2 Economics reference
- Blended LTV/install **$0.30–$0.80** launch (upside $1.00–1.50+); sub cohort LTV **$30–80+** (profit lever).
- Sub conversion target **1–3% MAU**; IAP-payer **1–2%**, ARPPU **$8–20**; **ARPDAU $0.03–0.06**.
- **KEY SENSITIVITY:** LLM cost/DAU **< 35% ARPDAU** — enforced by caching, hybrid pre-gen, small models, token caps, subscriber-funded live chat. (Full economy model in `GAMEPLAY_AND_PROGRESSION_BIBLE.md`; LLM/infra cost model in `GAME_TECHNICAL_SYSTEMS.md`.)

### 14.3 Mandatory leading-churn indicators (instrument from P3)
- **"noticed AI repetition"** and **"felt guilt-tripped about the pet"** — these predict D7/D30 collapse before raw numbers move. ~15 analytics events total, mapped to funnel gates.

---

## 15. Solo-Founder + AI Weekly Operating Cadence

A sustainable rhythm is itself a risk mitigation (R8). The founder is the bottleneck; AI agents are the throughput multiplier. The cadence below assumes a focused solo founder week and is designed to be **maintainable indefinitely**, not heroic.

### 15.1 Weekly rhythm

| Day | Focus | Founder role | AI-agent leverage |
|---|---|---|---|
| **Mon** | Plan + state | Review `current_state.json`; set the week's 3 outcomes against the active phase gate. | Agents draft the week plan from gate criteria; summarize last week's analytics deltas. |
| **Tue** | Build (deep work) | Critical-path engineering (sim, Heartmind integration, cloud save, anti-fraud). | Agents scaffold code, write migrations, generate test cases, draft dialogue-bank entries for human review. |
| **Wed** | Build (deep work) | Continue critical path; integration. | Agents pair-program, refactor, generate boilerplate UI, propose param/palette-swap asset variants. |
| **Thu** | Content + assets | Author/curate dialogue bank, cosmetics, Keepsake templates; review AI-generated assets against asset budget. | Agents generate cosmetics overlays, localization passes, marketing copy; flag asset-budget overruns. |
| **Fri** | Test + safety + ship | Playtest the loop; run moderation/safety checks; cut a build; review leading-churn signals. | Agents run regression suites, summarize playtest notes, audit moderation logs, draft release notes. |
| **Sat (light)** | Community + impact | Respond to beta/community; check donation ledger reconciliation (P4+). | Agents triage feedback, draft community replies for approval, prep Impact Report sections. |
| **Sun** | Rest / buffer | Off, or absorb slippage. | — |

### 15.2 Cadence guardrails (cozy applies to the founder too)
- **One critical-path outcome per week minimum** tied to the active gate; everything else is secondary.
- **AI does the volume, the founder owns the judgment** — especially dialogue-bank curation (R3) and safety review (R1, R10). Never ship AI-authored child-facing dialogue unreviewed.
- **Asset-budget check every Thursday** against the ~140-asset / ~$5,500 cap; an over-budget request must be justified by FPD or rejected.
- **Update `current_state.json` on every major decision** — it is the SSOT for live state and the next week's plan.
- **Gate weeks** are decision weeks: freeze new scope, run the Go/No-Go checklist (§17), record the result.
- **Live-ops cadence (P6)** is honestly low: ~1 small content moment / 6–8 weeks. Retention rides bond/memory, not a content treadmill.

### 15.3 Monthly & quarterly rhythm
- **Monthly:** reconcile budget vs. ~$5,500 asset cap and LLM OPEX vs. model; review the risk register (§16) for status changes.
- **Quarterly (P6):** publish the **Impact Report**; run the recurring **G6** gate; re-rank live-ops backlog by FPD.

---

## 16. Master Risk Register & Mitigations

*(Canonical top-10 from the brief, plus phase-mapping. Severity and mitigations are verbatim-aligned to the brief.)*

| # | Risk | Sev | Mitigation (canonical) | Owned-by-gate |
|---|---|---|---|---|
| **R1** | Kids-compliance (COPPA/GDPR-K/store kids policy) — existential; detonated by AI chat, voice capture, ad targeting. | Critical | Build to child-safe standard for ALL users; hybrid (templated under-13, no free-text storage from minors); no behavioral ad targeting; **mandatory budgeted pre-launch legal review**. | G3 |
| **R2** | Unbounded LLM OPEX scales with engagement (anti-F2P economics). | Critical | Hybrid pre-gen + structured memory; small/cheap model; prompt-caching; token + daily-turn caps; live chat subscriber-only & age-gated; **cost/DAU < 35% ARPDAU**. | G4 |
| **R3** | AI-memory authenticity — the single load-bearing feature; flaky recall = "theater" across personas. | Critical | Narrow+reliable memory over broad+flaky; tangible **Memory Book** trust signal; **≥95% callback reliability**; anti-repetition rotation. | G2 |
| **R4** | Save loss / pet "death" = refund + 1-star + broken trust. | High | Authoritative versioned cloud save + automated migration + restore flow; **no-death decay floor**. | G3 |
| **R5** | Donation legal/charity-washing — vague/coercive = backlash (Priya) + regulatory. | High | % NET-revenue pledge via vetted intermediary; named partners + receipts + verification badge; hard ethical wall; lawyer review; **NO donation IAP**. | G4 |
| **R6** | Neglect-guilt / punitive streaks churn highest-LTV personas + violate cozy brand. | High | "Pet missed you but is okay" longing model; **Streak Warmth** (freeze/repair); never punish absence. | G1 |
| **R7** | Asset-cost explosion (multi-species, per-stage animation, cosmetics). | High | 1 modular Live2D rig/species; 3 stages via param/scale; overlay cosmetics + palette-swap; **defer 2nd species at G2 if hot**; never under-budget the rig. | G2 |
| **R8** | Live-ops content treadmill exceeds solo+AI capacity → post-launch churn. | Medium | Remote-config/data-driven event infra in MVP; honestly low launch cadence (1 small moment / 6–8 wks); core loop retains via bond/memory. | G6 |
| **R9** | Cross-platform native fragmentation (widgets/notifications/billing). | Medium | RevenueCat for billing; single shared status payload → one widget/platform; local notifications MVP; **defer lock-screen/Live Activities**. | G5 |
| **R10** | Negative virality — one tone-deaf/unsafe AI screenshot defines the brand. | Med-High | Hard guardrails + child-safe persona lock + per-turn moderation; many small authentic moments over one engineered spectacle; **under-13 templated-only**. | G2/G5 |

**Risk review cadence:** monthly status pass + at every gate. Status changes recorded in `current_state.json`.

---

## 17. Feature Classification Summary

*(Canonical master table from the brief. FPD verdicts are authoritative; full rationale and reconciled conflicts live in `GAME_DECISION_LOG.md`.)*

| # | Feature | FPD | Verdict |
|---|---|---|---|
| 1 | Rescue Day (adoption cold-open) | 3.33 | **MVP** |
| 2 | Care Meters (4 needs / mood) | 2.67 | **MVP** |
| 3 | Core care (feed/clean/play) | 2.67 | **MVP** |
| 4 | The Bond (affection progression) | 4.50 | **MVP** |
| 5 | Growth / Life-Stages | 1.80 | **MVP** |
| 6 | Heartmind dialogue (HYBRID) | 1.29 | **MVP\*** |
| 6b | Heartmind LIVE free-form LLM chat | 1.29 | **Deferred** |
| 7 | AI Memory (Memory Book) | 1.67 | **MVP** |
| 8 | Evolving Personality | 1.75 | **MVP** |
| 9 | Child-Safety Moderation | 0.80 | **MVP (forced)** |
| 10 | Voice Mimic Layer | 0.88 | **Deferred** |
| 11 | Donation/Impact Engine | 1.33 | **MVP\*** |
| 12 | Rescue Wall (impact UI) | 2.33 | **MVP** |
| 13 | Anti-fraud (platform-native) | — | **MVP (forced)** |
| 13b | Anti-fraud (bespoke anomaly/ML) | 0.60 | **Deferred** |
| 14 | Home-Screen Widget | 1.60 | **MVP** |
| 15 | Lock-Screen Widget / Live Activities | 1.00 | **Deferred** |
| 16 | Notifications (pet-voiced) | 3.50 | **MVP** |
| 17 | Care Streak (+ Streak Warmth) | 3.50 | **MVP** |
| 18 | Ambient Interactions (idle life) | 1.75 | **MVP** |
| 19 | The Nest (decoration) | 1.20 | **MVP\*** |
| 20 | Training / Tricks | 1.00 | **Deferred** |
| 21 | Cosmetics Shop | 1.50 | **MVP** |
| 22 | Subscription (Forever Friends) | 1.25 | **MVP\*** |
| 23 | Ads (rewarded + sparse interstitial) | 1.33 | **MVP** |
| 24 | Keepsake Cards (sharing/virality) | 2.67 | **MVP** |
| 25 | Cloud Save / Account | 0.60 | **MVP (forced)** |
| 26 | Localization (static UI) | 1.25 | **MVP\*** |
| 27 | Live-Ops Events | 1.17 | **Deferred** |
| 28 | More Species / Breeds (beyond 2) | 0.75 | **Deferred** |
| 29 | Health / Illness / Vet | 0.80 | **Removed** |
| 30 | Multiplayer / Social Visiting | 0.67 | **North-Star** |
| 31 | UGC / Custom Pet Creation | 0.56 | **North-Star** |

**FPD verdict bands:** ≥1.5 strong MVP · 1.0–1.49 MVP only if simplified to cheapest emotionally-intact form (**MVP\***) · 0.6–0.99 Defer · <0.6 Remove/North-Star. Forced-MVP dependencies (#9, #13, #25) are MVP regardless of FPD.

**Hard-constraint compliance check:** No multiplayer (#30 North-Star), no UGC (#31 North-Star), no open world, no full-voice conversation (#6b Deferred), no custom-3D (Live2D only), voice mimic Deferred (#10). All satisfied.

---

## 18. Go / No-Go Checklists

> Run at the end of each phase during the gate week. **Any** unchecked box = **No-Go**: do not advance; apply canonical cut levers (§4) or remediate, re-test, and record the result in `current_state.json`.

### G0 — Pre-production → Core-loop prototype
- [ ] Canonical brief ratified; 6 docs cross-link it; `current_state.json` created.
- [ ] Rig contractor secured (2 rigs + 15–20% contingency); rig design locked via AI concept.
- [ ] LLM cost/DAU model shows < ARPDAU at projected mix.
- [ ] Pre-launch legal review booked (calendar + budget).
- [ ] Open Decision #1 (engine: Unity vs Flutter+Live2D) resolved; #3 (LLM provider/model) modeled.

### G1 — Core-loop prototype → Vertical slice
- [ ] Internal playtest: core loop "feels alive & cozy."
- [ ] Deterministic simulation + offline-catch-up tested and green.
- [ ] Zero neglect-guilt present in the loop.

### G2 — Vertical slice → MVP / Closed beta
- [ ] Personas (Maya/Tom/David) hit "would tell a friend."
- [ ] AI memory callback reliability ≥95%, zero hallucinated facts.
- [ ] First-AI-line latency = 0 spinner.
- [ ] Rig pipeline cost on-budget — **else cut 2nd species** (Open Decision #2).

### G3 — MVP / Closed beta → Soft launch
- [ ] Closed beta D1 ≥40% · D7 ≥18%.
- [ ] 0 child-safety incidents.
- [ ] Cloud-save restore proven (under schema migration).
- [ ] LLM cost/DAU within model.
- [ ] Crash-free ≥99%.
- [ ] Legal green-light (Open Decision #9 under-13 handling resolved).
- [ ] Open Decisions #6 (localization langs), #7 (soft-launch geos) resolved.

### G4 — Soft launch → Global launch
- [ ] D1 ≥42% · D7 ≥20% · D30 ≥10%.
- [ ] ARPDAU ≥ $0.03.
- [ ] LLM cost/DAU < 35% of ARPDAU.
- [ ] ≥1 viral Keepsake share / DAU-week.
- [ ] Donation reconciliation clean (first disbursement).
- [ ] Open Decisions #4 (intermediary+partners), #5 (donation %), #8 (sub price), #10 (live-chat go/no-go) resolved.

### G5 — Global launch → Live ops
- [ ] Soft-launch KPIs held at scale for 4 weeks (D1 ≥42% / D7 ≥20% / D30 ≥10%).
- [ ] Infra cost/DAU stable.
- [ ] Crash-free ≥99.5%.
- [ ] Donation transparency badge live.

### G6 — Live ops (recurring quarterly)
- [ ] D30 holding ≥10%.
- [ ] Sub conversion ≥2% (MAU).
- [ ] IAP-payer ≥1.5%.
- [ ] Donation volume up + quarterly Impact Report shipped.
- [ ] Content cadence sustainable solo+AI.
- [ ] Leading-churn metrics ("noticed AI repetition," "felt guilt-tripped") within bounds.

---

*End of GAME_MASTER_EXECUTION_ROADMAP.md — v1.0. Canonical for phase/gate structure, critical path, KPI-by-phase, weekly cadence, and master risk register. All facts derive from the KindredPaws Canonical Decision Brief v1.0 LOCKED; live state mirrored in `current_state.json`.*
