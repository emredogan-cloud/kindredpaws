# KINDREDPAWS — GAME_TECHNICAL_SYSTEMS.md

**Document role / canonical for:** The full technical systems architecture of KindredPaws — client simulation, the Heartmind AI companion layer (LLM + memory + safety), the Voice Mimic evaluation, Companion Presence (widgets/notifications/streaks), the Impact Pledge donation backend + anti-fraud, data/persistence/sync, infra, analytics, security/privacy/compliance, and the LLM/infra cost model. **This document is the single canonical home for every technical decision.** It is downstream of, and subordinate to, `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md` (the v1.0 LOCKED brief). Where this document would conflict with the brief, the brief wins; report the conflict instead of diverging.

> **Status:** v1.0 · **Date:** 2026-06-22 · **Audience:** the solo founder + AI agents who will execute it. Not an end-user doc.
>
> **Cross-links (facts live in exactly ONE canonical doc — see CONSOLIDATION RULES):**
> - Feature classification, FPD verdicts, phase/gate IDs, KPI thresholds, currency names, asset budget → `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md` (SSOT).
> - Live machine-readable project state → `current_state.json` (created in Phase **P0**; mirrors the brief).
> - Game design / loop / feelings / verbs → see `GAMEPLAY_AND_PROGRESSION_BIBLE.md`.
> - Economy tuning, currency sinks/sources, pricing elasticity → see `GAMEPLAY_AND_PROGRESSION_BIBLE.md`.
> - Art/asset pipeline, Live2D rig spec, palette-swap kit → see `GAME_CONTENT_FACTORY.md`.
> - Donation policy text, partner vetting, Impact Pledge legal wording → see `GAMEPLAY_AND_PROGRESSION_BIBLE.md` (donation loop) and `GAME_DECISION_LOG.md` (locked donation-ethics decisions).
> - Go-to-market, ASO, virality copy → see `GAMEPLAY_AND_PROGRESSION_BIBLE.md`.
>
> This doc references those by filename and does **not** restate their content. It owns the **how it is built**.

---

## 0. Reading guide & FPD legend

Every system below carries its brief-canonical verdict so an executor never has to cross-reference to know whether to build it now:

- **MVP** — in the first shippable game.
- **MVP\*** — MVP only in its cheapest emotionally-intact form (the form is specified here).
- **MVP (forced)** — in MVP regardless of FPD because it gates a legal or data dependency.
- **Deferred** — architected-for now, built post-launch / live-ops.
- **Removed** — cut entirely.
- **North-Star** — long-term vision, NOT committed for launch.

FPD = FUN / DOLLAR (brief §FRAMEWORKS). Verdict bands: ≥1.5 strong MVP; 1.0–1.49 MVP* simplified; 0.6–0.99 Defer; <0.6 Remove/North-Star.

**Three architectural through-lines that everything obeys:**
1. **Sim is client-side and deterministic; trust is server-side.** The pet's needs/mood/Bond run on-device from elapsed time. Anything that mints value or must not be forgeable (Compassion Coins, entitlements, the Memory Book of record, the donation ledger) is server-authoritative.
2. **"It remembers" comes from a structured memory store + curated callbacks, NOT free-form generation** (brief Reconciled Conflict #1). The magic is data, not tokens.
3. **LLM cost/DAU is the make-or-break variable.** Target **< 35% of ARPDAU** (gate **G4**). Hybrid pre-generation + structured-memory injection + prompt caching + small models + token caps are all in service of this single number.

---

## 1. Architecture Overview

### 1.1 Client/server text diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  DEVICE (iOS / Android)                                                         │
│                                                                                │
│  ┌────────────────────────── GAME CLIENT (Unity 2D or Flutter+Live2D) ───────┐ │
│  │                                                                            │ │
│  │  Presentation        Simulation (deterministic, offline-capable)          │ │
│  │  ┌───────────────┐   ┌──────────────────────────────────────────────┐     │ │
│  │  │ Live2D rig     │   │ Pet State Machine (Pup/Kit→Young One→Grown)   │     │ │
│  │  │ render + FX    │◀──│ Care Meters (4) · Mood · The Bond            │     │ │
│  │  │ The Nest UI    │   │ Elapsed-time decay · offline catch-up        │     │ │
│  │  │ Memory Book UI │   │ Ambient Interaction sequencer                │     │ │
│  │  └───────────────┘   └──────────────────────────────────────────────┘     │ │
│  │                                                                            │ │
│  │  Local store (SQLite/Hive)   Native bridges                               │ │
│  │  ┌───────────────────────┐   ┌──────────────────────────────────────┐     │ │
│  │  │ save snapshot (v-stamp)│   │ WidgetKit / Glance status payload     │    │ │
│  │  │ pending mutation queue │   │ Local notification scheduler          │    │ │
│  │  │ cached dialogue bank   │   │ Voice DSP (DEFERRED, on-device only)  │    │ │
│  │  └───────────────────────┘   └──────────────────────────────────────┘     │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│            │ HTTPS (TLS1.2+)        │ StoreKit / Play Billing      │ ad SDK     │ │
└────────────┼───────────────────────┼──────────────────────────────┼────────────┘
             │                       │                              │
   ┌─────────▼───────────────────────▼──────────────────────────────▼──────────┐
   │  MANAGED BACKEND (Firebase or Supabase) — no owned servers                 │
   │                                                                            │
   │  Auth (Apple/Google + guest)   Cloud Save (authoritative, versioned)       │
   │  Remote Config / feature flags Analytics ingest (~15 events)               │
   │                                                                            │
   │  ┌──────────────── Edge / Cloud Functions (thin trusted proxies) ────────┐ │
   │  │                                                                        │ │
   │  │  Heartmind proxy ───────────► Anthropic API (claude-opus-4-8)          │ │
   │  │   • persona prompt (cached)   • moderation in + out                    │ │
   │  │   • structured-memory inject  • token + turn caps                      │ │
   │  │                                                                        │ │
   │  │  Memory service ────────────► Memory fact store (KV, 10–30 facts)      │ │
   │  │  Coin-mint gate ────────────► S2S ad postbacks · receipt validation    │ │
   │  │   • App Attest / Play Integrity attestation                            │ │
   │  │  Impact ledger ─────────────► segregated Impact Pool (append-only)     │ │
   │  └────────────────────────────────────────────────────────────────────────┘ │
   │            │                          │                                     │
   └────────────┼──────────────────────────┼─────────────────────────────────────┘
                │                          │
        Ad networks (S2S)         Giving intermediary (PayPal Giving Fund /
        AdMob/ironSource          Percent / Benevity) → 1–3 vetted shelters
```

### 1.2 What runs where (authority matrix)

| Concern | Client | Backend | Why |
|---|---|---|---|
| Care Meters, Mood, Bond, life-stage | ✅ authoritative for gameplay feel | server-validatable snapshot | Must work offline; cheap; emotion-critical responsiveness. |
| Ambient interactions / idle life | ✅ | — | Pure sequencing of existing assets. |
| Dialogue bank selection | ✅ (pre-gen bank shipped/cached) | — | Zero-latency, zero-token, child-safe. |
| Heartmind memory facts | read cache | ✅ authoritative | "It remembered" must be reliable + tamper-proof. |
| Live LLM generation (Deferred) | — | ✅ via proxy | Key security, rate-limit, moderation. |
| Entitlements (Forever Friends, cosmetics) | cached | ✅ (RevenueCat) | Restore + anti-fraud. |
| Compassion Coin minting | request only | ✅ gate | Coins map 1:1 to real money; never client-trusted. |
| Impact Pool ledger | read-only view | ✅ append-only | Donation trust + audit. |
| Cloud save of record | local-first cache | ✅ | Losing the pet = catastrophic (R4). |

---

## 2. Recommended Tech Stack

*(Mirrors brief §6 TECH STACK. The brief is canonical; this section adds rationale, alternatives, and the open-decision resolution path.)*

| Layer | Decision | Rationale | Alternatives considered | Decide at |
|---|---|---|---|---|
| **Engine** | **Unity (2D) OR Flutter + Live2D SDK** — pick whichever the founder+AI ship fastest. | Both run the **Live2D Cubism** runtime and expose native widget/notification interop. Bias to the stack the founder already knows; AI-agent codegen leverage is higher in the more mainstream stack. | Godot (weaker Live2D + native-widget story); React Native + Skia (Live2D maturity risk); native-per-platform (doubles work — violates solo+AI constraint). | **G0** (Open Decision #1). |
| **Backend** | **Managed BaaS — Firebase OR Supabase.** Auth, DB, cloud save, remote config, functions. No owned servers. | Near-zero ops; both have generous free tiers and serverless functions for the Heartmind/Coin/ledger proxies. Firebase = best mobile SDKs + Crashlytics + Remote Config maturity; Supabase = Postgres + row-level security (cleaner ledger/audit model + easier SQL-based reconciliation). | Owned VPS/k8s (violates solo-maintainability); AWS Amplify (heavier). | **G0** alongside engine. |
| **LLM** | **Anthropic `claude-opus-4-8`** for the offline pre-generation pass (highest quality, reviewed once, cached); live Deferred chat may route a cheaper model. | Pre-gen quality is paid **once** and amortized across all players → cost is irrelevant to per-DAU economics. Live chat (Deferred) is the cost-sensitive path; see §12 for model tiering. | OpenAI/Gemini (would split this skill's tooling; no reason to leave Anthropic for the pre-gen quality bar). | Provider+tiers modeled at G0, validated **G3/G4** (Open Decision #3). |
| **Payments** | **RevenueCat** over StoreKit 2 + Play Billing. | One abstraction, receipt validation, entitlements, restore, webhooks for the Coin-mint gate. Collapses two billing stacks. | Raw StoreKit+Billing (double the surface; we are solo). | MVP (forced, feature #25 dependency). |
| **Ads** | **AdMob or ironSource mediation**, COPPA/kids-flagged, rewarded-first. | Standard, S2S-postback capable (required for Coin minting). | AppLovin MAX (viable alt). | MVP. |
| **Widgets** | Native **WidgetKit (iOS)** + **Glance/AppWidget (Android)**, fed by one shared status payload, pre-rendered mood images. | Live rig render in a widget is impossible/expensive; pre-rendered moods are cheap and premium-looking. | Live render (rejected — battery/complexity). | MVP (feature #14). |
| **Notifications** | **Local-scheduled** in MVP (no push cost); FCM/APNs templated lines fast-follow. | Cheapest retention lever (feature #16, FPD 3.50). | Push-only (adds server cost + consent friction). | MVP. |
| **Analytics** | Managed (**Firebase Analytics** or **GameAnalytics**), ~15 events, privacy-by-design, no PII. | Funnel mapped to gates; free tier sufficient at indie scale. | Amplitude/Mixpanel (overkill cost). | MVP (feature mapped to gates). |
| **Crash/perf** | Crashlytics (Firebase) or Sentry. | Crash-free ≥99% (G3) / ≥99.5% (G5) must be measured. | — | MVP. |

**Anthropic SDK note for executors:** the Heartmind proxy is a thin serverless function. Default to `claude-opus-4-8` with **adaptive thinking** for the offline pre-generation pass and **prompt caching** on the (large, stable) persona system prompt so repeated generations and any live calls read the persona from cache at ~0.1× cost. Use the official Anthropic SDK for the proxy's language; never call the API directly from the client (key exposure).

---

## 3. Core Client Systems

### 3.1 Pet State Machine — life-stages & mood

**Verdict:** Growth/Life-Stages = **MVP** (FPD 1.80, #1 art-cost lever, capped at **3 stages × 2 species**). Care Meters = **MVP** (2.67). Core care = **MVP** (2.67). The Bond = **MVP** (4.50, highest FPD).

**Life stages (3, per brief §1):** `Pup/Kit (infancy) → Young One (juvenile) → Grown (adult)`. Implemented as a **rig parameter / scale**, never a new rig (brief §4 discipline rule, R7). Transition is driven by the Bond + elapsed days, not by spending.

```
State machine (high level):

  [Rescue Day cold-open]
        │ (one-time, 60–90s)
        ▼
  ┌──────────────┐  bond≥T1 & days≥D1   ┌──────────────┐  bond≥T2 & days≥D2  ┌──────────────┐
  │  PUP/KIT     │ ───────────────────▶ │  YOUNG ONE   │ ──────────────────▶ │   GROWN      │
  │ (infancy)    │                      │ (juvenile)   │                     │  (adult)     │
  └──────────────┘                      └──────────────┘                     └──────────────┘
   rig scale 0.7                          rig scale 0.85                       rig scale 1.0
   + param blend A                        + param blend B                      + param blend C

  Mood overlay (orthogonal, recomputed each tick from Care Meters):
   content · sleepy · hungry · sad-but-safe   →  drives idle animation + notification tone
```

- **Stage gates** `T1/D1, T2/D2` are tuning values owned by `GAMEPLAY_AND_PROGRESSION_BIBLE.md`; this doc only specifies that they are gated on **Bond AND elapsed days** so growth cannot be bought (preserves the "raised it" fantasy).
- **No new rigs per stage** — scale + 3 param blends. 12 emotion motions are **param blends = 0 new art** (brief §4).
- Mood is a derived value, not stored state: `mood = f(hunger, energy, hygiene, happiness)` → one of ~4 states. This keeps save data tiny and deterministic.

### 3.2 Care Meters (needs/mood sim)

**Four meters (brief §5):** `hunger, energy/sleep, hygiene, happiness` — 0–100 floats, gentle decay.

**The no-death floor (Risk R4, brief §5 & §11):**

```
For each meter m:
  m(t) = clamp( m(t-Δ) - decayRate[m] * Δ , FLOOR, 100 )
  FLOOR = "sad but safe"  (e.g. 15) — the pet can NEVER drop below it, can NEVER die or suffer irreversibly.

Bond coupling:
  if any meter < lowThreshold:  Bond GAIN is dampened (multiplier < 1)
  Bond is NEVER reduced.  Neglect slows growth; it never punishes.
```

- Decay rates are slow and forgiving (cozy core). Exact rates owned by `GAMEPLAY_AND_PROGRESSION_BIBLE.md`; the **invariants** (hard floor, gain-only Bond, no irreversible state) are owned here and are non-negotiable.
- Care actions (feed/clean/play — exactly **3 interactions**, brief #3) raise the relevant meter, trigger a reaction animation (param blend), and award a small Bond increment + Kibble.

### 3.3 Time simulation & offline progression

The sim is **elapsed-time driven and deterministic** so it produces identical results on-device and when server-validated (gate **G1** requires "deterministic sim + offline-catch-up tested").

```
On app foreground / wake:
  Δ = clamp(serverTrustedNow - lastSimTimestamp, 0, MAX_CATCHUP)   // monotonic, clamp negative clock skew to 0
  applyDecay(Δ)                  // pure function of Δ and stored meters
  recomputeMood()
  resolveAmbientSinceLast(Δ)     // "pet missed you but is okay" longing model (R6)
  lastSimTimestamp = serverTrustedNow
  persistSnapshot()
```

- **MAX_CATCHUP cap** (e.g. 7 days of decay max) so a returning lapsed player never sees a pet that "neglected itself for a month" — that would violate the cozy/no-guilt brand (R6).
- **Longing model, not guilt model:** on return after absence the pet shows "missed you" warmth, never distress. This is the **Streak Warmth** philosophy applied to the sim itself.
- **Clock-tamper resistance:** the sim trusts a server-provided time when online; offline it uses monotonic device clock and never advances negative. Because the sim mints no value (only Coins do, server-side), clock cheating yields cosmetic decay only — not exploitable.

### 3.4 Save / load

**Cloud Save / Account = MVP (forced)** (#25 — "Losing the pet = catastrophic"; prerequisite for memory/ledger/entitlements).

- **Local-first:** authoritative-feeling local snapshot in SQLite/Hive, written on every meaningful mutation and on background.
- **Schema is versioned** (`saveSchemaVersion`); every bump ships an automated migration + a restore flow (R4). **No update may orphan a pet.**
- **Single-device, last-write-wins for MVP.** True multi-device live sync is **deferred** (brief §6). On sign-in to a new device, restore the cloud snapshot; show a clear "this will replace local progress / restore your pet" choice.
- **Pending-mutation queue:** Coin-mint requests, donation-affecting events, and memory-fact writes are queued locally and flushed to the backend; they are idempotent (client-generated UUID per mutation) so a retry never double-counts.

```
Save snapshot (illustrative shape):
{
  saveSchemaVersion: 3,
  petId, species: "puppy"|"kitten", name,
  lifeStage, careMeters:{hunger,energy,hygiene,happiness},
  bond:{value, stage:"Stranger|Friend|Companion|Kindred|Soulmate"},
  nest:{layoutId, cosmeticIds[]},
  careStreak:{count, lastCareDay, warmthBanked},
  lastSimTimestamp,
  pendingMutations:[ {uuid, type, payload} ]
}
```

---

## 4. AI Companion Layer (Heartmind)

**Internal name:** **Heartmind** = dialogue + memory + personality (brief §1). Player-visible memory artifact = **The Memory Book**.

**Canonical resolution (Reconciled Conflict #1):** **Hybrid-first is MVP.** The "it remembers" magic comes from the **structured memory store + curated callbacks**, not free-form generation.

| Sub-feature | FPD | Verdict |
|---|---|---|
| #6 Heartmind dialogue (HYBRID: pre-gen bank + structured memory) | 1.29 | **MVP\*** |
| #6b Heartmind LIVE free-form LLM chat | 1.29 | **Deferred** (age-verify + subscriber + caps + moderation; post-soft-launch) |
| #7 AI Memory (Memory Book) | 1.67 | **MVP** |
| #8 Evolving Personality | 1.75 | **MVP** |
| #9 Child-Safety Moderation | 0.80 | **MVP (forced)** — legal gate, FPD irrelevant |

### 4.1 LLM architecture — the hybrid model

```
                         OFFLINE (build / live-ops time, paid ONCE)
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Author intents + pet-state contexts → claude-opus-4-8 (adaptive thinking)  │
  │   generates a large DIALOGUE BANK of lines, keyed by:                       │
  │     (lifeStage × mood × intent × bondStage × personalityDial)               │
  │ → 100% HUMAN-REVIEWED before shipping → child-safe by construction          │
  │ → bundled with app + remote-config top-ups                                  │
  └──────────────────────────────────────────────────────────────────────────┘
                                     │ ships in client / remote config
                                     ▼
                         RUNTIME (per interaction, on-device — $0 tokens)
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ 1. Determine pet-state key (lifeStage, mood, bondStage, personalityDial)    │
  │ 2. Select a line from the bank for the matched intent                       │
  │ 3. Inject 0–2 structured MEMORY FACTS via safe template slots               │
  │      e.g. "I remembered you said you like {fact:favorite_thing}!"           │
  │ 4. Anti-repetition rotation (don't reuse the last N lines for this key)     │
  │ → render with pet voice/text. NO network call. NO latency. NO spinner.      │
  └──────────────────────────────────────────────────────────────────────────┘

                         DEFERRED (post-soft-launch, gated, capped)
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Live free-form chat (#6b): adult-verified + Forever Friends subscriber only │
  │  client → Heartmind proxy → moderation(in) → claude (small/cheap model,     │
  │  cached persona prompt + injected facts, token cap ~60–100 out, daily turn  │
  │  cap, per-user cost ceiling) → moderation(out) → client                     │
  └──────────────────────────────────────────────────────────────────────────┘
```

**Why this satisfies both cost and child-safety (brief Conflict #1):** the MVP magic costs **zero runtime tokens** and every shippable line is reviewed; free-form generation — the only path that can produce an unsafe novel line — is walled behind age-verify + subscriber + moderation and only exists post-soft-launch.

**Spinner-free first AI line (gate G2 criterion):** because the first line is bank-selected on-device, there is no network round-trip. This is an architectural guarantee, not a perf optimization.

### 4.2 Memory system design (The Memory Book)

**Reliability > breadth** (brief §6, R3): "a few reliable callbacks beat broad flaky recall." Gate **G2** requires **AI memory callback reliability ≥ 95% (no hallucinated facts).**

- **Structured key-value fact store:** **10–30 durable facts** per player, server-authoritative (so it can never be tampered or lost — R3/R4).

```
MemoryFact {
  factKey: "favorite_thing" | "had_a_hard_day_on" | "named_pet_after" | ... (enumerated, closed set)
  value:   short normalized string (validated/sanitized)
  source:  "onboarding" | "extracted" | "explicit"
  confidence: float
  createdAt, lastSurfacedAt
}
```

- **How facts get in:**
  - **Explicit/onboarding** (MVP): structured prompts during Rescue Day and light "tell me about you" moments. Safe by construction (closed-form input where possible).
  - **Extracted** (Deferred, rides with live chat): batched **off-peak fact extraction** from chat turns, not per-turn — cheap and reviewable.
- **How facts surface:** the runtime line-selector injects 0–2 facts into safe template slots. A surfaced fact is logged so the Memory Book UI can show "Mochi remembered: you like rainy days." This **tangible journal artifact is the trust signal** (Tom/Playtest mandate, R3) and the #1 viral moment ("Long Memory Callback," brief §8.2).
- **No-hallucination guarantee:** facts are only ever inserted into pre-reviewed templates with **validated** values from the closed-set store. The model never free-generates a "memory" in MVP. This is how we hit ≥95% with zero hallucinated facts — the number is bounded by template/slot correctness, not by model recall.
- **Closed set is enumerated** so under-13 handling stays templated/non-generative (R1).

### 4.3 Evolving-personality model

**Verdict: MVP** (FPD 1.75; "prompt-parameterized dials; ~0 marginal cost; deepens D30 bond").

- Personality is a small set of **dials** (e.g. `playfulness`, `cuddliness`, `chattiness`, `bravery`) — a few discrete levels each.
- Dials shift slowly with how the player interacts (lots of play → playfulness up) and with bond-stage milestones. The shift is **deterministic and client-side** (free).
- **In MVP**, dials select **which bank lines** are eligible (key includes `personalityDial`) — no generation cost. "Only MY pet would say this" (brief §8.7) emerges because the dial-combination + memory-fact slots produce a player-singular voice from shared assets.
- **In Deferred live chat**, the dials are injected as parameters into the (cached) persona prompt — still ~0 marginal cost because the persona prefix is prompt-cached.

### 4.4 Prompt & guardrail design (for the Deferred live path and the offline pre-gen pass)

The persona system prompt is **large, stable, and prompt-cached** (renders first in the `tools → system → messages` order, so the cache prefix never moves). It encodes:

- **Identity & tone:** a rescued puppy/kitten companion — wholesome, warm, emotionally safe, **child-friendly at all times** (Differentiator 1 hard requirement).
- **Hard constraints in the system prompt itself:** never produce unsafe, scary, romantic, violent, medical, or commercial-pressure content; never claim to be human; never tie its wellbeing to the player's real money (HARD ETHICAL WALL, brief §9); never discuss self-harm beyond a **fixed safe-fallback line**.
- **Memory injection:** validated facts passed as structured context, not as free instructions, so injected text can't smuggle a jailbreak.
- **Output discipline:** short, in-character, no preamble; token-capped (~60–100 output tokens for live chat).
- **Operator channel:** runtime mode/state changes are delivered as a mid-conversation `role:"system"` message appended to `messages` (Opus 4.8 supports this), preserving the cached prefix and keeping the operator instruction non-spoofable by user text.

### 4.5 Child-safety moderation pipeline

**Verdict: MVP (forced)** — FPD 0.80 is irrelevant; this is a **non-negotiable legal gate** (#9, R1). Applies to **any** AI-generated text (so: the Deferred live path; the offline pre-gen pass is additionally 100% human-reviewed).

```
LIVE-CHAT TURN (Deferred path):

 user text ──► [INPUT MODERATION]  cheap classifier/endpoint
                  │  unsafe ─────────► fixed safe-fallback line, log, stop
                  ▼  safe
              [LLM GENERATE]  cached persona + injected facts + caps
                  │
                  ▼
             [OUTPUT MODERATION]  same classifier on the generated line
                  │  unsafe ─────────► fixed safe-fallback line, log, stop
                  ▼  safe
              render to player

 SPECIAL CASE: self-harm signal anywhere ─► static safe message (no generation), full audit log.
 UNDER-13: live generation is DISABLED entirely — templated/non-generative bank only (R1).
```

- **Two-sided:** both input and output pass moderation (brief §6).
- **Fixed safe-fallback line** is a pre-written, in-character, reviewed string — never generated.
- **Full audit logging** of every moderation decision (request_id, decision, category) for incident response and the G3 "no child-safety incident" gate.
- **Per-turn moderation cost** rides in the unit-economics model (§12) — it is a real per-DAU cost on the live path and a reason live chat is subscriber-funded.
- **Refusal handling:** if the model itself declines (`stop_reason: "refusal"`), serve the fixed safe-fallback line — never surface a raw refusal to a child.

### 4.6 On-device vs cloud (Heartmind)

| Path | Where | Token cost | Notes |
|---|---|---|---|
| Bank selection + memory injection (MVP) | on-device | $0 | The whole MVP magic. No spinner. |
| Memory fact store of record | cloud | $0 (DB) | Authoritative; never client-trusted. |
| Live generation (Deferred) | cloud proxy → Anthropic | metered | Gated, capped, subscriber+adult only. |
| Fact extraction (Deferred) | cloud, batched off-peak | metered, amortized | Cheap because batched, not per-turn. |
| Voice mimic (Deferred) | on-device DSP only | $0 | Audio never leaves device (see §5). |

### 4.7 Fallbacks & failure modes

- **No network:** MVP path is unaffected (it never needed the network). Live chat (Deferred) shows an in-character "let's just cuddle for now" gentle fallback — never an error dialog.
- **LLM/proxy down (Deferred):** degrade to the MVP bank path transparently; the pet keeps talking, just from the bank.
- **Moderation endpoint down:** **fail closed** — serve the safe-fallback line; do not generate unmoderated text to a user (safety > availability).
- **Cost ceiling hit (Deferred):** per-user daily turn cap reached → "I'm a little sleepy, let's chat more tomorrow" + revert to bank. This is a designed, warm cap, not an error.

### 4.8 Token-cost controls (summary; full model §12)

Hybrid pre-gen (zero runtime tokens for MVP) · prompt-cache the persona prefix (~0.1× on reads) · small/cheap model for live chat · output token cap (~60–100) · daily turn caps · per-user cost ceiling · live chat subscriber-funded · batched off-peak extraction. **All exist to keep LLM cost/DAU < 35% ARPDAU (G4).**

---

## 5. Voice Mimic Layer

**Verdict: Deferred** (#10, FPD **0.88**). "Not the emotional core; child-voice privacy minefield; on-device pitch-shift only, post-launch" (brief §2). Differentiator 2 explicitly "MUST be evaluated under FPD and may be DEFERRED if too expensive" — it is.

### 5.1 Why deferred (the FPD + risk case)

- **FUN is real but not core:** funny and shareable, but the brief's core feeling priority is attachment/care, which Heartmind + Bond + Growth already deliver. Voice mimic is a delighter, not a pillar.
- **DOLLAR is dominated by risk, not build:** capturing **children's voices** is a COPPA/GDPR-K minefield (R1, Critical). Cloud voice transformation adds OPEX and a biometric-data classification problem. Together these push FPD below the 1.0 MVP bar.

### 5.2 The cheaper alternative (the form it ships in, post-launch)

**On-device DSP pitch-shift only. Audio never leaves the device** (brief §6 on-device vs cloud).

```
mic ─► on-device capture (short clip, explicit per-use consent)
     ─► on-device pitch-shift / time-stretch DSP (no ML, no upload)
     ─► pet "speaks" the transformed clip, then the clip is discarded
NO network. NO storage of raw audio. NO biometric processing. NO cloud ML.
```

- This sidesteps the biometric/COPPA problem almost entirely: nothing leaves the device, nothing is stored, no model is trained.
- Under-13: gated behind the same parental-consent/age handling resolved at G3 (R1); default off.
- **Classification reminder for executors:** even on-device, surface a clear consent affordance and a "delete clip" guarantee; document it in `GAMEPLAY_AND_PROGRESSION_BIBLE.md`'s player-wellbeing/ethics section and the store privacy labels.

### 5.3 Build trigger (when to un-defer)

Promote from Deferred only in **P6 live-ops**, and only if: (a) the on-device DSP path is proven cheap to maintain solo+AI, (b) the legal child-directedness determination (G3) permits the consent flow, and (c) live-ops capacity exists (R8). Until then it stays a roadmap line, not committed work.

---

## 6. Daily-Life Integration (Companion Presence)

**Companion Presence** = widgets + notifications + streaks (brief §1). Goal: the player feels "my pet lives with me" (Differentiator 4).

| Feature | FPD | Verdict |
|---|---|---|
| #14 Home-Screen Widget | 1.60 | **MVP** |
| #15 Lock-Screen Widget / Live Activities | 1.00 | **Deferred** (fast-follow once pipeline proven) |
| #16 Notifications (pet-voiced) | 3.50 | **MVP** |
| #17 Care Streak (+ Streak Warmth) | 3.50 | **MVP** |
| #18 Ambient Interactions (idle life) | 1.75 | **MVP** |

### 6.1 The single shared status payload

The whole presence layer is fed by **one** "pet status snapshot" the client writes on every meaningful change (brief §6):

```
PetStatusSnapshot {
  moodState: "content|sleepy|hungry|sad-but-safe",
  lifeStage, bondStage, name, species,
  preRenderedMoodImageRef,   // chosen from a small pre-rendered set, NOT a live rig render
  careStreakCount, streakWarmthBanked,
  nextSuggestedCareAt        // drives notification scheduling
}
```

This one payload feeds: the home widget, the (Deferred) lock-screen widget, and the notification scheduler. One source → no drift, minimal native code.

### 6.2 iOS / Android widgets

- **iOS WidgetKit / Android Glance (or AppWidget).** Render the **pre-rendered mood image** + name + a soft status line. Never a live Live2D render in the widget (battery/complexity — rejected in §2).
- **Refresh:** timeline entries derived from `nextSuggestedCareAt`; the OS budgets refreshes, which is fine — the widget is ambient, not real-time.
- **Widget Candids (brief §8.6):** the endearing widget moment is screenshotted directly → the widget *is* the ambient ad. No extra build for this beyond making moods photogenic.

### 6.3 Lock-screen widget / Live Activities (Deferred)

Incremental over the home widget; **fast-follow once the home-widget pipeline is proven** (brief #15). Same shared payload, so the marginal build is small — that's exactly why it's a deferred fast-follow, not a North-Star.

### 6.4 Notifications (pet-voiced)

- **Local-scheduled first** (no push cost, brief §6) — scheduled from `nextSuggestedCareAt`. **Cap 1–2/day.**
- **Warm/invitational, never guilt** (brief #16, R6): pet-voiced lines like "Mochi is doing a little stretch and thinking of you 🐾" — never "Your pet is starving!" The no-death floor (§3.2) means there is never anything to feel guilty about.
- FCM/APNs templated lines are a fast-follow when push value is proven (e.g. re-engagement of lapsed players); still capped, still warm.

### 6.5 Care Streak engine (+ Streak Warmth)

**MUST be forgiving** (brief #17, R6 — "neglect-guilt / punitive streaks churn highest-LTV personas").

```
On a care action on a new local day:
  if (today == lastCareDay + 1)        streak += 1
  else if (today > lastCareDay + 1):
        missed = today - lastCareDay - 1
        if (warmthBanked >= missed)    warmthBanked -= missed; streak += 1   // freeze: streak survives
        else                           streak = 1                            // gentle reset, NO penalty, NO loss of pet/Bond
  lastCareDay = today
  periodically:  warmthBanked = min(warmthBanked + 1, WARMTH_CAP)            // earns freezes over time

Invariants:
  - Missing days NEVER reduces Bond, NEVER harms the pet (no-death floor).
  - A reset streak is framed warmly ("welcome back!"), never punitively.
```

**Streak Warmth** = the freeze/repair bank. This is the entire reason the streak is a habit loop and not a churn lever.

### 6.6 Ambient interactions (idle life)

**Pure sequencing of existing assets** (brief #18) — no new art. A weighted scheduler plays idle behaviors (stretch, nap, chase tail, look up at the player) chosen by mood + life-stage + personality dial. This is what makes the pet "feel alive" between care actions, and it's nearly free because it reuses param-blend motions.

---

## 7. Real-World Impact / Donation Backend (The Impact Pledge + Rescue Wall)

**Canonical model (brief §9, Reconciled Conflict #4):** "Transparent Pooled Allocation with 1:1 Impact Mapping." **% of NET revenue** pledged to a vetted **intermediary** (PayPal Giving Fund / Percent / Benevity) → **1–3 vetted partners**. **NO donation-IAP. NO player tax-deductible donations in MVP. Compassion Coins represent pooled intent, not personal deductible gifts.**

| Feature | FPD | Verdict |
|---|---|---|
| #11 Donation/Impact Engine | 1.33 | **MVP\*** (cheapest form = % net-rev pledge to ONE vetted intermediary) |
| #12 Rescue Wall (impact UI) | 2.33 | **MVP** |
| #13 Anti-fraud (platform-native) | — | **MVP (forced)** — gates Coin minting |
| #13b Anti-fraud (bespoke anomaly/ML) | 0.60 | **Deferred** |

> Donation **policy/wording, partner vetting, the version-stamped Impact Pledge doc** and the player-facing impact loop live in `GAMEPLAY_AND_PROGRESSION_BIBLE.md`; the locked donation-ethics decisions live in `GAME_DECISION_LOG.md`. This section owns the **backend mechanics, ledger, and anti-fraud**.

### 7.1 Payment & value flow

```
REVENUE IN                         VALUE REPRESENTED                REAL-WORLD OUT
──────────                         ─────────────────                ──────────────
Rewarded ad watch ─► S2S postback ─► (gate) mint Compassion Coins ─┐
IAP / Forever Friends ─► receipt ──► (gate) entitlements + Coins   │
Rescue Bundle purchase ─► receipt ─► (gate) cosmetic + disclosed   │
                                       donation slice              │
                                                                   ▼
                              % of NET revenue accrues to ─► Impact Pool (segregated,
                              (net of store 15–30%, processing,      append-only ledger)
                               ad-network cut)                       │
                                                                     ▼ fixed cadence (monthly/quarterly),
                                                                       AFTER settlement window
                                              Giving intermediary (PayPal Giving Fund /
                                              Percent / Benevity) ─► 1–3 vetted shelters
                                                                     │
                              Rescue Wall reads ◀────────────────────┘ dated receipts,
                              (lifetime/personal real $, live          partner acknowledgments
                               campaign bars, downloadable receipts)
```

- **Compassion Coins are an in-app *representation*** of the pooled real allocation — **not** a charitable IAP and **not** tax-deductible (brief Conflict #4, §9). 50 Coins = 1 real meal (illustrative 1:1 outcome mapping, brief §5).
- **Rescue Bundles are commercial purchases** (cosmetic + disclosed donation slice, e.g. 70/30), with the split shown **pre-purchase + on receipt** (brief §5, §9 trust pillar 5).
- Every rewarded-ad watch mints Coins (brief §5) — **free players still generate real impact** (HARD ETHICAL WALL: impact never requires payment, §9).

### 7.2 Donation ledger (Impact Pool)

- **Segregated, append-only, auditable** (brief §9 trust pillar 2). Supabase Postgres makes this clean (row-level security + SQL reconciliation); on Firebase, a write-once collection with Cloud Functions enforcing append-only.
- **Ledger entry:**

```
ImpactLedgerEntry {
  id, ts, type: "ad|iap|sub|bundle",
  grossAmount, storeFee, processingFee, netAmount,
  donationRate, accruedDonation,    // accruedDonation = netAmount * donationRate
  settlementState: "pending|settled|clawed_back",
  disbursementBatchId  // null until disbursed
}
```

- **Disburse only after the settlement window** (refund/chargeback safe) on a fixed cadence; record the intermediary's confirmation + dated receipt against the batch.
- Numbers in the player-facing Rescue Wall are **always rounded DOWN** (under-promise/over-deliver, brief §9 trust pillar 4).

### 7.3 Impact-reporting data (Rescue Wall)

Data-driven dashboard (brief #12) reading the ledger:

- Lifetime real $ donated (pool) + this player's contribution share.
- Live campaign progress bars per partner.
- **Dated, downloadable receipts** + partner acknowledgments.
- Third-party **"Impact verified through <date>" badge** past a volume threshold (brief §9 trust pillar 7; badge UI is MVP-ready, verification flips on at scale per G5).

### 7.4 Anti-fraud mechanisms (platform-native = MVP forced)

Coins map 1:1 to real money, so **minting must be server-gated** (brief §5, §13):

1. **Server-side mint-gating:** Coins are minted **only** by a backend function, never by the client.
2. **S2S signed ad postbacks:** reconcile against **network-PAID impressions only** — a client claiming "I watched an ad" mints nothing; the ad network's signed server-to-server postback does.
3. **Receipt validation:** Apple/Google receipt validation (via RevenueCat) before IAP/sub Coins or entitlements.
4. **Device attestation:** **App Attest (iOS) / Play Integrity (Android)** on mint requests — rejects emulators/tampered clients.
5. **Per-user / per-device daily caps** on mintable Coins.
6. **Clawback:** on refund/chargeback → claw back Coins + revoke badges; disburse only after the settlement window.
7. **Non-transferable, non-convertible Coins** (brief §5) — kills laundering: there's no way to extract value, so fraud yields only cosmetic in-game Coins, not money.

**Bespoke anomaly/ML anti-fraud (#13b, FPD 0.60) = Deferred** — premature at MVP scale; add when volume/social justify (brief §13b).

### 7.5 Donation compliance (mechanics view)

- **No donation IAP, no tax-deductible player donations in MVP** (store-policy + charity-registration compliance, R5) — enforced by *never* exposing a "donate $X" purchase; only Rescue Bundles (commercial) and ad-funded Coins exist.
- "X% of revenue" claims are **always stated NET** to avoid misleading (brief §5).
- The legal backbone (% net-revenue pledge via intermediary) and partner vetting are owned by `GAMEPLAY_AND_PROGRESSION_BIBLE.md` (player-facing donation loop) and `GAME_DECISION_LOG.md` (locked donation-ethics decisions); this doc guarantees the **ledger + gating** that makes those claims true.

---

## 8. Data, Persistence & Sync

### 8.1 Local-first

- Client is the fast path: SQLite/Hive snapshot (§3.4), pending-mutation queue, cached dialogue bank.
- The sim never blocks on the network; the only things that *must* be server-authoritative are value/trust objects (Coins, ledger, entitlements, memory of record).

### 8.2 Cloud save (authoritative, versioned)

- Authoritative cloud snapshot keyed to **Apple/Google sign-in (+ guest)** (brief §6). Guest play is allowed but warns that an un-linked pet can be lost — converting to a real account is encouraged early (this protects R4 for the highest-LTV cohort).
- **Versioned schema + automated migration + restore flow** (R4). Every schema bump ships a migration; **no update may orphan a pet.**
- **Single-device last-write-wins for MVP**; true multi-device live sync **deferred** (brief §6).
- **Conflict policy:** on restore, if local and cloud both exist, prefer the snapshot with the newer `lastSimTimestamp` and surface a clear, warm choice — never silently discard a pet.

### 8.3 Account / identity

- Apple Sign-In + Google Sign-In + guest (anonymous). No email/password to minimize PII and child-data surface (R1).
- The account binds: cloud save, memory-fact store, Compassion Coin balance, Impact-Pool contribution share, and RevenueCat entitlements.
- **Right-to-be-forgotten** (GDPR/COPPA): a documented deletion path wipes the save, memory facts, and analytics identifiers; ledger entries are anonymized (retain the financial fact, drop the personal link) so donation audit integrity survives deletion.

---

## 9. Backend & Infrastructure

### 9.1 Serverless choices

- **Managed BaaS only** (Firebase or Supabase) — **no owned servers** (brief §6). This is a solo-maintainability requirement, not a preference (Founder-Fit).
- **Thin Cloud/Edge Functions** for the four trusted operations: Heartmind proxy, Memory service, Coin-mint gate, Impact ledger/disbursement. Each is small, stateless, and AI-agent-scaffoldable.
- **Remote Config** drives: live-ops event flags, dialogue-bank top-ups, donation rates, caps, and the live-chat gate — so behavior changes ship without app updates (architected in MVP for R8; events themselves are Deferred, brief #27).

### 9.2 Scaling

- BaaS auto-scales reads/writes; our write volume is low (sim is client-side). The only request-rate-sensitive path is the **Deferred live-chat proxy**, which is capped per-user by design (§4), so it cannot scale-spike OPEX uncontrollably (R2).
- Widget/notification load is client/OS-side (local scheduling), so it does not load the backend.

### 9.3 Cost (infra, excluding LLM — see §12)

- BaaS free/low tiers cover indie scale; cost/DAU is dominated by LLM (§12), not by DB/auth/functions.
- **Gate G5** requires **infra cost/DAU stable** at scale; instrument function invocation counts and BaaS read/write quotas as part of the ~15 analytics events so this is measurable, not guessed.
- **CAC near-zero at launch** (brief §5) — growth is organic/viral (see `GAMEPLAY_AND_PROGRESSION_BIBLE.md`); paid UA only after sub LTV > CAC is proven.

---

## 10. Analytics & Telemetry

**~15 events mapped to funnel gates** (brief §6), privacy-by-design, **no PII** (R1).

### 10.1 Event set (illustrative, ~15)

| # | Event | Maps to gate / KPI |
|---|---|---|
| 1 | `rescue_day_completed` | onboarding funnel (G2/G3) |
| 2 | `session_start` | D1/D7/D30 (G3/G4) |
| 3 | `care_action` (feed/clean/play) | core-loop engagement (G1) |
| 4 | `bond_stage_up` | relationship growth (meta loop) |
| 5 | `life_stage_up` | growth payoff |
| 6 | `memory_callback_shown` | AI-memory authenticity (G2) |
| 7 | `ai_line_shown` (+ `is_repeat` flag) | **"noticed AI repetition"** leading churn (G6) |
| 8 | `notification_opened` | re-engagement (G3) |
| 9 | `streak_continued` / `streak_warmth_used` | habit loop (G4) |
| 10 | `keepsake_card_shared` | viral share/DAU-week (G4) |
| 11 | `rewarded_ad_completed` | ad revenue + Coin mint (G4) |
| 12 | `iap_purchase` / `sub_started` | ARPDAU, sub conversion (G4/G6) |
| 13 | `compassion_coins_minted` | donation volume (G6) |
| 14 | `guilt_signal` (survey/proxy) | **"felt guilt-tripped"** leading churn (G6) |
| 15 | `llm_turn` (live path) + token usage | LLM cost/DAU < 35% ARPDAU (G4) |

### 10.2 Mandatory leading churn indicators

Brief §10 makes these **non-optional**: instrument **"noticed AI repetition"** (via `ai_line_shown.is_repeat` rate) and **"felt guilt-tripped about the pet."** They "predict D7/D30 collapse before raw numbers move." Wire them to dashboards from G3.

### 10.3 KPI thresholds the telemetry must prove (brief §10)

- **G1:** loop "fun" qualitative; deterministic sim + offline-catch-up green; zero neglect-guilt.
- **G2:** persona "tell a friend"; **AI memory callback reliability ≥95% (no hallucinated facts)**; first-AI-line latency = 0 spinner; rig cost on-budget.
- **G3 (closed beta):** **D1 ≥40% / D7 ≥18%**; 0 child-safety incidents; cloud-restore proven; LLM cost/DAU within model; crash-free ≥99%.
- **G4 (soft launch):** **D1 ≥42% / D7 ≥20% / D30 ≥10%**; **ARPDAU ≥$0.03**; **LLM cost/DAU < 35% ARPDAU**; ≥1 viral share / DAU-week; clean donation reconciliation.
- **G5 (global):** soft KPIs held 4 wks at scale; infra cost/DAU stable; **crash-free ≥99.5%**; transparency badge live.
- **G6 (live ops, quarterly):** D30 ≥10%; sub conversion ≥2%; IAP-payer ≥1.5%; donation volume up + quarterly Impact Report shipped; the two leading-churn metrics within bounds.

*(Headline targets, brief §7: D1 ~45% (40–48) · D7 ~20–22% (18–25) · D30 ~10–12% (8–14). Worst case if AI memory disappoints: D30 → ~5–6%.)*

---

## 11. Security, Privacy & Compliance

**R1 (Kids-compliance) is the existential risk** (brief §11, Critical) and shapes the entire design.

### 11.1 Build to a child-safe standard for ALL users

- **No free-text storage from minors; under-13 = templated/non-generative only** (brief §11 R1, §4.5).
- **No behavioral ad targeting** anywhere; ads run with COPPA/kids flags, contextual-only or none for kids (brief §5).
- **Mandatory, budgeted pre-launch legal review** is a **gate at G3** (brief §11 R1, Open Decision #9) — child-directedness determination drives neutral-age-gate vs fully-child-safe-for-all.

### 11.2 Kids data & PII minimization

- Sign-in via Apple/Google or guest — **no email/password**, minimal PII.
- Voice mimic (Deferred) is **on-device DSP only, audio never leaves the device** (§5) — sidesteps biometric capture.
- Memory facts are a **closed enumerated set** of innocuous values; no free-form personal data is stored in MVP.
- Analytics carries **no PII**; identifiers are reset on account deletion.

### 11.3 App Store / Play rules

- **No gacha/loot boxes** (brief §5) — cosmetics are direct-purchase, horizontal.
- **No donation IAP / no tax-deductible player donations** (R5) — Rescue Bundles are commercial with disclosed splits; ad-funded Coins are free.
- RevenueCat handles receipt validation/restore so store-compliance for purchases is centralized.
- Privacy nutrition labels / Data Safety form filled honestly: data collected = account ID, save data, coarse analytics; **declare no behavioral ad targeting** and the on-device-only voice handling.

### 11.4 AI-generated content policy

- **MVP ships 100% human-reviewed pre-generated lines** → no novel unsafe text can reach a player on the MVP path.
- The Deferred live path runs **two-sided moderation + hard system-prompt guardrails + fixed safe-fallback + self-harm static message + full audit logging** (§4.5) and is **disabled for under-13**.
- **HARD ETHICAL WALL** (brief §9): the AI never ties the pet's wellbeing/survival to real donations and never guilt-frames. This is enforced in the persona prompt and in the no-death floor.
- **Negative-virality defense (R10):** hard guardrails + child-safe persona lock + per-turn moderation; "many small authentic moments over one engineered spectacle." One tone-deaf screenshot defines the brand, so the safe path is the default path.

### 11.5 Transport & secrets

- TLS 1.2+ everywhere; the Anthropic API key lives only in the server-side proxy (never in the client).
- Device attestation (App Attest / Play Integrity) on value-minting calls (§7.4).
- Audit logs (moderation decisions, ledger mutations, disbursements) retained for incident response and donation transparency.

---

## 12. LLM & Infra Cost Model (per-DAU cost + controls)

**This is the make-or-break OPEX model** (brief §6, R2). **Hard gate G4: LLM cost/DAU < 35% of ARPDAU.** Target ARPDAU $0.03–0.06 (brief §5).

### 12.1 Where token spend exists (and where it doesn't)

| Path | Verdict | Runtime token cost / DAU | Why |
|---|---|---|---|
| MVP dialogue (bank + memory injection) | MVP\* | **$0** | Pre-generated once, selected on-device. |
| Offline pre-generation pass | MVP | **amortized to ~$0/DAU** | Paid once at build/live-ops time, spread across all installs. |
| Memory fact store reads/writes | MVP | **$0 tokens** (DB only) | No model in the loop at runtime. |
| Live free-form chat | **Deferred** | metered, **subscriber-funded** | Only adult-verified subscribers; capped. |
| Fact extraction | Deferred | metered, **batched off-peak** | Amortized, not per-turn. |
| Moderation (live path) | MVP (forced for AI) | per-turn, live path only | Rides on the live-chat path's economics. |

**Key consequence:** at MVP, the *blended* LLM cost/DAU is dominated by the amortized pre-gen pass, which is structurally tiny per DAU. The cost-sensitive variable only switches on with the **Deferred** live path — which is why it is gated behind subscribers (who fund it).

### 12.2 The seven cost controls (brief §5, §6, R2)

1. **Hybrid pre-generation** — zero runtime tokens for the MVP experience.
2. **Structured memory injection** — "it remembers" is data, not generation.
3. **Prompt-cache the persona prefix** — the large stable system prompt reads at ~0.1× input price; keep it byte-stable (no timestamps/IDs in the prefix) so the cache never invalidates.
4. **Small/cheap model for live chat** (Deferred) — the cost-sensitive path doesn't need the top model; the pre-gen pass (quality-sensitive) uses `claude-opus-4-8` and is paid once.
5. **Output token caps (~60–100)** and tight, in-character output discipline.
6. **Daily turn caps + per-user cost ceiling** — bounds worst-case spend per user (kills the "engagement scales OPEX unboundedly" anti-F2P trap, R2).
7. **Live chat is subscriber + age gated** — the only metered path is funded by the cohort paying for it (Forever Friends $5.99/mo · $39.99/yr funds LLM OPEX, brief §5).

### 12.3 The guard equation (instrument at G3, enforce at G4)

```
LLM_cost_per_DAU = (amortized_pregen_cost_per_DAU)
                 + (live_chat_share_of_DAU × avg_turns × tokens × price_per_token_after_cache)
                 + (moderation_cost_per_live_turn × live_turns_per_DAU)

REQUIRE:  LLM_cost_per_DAU < 0.35 × ARPDAU      (gate G4)
```

- Because MVP has **no live chat**, `LLM_cost_per_DAU ≈ amortized_pregen_cost_per_DAU` → trivially within budget at launch.
- The live path (P4 pilot, Open Decision #10) is only expanded if this inequality holds with live traffic in it.
- If the inequality is threatened: tighten caps → shrink live-chat cohort → fall back further to the bank. The bank path is always the safety floor.

### 12.4 LTV / funding context (brief §5, cross-link `GAMEPLAY_AND_PROGRESSION_BIBLE.md`)

- Blended LTV/install **$0.30–$0.80** (upside $1.00–1.50+); sub-cohort LTV **$30–80+** (the profit lever and the LLM funding source).
- Sub conversion target **1–3% MAU**; IAP-payer **1–2%**, ARPPU **$8–20**.
- **Subscription funds LLM OPEX** — this is why live chat is subscriber-gated, not a paywall for its own sake.

---

## 13. Build vs Buy Table

*(Solo + AI in 12–18 months. "Buy/managed" wherever it removes ops or risk; "build thin" only the trust-critical glue.)*

| Capability | Decision | Rationale (Founder-Fit: buildable + maintainable solo+AI) |
|---|---|---|
| Live2D rig + animation | **Buy** (commission 2 rigs, $1,200–$2,000 ea, +15–20% revision) | No custom 3D pipeline (hard constraint); lock design with AI concept (Midjourney) before paying. See `GAME_CONTENT_FACTORY.md`. |
| Engine / runtime | **Buy** (Unity or Flutter+Live2D) | Off-the-shelf; no engine work. |
| Backend / auth / DB / cloud save / remote config | **Buy/managed** (Firebase or Supabase) | No owned servers (R-maintainability). |
| Billing / entitlements / receipts | **Buy** (RevenueCat) | Collapses two billing stacks; receipt validation included. |
| Ads / mediation | **Buy** (AdMob/ironSource) | S2S postbacks come built-in (needed for Coin minting). |
| LLM | **Buy** (Anthropic API) | No model hosting. Pre-gen pass paid once. |
| Moderation | **Buy** (cheap classifier/moderation endpoint) | Per-turn moderation as a service; no in-house classifier. |
| Dialogue bank generation | **Build (offline, AI-assisted) + human review** | One-time content op; AI-agent leverage; review is the safety gate. |
| Heartmind proxy / Memory service / Coin-mint gate / Impact ledger | **Build thin** (serverless functions) | The only trust-critical custom glue; small, stateless, AI-scaffoldable. |
| Donation disbursement | **Buy** (PayPal Giving Fund / Percent / Benevity) | Trust in process, not founder's word (brief §9); they handle charity compliance. |
| Widgets / notifications | **Build thin** (native WidgetKit/Glance + local scheduler) | Unavoidable native glue, but tiny (one shared payload). |
| Analytics / crash | **Buy/managed** (Firebase/GameAnalytics + Crashlytics/Sentry) | Free tier; no data infra. |
| Anti-fraud (platform-native) | **Buy primitives** (App Attest / Play Integrity + S2S postbacks + receipt validation) | Use platform attestation; no bespoke ML at MVP (#13b Deferred). |
| Voice transform (Deferred) | **Build (on-device DSP)** when un-deferred | No cloud ML; keeps audio on-device (privacy). |

---

## 14. Technical Risk Register

*(Top risks with technical mitigations. Severities/IDs mirror the brief §11 risk register; this table adds the **technical** mitigation owned by this document.)*

| # | Risk | Sev | Technical mitigation (owned here) | Gate |
|---|---|---|---|---|
| **R1** | Kids-compliance (COPPA/GDPR-K/store kids policy) — detonated by AI chat, voice capture, ad targeting. | Critical | Build child-safe for ALL users; MVP dialogue is 100% pre-reviewed; under-13 = templated/non-generative only; no behavioral ad targeting; on-device-only voice (Deferred); closed-set memory facts; no PII sign-in. | **G3** legal sign-off |
| **R2** | Unbounded LLM OPEX scales with engagement. | Critical | Hybrid pre-gen (zero runtime tokens at MVP); prompt-cache persona; small model for live chat; output + daily-turn caps; per-user cost ceiling; live chat subscriber+age gated; §12 guard equation. | **G4** cost/DAU < 35% ARPDAU |
| **R3** | AI-memory authenticity — load-bearing feature; flaky recall = "theater." | Critical | Narrow+reliable structured fact store (10–30, closed set); facts only injected into pre-reviewed template slots → no hallucinated facts; tangible Memory Book trust artifact; anti-repetition rotation. | **G2** ≥95% callback reliability |
| **R4** | Save loss / pet "death." | High | Authoritative versioned cloud save + automated migration + restore flow; no-death decay floor (pet can never suffer irreversibly); idempotent pending-mutation queue; guest→account conversion nudge. | **G3** cloud-restore proven |
| **R5** | Donation legal/charity-washing. | High | % NET-revenue pledge via vetted intermediary; segregated append-only Impact-Pool ledger; disburse after settlement window; rounded-down outcome claims; NO donation IAP; per-bundle split disclosed. (Policy text → `GAMEPLAY_AND_PROGRESSION_BIBLE.md`; donation-ethics decisions → `GAME_DECISION_LOG.md`.) | **G4** clean reconciliation |
| **R6** | Neglect-guilt / punitive streaks churn high-LTV personas. | High | No-death floor + MAX_CATCHUP cap (longing, not distress); Streak Warmth freeze/repair; warm/invitational notifications capped 1–2/day; Bond is gain-only. | **G1** zero neglect-guilt |
| **R7** | Asset-cost explosion (multi-species, per-stage animation). | High | 1 modular Live2D rig/species; 3 stages via scale/param (not new rigs); emotions = param blends (0 new art); cosmetics = overlay+palette-swap; defer 2nd species at G2 if rig cost hot. | **G2** rig cost on-budget |
| **R8** | Live-ops content treadmill exceeds solo+AI capacity. | Medium | Remote-config/data-driven event infra built in MVP (events themselves Deferred); core loop retains via Bond/Memory, not new content; dialogue-bank top-ups via remote config. | **G6** sustainable cadence |
| **R9** | Cross-platform native fragmentation (widgets/notifications/billing). | Medium | RevenueCat for billing; ONE shared status payload → one widget per platform; local notifications in MVP; lock-screen/Live Activities Deferred fast-follow. | **G5** |
| **R10** | Negative virality — one unsafe/tone-deaf AI screenshot defines the brand. | Med-High | Hard system-prompt guardrails + child-safe persona lock + per-turn two-sided moderation + fixed safe-fallback; under-13 templated-only; many small authentic moments over one engineered spectacle. | **G3** 0 incidents |

---

## 15. Phase mapping (what gets built when — cross-link brief §3)

*(This doc owns no phase definitions; it maps its systems onto the brief's locked phases so an executor knows build order. Phase names/durations/gates are canonical in the brief.)*

| Phase | Technical systems delivered (from this doc) | Gate |
|---|---|---|
| **P0 — Pre-production (6 wks)** | `current_state.json` created; engine + BaaS picked (Open Decision #1); LLM provider/tiers modeled (#3); Live2D rig design locked via AI concept; legal review booked. | **G0** |
| **P1 — Core-loop prototype (8 wks)** | 1 rig (puppy); 4 Care Meters + no-death floor; feed/clean/play; The Bond; deterministic sim + offline catch-up; 1 placeholder room; local notifications. | **G1** |
| **P2 — Vertical slice (10 wks)** | Rescue Day; Heartmind hybrid (pre-gen bank + structured memory + Memory Book); 3 life-stages; home widget; Keepsake Cards; 2nd species OR cut decision (rig-cost driven). | **G2** |
| **P3 — MVP / Closed beta (12 wks)** | Full MVP feature set; RevenueCat IAP/sub; ads SDK (child-safe config); Coin-mint gate + platform-native anti-fraud; Rescue Wall; cloud save + migration; ~15 analytics events; legal sign-off; localization shell. | **G3** |
| **P4 — Soft launch (8 wks)** | Phased geo rollout; **live LLM gated pilot for adults** (#6b begins, subscriber+age-gated); donation intermediary live + first disbursement; ASO assets. | **G4** |
| **P5 — Global launch (4 wks)** | Full localization; scaled infra; transparency badge live; crash-free ≥99.5%. | **G5** |
| **P6 — Live ops (ongoing)** | Lock-screen widget; **voice mimic (on-device DSP)** if un-deferred; training; Care Pass; seasonal events (remote-config driven); 2nd species (if cut at G2); breed palette-swaps; bespoke anti-fraud (#13b) if volume justifies. | **G6 (quarterly)** |

---

## 16. Open technical decisions (resolve by gate — cross-link brief §12)

| # | Decision | Resolve at |
|---|---|---|
| 1 | Engine: Unity vs Flutter+Live2D (bias to fastest solo+AI shipping path with native widget interop). | **G0** |
| 2 | 2nd species ship-or-cut (rig-pipeline cost burn; budget for 2, ship 1 if hot). | **G2** |
| 3 | LLM provider + exact model tiers (cheap live-chat model vs pre-gen model) + final token/turn caps. | model G0, validate **G3/G4** |
| 4 | Donation intermediary (PayPal Giving Fund vs Percent vs Benevity) + initial 1–3 partners (must be live for soft launch). | before **G4** |
| 5 | Exact donation % per revenue type (net) — finalize with accounting/legal. | before **G4** |
| 6 | Launch localization languages (static UI); AI-dialogue languages stay EN(+1–2). | by **G3** |
| 7 | Soft-launch geos (e.g. CA/PH/NZ candidate). | by **G3** |
| 8 | Subscription final price ($5.99 assumed) + Care Pass pricing — validate elasticity. | **G4** |
| 9 | Under-13 handling: neutral age gate vs fully child-safe-for-all (legal child-directedness determination). | **G3** legal review |
| 10 | Live free-form chat go/no-go for adults — pilot P4, decide expand/hold on cost + safety data. | **G4** |

---

*End of GAME_TECHNICAL_SYSTEMS.md (v1.0). All feature classifications, FPD verdicts, phase/gate IDs, KPI thresholds, currency names, and asset numbers are inherited verbatim from `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md`; the machine-readable mirror is `current_state.json`. No fact in this document may contradict the brief — if it appears to, the brief wins and the conflict must be reported.*
