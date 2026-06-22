# KINDREDPAWS — GAME DECISION LOG

**Document role:** This is the **auditable decision record** for Project KindredPaws — the chronological, traceable account of *every major decision*, its rationale, the framework that produced it (FPD / Founder-Fit / Playtester / Discovery / Asset-Budget), and any later reversal.

**Canonical for:** Feature classification verdicts (MVP / Deferred / Removed / North-Star) with FPD scores; FPD evaluation details per feature; Founder-Fit audit results; AI Playtester findings-to-decisions; Discovery/virality decisions; Asset-budget decisions; Architecture Decision Records (ADRs); numbered decision entries (D-001…); open decisions; reversal/change log.

**NOT canonical for (cross-links, do not duplicate):**
- The single source of truth for *project framing, terminology, phases, KPI thresholds, economy, tech stack* is the **KINDREDPAWS — CANONICAL DECISION BRIEF (v1.0 LOCKED, 2026-06-22)**. Where this log restates a brief number, it is a *mirror* of the brief; if they ever diverge, **the brief wins** and this log must be corrected via the Reversal & Change Log.
- Machine-readable live state → `current_state.json` (created at Phase 0; mirrors the brief + this log's open/closed decisions).
- Technical/architecture deep detail → `GAME_TECHNICAL_SYSTEMS.md`.
- Economy/monetization deep detail → `GAMEPLAY_AND_PROGRESSION_BIBLE.md`.
- Donation/impact player-facing loop + trust pillars → `GAMEPLAY_AND_PROGRESSION_BIBLE.md`; donation ledger/anti-fraud backend → `GAME_TECHNICAL_SYSTEMS.md`.
- Art/asset production plan → `GAME_CONTENT_FACTORY.md`.
- Design/loop/feature spec → `GAMEPLAY_AND_PROGRESSION_BIBLE.md`.

> **Consolidation rule:** Each fact lives in exactly ONE canonical document. This log owns *decisions and their rationale*. It cross-links rather than re-specifies. No entry here may contradict the brief.

---

## Table of Contents

1. [How to Use This Log](#1-how-to-use-this-log)
2. [Decision Record Format (template)](#2-decision-record-format-template)
3. [Feature Classification MASTER TABLE](#3-feature-classification-master-table)
4. [FPD Evaluation Details (per feature)](#4-fpd-evaluation-details-per-feature)
5. [Founder-Fit Audit Results](#5-founder-fit-audit-results)
6. [AI Playtester Simulation Findings → Decisions](#6-ai-playtester-simulation-findings--decisions)
7. [Discovery / Virality Decisions](#7-discovery--virality-decisions)
8. [Asset-Budget Decisions](#8-asset-budget-decisions)
9. [Monetization & Donation-Ethics Decisions](#9-monetization--donation-ethics-decisions)
10. [Architecture Decision Records (ADRs)](#10-architecture-decision-records-adrs)
11. [Numbered Decision Entries (D-001…)](#11-numbered-decision-entries-d-001)
12. [Open Decisions / To-Be-Resolved](#12-open-decisions--to-be-resolved)
13. [Reversal & Change Log](#13-reversal--change-log)

---

## 1. How to Use This Log

This log is an **operating document**, not a retrospective archive. A solo founder + AI agents execute against it daily.

**When to write a new entry (mandatory triggers):**
- Any feature changes classification (MVP ↔ Deferred ↔ Removed ↔ North-Star).
- Any FPD score is recomputed and crosses a verdict band (≥1.5 / 1.0–1.49 / 0.6–0.99 / <0.6).
- Any architectural commitment is made or reversed (→ ADR).
- Any gate (G0–G6) is passed, failed, or its criteria changed.
- Any of the brief's **Open Decisions §12** is resolved.
- Any number in the brief (cost, %, KPI, decay rate, cap) is changed.
- Any hard-constraint exception is *requested* (it should be denied — log the denial).

**How to read it:**
- Start with the **Master Table (§3)** for the current verdict on any feature.
- Drill into **§4** for *why* a feature got its FPD, **§5** for *can the founder build/maintain it*, **§6** for *will players love it*.
- Architecture choices live in **§10 (ADRs)**; everything else with a discrete decision lives in **§11 (D-entries)**.
- **§13** is the audit trail of anything that changed after first being locked.

**Authority order (highest first):** Hard Constraints → Canonical Decision Brief → this Decision Log → sibling docs → `current_state.json` reflects all of the above.

**State sync rule:** Every closed decision here MUST update `current_state.json` in the same working session. The JSON is the machine-readable mirror; this log is the human-readable rationale.

**Status vocabulary:** `PROPOSED` · `ACCEPTED` · `LOCKED` (ratified at a gate) · `DEFERRED` · `SUPERSEDED` · `REVERSED` · `REMOVED` (cut entirely) · `NORTH-STAR` (vision; deliberately excluded from MVP, not committed). Note: `REMOVED` and `NORTH-STAR` are distinct — `REMOVED` means cut from the product, `NORTH-STAR` means parked as long-term vision.

---

## 2. Decision Record Format (template)

Use this template for every numbered entry in §11 and every ADR in §10 (ADRs add the architecture-specific fields).

```
### D-XXX — <Short imperative title>
- Status: PROPOSED | ACCEPTED | LOCKED | DEFERRED | SUPERSEDED | REVERSED | REMOVED | NORTH-STAR
- Date: YYYY-MM-DD
- Owner: <role>  (solo founder unless delegated)
- Gate/Phase: <P0..P6 / G0..G6 / Live-ops>
- Framework basis: FPD | Founder-Fit | Playtester | Discovery | Asset-Budget | Legal | Brief-mandate
- Decision: <one or two sentences — the actual commitment>
- Context / Why now: <forces, constraints, conflict being resolved>
- Options considered:
    A) <option> — <pro/con>
    B) <option> — <pro/con>
- Rationale: <why the chosen option wins under the framework + hard constraints>
- FPD (if feature): FUN x / DOLLAR y = FPD z → Verdict <band>
- Hard-constraint check: <which constraints touched; how honored>
- Consequences: <what this enables/blocks; downstream doc impact>
- Reversal trigger: <the measurable condition that would reopen this>
- Cross-links: <sibling docs / other D-entries / brief §>
```

**ADR additional fields:** `Architectural scope` · `Alternatives rejected (with reason)` · `Reversibility cost (low/med/high)` · `Validation gate`.

---

## 3. Feature Classification MASTER TABLE

> **Mirror of brief §2.** FPD = FUN / DOLLAR (each scored 1–10). Verdict bands: **≥1.5 strong MVP** · **1.0–1.49 MVP only if simplified to cheapest emotionally-intact form (MVP\*)** · **0.6–0.99 Defer** · **<0.6 Remove / North-Star**. "Forced-MVP" features ship regardless of FPD because something else depends on them.

| # | Feature | FUN | $ | FPD | Verdict | D-entry | Rationale (one line) |
|---|---|---|---|---|---|---|---|
| 1 | Rescue Day (adoption cold-open) | 10 | 3 | **3.33** | **MVP** | D-010 | Player fantasy in one 60–90s scene; reuses the rig; cheapest high-fun hook. |
| 2 | Care Meters (4 needs / mood) | 8 | 3 | **2.67** | **MVP** | D-011 | Retention engine; pure data; no-death floor. |
| 3 | Core care (feed/clean/play) | 8 | 3 | **2.67** | **MVP** | D-012 | Tactile daily verbs; 3 interactions only. |
| 4 | The Bond (affection progression) | 9 | 2 | **4.50** | **MVP** | D-013 | Highest FPD; literal quantification of attachment; near-free. |
| 5 | Growth / Life-Stages | 9 | 5 | **1.80** | **MVP** | D-014 | Payoff of "raised it"; #1 art-cost lever — capped 3 stages × 2 species. |
| 6 | Heartmind dialogue (HYBRID) | 9 | 7 | **1.29** | **MVP\*** | D-015 | Pre-gen bank + structured memory, NOT live free-form; cost-gated. |
| 6b | Heartmind LIVE free-form LLM chat | 9 | 7 | **1.29** | **Deferred** | D-016 | Age-verify + subscriber + caps + moderation; post-soft-launch. |
| 7 | AI Memory (Memory Book) | 10 | 6 | **1.67** | **MVP** | D-017 | Emotional payload + #1 viral moment; structured fact store is cheap. |
| 8 | Evolving Personality | 7 | 4 | **1.75** | **MVP** | D-018 | Prompt-parameterized dials; ~0 marginal cost; deepens D30 bond. |
| 9 | Child-Safety Moderation | 8 | 10 | **0.80** | **MVP (forced)** | D-019 | Non-negotiable legal gate for any AI; FPD irrelevant. |
| 10 | Voice Mimic Layer | 7 | 8 | **0.88** | **Deferred** | D-020 | Not emotional core; child-voice privacy minefield; on-device pitch-shift, post-launch. |
| 11 | Donation / Impact Engine | 8 | 6 | **1.33** | **MVP\*** | D-021 | Differentiator 3; cheapest = % net-rev pledge to ONE vetted intermediary. |
| 12 | Rescue Wall (impact UI) | 7 | 3 | **2.33** | **MVP** | D-022 | Converts policy into felt, shareable trust; data-driven dashboard. |
| 13 | Anti-fraud (platform-native) | — | — | — | **MVP (forced)** | D-023 | S2S postbacks + receipt validation + attestation gate Coin minting. |
| 13b | Anti-fraud (bespoke anomaly/ML) | 6 | 10 | **0.60** | **Deferred** | D-024 | Premature at MVP scale; add when volume/social justify. |
| 14 | Home-Screen Widget | 8 | 5 | **1.60** | **MVP** | D-025 | Centerpiece of Companion Presence; primary re-engage for high-LTV cohort. |
| 15 | Lock-Screen Widget / Live Activities | 5 | 5 | **1.00** | **Deferred** | D-026 | Incremental over home widget; fast-follow once pipeline proven. |
| 16 | Notifications (pet-voiced) | 7 | 2 | **3.50** | **MVP** | D-027 | Cheapest retention lever; warm/invitational, never guilt. Local-first. |
| 17 | Care Streak (+ Streak Warmth) | 7 | 2 | **3.50** | **MVP** | D-028 | Cheap habit loop; MUST be forgiving (freeze/repair). |
| 18 | Ambient Interactions (idle life) | 7 | 4 | **1.75** | **MVP** | D-029 | Makes pet feel alive; pure sequencing of existing assets. |
| 19 | The Nest (decoration) | 6 | 5 | **1.20** | **MVP\*** | D-030 | Cosmetic surface; 1 room + modular palette-swap kit only. |
| 20 | Training / Tricks | 5 | 5 | **1.00** | **Deferred** | D-031 | Animation-expensive, non-differentiating; live-ops drop. |
| 21 | Cosmetics Shop | 6 | 4 | **1.50** | **MVP** | D-032 | Primary non-sub revenue; overlay sprites; ~30 pieces at launch. |
| 22 | Subscription (Forever Friends) | 5 | 4 | **1.25** | **MVP\*** | D-033 | Financial keystone funding LLM OPEX; single tier. |
| 23 | Ads (rewarded + sparse interstitial) | 4 | 3 | **1.33** | **MVP** | D-034 | F2P floor + donation funding; rewarded-first, kids see contextual/none. |
| 24 | Keepsake Cards (sharing/virality) | 8 | 3 | **2.67** | **MVP** | D-035 | K-factor engine; templated composition; 1-tap native share. |
| 25 | Cloud Save / Account | 6 | 10 | **0.60** | **MVP (forced)** | D-036 | Losing the pet = catastrophic; prerequisite for memory/ledger/entitlements. |
| 26 | Localization (static UI) | 5 | 4 | **1.25** | **MVP\*** | D-037 | Global reach; AI-translate UI/copy; dialogue stays EN(+1–2) first. |
| 27 | Live-Ops Events | 7 | 6 | **1.17** | **Deferred** | D-038 | Inherently post-launch; MUST architect remote-config now. |
| 28 | More Species / Breeds (beyond 2) | 6 | 8 | **0.75** | **Deferred** | D-039 | Costliest expansion; breed palette-swaps first, new rig later. |
| 29 | Health / Illness / Vet | 4 | 5 | **0.80** | **Removed** | D-040 | Contradicts cozy/safe core; fold "comfort when sad" into mood. |
| 30 | Multiplayer / Social Visiting | 6 | 9 | **0.67** | **North-Star** | D-041 | Hard-constraint excluded; community impact counter is the only MVP proxy. |
| 31 | UGC / Custom Pet Creation | 5 | 9 | **0.56** | **North-Star** | D-042 | Hard-constraint excluded; lowest FPD; curated cosmetics meet expression need. |

**Hard-constraint compliance check (mirror of brief):** ✅ No multiplayer (#30 North-Star) · ✅ No UGC (#31 North-Star) · ✅ No open world · ✅ No full-voice conversation (#6b Deferred) · ✅ No custom-3D (Live2D Cubism only) · ✅ Voice mimic Deferred (#10).

**Verdict tally:** MVP = 18 (incl. 5 MVP\* and 3 forced) · Deferred = 8 · Removed = 1 · North-Star = 2.

---

## 4. FPD Evaluation Details (per feature)

> Each feature scored FUN (emotional impact + retention power + differentiation + virality) and DOLLAR (build effort + unique-asset cost + ongoing/LLM/infra cost + technical risk + maintenance load). The **cheapest viable version that preserves the emotional core** is named for every MVP\* and every borderline feature.

### 4.1 Strong MVP (FPD ≥ 1.5)

**#4 The Bond — FUN 9 / $ 2 = 4.50.** FUN: literal quantification of attachment, the single most important number, drives every other system's payoff, free virality via stage-up moments. $: pure float + 5-stage state machine (Stranger → Friend → Companion → Kindred → Soulmate), no assets, trivial maintenance. *Cheapest viable:* one monotonic-up score with 5 named thresholds; Care-Meter deficits dampen *gain* but never reverse. **Highest-FPD feature in the game — build first, polish forever.**

**#1 Rescue Day — FUN 10 / $ 3 = 3.33.** FUN: delivers the entire player fantasy ("I rescued a tiny abandoned animal") in 60–90s; sets emotional anchor for D1 retention. $: a scripted sequence reusing the same rig with emotion param-blends (scared → trusting), 1 environment tint, a few lines from the pre-gen bank. *Cheapest viable:* single linear cold-open, no branching, no new art beyond emotion params.

**#16 Notifications (pet-voiced) — FUN 7 / $ 2 = 3.50.** FUN: cheapest retention lever in mobile; warm, in-character, invitational. $: local-scheduled (no push cost), templated lines from the same dialogue bank. *Constraint:* 1–2/day cap, never guilt, never mid-emotion. See `GAME_TECHNICAL_SYSTEMS.md`.

**#17 Care Streak + Streak Warmth — FUN 7 / $ 2 = 3.50.** FUN: proven casual habit loop. $: counter + forgiving rules. *Hard rule:* freeze/repair tokens, "pet missed you but is okay" framing — never punitive (Risk R6).

**#2 Care Meters — FUN 8 / $ 3 = 2.67.** 4 needs (hunger, energy/sleep, hygiene, happiness), 0–100 floats, gentle decay, **hard floor at "sad but safe"**. Pure data, deterministic, offline-catch-up. *Cheapest viable:* 4 floats → 4 mood states.

**#3 Core care (feed/clean/play) — FUN 8 / $ 3 = 2.67.** Three interactions only; tap + prop sprite + emotion-blend reaction. No new rigs.

**#24 Keepsake Cards — FUN 8 / $ 3 = 2.67.** Templated image composition (pet snapshot + line + name + tasteful watermark) + 1-tap native share. The K-factor engine (see §7).

**#12 Rescue Wall — FUN 7 / $ 3 = 2.33.** Data-driven dashboard turning the Impact Pledge into felt, shareable trust. No bespoke art beyond UI/icons.

**#5 Growth / Life-Stages — FUN 9 / $ 5 = 1.80.** FUN: the payoff of "raised it from infancy." $: **#1 art-cost lever** — capped at 3 stages (Pup/Kit → Young One → Grown) × 2 species via rig **param/scale, not new rigs**. *Cheapest viable that holds the core:* scale + proportion params on the single rig per species.

**#8 Evolving Personality — FUN 7 / $ 4 = 1.75.** Prompt-parameterized "dials" (playful↔calm, etc.) tuned by Bond + history; ~0 marginal cost; deepens D30. *Cheapest viable:* 3–4 personality dials injected into the cached persona prompt.

**#18 Ambient Interactions — FUN 7 / $ 4 = 1.75.** "Idle life" via sequencing of existing emotion motions; makes the pet feel alive. No new art.

**#7 AI Memory (Memory Book) — FUN 10 / $ 6 = 1.67.** FUN: highest emotional payload + #1 viral moment ("it remembered me"). $: a structured key-value store of 10–30 durable facts is cheap; the cost/risk is *reliability*. **Load-bearing feature (Risk R3):** engineer *narrow + reliable* over *broad + flaky*; ≥95% callback reliability gated at G2. The player-visible Memory Book is a tangible trust artifact.

**#14 Home-Screen Widget — FUN 8 / $ 5 = 1.60.** Centerpiece of Companion Presence; primary re-engage for high-LTV David cohort. Pre-rendered mood images, single shared status payload feeds widget + notifications. Lock-screen variant deferred (#15).

**#21 Cosmetics Shop — FUN 6 / $ 4 = 1.50.** Primary non-sub revenue; overlay sprites + palette-swap; ~30 pieces at launch; **NO gacha/loot boxes**.

### 4.2 MVP\* — MVP only in cheapest emotionally-intact form (FPD 1.0–1.49)

**#7-related #6 Heartmind dialogue (HYBRID) — FUN 9 / $ 7 = 1.29.** FUN: the AI companion magic. $: live free-form LLM is the OPEX risk (Risk R2) and child-safety risk (R1). **Cheapest emotionally-intact form = HYBRID:** an offline-pre-generated, human-reviewed dialogue bank selected at runtime by pet-state, with structured memory facts injected into a cached persona prompt. *The "it remembers" magic comes from the memory store + curated callbacks, not free-form generation.* See ADR-004.

**#11 Donation/Impact Engine — FUN 8 / $ 6 = 1.33.** Cheapest form = **% of NET revenue pledged to ONE vetted intermediary** (PayPal Giving Fund / Percent / Benevity). NO donation-IAP. See §9, `GAMEPLAY_AND_PROGRESSION_BIBLE.md` (donation loop), `GAME_TECHNICAL_SYSTEMS.md` (ledger).

**#23 Ads — FUN 4 / $ 3 = 1.33.** Rewarded-first, ~4–6/day cap, max 1 interstitial/session at natural breaks, never mid-emotion; kids see contextual-only or none; every watch mints Compassion Coins. See `GAMEPLAY_AND_PROGRESSION_BIBLE.md`.

**#22 Subscription (Forever Friends) — FUN 5 / $ 4 = 1.25.** Single tier $5.99/mo · $39.99/yr; the financial keystone funding LLM OPEX. *Cheapest form:* one tier, no tier laddering at launch.

**#26 Localization (static UI) — FUN 5 / $ 4 = 1.25.** AI-translate static UI/copy; **dialogue stays EN(+1–2)** until per-language safety validation post-launch.

**#19 The Nest — FUN 6 / $ 5 = 1.20.** *Cheapest form:* 1 room + modular palette-swap kit; cosmetic monetization surface only.

### 4.3 Forced-MVP (ship regardless of FPD — dependency/legal gates)

**#9 Child-Safety Moderation — FUN 8 / $ 10 = 0.80 → MVP (forced).** Two-sided input+output moderation, hard system-prompt constraints, fixed safe-fallback line, self-harm → static safe message, full audit logging. Under-13 = templated/non-generative only. FPD is irrelevant; this is the legal gate for *any* AI (Risk R1).

**#13 Anti-fraud (platform-native) — MVP (forced).** S2S signed ad postbacks + Apple/Google receipt validation + App Attest/Play Integrity attestation; gates Compassion-Coin minting. Bespoke ML deferred (#13b, FPD 0.60).

**#25 Cloud Save / Account — FUN 6 / $ 10 = 0.60 → MVP (forced).** Losing the pet = refund + 1-star + broken trust (Risk R4). Prerequisite for memory, donation ledger, and entitlements. *Cheapest form:* local-first, single-device last-write-wins, versioned schema + automated migration + restore flow.

### 4.4 Deferred (0.6–0.99, or higher FPD but inherently post-launch)

| Feature | FPD | Why deferred (not removed) |
|---|---|---|
| #6b Live free-form LLM chat | 1.29 | Real value, but OPEX + child-safety force gating to verified-adult subscribers post-soft-launch. |
| #10 Voice Mimic | 0.88 | Not the emotional core; child-voice privacy minefield; on-device DSP only, audio never leaves device. |
| #15 Lock-Screen Widget / Live Activities | 1.00 | Incremental over home widget; fast-follow once widget pipeline proven. |
| #20 Training / Tricks | 1.00 | Animation-expensive, non-differentiating; clean live-ops drop. |
| #27 Live-Ops Events | 1.17 | Inherently post-launch — but **remote-config infra must be architected in MVP** (ADR-009). |
| #28 More Species / Breeds | 0.75 | Costliest expansion; breed palette-swaps first, new rig later. |
| #13b Anti-fraud (bespoke ML) | 0.60 | Premature at MVP scale; add when volume/social justify. |

### 4.5 Removed (cut entirely)

| Feature | FPD | Why removed |
|---|---|---|
| #29 Health / Illness / Vet | 0.80 | Directly contradicts the cozy/safe core and the no-death floor. The emotional need ("comfort my pet when it's sad") is folded into the mood system instead. |

### 4.6 North-Star (vision, NOT committed for launch)

| Feature | FPD | Why North-Star |
|---|---|---|
| #30 Multiplayer / Social Visiting | 0.67 | Hard-constraint excluded from MVP; MVP proxy = community impact counter only. |
| #31 UGC / Custom Pet Creation | 0.56 | Hard-constraint excluded; lowest FPD; curated cosmetics satisfy the expression need. |

---

## 5. Founder-Fit Audit Results

> Each major system rated **Buildability (1–5)** and **Maintainability (1–5)** for ONE founder + AI agents over 12–18 months. Anything not buildable AND maintainable is simplified, deferred, or removed. Columns: B = Buildability, M = Maintainability.

| System | B | M | Key risk | AI-agent leverage | Mitigation | Decision |
|---|---|---|---|---|---|---|
| The Bond | 5 | 5 | Over-tuning thresholds | Agent generates + balances threshold tables | Single monotonic score, 5 named stages | **MVP — keep simple** |
| Care Meters | 5 | 5 | Decay-rate feel | Agent runs offline sim sweeps | No-death floor, 4 floats | **MVP** |
| Core care | 5 | 4 | Reaction polish | Agent wires tap→prop→emotion | 3 interactions only | **MVP** |
| Rescue Day | 4 | 5 | Emotional pacing | Agent scripts beats, founder polishes | Linear, no branching | **MVP** |
| Heartmind HYBRID | 3 | 3 | OPEX + safety + repetition | Agents generate/review pre-gen bank, build proxy | Hybrid, caching, caps, moderation | **MVP\* (cost-gated)** |
| AI Memory | 3 | 3 | Reliability/hallucination | Agent builds fact-extraction batch job | Narrow+reliable, ≥95% gate, Memory Book | **MVP (load-bearing)** |
| Evolving Personality | 4 | 4 | Drift/inconsistency | Agent tunes dial→prompt mapping | 3–4 dials, deterministic blend | **MVP** |
| Child-Safety Moderation | 3 | 2 | Legal liability; new attack surfaces | Agent builds audit logging + classifier wiring | Two-sided moderation; **budgeted legal review (G3)** | **MVP (forced)** |
| Donation/Impact Engine | 3 | 3 | Charity-washing / legal | Agent builds ledger + reconciliation | Vetted intermediary, NET-rev pledge | **MVP\*** |
| Rescue Wall | 4 | 4 | Data accuracy = trust | Agent builds dashboard from ledger | Round down; dated receipts | **MVP** |
| Anti-fraud (native) | 3 | 3 | Coin-mint exploits | Agent wires S2S + attestation | Mint only on PAID impressions; caps | **MVP (forced)** |
| Home Widget | 3 | 3 | Native fragmentation (iOS/Android) | Agent scaffolds WidgetKit + Glance | Single shared status payload, pre-rendered images | **MVP** |
| Notifications | 5 | 4 | Tone (guilt risk) | Agent writes templated warm lines | Local-first, 1–2/day cap | **MVP** |
| Care Streak | 5 | 5 | Punitive feel | Agent models Streak Warmth | Freeze/repair, never punish | **MVP** |
| Ambient Interactions | 4 | 4 | Repetition | Agent builds sequencer + rotation | Reuse motions, anti-repeat | **MVP** |
| The Nest | 4 | 4 | Asset creep | Agent generates palette-swaps | 1 room + modular kit | **MVP\*** |
| Cosmetics Shop | 4 | 4 | Catalog maintenance | Agent generates overlay sprites | ~30 pieces; no gacha | **MVP** |
| Subscription | 4 | 4 | Billing edge cases | RevenueCat abstraction | Single tier | **MVP\*** |
| Ads | 4 | 4 | Kids-config compliance | Agent wires mediation + flags | Rewarded-first, kids contextual/none | **MVP** |
| Keepsake Cards | 4 | 4 | Watermark taste/templating | Agent builds composition templates | 1-tap native share | **MVP** |
| Cloud Save | 3 | 3 | Migration/orphaned saves | Agent builds versioned migration + restore | Versioned schema; restore flow | **MVP (forced)** |
| Localization (static) | 4 | 4 | Translation QA | Agent translates UI strings | EN(+1–2) dialogue only | **MVP\*** |
| Voice Mimic | 2 | 2 | Child-voice privacy | (deferred) | On-device DSP only | **Defer** |
| Live free-form chat | 2 | 2 | OPEX + safety blow-up | Agent builds gated proxy later | Adult+subscriber+caps | **Defer** |
| Live-Ops Events | 3 | 2 | Content treadmill (R8) | Agent builds remote-config-driven events | Honest low cadence (1 / 6–8 wks) | **Defer (architect now)** |
| Multiplayer / UGC | 1 | 1 | Scope + moderation explosion | — | Excluded | **North-Star** |

**Founder-fit verdict summary:** The MVP set is buildable solo+AI in 12–18 months **provided** the three B/M=3 high-risk systems (Heartmind hybrid, AI Memory, Cloud Save) are kept in their *cheapest reliable* form and validated at G2/G3. The two systems that would break a solo founder (Multiplayer, UGC) are correctly North-Star. The treadmill risk (Live-Ops) is mitigated by architecting remote-config now and committing to an *honestly low* launch cadence.

---

## 6. AI Playtester Simulation Findings → Decisions

> Personas (mirror of brief §7): **Maya** (Gen-Z TikTok casual, highest K-factor) · **David** (busy adult pet-lover, highest LTV) · **Priya** (socially-conscious donor, trust-gated) · **Tom** (lapsed Tamagotchi nostalgic, AI-memory stress-tester) · **Leo & Parent** (kid under supervision, one-strike safety gate). Every finding converts to a concrete design change with a D-entry.

### 6.1 D1 session findings

| Persona | Fun moment | Friction / drop-off risk | Decision (→ D-entry) |
|---|---|---|---|
| Maya | Rescue Day cold-open lands in <90s; unprompted comfort moment | Any latency on first AI line reads as "broken/cringe" | **First AI line must be 0-spinner** (pre-gen bank, no live call). Gated at G2. → D-015, ADR-004 |
| David | Widget on home screen; pet "lives with me" | Onboarding asks too much before payoff | Rescue Day before any setup friction; widget prompt deferred to post-bond. → D-010, D-025 |
| Tom | "It remembered my name / what I said" | Detects scripted-ness fast; flaky recall = "theater" | Narrow+reliable memory; Memory Book as proof. → D-017, R3 |
| Leo & Parent | Pet is kind, gentle, safe | Parent vets AI before letting child chat | Under-13 templated-only; no free-text stored from minors. → D-019, R1 |
| Priya | Sees real shelter named | Suspicion of charity-washing | Rescue Wall with dated receipts + named partner; round down. → D-021, D-022 |

### 6.2 D7 session findings

- **Maya / Tom:** "noticed AI repetition" is the leading churn signal. → **Decision:** anti-repetition rotation system over the pre-gen bank; instrument "noticed AI repetition" as a mandatory leading-churn metric. (→ D-018, D-043)
- **David:** guilt from streak pressure would churn the highest-LTV cohort. → **Decision:** Streak Warmth (freeze/repair) + "pet missed you but is okay" longing model; never punish absence. (→ D-028, R6)
- **All:** offline absence must catch up gracefully (deterministic sim). → **Decision:** server-validatable elapsed-time catch-up; gated at G1. (→ ADR-005)

### 6.3 D30 session findings

- **Tom / Maya:** the D30 payoff is the *long memory callback* ("it remembered something from weeks ago") and *before/after growth*. These are the retention + virality keystones. → **Decision:** memory callbacks scheduled to surface at emotionally-earned moments; auto before/after Keepsake Card at Grown stage. (→ D-017, D-035)
- **Worst-case modeled:** if AI memory disappoints, D30 collapses to ~5–6% (genre median) vs. target ~10–12%. → **Decision:** ≥95% callback reliability is a HARD G2 gate; ship narrow before broad. (→ R3)

### 6.4 "Would I tell a friend?" test → virality decisions

| Persona | Shareable artifact | Decision |
|---|---|---|
| Maya | Unprompted comfort card (D1), memory payoff (D30) | Native 1-tap share, tasteful watermark. → §7 |
| David | Before/after growth + donation impact | Auto split-card at Grown; impact badge. → §7 |
| Priya | Verified impact badge | Third-party "Impact verified through <date>" past threshold. → §9 |
| Tom | "It remembered me" (Reddit/Discord) | Memory Book screenshot is its own artifact. → §7 |
| Leo & Parent | Parent-to-parent "safe & kind" referral | Safety posture IS the referral. → R1 |

### 6.5 Headline retention targets (mirror of brief §7, used as gate KPIs)

- **D1 ~45% (40–48) · D7 ~20–22% (18–25) · D30 ~10–12% (8–14).** Bimodal — hinges on (a) AI-memory authenticity and (b) the forgiving-absence model.
- **Mandatory leading-churn instrumentation:** "noticed AI repetition" and "felt guilt-tripped about the pet." These predict D7/D30 collapse before raw numbers move. (→ D-043)

---

## 7. Discovery / Virality Decisions

> Principle (mirror of brief §8): **all sharing is player-initiated off genuinely felt moments → Keepsake Cards. NO forced popups, NO guilt, NO transactional referral.** Virality emerges from emotion + authenticity, not gimmicks.

**Locked shareable-moment shortlist (each → a distinct Keepsake Card template):**

1. **Unprompted Comfort** — pet notices low mood, offers care unasked → "an AI pet comforted me." (Maya) → D-044
2. **Long Memory Callback** — surfaces a weeks-old personal fact → "it remembered." (Tom — highest WOM) → D-017
3. **Before/After Growth** — auto split-card, scared rescue vs. thriving Grown, elapsed days. (David) → D-035
4. **Rescue/Gotcha-Day Milestones** — "forever home" ceremony card at peak pride. → D-010
5. **Real-Impact Celebration** — verified named-shelter impact badge "I helped real animals." (Priya, David) → D-022
6. **Widget Candids** — endearing widget moment screenshotted directly; the widget IS the ambient ad. → D-025
7. **Naming/Personality Reveal** — "only MY pet would say this," singular per player. → D-018

**Build-native decisions:**
- 1-tap native share sheet; tasteful watermark + pet name + actual line; light CTA "Adopt your own."
- Distinct shareable artifact per persona (no one-size card).
- **K-factor levers:** authenticity-driven moments (not referral bribes); the widget as passive ambient billboard; Memory Book screenshots; before/after format native to TikTok/Reels.
- **ASO angles:** "AI pet that remembers you," "raise a rescued puppy/kitten," "your purchases help real shelters." Keep claims honest (NET-revenue donation language, §9).

**Anti-pattern bans (logged as decisions, see D-045):** no forced share popups; no guilt-framed re-engagement; no referral rewards that pressure; no tying the pet's wellbeing to sharing.

---

## 8. Asset-Budget Decisions

> Mirror of brief §4. **Style: Live2D Cubism, 1 rig per species. NO custom 3D (hard constraint).** Fallback: Spine 2D-skeletal.

**Locked asset budget:**

| Decision | Value | D-entry |
|---|---|---|
| Hero spend | 2 commissioned Live2D rigs @ **$1,200–$2,000 each**; lock design with AI concept (Midjourney) **before** paying for rig; **+15–20% contingency** for revision rounds. | D-046, ADR-002 |
| Total unique authored assets (MVP) | **~140** = 2 rigs + 6 life-stage skins + 12 emotion motions (0 new art) + 4 environments + 25 props + 30 cosmetics + ~52 UI/icons/widgets + 12 FX + ~48 audio + 5 music. **Truly newly-drawn ≈ 65**; the rest derived via rig params + palette-swaps. | D-046 |
| Total art/audio budget | **$3,500–$7,550; plan at ~$5,500** (excludes engine/LLM/infra/store fees/founder time). | D-046 |

**Discipline rules (locked, enforced on every art request):**
- Cap **2 species**; reaffirmed as the **#1 cut lever at G2** if rig pipeline runs hot (budget for 2, ship 1).
- **3 life-stages via scale/param, NOT new rigs.**
- Emotions = param blends (free).
- Day/night/weather = **shader tints on the same 4 BGs**, not new environments.
- Cosmetics = overlay sprites + palette-swap.
- **Reallocate from music/SFX before EVER cutting rig quality** (the rig is the emotional vessel).

**Asset-budget verdicts touching FPD:** Growth/Life-Stages (#5) and More Species (#28) are the two biggest cost levers; the brief's discipline rules are precisely what keep #5 in MVP and push #28 to Deferred.

---

## 9. Monetization & Donation-Ethics Decisions

> Mirror of brief §5 + §9. Deep detail in `GAMEPLAY_AND_PROGRESSION_BIBLE.md` (economy + player-facing donation loop) and `GAME_TECHNICAL_SYSTEMS.md` (donation ledger/anti-fraud backend). This log records the *decisions and the ethical wall*.

### 9.1 Currencies (3) — locked

- **Kibble** — soft, abundant, earned, buys delight only.
- **Heartstones** — premium, scarce, IAP + milestone-earned.
- **Compassion Coins** — impact currency; **non-tradeable, non-convertible, zero gameplay power**; maps 1:1 to real outcomes (e.g., 50 Coins = 1 real meal). Non-transferability deliberately kills laundering (anti-fraud).

### 9.2 Four revenue streams — locked (est. % gross)

| Stream | Design | Est. % gross | D-entry |
|---|---|---|---|
| Rewarded + sparse interstitial ads | Rewarded-first, opt-in, ~4–6/day cap; max 1 interstitial/session at natural breaks; never mid-emotion; kids contextual-only/none; every watch mints Coins | **45–55%** | D-034 |
| Subscription (Forever Friends) | $5.99/mo · $39.99/yr; removes interstitials, daily Kibble, monthly Heartstones+Coins, cosmetic drip, higher donation match | **30–40%** (LTV anchor) | D-033 |
| Cosmetic IAP | Horizontal cosmetics only, direct-purchase, **NO gacha/loot boxes** | **10–20%** | D-032 |
| Donation-linked Rescue Bundles | Stated split (e.g., 70% donation / 30% cosmetic+fee), disclosed pre-purchase + receipt | **5–10%** (outsized trust/virality) | D-021 |

### 9.3 Economy guardrails — locked

- **Care Meters** never below "sad but safe" floor; pet can **never die/suffer irreversibly**; deficits only dampen Bond *gain*, never reverse it.
- **LTV assumptions (conservative):** blended LTV/install **$0.30–$0.80** (upside $1.00–1.50+); sub-cohort LTV $30–80+; sub conversion target **1–3% MAU**; IAP-payer 1–2%, ARPPU $8–20; **ARPDAU $0.03–0.06**.
- **CAC near-zero at launch** — growth must be organic/viral; paid UA only after sub LTV > CAC proven.
- **KEY SENSITIVITY (Risk R2):** **LLM cost/DAU must stay < 35% of ARPDAU** — enforced by caching, hybrid pre-gen, small models, token caps, subscriber-funded live chat. Gated at G4.

### 9.4 Donation trust model — locked (mirror of brief §9)

- **Model:** "Transparent Pooled Allocation with 1:1 Impact Mapping." % of **NET** revenue → segregated auditable **Impact Pool** ledger → disbursed monthly/quarterly via an **established giving intermediary** (PayPal Giving Fund / Percent / Benevity) to **1–3 vetted partners** (registered nonprofit, Charity Navigator/GuideStar rating, audited financials).
- **NO donation-IAP, NO player tax-deductible donations in MVP.** Compassion Coins represent pooled intent, not personal deductible gifts. Rescue Bundles are *commercial* purchases with a disclosed donation slice.
- **Trust pillars:** version-stamped Impact Pledge doc (SSOT) · segregated ledger + neutral intermediary · Rescue Wall (lifetime/personal real $, live campaign bars, dated downloadable receipts, partner acknowledgments) · outcome claims **always rounded DOWN** · explicit donated-vs-cosmetic+fee split on every bundle · quarterly co-signed Impact Report · third-party verification badge past volume threshold.
- **HARD ETHICAL WALL (non-negotiable, D-047):** never tie the virtual pet's wellbeing/survival to real donations; never guilt-frame. Free players still generate real impact via ad-funded daily "kind act" Coins.

### 9.5 Anti-fraud (MVP) — locked

Server-side mint-gating (S2S signed ad postbacks; Apple/Google receipt validation); device attestation (App Attest / Play Integrity); per-user/device daily caps; reconcile against network-**PAID** impressions only; clawback Coins + revoke badges on refund/chargeback (disburse only after settlement window); Compassion Coins non-transferable/non-convertible. **Bespoke anomaly ML = Deferred (#13b).** → D-023, D-024.

---

## 10. Architecture Decision Records (ADRs)

> ADR format extends §2 with: Architectural scope · Alternatives rejected (reason) · Reversibility cost · Validation gate. These are the load-bearing technical commitments. Deep detail → `GAME_TECHNICAL_SYSTEMS.md`.

### ADR-001 — Engine: Flutter + Live2D SDK (decided at G0; Unity 2D rejected)
- **Status:** LOCKED (2026-06-22 at G0; was PROPOSED) → **Flutter + Live2D SDK**, with Rive pre-authorized as the de-risked fallback (D-048). · **Scope:** client engine.
- **Decision:** Flutter client + Live2D Cubism via a community/custom runtime bridge; founder pre-authorized switching the rig commission to Rive (Flutter-native) if the Live2D-on-Flutter integration spike runs hot at the start of P1 (`PetRenderer` seam makes this a backend swap). Original framing: defer to G0, bias to whichever lets founder+AI ship fastest with Live2D runtime + native widget interop.
- **Alternatives rejected:** Custom 3D engine (violates no-custom-3D constraint); pure web (no native widgets/billing).
- **Reversibility cost:** HIGH (rewrite). · **Validation gate:** G0. · **Cross-link:** brief §6, §12.1, D-002.

### ADR-002 — Art style: Live2D Cubism, 1 rig/species, life-stages via param/scale
- **Status:** LOCKED · **Scope:** art pipeline.
- **Decision:** Live2D Cubism, 1 rig per species; 3 life-stages and all emotions via rig params/scale; **no new rigs per stage**. Fallback Spine 2D-skeletal.
- **Alternatives rejected:** Custom 3D animation pipeline (hard constraint); pre-rendered frame sheets per stage (asset explosion, Risk R7).
- **Reversibility cost:** MED. · **Validation gate:** rig cost on-budget at **G2 (else cut 2nd species)**. · **Cross-link:** §8, `GAME_CONTENT_FACTORY.md`, D-046.

### ADR-003 — Backend: managed BaaS — Firebase (decided at G0), no owned servers
- **Status:** LOCKED (2026-06-22 at G0; was ACCEPTED) → **Firebase** (D-049). · **Scope:** backend/persistence.
- **Decision:** Firebase for auth, Firestore DB, cloud save, remote config, analytics. No owned servers. (Supabase was the rejected BaaS alternative.)
- **Alternatives rejected:** Self-hosted backend (ops burden breaks solo+AI maintainability).
- **Reversibility cost:** MED. · **Validation gate:** G1. · **Cross-link:** brief §6, ADR-005, ADR-009.

### ADR-004 — LLM strategy: HYBRID (pre-gen bank + structured memory; live chat gated/deferred)
- **Status:** LOCKED · **Scope:** dialogue/AI.
- **Decision:** Offline LLM pre-generates a large human-reviewed dialogue bank; runtime selects by pet-state and injects structured memory facts into a **prompt-cached** persona. Live free-form LLM (small/cheap model) is **DEFERRED + gated**: adult-verified + subscriber + token caps (~60–100 out) + daily-turn caps + per-user cost ceiling. Thin backend proxy for key security + rate-limit + moderation.
- **Alternatives rejected:** Ship live free-form LLM at MVP (Risk R1 child-safety + Risk R2 unbounded OPEX); fully scripted no-LLM (loses "it remembers" magic — but note the magic comes from memory store + callbacks, not generation).
- **Reversibility cost:** MED. · **Validation gate:** 0-spinner first line at G2; cost/DAU < 35% ARPDAU at G4. · **Cross-link:** §4.2, §6.1, D-015, D-016, R2.

### ADR-005 — Sim authority: client-side deterministic + server-validatable; memory/ledger/entitlements server-side
- **Status:** ACCEPTED · **Scope:** simulation/state.
- **Decision:** Care-meter sim runs client-side (deterministic, elapsed-time, server-validatable). Memory, entitlements, and donation ledger are server-side authoritative. Voice mimic (deferred) = on-device DSP only; audio never leaves device.
- **Alternatives rejected:** Fully server-authoritative sim (cost + latency); fully client-trusted economy (fraud).
- **Reversibility cost:** MED. · **Validation gate:** deterministic + offline-catch-up tested at G1. · **Cross-link:** §6.2, brief §6.

### ADR-006 — AI memory: structured key-value fact store (10–30 facts) + rolling window + batch extraction
- **Status:** LOCKED · **Scope:** memory.
- **Decision:** 10–30 durable facts in BaaS DB + short rolling turn window + batched off-peak fact extraction; surfaced as the Memory Book. **Reliability > breadth.**
- **Alternatives rejected:** Vector-RAG over full chat history (cost + hallucination risk — broad+flaky violates Risk R3 mandate).
- **Reversibility cost:** LOW. · **Validation gate:** ≥95% callback reliability, no hallucinated facts, at **G2**. · **Cross-link:** §4.1 (#7), §6.3, R3, D-017.

### ADR-007 — Payments: RevenueCat single abstraction over StoreKit + Play Billing
- **Status:** ACCEPTED · **Scope:** billing.
- **Decision:** RevenueCat for receipt validation, entitlements, restore — one abstraction over two billing stacks.
- **Alternatives rejected:** Hand-rolled dual billing (maintainability fail for solo+AI, Risk R9).
- **Reversibility cost:** MED. · **Validation gate:** IAP/sub working at G3. · **Cross-link:** §9, brief §6.

### ADR-008 — Companion Presence: single shared status payload feeds widget + notifications; pre-rendered mood images
- **Status:** ACCEPTED · **Scope:** widgets/notifications.
- **Decision:** Native iOS WidgetKit + Android Glance/AppWidget. ONE shared "pet status snapshot" payload drives both widget and notification scheduler. Pre-rendered mood images, not live rig render. Notifications local-scheduled (no push cost) in MVP, 1–2/day cap. Lock-screen/Live Activities deferred (#15).
- **Alternatives rejected:** Live rig render in widget (battery/perf); separate payloads per surface (maintenance, Risk R9).
- **Reversibility cost:** LOW–MED. · **Validation gate:** widget on-device at G2. · **Cross-link:** §4.1 (#14, #16), D-025, D-027.

### ADR-009 — Live-ops: remote-config / data-driven event infra built in MVP, content deferred
- **Status:** ACCEPTED · **Scope:** content delivery.
- **Decision:** Build remote-config-driven event scaffolding in MVP so deferred Live-Ops (#27), seasonal Care Pass, and 2nd-species drops require no client update. Commit to an **honestly low launch cadence (1 small moment / 6–8 weeks)**.
- **Alternatives rejected:** Client-update-per-event (treadmill breaks solo+AI, Risk R8).
- **Reversibility cost:** MED. · **Validation gate:** remote-config live at G3. · **Cross-link:** §4.4, R8, D-038.

### ADR-010 — Save/sync: authoritative versioned cloud save, local-first, single-device LWW; no update orphans a pet
- **Status:** LOCKED · **Scope:** persistence/trust.
- **Decision:** Authoritative cloud save keyed to Apple/Google sign-in (+ guest); local-first, single-device last-write-wins for MVP; **defer true multi-device live sync.** Version every schema + automated migration + restore flow.
- **Alternatives rejected:** No cloud save (Risk R4 catastrophic); full multi-device CRDT sync (over-scope for MVP).
- **Reversibility cost:** HIGH (data). · **Validation gate:** cloud-restore proven at G3. · **Cross-link:** §4.3 (#25), R4, D-036.

### ADR-011 — Moderation: two-sided input+output, hard system-prompt constraints, audit logging; under-13 templated-only
- **Status:** LOCKED · **Scope:** safety.
- **Decision:** Input + output through a cheap moderation/classification endpoint; hard system-prompt constraints; fixed safe-fallback line; self-harm → static safe message; full audit logging. **Under-13: templated/non-generative only.** Build to child-safe standard for ALL users.
- **Alternatives rejected:** Output-only moderation (insufficient); no moderation (existential Risk R1).
- **Reversibility cost:** LOW. · **Validation gate:** legal sign-off at **G3**; 0 child-safety incidents through G4. · **Cross-link:** §4.3 (#9), R1, R10, D-019.

---

## 11. Numbered Decision Entries (D-001…)

> Foundational decisions (D-001…D-009), then one entry per Master-Table feature (D-010…D-042), then cross-cutting decisions (D-043…D-047). All dated 2026-06-22 unless reopened.

### D-001 — Ratify the Canonical Decision Brief as single source of truth
- **Status:** LOCKED · **Gate/Phase:** P0 / G0 · **Basis:** Brief-mandate.
- **Decision:** Adopt KINDREDPAWS Canonical Decision Brief v1.0 as SSOT; all docs cross-link, none redefine.
- **Consequences:** This log + 5 sibling docs + `current_state.json` derive from it. **Reversal trigger:** brief versioned to v1.1+. **Cross-link:** all docs.

### D-002 — Create current_state.json as machine-readable mirror (first P0 action)
- **Status:** ACCEPTED · **Gate/Phase:** P0 · **Basis:** Brief-mandate (CONSOLIDATION RULES).
- **Decision:** First action of Phase 0 is to create `/home/emre/Downloads/my-talking-tom/game-os/current_state.json` mirroring the brief + this log's open/closed decisions. Updated on every major decision. **Reversal trigger:** none (permanent). **Cross-link:** D-001.

### D-003 — Lock canonical terminology
- **Status:** LOCKED · **Basis:** Brief §1.
- **Decision:** All docs use exact strings: **KindredPaws · Forever Friends · Care Pass · Kibble · Heartstones · Compassion Coins · The Bond (Stranger→Friend→Companion→Kindred→Soulmate) · Pup/Kit→Young One→Grown · Heartmind · The Memory Book · Care Meters · Companion Presence · Care Streak (+ Streak Warmth) · The Impact Pledge · Rescue Wall · Rescue Day · Gotcha Day · Keepsake Cards · The Nest.** Example pets: **Mochi** (kitten), **Biscuit** (puppy). **Reversal trigger:** brief §1 change.

### D-004 — Lock phase & gate skeleton (~16 months baseline)
- **Status:** LOCKED · **Basis:** Brief §3.
- **Decision:** P0 (6w) → P1 (8w) → P2 (10w) → P3 (12w) → P4 (8w) → P5 (4w) → P6 (ongoing), with gates G0–G6 as specified. **Reversal trigger:** timeline slip forcing re-scope.

### D-005 — Lock headline retention targets as gate KPIs
- **Status:** LOCKED · **Basis:** Brief §7, §10 · Playtester.
- **Decision:** D1 ~45% (40–48) · D7 ~20–22% (18–25) · D30 ~10–12% (8–14). G3: D1≥40%/D7≥18%. G4: D1≥42%/D7≥20%/D30≥10%. **Reversal trigger:** soft-launch data forcing re-baseline. **Cross-link:** §6.5.

### D-006 — Lock LLM cost sensitivity: cost/DAU < 35% of ARPDAU (gate G4)
- **Status:** LOCKED · **Basis:** FPD/Econ · Risk R2.
- **Decision:** LLM cost/DAU must stay below 35% of ARPDAU; enforced via hybrid pre-gen, caching, small models, token caps, subscriber-funded live chat. Hard G4 gate. **Reversal trigger:** model the economics show infeasibility at G3. **Cross-link:** ADR-004, §9.3.

### D-007 — Build to child-safe standard for ALL users
- **Status:** LOCKED · **Basis:** Legal · Risk R1.
- **Decision:** Treat all users as if child-directed for safety; hybrid templated-under-13; no behavioral ad targeting; mandatory budgeted pre-launch legal review at G3. **Reversal trigger:** legal determination of non-child-directedness (Open Decision §12.9). **Cross-link:** ADR-011, D-019.

### D-008 — No-death decay floor ("sad but safe")
- **Status:** LOCKED · **Basis:** Design/Brief §5 · Risk R4/R6.
- **Decision:** Care Meters never fall below a "sad but safe" floor; pet can never die or suffer irreversibly; deficits dampen Bond *gain* only, never reverse it. **Reversal trigger:** none (core brand). **Cross-link:** §9.3, D-011.

### D-009 — 2 species in MVP; #1 cut lever at G2
- **Status:** ACCEPTED (conditional) · **Basis:** FPD vs Founder-fit reconciliation (brief conflict #3).
- **Decision:** Budget for 2 species (1 puppy + 1 kitten); ship 2 if rig pipeline on-budget; **cut to 1 at G2 if rig pipeline runs hot.** **Reversal trigger:** rig cost overrun at G2. **Cross-link:** ADR-002, §8, D-039, brief §12.2.

---

#### Feature decisions (D-010 … D-042) — one per Master-Table row

> Each carries its FPD verdict and the cheapest emotionally-intact form. Full FPD rationale in §4; full founder-fit in §5.

### D-010 — Rescue Day = MVP (FPD 3.33)
- **Status:** LOCKED · **Decision:** Ship the 60–90s adoption cold-open as the D1 emotional anchor; linear, no branching, reuses rig + emotion params. **Cross-link:** §7(#4), D-035.

### D-011 — Care Meters = MVP (FPD 2.67)
- **Status:** LOCKED · **Decision:** 4 needs, 0–100 floats, gentle decay, no-death floor → 4 mood states. **Cross-link:** D-008.

### D-012 — Core care (feed/clean/play) = MVP (FPD 2.67)
- **Status:** LOCKED · **Decision:** Exactly 3 interactions; tap + prop + emotion-blend reaction; no new rigs.

### D-013 — The Bond = MVP (FPD 4.50, highest)
- **Status:** LOCKED · **Decision:** Single monotonic-up score, 5 named stages; build first. **Cross-link:** D-003.

### D-014 — Growth / Life-Stages = MVP (FPD 1.80)
- **Status:** LOCKED · **Decision:** 3 stages × 2 species via param/scale, not new rigs; #1 art-cost lever. **Cross-link:** ADR-002, D-009.

### D-015 — Heartmind dialogue (HYBRID) = MVP\* (FPD 1.29)
- **Status:** LOCKED · **Decision:** Pre-gen reviewed bank + structured memory injection into cached persona prompt; 0-spinner first line. NOT live free-form. **Cross-link:** ADR-004, D-016.

### D-016 — Heartmind LIVE free-form chat = Deferred (FPD 1.29)
- **Status:** DEFERRED · **Decision:** Gate behind age-verify + subscriber + token/turn caps + moderation; pilot in P4, decide expand/hold at G4. **Cross-link:** ADR-004, §12.10.

### D-017 — AI Memory (Memory Book) = MVP (FPD 1.67, load-bearing)
- **Status:** LOCKED · **Decision:** 10–30 durable facts, narrow+reliable; player-visible Memory Book; ≥95% callback reliability gated at G2. **Cross-link:** ADR-006, R3, §6.3.

### D-018 — Evolving Personality = MVP (FPD 1.75)
- **Status:** LOCKED · **Decision:** 3–4 prompt-parameterized dials tuned by Bond + history; anti-repetition rotation. **Cross-link:** §6.2, D-043.

### D-019 — Child-Safety Moderation = MVP (forced, FPD 0.80)
- **Status:** LOCKED · **Decision:** Two-sided moderation, under-13 templated-only, audit logging; legal gate at G3. **Cross-link:** ADR-011, D-007, R1.

### D-020 — Voice Mimic = Deferred (FPD 0.88)
- **Status:** DEFERRED · **Decision:** On-device DSP pitch-shift only, audio never leaves device; post-launch. **Cross-link:** Brief Differentiator 2, R1.

### D-021 — Donation/Impact Engine = MVP\* (FPD 1.33)
- **Status:** LOCKED · **Decision:** % of NET revenue pledge to ONE vetted intermediary; NO donation-IAP. **Cross-link:** §9.4, D-047, `GAMEPLAY_AND_PROGRESSION_BIBLE.md`, `GAME_TECHNICAL_SYSTEMS.md`.

### D-022 — Rescue Wall = MVP (FPD 2.33)
- **Status:** LOCKED · **Decision:** Data-driven impact dashboard; lifetime/personal $, live bars, dated receipts, partner acknowledgments; round down. **Cross-link:** §9.4, §7(#5).

### D-023 — Anti-fraud (platform-native) = MVP (forced)
- **Status:** LOCKED · **Decision:** S2S postbacks + receipt validation + attestation gate Coin minting; mint only on PAID impressions. **Cross-link:** §9.5, D-024.

### D-024 — Anti-fraud (bespoke ML) = Deferred (FPD 0.60)
- **Status:** DEFERRED · **Decision:** Add anomaly/ML only when volume/social justify. **Cross-link:** D-023.

### D-025 — Home-Screen Widget = MVP (FPD 1.60)
- **Status:** LOCKED · **Decision:** WidgetKit + Glance; single shared status payload; pre-rendered mood images. **Cross-link:** ADR-008, D-026.

### D-026 — Lock-Screen Widget / Live Activities = Deferred (FPD 1.00)
- **Status:** DEFERRED · **Decision:** Fast-follow after home-widget pipeline proven. **Cross-link:** ADR-008.

### D-027 — Notifications (pet-voiced) = MVP (FPD 3.50)
- **Status:** LOCKED · **Decision:** Local-scheduled, templated warm lines, 1–2/day cap, never guilt, never mid-emotion. **Cross-link:** ADR-008, R6.

### D-028 — Care Streak + Streak Warmth = MVP (FPD 3.50)
- **Status:** LOCKED · **Decision:** Forgiving streak with freeze/repair; "pet missed you but is okay"; never punitive. **Cross-link:** §6.2, R6.

### D-029 — Ambient Interactions = MVP (FPD 1.75)
- **Status:** LOCKED · **Decision:** Idle-life sequencing of existing emotion motions with anti-repetition.

### D-030 — The Nest = MVP\* (FPD 1.20)
- **Status:** LOCKED · **Decision:** 1 room + modular palette-swap kit; cosmetic surface only. **Cross-link:** §8.

### D-031 — Training / Tricks = Deferred (FPD 1.00)
- **Status:** DEFERRED · **Decision:** Animation-expensive, non-differentiating; live-ops drop.

### D-032 — Cosmetics Shop = MVP (FPD 1.50)
- **Status:** LOCKED · **Decision:** ~30 overlay-sprite/palette-swap pieces at launch; horizontal only; NO gacha. **Cross-link:** §9.2.

### D-033 — Subscription (Forever Friends) = MVP\* (FPD 1.25)
- **Status:** LOCKED · **Decision:** Single tier $5.99/mo · $39.99/yr; the LLM-OPEX funding keystone. **Cross-link:** §9.2, ADR-007, §12.8.

### D-034 — Ads (rewarded + sparse interstitial) = MVP (FPD 1.33)
- **Status:** LOCKED · **Decision:** Rewarded-first, ~4–6/day cap, ≤1 interstitial/session, never mid-emotion; kids contextual/none; each watch mints Coins. **Cross-link:** §9.2.

### D-035 — Keepsake Cards = MVP (FPD 2.67)
- **Status:** LOCKED · **Decision:** Templated composition + 1-tap native share; tasteful watermark; distinct artifact per persona. **Cross-link:** §7.

### D-036 — Cloud Save / Account = MVP (forced, FPD 0.60)
- **Status:** LOCKED · **Decision:** Authoritative versioned cloud save, local-first, single-device LWW; no update orphans a pet. **Cross-link:** ADR-010, R4.

### D-037 — Localization (static UI) = MVP\* (FPD 1.25)
- **Status:** LOCKED · **Decision:** AI-translate static UI/copy; dialogue stays EN(+1–2) until per-language safety validation. **Cross-link:** §12.6.

### D-038 — Live-Ops Events = Deferred (FPD 1.17), architect remote-config now
- **Status:** DEFERRED · **Decision:** Build remote-config infra in MVP; defer content; honest low cadence (1 / 6–8 wks). **Cross-link:** ADR-009, R8.

### D-039 — More Species / Breeds (beyond 2) = Deferred (FPD 0.75)
- **Status:** DEFERRED · **Decision:** Breed palette-swaps first, new rig later. **Cross-link:** D-009, §8.

### D-040 — Health / Illness / Vet = Removed (FPD 0.80)
- **Status:** REMOVED · **Decision:** Cut entirely; contradicts cozy/safe core; fold "comfort when sad" into mood. **Cross-link:** D-008.

### D-041 — Multiplayer / Social Visiting = North-Star (FPD 0.67)
- **Status:** NORTH-STAR · **Decision:** Excluded by hard constraint (no multiplayer in MVP); MVP proxy = community impact counter only.

### D-042 — UGC / Custom Pet Creation = North-Star (FPD 0.56)
- **Status:** NORTH-STAR · **Decision:** Excluded by hard constraint (no UGC in MVP); curated cosmetics meet the expression need.

---

#### Cross-cutting decisions (D-043 … D-047)

### D-043 — Instrument mandatory leading-churn metrics
- **Status:** LOCKED · **Basis:** Playtester · Brief §10.
- **Decision:** Instrument "noticed AI repetition" and "felt guilt-tripped about the pet" as mandatory leading-churn signals; they predict D7/D30 collapse before raw numbers move. ~15 analytics events total mapped to gates. **Cross-link:** §6.2, brief §10.

### D-044 — Unprompted Comfort as the D1 signature viral moment
- **Status:** LOCKED · **Basis:** Discovery/Playtester (Maya).
- **Decision:** Pet detects low player mood and offers care unasked → "an AI pet comforted me" Keepsake Card. **Cross-link:** §7(#1).

### D-045 — Ban dark-pattern virality
- **Status:** LOCKED · **Basis:** Discovery/Brief §8.
- **Decision:** No forced share popups, no guilt-framed re-engagement, no pressuring referral rewards, never tie pet wellbeing to sharing. **Cross-link:** §7, D-047.

### D-046 — Lock asset budget at ~$5,500 (range $3,500–$7,550), ~140 assets
- **Status:** LOCKED · **Basis:** Asset-Budget · Brief §4.
- **Decision:** As §8; lock rig design with AI concept before paying; +15–20% rig-revision contingency; reallocate from music/SFX before cutting rig quality. **Cross-link:** ADR-002, §8.

### D-047 — Hard ethical wall on donations
- **Status:** LOCKED · **Basis:** Donation-Ethics · Risk R5.
- **Decision:** Never tie the virtual pet's wellbeing/survival to real donations; never guilt-frame; free players still generate impact via ad-funded daily "kind act" Coins. **Cross-link:** §9.4, D-045.

---

#### Phase-0 / G0 decisions (D-048 … D-052) — added 2026-06-22 on founder approval to execute Phase 0

### D-048 — Engine = Flutter + Live2D SDK (resolves OD-1)
- **Status:** LOCKED · **Gate/Phase:** P0 / G0 · **Basis:** Founder-decision + Founder-Fit.
- **Decision:** Flutter (stable) + Live2D Cubism. **Rive** is the authorized fallback if the Live2D-on-Flutter integration spike (start of P1) runs hot; the `PetRenderer` abstraction makes the rig backend a swap with no gameplay changes.
- **Consequences:** ADR-001 PROPOSED → **LOCKED**; OD-1 RESOLVED. `PetRenderer` seam + `PlaceholderPetRenderer` shipped in P0.
- **Cross-link:** ADR-001, `docs/LIVE2D_RIG_DESIGN_BRIEF.md` (§Integration spike), brief §6/§12.1.

### D-049 — Backend = Firebase (resolves the Firebase-or-Supabase choice)
- **Status:** LOCKED · **P0 / G0** · **Basis:** Founder-decision.
- **Decision:** Firebase as the canonical BaaS — auth, Firestore cloud save, Remote Config, Analytics, Crashlytics. No owned servers.
- **Consequences:** ADR-003 ACCEPTED → **LOCKED**. Firebase adapter seam shipped (inert until `flutterfire configure` + creds — `REQUIRED_ENVIRONMENTS.md` §1).
- **Cross-link:** ADR-003, brief §6, `REQUIRED_ENVIRONMENTS.md`.

### D-050 — LLM models: runtime/live = claude-haiku-4-5, pre-gen = claude-opus-4-8 (partially resolves OD-3)
- **Status:** LOCKED (models); final caps validated at G3/G4 · **P0 / G0** · **Basis:** Founder-decision + Econ.
- **Decision:** Anthropic Claude. Founder default runtime "Claude Haiku 4" → `claude-haiku-4-5` (cost-sensitive live path); offline pre-gen → `claude-opus-4-8` (quality, paid once).
- **Cross-link:** ADR-004, D-006, `docs/LLM_UNIT_ECONOMICS_MODEL.md`, OD-3.

### D-051 — LLM unit-economics model v1 PASSES the G0 cost gate
- **Status:** LOCKED · **P0 / G0** · **Basis:** Econ / Risk R2.
- **Decision:** Modeled LLM cost/DAU = **2.7%** (MVP hybrid, $0 runtime tokens) and **3.9%** (soft-launch capped live pilot) of ARPDAU — both far under the 35% gate; an uncapped control scenario fails at 296%, proving the guard. Satisfies **G0 pass criterion #3**.
- **Cross-link:** D-006, ADR-004, `lib/tooling/llm_cost_model.dart`, `test/unit/llm_cost_model_test.dart`.

### D-052 — P0 tech stack provisioned + versioned-save layer scaffolded
- **Status:** ACCEPTED · **P0 / G0** · **Basis:** Brief-mandate / Risk R4, R8.
- **Decision:** Flutter architecture skeleton (config/feature-flags/DI), service abstractions + offline mocks (Auth/Backend/RemoteConfig/Analytics/Heartmind) + gated Firebase seam; versioned-save migration/restore framework (R4); Heartmind memory/dialogue schemas + safety constants; analytics ~15-event taxonomy; remote-config defaults (R8 / ADR-009); PetRenderer abstraction. Validated: `flutter analyze` clean, 31 tests @ 76.4% coverage, APK build + emulator E2E green.
- **Consequences:** G0 status **engineering-complete**; the two remaining G0 criteria (secure rig contractor, book legal review) are founder/credentialed actions, fully enabled by delivered docs. **Phase 1 (core-loop) NOT started.**
- **Cross-link:** `REQUIRED_ENVIRONMENTS.md`, ADR-009, ADR-010, ADR-011.

> **ADR status updates (2026-06-22):** ADR-001 PROPOSED → **LOCKED** (Flutter+Live2D, D-048); ADR-003 ACCEPTED → **LOCKED** (Firebase, D-049).

---

## 12. Open Decisions / To-Be-Resolved

> Mirror of brief §12. Each must be resolved by the noted gate and converted to a LOCKED D-entry + `current_state.json` update.

- [x] **OD-1 — Engine: Unity vs Flutter+Live2D.** **RESOLVED 2026-06-22 → Flutter + Live2D SDK** (Rive fallback authorized). → D-048, ADR-001.
- [ ] **OD-2 — 2nd species ship-or-cut.** Resolve at **G2** on rig-pipeline cost burn (budget 2, ship 1 if hot). → D-009.
- [~] **OD-3 — LLM provider + model tiers + final token/turn caps.** **MODEL RESOLVED 2026-06-22 → `claude-haiku-4-5` (runtime/live) / `claude-opus-4-8` (pre-gen)**; final token/turn caps validated at **G3/G4**. → D-050, ADR-004, D-006.
- [ ] **OD-4 — Donation intermediary (PayPal Giving Fund / Percent / Benevity) + initial 1–3 partner shelters.** Resolve before **G4** (must be live for soft launch). → D-021.
- [ ] **OD-5 — Exact donation % per revenue type (NET).** Finalize with accounting/legal before **G4**; lock in Impact Pledge doc. → §9.4.
- [ ] **OD-6 — Launch localization languages (4–6 for static UI).** Decide by **G3**; dialogue languages EN(+1–2), expand post-launch per-language safety validation. → D-037.
- [ ] **OD-7 — Soft-launch geos (e.g., CA/PH/NZ candidate).** Decide by **G3**. → brief §3 P4.
- [ ] **OD-8 — Subscription final price point ($5.99 assumed) + Care Pass pricing.** Validate elasticity in soft launch **G4**. → D-033.
- [ ] **OD-9 — Under-13 handling: neutral age gate vs. fully child-safe-for-all.** Driven by legal child-directedness determination; resolve at **G3** legal review. → D-007, ADR-011.
- [ ] **OD-10 — Live free-form chat go/no-go for adults.** Pilot in **P4**, decide expand/hold at **G4** on cost + safety data. → D-016.

---

## 13. Reversal & Change Log

> Every change to a LOCKED decision, every classification move, every gate-criteria edit, and every brief-version bump is recorded here. Append-only. Format: `[date] CHG-NNN — <what changed> — <from → to> — <reason / who> — <affected D/ADR>`.

| Change ID | Date | What changed | From → To | Reason | Affected |
|---|---|---|---|---|---|
| CHG-001 | 2026-06-22 | Initial decision log authored from brief v1.0 | — → v1.0 baseline | P0 seed | All D-001…D-047, ADR-001…011 |
| CHG-002 | 2026-06-22 | Phase 0 launched on founder approval; locked engine/backend/LLM; G0 engineering deliverables complete | OD-1 open→resolved; OD-3 model open→resolved; ADR-001 PROPOSED→LOCKED; ADR-003 ACCEPTED→LOCKED | Founder decision + P0 execution | D-048…D-052, ADR-001, ADR-003, OD-1, OD-3 |

**Reconciled conflicts already resolved in brief v1.0 (recorded for audit, no further action):**
- **RC-1** AI dialogue: live LLM vs hybrid → **Hybrid-first canonical for MVP**; live LLM gated/deferred. (→ D-015, D-016, ADR-004)
- **RC-2** Anti-fraud: Defer vs Simplify → **Platform-native = MVP (forced)**; bespoke ML deferred. (→ D-023, D-024)
- **RC-3** Species count: 2 vs 1 → **2 in MVP, #1 cut lever at G2.** (→ D-009)
- **RC-4** Donation: fixed-% / no-IAP / Bundles+Coins → **% NET pledge via intermediary; Coins = representation, not deductible IAP; Rescue Bundles = commercial.** (→ D-021, D-047)

**Pending reversal triggers being watched (from D-entries / ADRs):**
- Rig cost overrun at G2 → fires **D-009 / OD-2** (cut 2nd species).
- LLM cost/DAU ≥ 35% ARPDAU at G3/G4 → fires **D-006** re-scope of Heartmind.
- AI-memory callback reliability < 95% at G2 → fires **D-017 / R3** narrowing.
- Legal child-directedness determination → fires **D-007 / OD-9** (age-gate model).
- Brief versioned to v1.1+ → fires **D-001** (re-ratify, cascade all docs).

---

*End of GAME_DECISION_LOG.md — canonical for decisions & rationale. For project framing, terminology, phases, KPIs, economy, and tech stack, defer to the Canonical Decision Brief; for live state, `current_state.json`.*
