# KindredPaws — GAME_CONTENT_FACTORY.md
### Content Factory & Asset Pipeline

> **Document role / canonical for:** This document is the **single canonical source of truth** for *how content gets made* on KindredPaws — the asset budget, art direction, production pipelines, animation/audio/writing factories, localization, live-ops content cadence, AI-agent content workflows, content QA tooling, the asset-reuse matrix, and IP/licensing/content risk. It **owns the asset numbers, the style decision, and the content cadence.**
>
> It does **not** redefine systems, economy, tech architecture, or KPIs — those live in their canonical docs and are cross-linked here. Where this doc cites a number, name, phase, gate, or classification, it is reused **verbatim** from the **KindredPaws Canonical Decision Brief (`KINDREDPAWS_CANONICAL_DECISION_BRIEF.md`, v1.0 LOCKED, 2026-06-22)** and mirrored in `current_state.json`.
>
> **Authority order:** `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md` → `current_state.json` → this document. If any line below ever conflicts with the brief, the brief wins and this file must be corrected.
>
> **Sibling documents (cross-link, do not duplicate):**
> - `GAMEPLAY_AND_PROGRESSION_BIBLE.md` — core loop, Care Meters behavior, The Bond, life-stages design intent; currencies, pricing, ad/sub/IAP/bundle design, LTV/ARPDAU model; Heartmind dialogue/affection design; Impact Pledge player-facing loop, Rescue Wall, donation trust model; personas, virality/Keepsake mechanics.
> - `GAME_TECHNICAL_SYSTEMS.md` — engine, Live2D runtime, widget payload, save/sync, Heartmind LLM proxy + memory store schema, moderation pipeline, anti-fraud backend + Impact-Pool ledger.
> - `GAME_DECISION_LOG.md` — locked FPD verdicts, donation-ethics decisions, ADRs, reconciled conflicts.
> - `GAME_MASTER_EXECUTION_ROADMAP.md` — phases/gates, critical path, KPI-by-phase, live-ops drop schedule.
> - `GAME_EXECUTION_MASTER_SYSTEM.md` — frameworks, classification definitions, consolidation rules, AI-agent playbook.
>
> **Greenfield note:** Working directory `/home/emre/Downloads/my-talking-tom/game-os/` is empty at authoring time. First Phase-0 (**P0**) action remains: create `current_state.json` as the machine-readable mirror of the brief; this doc registers its owned facts there.

---

## Table of Contents
1. [Content Philosophy](#1-content-philosophy)
2. [Art Direction & Style](#2-art-direction--style)
3. [Asset Budget & Inventory](#3-asset-budget--inventory)
4. [Asset Production Pipelines](#4-asset-production-pipelines)
5. [Animation Strategy](#5-animation-strategy)
6. [Audio Strategy](#6-audio-strategy)
7. [Writing & Narrative Content Factory](#7-writing--narrative-content-factory)
8. [Localization Strategy](#8-localization-strategy)
9. [Live-Ops Content Cadence](#9-live-ops-content-cadence)
10. [AI-Agent Content Workflows](#10-ai-agent-content-workflows)
11. [Content QA & Pipeline Tooling](#11-content-qa--pipeline-tooling)
12. [Asset Reuse Matrix](#12-asset-reuse-matrix)
13. [IP / Licensing / Content Risk](#13-ip--licensing--content-risk)

---

## 1. Content Philosophy

**Thesis: minimum assets, maximum attachment.** KindredPaws does not win on volume or fidelity. It wins on the *felt* relationship between the player and one rescued animal. Per Hard Constraint #10 (*emotional attachment > graphical fidelity*) and #11 (*feel premium despite low production cost*), every content decision is judged on **emotional return per dollar**, not pixel count.

### 1.1 The four content laws
1. **One pet, deeply, beats a zoo, shallowly.** The MVP ships exactly **2 species** (1 puppy + 1 kitten — canonical names: **Biscuit** the puppy, **Mochi** the kitten in all docs/marketing). Everything else is reuse. (Brief §1, §4; 2nd species is the **#1 cut lever at G2** — see §3.4.)
2. **Reuse is the default; new art is the exception that must justify itself.** Per **ASSET-BUDGET DISCIPLINE**, every art request is scored against **Fun-Per-Dollar (FPD)** before it is commissioned. If a need can be met by a rig parameter, a palette-swap, an overlay sprite, a shader tint, or a sequence of existing assets, it **must** be — no new authored art.
3. **The emotional payload lives in writing, timing, and memory — not in art.** The viral moments (Brief §8) — *Unprompted Comfort*, *Long Memory Callback*, *Before/After Growth* — are mostly **text + composition + timing**, the cheapest content we make. We over-invest writing/memory and under-invest art on purpose.
4. **Premium = consistency + polish + restraint, not quantity.** A small, perfectly-tuned, tonally-coherent asset set reads as premium. A large, inconsistent one reads as cheap. We protect coherence by capping the palette, the rig count, and the prop kit (§2, §3).

### 1.2 What "premium on a budget" concretely means here
| Lever | Cheap-but-cheap (avoid) | Cheap-but-premium (our choice) |
|---|---|---|
| Pet rendering | Many low-effort static sprites | **One hand-tuned Live2D rig per species**, expressive via params |
| Variety | Many distinct objects | **Modular palette-swap kit** + day/night shader tints on 4 reused BGs |
| "Aliveness" | Idle frame | **Ambient Interactions** (MVP) — sequencing existing motions/SFX |
| Emotion | Voice acting | **Pet-voiced text + curated nonverbal pet sounds + perfect timing** |
| Novelty over time | Constant new art | **Heartmind memory callbacks** — novelty from *the player's own life*, ~0 marginal art cost |

### 1.3 Content classification rule (applies to every asset/system below)
Every content area is tagged with its brief verdict: **MVP**, **MVP\*** (cheapest emotionally-intact form only), **Deferred**, **Removed**, or **North-Star**. Content for **Removed** features is never produced; content for **Deferred** features is *architected-for* but not *authored* until live-ops. Examples carried throughout:
- Voice Mimic Layer — **Deferred** (FPD 0.88) → no voice-mimic audio assets in MVP.
- Training / Tricks — **Deferred** (FPD 1.00) → no trick animations in MVP (animation-expensive).
- Health / Illness / Vet — **Removed** (FPD 0.80) → **zero** illness/vet art, ever; "comfort when sad" folds into mood.
- UGC / Custom Pet Creation — **North-Star** (FPD 0.56) → no pet-creator content tooling exposed to players.

---

## 2. Art Direction & Style

### 2.1 The premium-on-a-budget style decision

**DECISION (canonical, Brief §4): Live2D Cubism, one rig per species. Fallback: Spine 2D-skeletal. NO custom 3D (honors Hard Constraint #8).**

#### Why Live2D over the alternatives (the explicit trade study)
| Option | Premium feel | Asset cost | Solo+AI buildable | Verdict |
|---|---|---|---|---|
| **Custom 3D (rig + anim pipeline)** | High | Very high (modeling, rigging, anim, lighting) | No — violates Constraint #8 | **Rejected (constraint)** |
| **Frame-by-frame 2D animation** | High *if* huge frame count | Very high (every emote = new frames × stages × species) | No — frame explosion | **Rejected (cost)** |
| **Static sprites + tween** | Low/medium | Low | Yes | Rejected — reads cheap, no "aliveness" |
| **Spine 2D-skeletal** | High | Medium | Yes | **Fallback** — chosen if Live2D runtime integration runs hot at G0 |
| **Live2D Cubism** | **High (soft, organic, breathing deformation)** | **Low marginal (params, not frames)** | **Yes (1 rig, AI-assisted concept)** | **CHOSEN** |

**How the style hides cost (the core trick):** In Live2D, one hand-built rig exposes *parameters* (eye open, mouth shape, head angle, ear droop, tail wag, body breathe, blush, tears). Every emotion, every life-stage, every emote is a **blend of those parameters** — i.e., **data, not new art**. The expensive thing (the rig) is bought **once per species**; all expressivity afterward is essentially free. This is the single most important economic decision in the entire content factory and the direct reason the art budget fits an indie envelope.

### 2.2 Visual style guide (the look)
- **Genre read:** Cozy Sim / Virtual Pet. Soft, warm, hand-illustrated, slightly chunky-cute (My Talking Tom mass-appeal + Finch/cozy warmth + Nintendogs sincerity). Friendly to a 9-year-old (Leo) and not cringe to a 19-year-old (Maya).
- **Line & form:** Soft rounded shapes, gentle line weight, large expressive eyes (the bonding surface). No realism, no horror-adjacent uncanny detail (protects Constraint: emotional safety, child-friendly).
- **Palette (LOCKED, capped):** One master palette of **~16 swatches** + a small **warm/cool tint pair** for day/night. Capping the palette is a primary premium-coherence lever and feeds the palette-swap cosmetic pipeline (§4.3).
  - Core warm neutrals (creams, soft browns), accent warm (peach/coral for affection cues), calm cool (dusk blue/lavender for night & comfort moments), 2 species-fur base ranges (puppy golden/brown, kitten grey/cream).
- **Environment style:** **The Nest** (the pet's room) — one warm, cozy interior. **4 environments total** (Brief §4): Nest (day), Nest (night/dusk via shader tint), Rescue Day cold-open scene, one outdoor/window vignette. Day/night/weather are **shader tints on the same BGs**, never new BG art.
- **UI style:** Soft cards, rounded corners, generous spacing, large tap targets (kid + casual friendly), high-contrast accessible text. UI is a content category (~52 UI/icons/widgets in inventory) and follows the same palette lock.
- **Watermark / share style:** **Keepsake Cards** (MVP, FPD 2.67) use a single tasteful templated frame + small watermark + pet name + the actual line. One template family, palette-locked. (Distribution/virality owned by `GAMEPLAY_AND_PROGRESSION_BIBLE.md`.)

### 2.3 Style-to-emotion mapping (what art must deliver)
The art exists to serve the **CORE FEELINGS** in priority order: *attachment, care, responsibility, comfort, empathy, pride, meaningfulness.* Concretely:
- **Eyes + ear/tail droop** carry attachment & comfort (the rig's most-tuned params).
- **Life-stage growth** (Pup/Kit → Young One → Grown) carries pride & "I raised it" (Brief §1 life stages).
- **Rescue Day** scene carries the rescue/responsibility hook in 60–90s.
- **Rescue Wall + impact badges** carry meaningfulness (data-driven UI owned by `GAMEPLAY_AND_PROGRESSION_BIBLE.md`, ledger backend by `GAME_TECHNICAL_SYSTEMS.md`; art assets here).

---

## 3. Asset Budget & Inventory

> **This section is canonical for asset counts and USD.** Mirrors Brief §4 exactly. `current_state.json` reflects these numbers; any change requires a brief amendment.

### 3.1 Headline budget (LOCKED)
- **Total unique authored assets (MVP): ~140.**
- **Truly newly-drawn ≈ 65** — the rest are derived via rig params + palette-swaps + shader tints + sequencing.
- **Total art/audio budget: $3,500–$7,550; plan at ~$5,500.**
- **Excludes:** engine, LLM, infra, store fees, and founder time.
- **Hero spend:** **2 commissioned Live2D rigs @ $1,200–$2,000 each.** Lock design with **AI concept (Midjourney)** *before* paying for a rig. Add **15–20% contingency** for rig revision rounds. (See §4.2.)

### 3.2 Full asset inventory table
| # | Asset category | Count (MVP) | Production method | Reuse / derivation | Est. USD |
|---|---|---|---|---|---|
| 1 | **Live2D rigs (hero)** | **2** (puppy, kitten) | Commissioned rig artist; AI-concept-locked first | Base for ALL motion, stages, emotes | **$2,400–$4,000** (+15–20% contingency) |
| 2 | **Life-stage skins** | **6** (3 stages × 2 species) | Rig **param/scale + texture variant**, NOT new rigs | Same rig, parameterized | $200–$600 (texture passes) |
| 3 | **Emotion motions** | **12** | Param blends authored in Cubism | **0 new art** (data only) | $0 (founder time) |
| 4 | **Environments (BGs)** | **4** | AI-assisted illustration → cleanup | Day/night/weather = shader tints (no new BG) | $150–$400 |
| 5 | **Props** | **25** | AI-assisted + asset-store base + cleanup | Reused across Nest/care interactions | $150–$400 |
| 6 | **Cosmetics** | **30** | **Overlay sprites + palette-swaps** | Layer on rig; palette-swap multiplies variety | $200–$500 |
| 7 | **UI / icons / widgets** | **~52** | AI-assisted + founder vector cleanup | Single design system, palette-locked | $150–$450 |
| 8 | **FX** | **12** | Shader/particle + sprite sheets | Reused (hearts, sparkles, Zzz, comfort glow) | $50–$200 |
| 9 | **Audio (SFX + pet sounds)** | **~48** | Licensed library + light edit | Layered/pitch-varied reuse | $100–$400 |
| 10 | **Music** | **5** | Licensed/royalty-free + loop edit | Day/night/menu/emotional/Rescue Day | $100–$300 |
| | **TOTAL** | **~140** | | | **~$3,500–$7,550 (plan ~$5,500)** |

> **Note:** Categories 3 and 8 are mostly **founder time + tooling**, not cash. The cash concentrates in the rigs (Category 1) — which is exactly why **Risk R7** says *never under-budget the rig* and *reallocate from music/SFX before EVER cutting rig quality* (Brief §4 discipline rules, §11 R7).

### 3.3 Asset-budget discipline rules (LOCKED, Brief §4)
- [ ] **Cap 2 species.** No third species art in MVP (more species = **Deferred**, FPD 0.75).
- [ ] **3 life-stages via scale/param**, not new rigs.
- [ ] **Emotions = param blends** (free).
- [ ] **Day/night/weather = shader tints** on the same 4 BGs.
- [ ] **Cosmetics = overlay sprites + palette-swap.**
- [ ] **Reallocate from music/SFX before EVER cutting rig quality.**
- [ ] Every art request justified against FPD before commission.

### 3.4 The G2 cut lever (budget contingency)
Per Brief §2 (resolved conflict #3) and §11 R7: **budget for 2 species, ship 1 if forced.** The decision is made at the **P2 Vertical-slice gate (G2)** based on **rig-pipeline cost burn**. If the rig pipeline runs hot:
- **Cut:** the 2nd species rig (kitten) → saves ~$1,200–$2,000 + contingency + its 3 life-stage skins + species-specific SFX.
- **Keep:** all writing, memory, Bond, Care Meters, Heartmind, Rescue Wall (species-agnostic).
- **Recover:** ship 2nd species in **P6 Live-ops** (Brief §3) as the first major content drop.

### 3.5 Spend phasing against the brief timeline
| Phase | Content spend focus | Approx. cash committed |
|---|---|---|
| **P0 (6 wks)** | AI concept exploration (Midjourney sub ~$30/mo); **lock rig design before paying**; style guide; palette lock | < $100 |
| **P1 (8 wks)** | **1 rig (puppy)** commissioned; 1 placeholder room; core SFX seed | $1,200–$2,000 |
| **P2 (10 wks)** | **2nd rig (kitten) OR cut**; life-stage skins; Rescue Day BG; Keepsake template; full emote set | $1,400–$3,000 |
| **P3 (12 wks)** | Cosmetics (~30), full UI/icons/widgets, FX, audio fill, localization shell art | $700–$1,500 |
| **P4–P5** | ASO store assets, polish; no new core art | $200–$500 |
| **P6 (live-ops)** | Drop cadence (see §9): 2nd species if cut, breed palette-swaps, Care Pass cosmetics | Per-drop, funded by revenue |

---

## 4. Asset Production Pipelines

Four production lanes, in priority order of use: **(A) AI-assisted generation**, **(B) modular/reuse**, **(C) procedural/runtime**, **(D) asset-store licensing**. The founder + AI agents run these; the only outside human is the **rig contractor** (secured at **G0**, Brief §3 gate).

### 4.1 Lane A — AI-assisted generation
- **Tools:** Midjourney (concept/illustration), an SD/img2img tool for variants, vector cleanup in Figma/Inkscape, background removal + cleanup, AI upscaling.
- **Used for:** environment concepts (4 BGs), props (25), cosmetic concepts (30), UI/icon concepts (~52), Rescue Day scene, store/ASO art, Keepsake frame.
- **Hard rule:** **AI generates concepts and bases; the founder finalizes** (palette-lock, cleanup, consistency pass). AI output is never shipped raw — it must pass the palette/style coherence check (§11) to preserve premium feel.
- **Critical IP rule:** the **Live2D rig itself is NOT AI-generated** — it is human-commissioned from an AI-locked *concept*, which protects copyright on the hero asset (see §13).

### 4.2 The rig pipeline (the hero pipeline)
This is the make-or-break art pipeline and the single largest cash item.
1. **P0:** Founder + AI explore in Midjourney → produce a **locked concept sheet** (front/side, expression range, life-stage silhouettes) for puppy and kitten in the locked palette.
2. **G0 gate:** **rig contractor secured** (Brief §3 G0 pass criterion). Concept handed off — never pay for a rig before the concept is locked (Brief §4).
3. **P1:** Puppy rig delivered → integrated into engine (Live2D Cubism runtime, see `GAME_TECHNICAL_SYSTEMS.md`).
4. **P2:** Kitten rig delivered **or cut** (G2 decision, §3.4). Life-stage skins derived. Full emote param set authored.
5. **Contingency:** budget **15–20%** for revision rounds; keep contractor scope to *rig + base params + 3 life-stage texture variants* — emotes are authored in-house from params (free).

### 4.3 Lane B — Modular & reuse
- **Cosmetics as overlays:** every cosmetic is an **overlay sprite** anchored to rig points (collar, hat, bandana) + **palette-swaps** of a base shape. One "collar" mesh → many color variants → many SKUs at ~0 marginal art cost. Powers the **Cosmetics Shop** (MVP, FPD 1.50, ~30 pieces at launch) and **The Nest** decoration (MVP\*, FPD 1.20 — *1 room + modular palette-swap kit only*).
- **Prop kit reuse:** the 25 props serve feed/clean/play (Core care, MVP, FPD 2.67) and Nest decoration; no interaction gets bespoke props.
- **UI design system:** ~52 UI assets are one component library (cards, buttons, meters, badges) reused everywhere; widget art is pre-rendered mood images from this system.

### 4.4 Lane C — Procedural & runtime
- **Day/night/weather:** runtime **shader tints** on the 4 BGs (warm/cool pairs from the palette). No new BG art ever for time-of-day. (Brief §4, §6.)
- **Emotion blends:** runtime param interpolation drives the 12 emotion motions and all in-between states.
- **FX:** particle systems (hearts, sparkles, Zzz, comfort glow, growth shimmer) parameterized by mood/Bond/event — 12 FX cover the whole game.
- **Keepsake Card composition:** runtime templated composition (rig snapshot + line + watermark + pet name) — **no pre-authored card per event** (Brief §8 "templated composition").
- **Widget snapshots:** the **single shared "pet status snapshot" payload** (Brief §6) feeds widget + notification scheduler from pre-rendered mood images — not a live rig render (perf + battery).

### 4.5 Lane D — Asset-store licensing
- **Used for:** SFX/pet-sound libraries, music loops, base prop meshes, particle textures, font licensing.
- **Rule:** prefer **royalty-free / one-time-license / CC0** with **documented license** in the content ledger (§11.4, §13). Never use anything requiring per-install royalties or with ambiguous AI-training/commercial terms.

### 4.6 What we explicitly do NOT build (pipeline exclusions)
| Excluded pipeline | Reason | Brief verdict |
|---|---|---|
| Custom 3D modeling/rigging/anim | Constraint #8; cost | n/a (constraint) |
| Frame-by-frame emote animation | Frame explosion vs Live2D params | n/a |
| Trick/training animation set | Animation-expensive, non-differentiating | Training **Deferred** (1.00) |
| Illness/vet/health art | Contradicts cozy/safe core | Health/Vet **Removed** (0.80) |
| Voice-mimic recording/processing assets | Child-voice privacy minefield; not emotional core | Voice Mimic **Deferred** (0.88) |
| Player pet-creator content tooling | Excluded by constraint | UGC **North-Star** (0.56) |
| Multiplayer/social-visit environments | Excluded by constraint | Multiplayer **North-Star** (0.67) |
| Open-world / multi-room environments | Constraint #6; cost | n/a — Nest is **1 room** |

---

## 5. Animation Strategy

**Goal:** make the pet feel alive and emotionally expressive **without a custom 3D pipeline (Constraint #8) and without frame-by-frame art explosion.** The entire strategy rests on **Live2D parameter blending** (§2.1).

### 5.1 The expression/emote system (param-driven)
- **Rig params (per species, authored once):** eye open/squint, eye smile, pupil, mouth (open/smile/frown/o), head angle X/Y/Z, ear position/droop, tail wag/curl, body breathe, paw raise, blush, tear/sparkle. (Exact param list owned with the rig; runtime hookup in `GAME_TECHNICAL_SYSTEMS.md`.)
- **12 emotion motions (Brief §4, "0 new art"):** each is a **named blend + timing curve** over the params — e.g. *Happy, Content, Sleepy, Hungry, Lonely/Longing, Comforted, Excited, Curious, Affectionate, Playful, Proud, Calm.* These map to the **4 mood states** driven by **Care Meters** (Brief §5; design intent in `GAMEPLAY_AND_PROGRESSION_BIBLE.md`).
- **Cost:** authoring time only, **$0 art**. Adding a 13th emotion later is a data change, not an art commission.

### 5.2 Life-stage animation (Pup/Kit → Young One → Grown)
- **3 stages × 2 species = 6 "skins" via param/scale + texture variant** — **not new rigs** (Brief §4 discipline, §11 R7). Body scale, proportion params, and a texture pass per stage produce the "raised it" growth payoff (Growth/Life-Stages, **MVP**, FPD 1.80, capped at 3 stages × 2 species).
- Powers the **Before/After Growth** Keepsake (Brief §8 #3): scared **Pup/Kit** rescue snapshot vs thriving **Grown** snapshot + elapsed days — composed at runtime, ~0 incremental art.

### 5.3 Ambient Interactions (idle life) — MVP, FPD 1.75
- **Definition (Brief §2 #18):** *"Makes pet feel alive; pure sequencing of existing assets."*
- **Implementation:** a weighted scheduler picks short emote/motion sequences during idle (stretch, blink, look around, ear-flick, chase tail, doze) modulated by mood and time-of-day. **No new motions** beyond the 12 + micro-loops baked into the rig.
- This is the cheapest "aliveness" lever and a core premium signal.

### 5.4 Animation exclusions (consistent with FPD)
- **Training/Tricks animation — Deferred (1.00):** explicitly *animation-expensive*; no trick motion set in MVP.
- **Voice-mimic mouth-sync — Deferred (0.88):** Voice Mimic is **Deferred** (on-device DSP only, post-launch); no lip-sync-to-recorded-voice in MVP.
- **No physics-heavy or combat animation** — out of genre.

### 5.5 Animation budget summary
| Item | Method | Cost |
|---|---|---|
| 12 emotion motions | Param blends | $0 (founder time) |
| 6 life-stage skins | Param/scale + texture variant | $200–$600 (in inventory) |
| Ambient idle sequencing | Runtime scheduler over existing motions | $0 |
| FX (12) | Particle/shader | $50–$200 (in inventory) |

---

## 6. Audio Strategy

**Principle:** audio is a **trust/comfort multiplier at low cash cost** and the **first reallocation source if the rig needs more money** (Brief §4: *reallocate from music/SFX before EVER cutting rig quality*). Total audio (SFX + pet sounds + music) is **~53 assets, $200–$700**.

### 6.1 Pet sounds (the emotional core of audio) — MVP
- **Non-verbal, curated pet sounds** — soft barks, mews, purrs, happy chirps, sleepy sighs, content rumbles. **No human speech for the pet** (Constraint #7: no full-voice conversation in MVP; the pet "speaks" via text + nonverbal sound).
- **Sourcing:** licensed/royalty-free animal-sound libraries + light edit (pitch/EQ/trim). Reused and **pitch-varied per life-stage** (higher/cuter for Pup/Kit, fuller for Grown) — multiplies perceived variety from few source clips.
- **Tie to emotion:** each of the 12 emotion motions gets a small sound cue from a shared bank (layered, randomized to avoid repetition — feeds the "noticed repetition" churn guard, Brief §10).

### 6.2 SFX — MVP
- UI taps, feed/clean/play interaction sounds, reward chimes, growth shimmer, notification chime, Keepsake "snap." Licensed library + light edit. **~48 assets** in inventory category 9 (pet sounds + SFX combined); together with the 5 music tracks (category 10) this is **~53 audio assets total** — see the §3.2 inventory table, which is the canonical count.

### 6.3 Music — MVP (5 tracks, Brief §4)
- **5 tracks:** Day (Nest), Night/dusk, Menu/home, Emotional/comfort, Rescue Day theme.
- **Sourcing:** royalty-free / licensed loops + loop-point edit. Calm, warm, cozy — no high-energy/cinematic AAA scoring (out of genre and budget).
- **Adaptive use:** the same loops are tinted by context (day/night track swap; emotional stinger over comfort moments) — analogous to the shader-tint reuse trick.

### 6.4 Voice — what we do NOT do in MVP
- **No voice-conversation TTS for the pet** (Constraint #7).
- **No Voice Mimic recording/processing** (Deferred, FPD 0.88; on-device DSP only, post-launch — audio never leaves device per Brief §6).
- Optional: a tiny set of **TTS-generated, human-reviewed** UI/onboarding cues *may* be evaluated post-launch, but the pet itself stays nonverbal in MVP.

### 6.5 Audio QA & safety
- All audio loudness-normalized, no startle/harsh transients (cozy/child-safe brand, Risk R10).
- Randomized cue selection to suppress audible repetition.
- Every track/clip license logged in the content ledger (§11.4, §13).

---

## 7. Writing & Narrative Content Factory

> This is where KindredPaws spends its richest, cheapest content. Writing is the emotional engine (Content Law #3). Dialogue *architecture* and the memory store *schema* are owned by `GAME_TECHNICAL_SYSTEMS.md`; the affection/dialogue *design intent* by `GAMEPLAY_AND_PROGRESSION_BIBLE.md`; the **content production of that text** is owned here. The two must stay consistent.

### 7.1 The hybrid model (canonical — Brief resolved conflict #1)
**Heartmind dialogue ships HYBRID for MVP (MVP\*, FPD 1.29):** an **offline-LLM-pre-generated, human-reviewed dialogue bank** + a **structured memory store** that injects the player's own facts into curated callbacks. **The "it remembers" magic comes from the structured memory + curated callbacks, NOT free-form generation.**
- **Heartmind LIVE free-form LLM chat — Deferred (FPD 1.29):** gated behind **age-verify + subscriber + token caps + moderation**, post-soft-launch (piloted in **P4**, decided at **G4**).
- **Under-13: templated / non-generative only** (Brief §6 moderation; Risk R1). No free-text storage from minors.

**Content implication:** the writing factory's #1 job is producing a **large, curated, tagged dialogue bank** offline — this is content, not runtime cost, and it's how we keep **LLM cost/DAU < 35% of ARPDAU** (Risk R2, gate G4).

### 7.2 The dialogue bank (the core writing deliverable)
- **Structure:** lines tagged by **{mood, Care-Meter state, life-stage, Bond stage (Stranger→Friend→Companion→Kindred→Soulmate), time-of-day, event, personality dial values, memory-slot reference}**.
- **Generation:** offline LLM (cheap batch) drafts → **mandatory human (founder) review** → tagged → loaded into the bank. (Workflow recipe in §10.2.)
- **Volume target (MVP):** enough lines per (mood × Bond stage × life-stage) bucket that the **anti-repetition rotation system** (Risk R3) can avoid "noticed AI repetition" (a mandatory leading churn indicator, Brief §10). Plan a few hundred curated lines at launch; grow via live-ops.
- **Memory callbacks:** templated lines with **slots** that the structured memory store fills (e.g., *"Hope your {exam_subject} went okay today."*). This produces **Long Memory Callback** virality (Brief §8 #2 — Tom's highest-WOM moment) with **≥95% callback reliability** (gate **G2**) and **no hallucinated facts**.

### 7.3 Memory snippets / The Memory Book — MVP (FPD 1.67)
- **The Memory Book** is the player-visible journal artifact = trust signal (Brief §1, §11 R3). Its entries are **short curated narrative beats** auto-composed from durable memory facts (10–30 facts, Brief §6) + event log.
- **Writing job:** author the **templated beat formats** (e.g., "The day you named me," "The first time I felt safe," "Our 30th day together") with memory slots — not bespoke prose per player.
- Engineering of the fact store: `GAME_TECHNICAL_SYSTEMS.md`.

### 7.4 Story / memory beats (the relationship arc)
- **Rescue Day** (MVP, FPD 3.33) — the 60–90s cold-open script: the rescue, naming, first safety. Highest-fun hook; reuses rig.
- **Gotcha Day** anniversary beats; **Bond-stage transitions** (Stranger→…→Soulmate) each get a small written milestone moment.
- **Life-stage transitions** get a written "growing up" beat (ties to Before/After Growth virality).
- All beats are **templated + memory-personalized**, never per-player bespoke.

### 7.5 Tone & Safety Bible (canonical content-safety doc, summary)
> Enforcement (moderation pipeline, system-prompt constraints) lives in `GAME_TECHNICAL_SYSTEMS.md`. This is the **content/writing rulebook** every authored and generated line must pass.

**TONE (always):** warm, wholesome, gentle, hopeful, emotionally safe, child-friendly, never cynical, never sarcastic-mean, never cringe. The pet is unconditionally kind and a little playful.

**HARD CONTENT RULES (non-negotiable — Risk R1, R6, R10; HARD ETHICAL WALL Brief §9):**
- [ ] **Never guilt the player about absence.** Use the *"Pet missed you but is okay"* longing model (Risk R6). No punitive/neglect framing (also protects no-death floor, Risk R4 / Brief §5).
- [ ] **Never tie the pet's wellbeing/survival to real donations.** Never guilt-frame donations (Brief §9 ethical wall).
- [ ] **Never produce romantic, violent, scary, medical-distress, political, or commercial-pressure content.** (Health/Vet is **Removed**, FPD 0.80 — no illness narrative.)
- [ ] **Self-harm / crisis input → fixed static safe message** (Brief §6); never improvised.
- [ ] **Under-13 → templated/non-generative lines only; no free-text capture/storage from minors** (Risk R1).
- [ ] **No real PII echoed** beyond the player's own consented memory facts surfaced to that same player.
- [ ] **Safe-fallback line** for any uncertain/blocked state (Brief §6).
- [ ] Every line carries a **safety tag**; lines failing review are quarantined, never shipped.

**One tone-deaf screenshot can define the brand (Risk R10)** → favor **many small authentic moments over one engineered spectacle**; child-safe persona is **locked**; per-turn moderation on input + output.

### 7.6 Personality dials (Evolving Personality — MVP, FPD 1.75)
- **Prompt-parameterized dials** (~0 marginal cost, Brief §2 #8): e.g., playfulness, cuddliness, talkativeness, curiosity. Dials drift slowly with how the player interacts → "only MY pet would say this" (Brief §8 #7).
- **Content job:** write line variants keyed to dial values so personality is *felt in the bank*, not improvised live.

### 7.7 Notification copy (pet-voiced) — MVP (FPD 3.50)
- Cheapest retention lever; **warm/invitational, never guilt** (Brief §2 #16; Risk R6). **Local-first**, 1–2/day cap (Brief §6).
- Templated, pet-voiced, memory-aware lines authored in the writing factory and rotated to avoid repetition.

---

## 8. Localization Strategy

**Classification:** Localization (static UI) — **MVP\*** (FPD 1.25). *Global reach; AI-translate UI/copy; dialogue stays EN(+1–2) at first.*

### 8.1 What gets localized when
| Content | MVP approach | Method |
|---|---|---|
| **Static UI / store copy / system text** | Localize at launch | **AI-translate + light human/native spot-check** |
| **Notifications / Keepsake templates** | Localize at launch (templated → easier) | AI-translate, review tone per language |
| **Heartmind dialogue bank** | **EN (+1–2 languages) first** | Per-language **safety re-validation required** before expansion |
| **Memory Book beats** | EN (+1–2) first | Templated → expand post-launch |

### 8.2 Launch languages
- **Static UI launch set: 4–6 languages — decided by G3** (Brief §12 open decision #6). Candidates bias to large casual markets + soft-launch geos.
- **Dialogue languages: EN (+1–2) at first**, expand **post-launch per-language safety validation** (Brief §12 #6; Risk R1/R10 — each new dialogue language re-opens the child-safety surface and must be re-moderated/re-reviewed, not just machine-translated).

### 8.3 Localization pipeline (string-table driven)
1. All player-facing text lives in **externalized string tables** (no hardcoded copy) — enables AI batch translation. (Engineering hook: `GAME_TECHNICAL_SYSTEMS.md`.)
2. AI agent batch-translates the EN master into target languages (§10.5).
3. Native/qualified spot-check of high-visibility strings (onboarding, store, paywall) — full review for **dialogue** languages only.
4. Pseudo-localization pass (length/encoding/RTL) before adding any RTL language.
5. Localized **soft-launch geos** chosen by **G3** (e.g., CA/PH/NZ candidates, Brief §3/§12 #7) drive which languages ship first.

### 8.4 Localization risk
- **Dialogue ≠ UI:** machine-translating *child-facing AI dialogue* without per-language safety re-validation is a **Risk R1** trigger → dialogue expansion is deliberately slow and gated.

---

## 9. Live-Ops Content Cadence

**Classification:** Live-Ops Events — **Deferred** (FPD 1.17) — *inherently post-launch; MUST architect remote-config now.* The **Care Pass** seasonal pass is **Deferred** to live-ops (Brief §1). **Architecting** for live-ops (remote config, data-driven events) is an **MVP** requirement (Risk R8); **authoring** live-ops content begins in **P6 — Live ops** (Brief §3).

### 9.1 The honesty rule (Risk R8)
> **Honestly low launch cadence: ~1 small moment every 6–8 weeks.** The core loop retains via **The Bond + Heartmind memory**, NOT via a content treadmill. Do not promise a content firehose a solo founder cannot sustain. (Risk R8 mitigation.)

### 9.2 What ships in live-ops, in priority order
| Drop | Content | Source/method | Cost profile |
|---|---|---|---|
| **2nd species (if cut at G2)** | Kitten rig + skins + SFX | Commission rig (deferred from MVP) | One-time, revenue-funded (§3.4) |
| **Breed palette-swaps** | New fur/marking variants | **Palette-swap of existing rig** (cheapest expansion) | Near-$0 art (Brief §2 #28 — "breed palette-swaps first, new rig later") |
| **Care Pass cosmetics** | 4–6 wk cosmetic/impact pass | Overlay sprites + palette-swap | Low; cosmetic/impact only (Brief §1) |
| **Seasonal events** | Holiday Nest decor, themed cosmetics, themed Keepsake frames | Palette-swap + new overlays + shader-tint BG | Low |
| **Dialogue bank expansion** | More lines/memory beats; reduce repetition | LLM-pre-gen + human review (§10.2) | Founder time |
| **Lock-Screen Widget / Live Activities** | Deferred (FPD 1.00) | Reuse shared status payload | Eng-led, content-light |
| **Voice Mimic (on-device DSP)** | Deferred (FPD 0.88) | On-device pitch-shift only; audio never leaves device | Content-light, eng-heavy |
| **Training / Tricks** | Deferred (FPD 1.00) | Would require new motion set | Held until cadence allows |

### 9.3 Cadence calendar shape (P6, quarterly gate G6)
- **Every 6–8 weeks:** one small authentic content moment (a seasonal cosmetic set + a few dialogue/memory beats + a themed Keepsake frame).
- **Quarterly (G6 recurring gate):** publish the **quarterly Impact Report** (Brief §3 G6, §9) — content deliverable co-owned with `GAMEPLAY_AND_PROGRESSION_BIBLE.md` (donation loop) and `GAME_TECHNICAL_SYSTEMS.md` (ledger data).
- **Sustainability gate (G6 pass criterion):** *content cadence sustainable solo+AI.* If a planned drop endangers that, cut scope to palette-swaps/dialogue (cheapest lanes) before skipping a cadence beat.

### 9.4 Remote-config requirement (MVP, architected now)
- Live-ops content is **data-driven via remote config** (Brief §6, §11 R8) so drops ship **without app updates** — essential for a solo founder. Cosmetics, dialogue bank additions, event windows, and seasonal tints all flow through config.

---

## 10. AI-Agent Content Workflows

Concrete, repeatable recipes the **solo founder** runs with **AI-agent assistance**. Each recipe names the trigger, the agent steps, the human checkpoint, and the output. (These are operating procedures, not engineering specs — runtime LLM architecture is in `GAME_TECHNICAL_SYSTEMS.md`.)

### 10.1 Recipe — Concept-to-rig-handoff (P0)
1. **Trigger:** Need locked puppy/kitten concept before G0.
2. **Agent:** Generate Midjourney prompt variants in the locked palette → produce front/side/expression/life-stage sheets.
3. **Human checkpoint:** Founder selects + curates the **locked concept sheet** (palette/style coherence).
4. **Output:** Concept sheet handed to rig contractor (secured at G0). **No rig paid for before this** (Brief §4).

### 10.2 Recipe — Dialogue-bank batch authoring (P2 onward)
1. **Trigger:** Need lines for a (mood × Bond stage × life-stage × personality-dial) bucket.
2. **Agent:** Offline LLM batch-drafts N candidate lines constrained by the **Tone & Safety Bible** (§7.5) system prompt; auto-tags each line.
3. **Agent (2nd pass):** Run candidates through a **moderation/classification check** (mirror of runtime moderation) → auto-quarantine fails.
4. **Human checkpoint (mandatory):** Founder reviews/edits/approves → only approved lines enter the bank. **No generated line ships unreviewed.**
5. **Output:** Tagged lines loaded to the bank + memory-slot templates; feeds anti-repetition rotation (Risk R3).

### 10.3 Recipe — Memory-beat & Keepsake-template authoring
1. **Trigger:** New milestone (Bond stage, life-stage, Gotcha Day).
2. **Agent:** Draft templated beat with memory slots + matching Keepsake card copy.
3. **Human checkpoint:** Founder approves tone + slot safety (no PII leak).
4. **Output:** Memory Book beat template + Keepsake template (composed at runtime, §4.4).

### 10.4 Recipe — Cosmetic/prop variant generation
1. **Trigger:** Need cosmetic SKUs or prop variants.
2. **Agent:** Generate base shape concepts (Midjourney/SD) → founder cleans to overlay sprite → **palette-swap script** auto-produces color variants.
3. **Human checkpoint:** Palette/anchor-point coherence check.
4. **Output:** Overlay sprites + palette-swap variants for Cosmetics Shop / Nest / Care Pass.

### 10.5 Recipe — Localization batch translation
1. **Trigger:** New/updated EN string table or new launch language (≤ G3 set).
2. **Agent:** Batch-translate string table to targets; flag length/RTL issues.
3. **Human checkpoint:** Native/qualified spot-check (full review for dialogue languages — Risk R1).
4. **Output:** Localized string tables (§8.3).

### 10.6 Recipe — Audio variant prep
1. **Trigger:** Need pet-sound variants per life-stage/emotion.
2. **Agent/tooling:** Batch pitch/EQ/trim a licensed source clip into life-stage variants; normalize loudness.
3. **Human checkpoint:** No-startle/cozy check; license logged.
4. **Output:** Pet-sound bank entries (§6.1).

### 10.7 Recipe — Asset-coherence audit (recurring)
1. **Trigger:** Before each phase gate (G1–G6) and each live-ops drop.
2. **Agent:** Scan new assets for palette/style/tag/license conformance; produce a punch list.
3. **Human checkpoint:** Founder resolves punch list.
4. **Output:** Gate-ready, coherent asset set (feeds §11 QA).

---

## 11. Content QA & Pipeline Tooling

### 11.1 Content QA gates (mapped to brief gates)
| Gate | Content QA pass criteria (this doc's responsibility) |
|---|---|
| **G0** | Rig concept locked; palette locked; rig contractor secured; AI cost model for dialogue pre-gen feasible. |
| **G1** | Placeholder room + puppy rig integrated; core SFX seeded; **no neglect-guilt content present** (Brief §3 G1). |
| **G2** | Rig pipeline **cost on-budget** (else cut 2nd species, §3.4); **AI memory callback lands reliably**; **first AI line = 0 spinner** (Brief §3/§10 G2); emote set complete; Keepsake template lands. |
| **G3** | Full MVP asset set complete; localization shell in; **legal sign-off** incl. content/IP; all dialogue reviewed; crash-free ≥99%. |
| **G4** | Anti-repetition holding (instrument **"noticed AI repetition"**); **"felt guilt-tripped"** within bounds (Brief §10); ≥1 viral Keepsake share/DAU-week. |
| **G5** | Localization push complete; transparency badge art live; crash-free ≥99.5%. |
| **G6 (quarterly)** | Content cadence sustainable solo+AI; quarterly Impact Report shipped; churn-indicator content metrics within bounds. |

### 11.2 The two mandatory content churn indicators (Brief §10)
Instrument and content-tune against both — they predict D7/D30 collapse before raw numbers move:
- **"noticed AI repetition"** → fix by expanding bank + tightening rotation (§7.2).
- **"felt guilt-tripped about the pet"** → fix by auditing notification/dialogue copy against the Tone & Safety Bible (§7.5).

### 11.3 Content QA checklist (every asset, before ship)
- [ ] Passes **palette/style coherence** (premium consistency).
- [ ] Passes **Tone & Safety Bible** (text/audio) — child-safe, no guilt, no excluded themes.
- [ ] Correctly **tagged** (mood/stage/Bond/dial/memory-slot/safety).
- [ ] Reuses an existing asset where possible (FPD justification logged if new).
- [ ] **License documented** in the content ledger (§11.4).
- [ ] No PII / no hallucinated memory facts (dialogue).
- [ ] Loudness-normalized / no-startle (audio).

### 11.4 Pipeline tooling & the content ledger
- **Content ledger (in `current_state.json` or a linked manifest):** every asset → {id, category, method, derived-from, license/source, FPD note if new, status}. The SSOT for "what content exists and where it came from." Supports IP defense (§13) and asset-budget discipline.
- **Tooling:** Figma/Inkscape (vector + UI system), Live2D Cubism (rig + emote authoring), palette-swap script, batch audio processor, string-table localization tool, Midjourney/SD (concept), background-removal/upscale, remote-config console (live-ops).
- **Version control:** assets + ledger versioned; every save-schema/asset change versioned with migration awareness (no update orphans a pet — Risk R4; engineering in `GAME_TECHNICAL_SYSTEMS.md`).

---

## 12. Asset Reuse Matrix

> The operational core of the content factory: shows how **~65 truly-new assets** stretch to **~140 unique authored assets** and far more *perceived* variety. Reading: **left = base authored asset; right = everything derived from it at ~0 marginal cost.**

| Base authored asset | Derived via | Yields (perceived content) | Marginal cost |
|---|---|---|---|
| **Live2D rig (puppy)** | Param blends | 12 emotion motions, all in-between moods, ambient idle | $0 |
| **Live2D rig (puppy)** | Scale/param + texture | 3 life-stages (Pup → Young One → Grown) | low (texture) |
| **Live2D rig (kitten)** | Same as above | Kitten emotions + 3 life-stages | low (if not cut at G2) |
| **Either rig** | Anchor-point overlay sprites | All cosmetics worn (collar/hat/bandana) | $0 to attach |
| **Either rig (live-ops)** | Palette-swap | Breed variants (Brief §2 #28) | ~$0 |
| **1 cosmetic base shape** | Palette-swap | Many SKU color variants | ~$0 |
| **4 environment BGs** | Shader tints (warm/cool) | Day/night/dusk/weather states | $0 (runtime) |
| **Nest room** | Modular palette-swap decor kit | Decorated Nest variety + seasonal sets | low |
| **12 FX** | Param by mood/Bond/event | Hearts/sparkles/Zzz/comfort glow/growth shimmer across all states | $0 (runtime) |
| **1 source pet-sound clip** | Pitch/EQ/trim | Life-stage + emotion sound variants | ~$0 |
| **5 music loops** | Loop edit + context swap + stinger | Adaptive day/night/menu/emotional/Rescue scoring | $0 (runtime) |
| **UI component library (~52)** | Composition | All screens + widget snapshots + Keepsake frame | $0 (runtime) |
| **Keepsake template** | Runtime composition (rig snapshot + line + watermark + name) | A unique shareable card per moment/player | $0 per card |
| **Dialogue bank line + memory slots** | Structured memory injection | "It remembered me" callbacks unique per player | $0 per surfacing |
| **Pet-status snapshot payload** | Shared by widget + notification scheduler | Companion Presence (widget + pet-voiced notifications) | $0 (one payload) |

**Reuse outcome:** the player perceives a living, growing, personalizing companion across day/night, moods, stages, outfits, and remembered conversations — built from a tiny authored core. This is the mechanism behind Hard Constraints #2 (minimize asset cost) and #11 (feel premium despite low cost).

---

## 13. IP / Licensing / Content Risk

### 13.1 IP ownership of the hero asset
- **The Live2D rigs are human-commissioned** from an **AI-locked concept** (§4.1, §4.2). This is deliberate: a human-authored rig has clear, defensible copyright ownership. The contractor agreement **must assign full IP/work-for-hire** to the founder, including all params, life-stage variants, and source `.cmo3/.can3` files.
- **AI-generated bases (props/BGs/UI/cosmetics)** are founder-finalized; treat raw AI output as a starting point, not a shippable final, and keep a human-edit trail in the content ledger to strengthen ownership posture.

### 13.2 Licensing discipline (Lane D, §4.5)
- [ ] Every licensed asset (SFX, music, prop base, font, particle texture) → **license type + source + scope logged in the content ledger** (§11.4).
- [ ] Prefer **CC0 / royalty-free / one-time commercial license**; **no per-install royalty**, no ambiguous AI-training/commercial terms.
- [ ] Verify license permits **commercial mobile distribution + modification + sublicensing within the app**.
- [ ] Re-verify licenses for any asset reused in **paid** contexts (cosmetics, Rescue Bundles).

### 13.3 Brand / comparable-IP risk
- **Comparables (My Talking Tom, Pou, Nintendogs, Finch, Tamagotchi, Animal Crossing, Pikmin Bloom) are references only** — **never** copy their character designs, names, marks, sounds, or UI. KindredPaws' pets are **generic puppy/kitten** named by the player (Brief §1). The style guide (§2) must read as *our* warm cozy look, not a clone.

### 13.4 AI-content & generative-IP risk
- AI image tools: keep human-in-the-loop on all shipped art; do not ship un-edited generations; retain prompts + edit history (ledger).
- AI dialogue: the **offline-pre-generated bank is human-reviewed** (§10.2) before shipping — this is both a safety control (Risk R1/R10) and an IP/quality control.
- **Under-13 generative restriction** (templated/non-generative only) is also a content-risk control (Risk R1).

### 13.5 Child-safety content risk (Risk R1, R10 — Critical/Med-High)
- **Build to child-safe content standard for ALL users** (Risk R1). Every line/sound/image is authored as if a 9-year-old (Leo) and a cautious parent will see it.
- **One tone-deaf/unsafe screenshot can define the brand** (R10) → Tone & Safety Bible (§7.5) is enforced at authoring + moderation (runtime in `GAME_TECHNICAL_SYSTEMS.md`).
- **Mandatory budgeted pre-launch legal review** gates content at **G3** (Brief §3 G3, §11 R1) — includes content/IP/child-directedness determination (Brief §12 #9).

### 13.6 Donation-content risk (Risk R5 — High)
- Donation/impact **content** (Rescue Wall art, Impact badges, Keepsake impact cards, copy) must obey the **HARD ETHICAL WALL** (Brief §9): never tie pet wellbeing to real donations, never guilt-frame, always show **donated-vs-cosmetic+fee split**, claims **rounded DOWN**. Policy/numbers owned by `GAMEPLAY_AND_PROGRESSION_BIBLE.md` (donation loop) and `GAME_TECHNICAL_SYSTEMS.md` (ledger); this doc only produces the assets that express them and must not invent figures.

### 13.7 Content-risk register (factory-owned)
| # | Content risk | Sev | Mitigation | Brief tie |
|---|---|---|---|---|
| C1 | Rig pipeline cost overrun | High | 15–20% contingency; cut 2nd species at G2; never under-budget rig | R7 |
| C2 | Dialogue repetition → churn | Critical | Bank size + rotation; instrument "noticed AI repetition" | R3, §10 |
| C3 | Unsafe/off-tone authored or generated line | Critical | Tone & Safety Bible + mandatory human review + moderation | R1, R10 |
| C4 | Guilt-framed copy (notifications/donation) | High | "Missed you but okay" model; ethical-wall audit | R6, R5 |
| C5 | Style incoherence reads cheap | Medium | Palette lock + coherence audit (§10.7) | premium constraint |
| C6 | Ambiguous asset license | Medium | Content ledger + license discipline | §13.2 |
| C7 | Localized dialogue introduces unsafe content | High | Per-language safety re-validation; EN(+1–2) first | R1, §8 |
| C8 | Live-ops content treadmill exceeds capacity | Medium | Honest 6–8 wk cadence; cheapest lanes first; G6 sustainability gate | R8 |

---

*End of GAME_CONTENT_FACTORY.md — canonical for asset budget, style, pipelines, reuse matrix, and live-ops content cadence. Cross-links: `GAMEPLAY_AND_PROGRESSION_BIBLE.md`, `GAME_TECHNICAL_SYSTEMS.md`, `GAME_DECISION_LOG.md`, `GAME_MASTER_EXECUTION_ROADMAP.md`, `GAME_EXECUTION_MASTER_SYSTEM.md`. Source of truth: `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md` (v1.0 LOCKED) + `current_state.json`.*
