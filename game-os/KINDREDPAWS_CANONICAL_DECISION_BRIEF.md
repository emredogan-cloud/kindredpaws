# KINDREDPAWS — CANONICAL DECISION BRIEF
**Status:** v1.0 LOCKED · **Date:** 2026-06-22 · **Author:** Lead Game Director · **Audience:** 6 downstream document authors (NOT end users)
**Authority:** This is the SINGLE SOURCE OF TRUTH. Where a specialist analysis conflicts with this brief, this brief wins. All other docs cross-link here; they do not redefine. `current_state.json` (to be created at Phase 0) is the machine-readable mirror of this brief.

> **Filename note:** This file is canonically named `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md` and lives at `/home/emre/Downloads/my-talking-tom/game-os/`. It is the SSOT root of the authority chain: **this brief → `current_state.json` → the six downstream docs**. Every downstream doc cross-links this exact filename. The six downstream docs are: `GAMEPLAY_AND_PROGRESSION_BIBLE.md`, `GAME_TECHNICAL_SYSTEMS.md`, `GAME_CONTENT_FACTORY.md`, `GAME_DECISION_LOG.md`, `GAME_MASTER_EXECUTION_ROADMAP.md`, `GAME_EXECUTION_MASTER_SYSTEM.md`.

**Reconciled conflicts (resolved decisions, for the record):**
1. **AI Dialogue — live LLM vs. pre-generated hybrid.** FPD analyst said "ship cheapest live LLM"; Founder-fit & Playtest said "DO NOT ship open free-form live chat to kids; ship a HYBRID (LLM-pre-generated + small structured memory)." **RESOLUTION: Hybrid-first is canonical for MVP.** Live LLM is gated, capped, age-walled, and only for verified-adult / subscriber input post-soft-launch. The "it remembers" magic comes from the structured memory store + curated callbacks, not free-form generation. This satisfies both cost and child-safety.
2. **Anti-fraud.** FPD = Deferred; Founder-fit = "Simplify for MVP (platform-native validation)." **RESOLUTION: platform-native validation (S2S postbacks, receipt validation, attestation) is MVP and non-negotiable because it gates donation-Coin minting; bespoke anomaly/ML anti-fraud is Deferred.**
3. **Second species.** FPD MVP = 2 species; Founder-fit = "1 species for MVP, defer 2nd." **RESOLUTION: 2 species (1 puppy + 1 kitten) is MVP — but it is the #1 cut lever at the Phase 2 vertical-slice gate if the rig pipeline runs hot. Budget for 2, ship 1 if forced.**
4. **Donation in-app.** FPD = "fixed % to one partner, paw-points cosmetic"; Founder-fit = "no donation IAP, % net-revenue pledge"; Econ = "Rescue Bundles + Compassion Coins." **RESOLUTION: % of NET revenue pledge to a vetted intermediary (PayPal Giving Fund / Percent / Benevity) is the legal backbone. Compassion Coins are an in-app *representation* of that pooled real allocation — NOT tax-deductible player donations through IAP. Rescue Bundles are commercial purchases (cosmetic + disclosed donation slice), not charitable donation IAP.**

---

## 1. CANONICAL TERMINOLOGY & NAMING
*(All docs MUST use these exact strings.)*

| Concept | Canonical Name | Notes |
|---|---|---|
| Game title | **KindredPaws** | One word, capital K + P. |
| Subscription tier | **Forever Friends** | ~$5.99/mo, $39.99/yr. (NOT "KindredPaws+".) |
| Seasonal pass | **Care Pass** | 4–6 wk, cosmetic/impact only. Deferred to live-ops. |
| Soft currency | **Kibble** | Abundant, earned, buys delight only. |
| Premium currency | **Heartstones** | Scarce, IAP + milestone-earned. |
| Donation/impact currency | **Compassion Coins** | Non-purchasable-for-power, non-tradeable, maps 1:1 to real outcomes. |
| The pet species (MVP) | **puppy** and **kitten** | Exactly 2. Generic; player names the individual. |
| Default example pet names (docs/marketing) | **Mochi** (kitten), **Biscuit** (puppy) | Use consistently in mocks/copy examples. |
| Affection/relationship system | **The Bond** | The single most important number. |
| Bond progression stages (5) | **Stranger → Friend → Companion → Kindred → Soulmate** | "Kindred" ties to title. |
| Life stages (3) | **Pup/Kit (infancy) → Young One (juvenile) → Grown (adult)** | Per species; via rig param/scale, not new rigs. |
| AI companion system | **Heartmind** | The dialogue + memory + personality layer (internal name). |
| Memory store (player-visible) | **The Memory Book** | Tangible journal artifact = trust signal (per Tom/Playtest mandate). |
| Needs/mood system | **Care Meters** | 4 needs (see §5). |
| Daily-life integration | **Companion Presence** | Widgets + notifications + streaks. |
| Streak | **Care Streak** | Forgiving; has **Streak Warmth** (freeze/repair), never punitive. |
| Donation system | **The Impact Pledge** (policy) + **Rescue Wall** (in-app impact UI) | "Our Impact" tab. |
| Adoption onboarding | **Rescue Day** | The cold-open. Anniversary = **Gotcha Day**. |
| Share artifacts | **Keepsake Cards** | Auto-generated, tasteful watermark. |
| Home customization | **The Nest** | The pet's room. |

---

## 2. FINAL FEATURE CLASSIFICATION — MASTER TABLE
*(FPD = Fun/Dollar. Verdict honors all hard constraints. "MVP*" = MVP only in cheapest emotionally-intact form. Forced-MVP dependencies are MVP regardless of FPD.)*

| # | Feature | FPD | Verdict | One-line rationale |
|---|---|---|---|---|
| 1 | Rescue Day (adoption cold-open) | 3.33 | **MVP** | The player fantasy in one 60–90s scene; cheapest high-fun hook; reuses rig. |
| 2 | Care Meters (4 needs / mood) | 2.67 | **MVP** | Retention engine; pure data; **no-death floor** (see §11 R4). |
| 3 | Core care (feed/clean/play) | 2.67 | **MVP** | Tactile daily verbs; tap + prop + reaction; 3 interactions only. |
| 4 | The Bond (affection progression) | 4.50 | **MVP** | Highest FPD; literal quantification of attachment; near-free. |
| 5 | Growth / Life-Stages | 1.80 | **MVP** | Payoff of "raised it"; #1 art-cost lever — capped at 3 stages × 2 species. |
| 6 | Heartmind dialogue (HYBRID) | 1.29 | **MVP*** | Hybrid LLM-pre-generated bank + structured memory, NOT live free-form. Cost-gated. |
| 6b | Heartmind LIVE free-form LLM chat | 1.29 | **Deferred** | Gated behind age-verify + subscriber + caps + moderation; post-soft-launch. |
| 7 | AI Memory (Memory Book) | 1.67 | **MVP** | Emotional payload + #1 viral moment; structured fact store is cheap. |
| 8 | Evolving Personality | 1.75 | **MVP** | Prompt-parameterized dials; ~0 marginal cost; deepens D30 bond. |
| 9 | Child-Safety Moderation | 0.80 | **MVP (forced)** | Non-negotiable legal gate for any AI; FPD irrelevant. |
| 10 | Voice Mimic Layer | 0.88 | **Deferred** | Not the emotional core; child-voice privacy minefield; on-device pitch-shift only, post-launch. |
| 11 | Donation/Impact Engine | 1.33 | **MVP*** | Differentiator 3; cheapest form = % net-rev pledge to ONE vetted intermediary. |
| 12 | Rescue Wall (impact UI) | 2.33 | **MVP** | Converts policy into felt, shareable trust; data-driven dashboard. |
| 13 | Anti-fraud (platform-native) | — | **MVP (forced)** | S2S postbacks + receipt validation + attestation gate Coin minting. |
| 13b | Anti-fraud (bespoke anomaly/ML) | 0.60 | **Deferred** | Premature at MVP scale; add when volume/social justify. |
| 14 | Home-Screen Widget | 1.60 | **MVP** | Centerpiece of Companion Presence; primary re-engage for high-LTV cohort. |
| 15 | Lock-Screen Widget / Live Activities | 1.00 | **Deferred** | Incremental over home widget; fast-follow once pipeline proven. |
| 16 | Notifications (pet-voiced) | 3.50 | **MVP** | Cheapest retention lever; warm/invitational, never guilt. Local-first. |
| 17 | Care Streak (+ Streak Warmth) | 3.50 | **MVP** | Cheap habit loop; MUST be forgiving (freeze/repair). |
| 18 | Ambient Interactions (idle life) | 1.75 | **MVP** | Makes pet feel alive; pure sequencing of existing assets. |
| 19 | The Nest (decoration) | 1.20 | **MVP*** | Cosmetic monetization surface; 1 room + modular palette-swap kit only. |
| 20 | Training / Tricks | 1.00 | **Deferred** | Animation-expensive, non-differentiating; live-ops drop. |
| 21 | Cosmetics Shop | 1.50 | **MVP** | Primary non-sub revenue; overlay sprites; ~30 pieces at launch. |
| 22 | Subscription (Forever Friends) | 1.25 | **MVP*** | Financial keystone funding LLM OPEX; single tier. |
| 23 | Ads (rewarded + sparse interstitial) | 1.33 | **MVP** | F2P floor + donation funding; rewarded-first, kids see contextual/none. |
| 24 | Keepsake Cards (sharing/virality) | 2.67 | **MVP** | K-factor engine; templated composition; 1-tap native share. |
| 25 | Cloud Save / Account | 0.60 | **MVP (forced)** | Losing the pet = catastrophic; prerequisite for memory/ledger/entitlements. |
| 26 | Localization (static UI) | 1.25 | **MVP*** | Global reach; AI-translate UI/copy; dialogue stays EN(+1–2) at first. |
| 27 | Live-Ops Events | 1.17 | **Deferred** | Inherently post-launch; MUST architect remote-config now. |
| 28 | More Species / Breeds (beyond 2) | 0.75 | **Deferred** | Costliest expansion; breed palette-swaps first, new rig later. |
| 29 | Health / Illness / Vet | 0.80 | **Removed** | Contradicts cozy/safe core; fold "comfort when sad" into mood. |
| 30 | Multiplayer / Social Visiting | 0.67 | **North-Star** | Hard-constraint excluded; community impact counter is the only MVP proxy. |
| 31 | UGC / Custom Pet Creation | 0.56 | **North-Star** | Hard-constraint excluded; lowest FPD; curated cosmetics meet expression need. |

**Hard-constraint compliance check:** ✅ No multiplayer (30=North-Star), no UGC (31=North-Star), no open world, no full-voice conversation (6b=Deferred), no custom-3D (Live2D only), voice mimic Deferred (10).

---

## 3. PHASE & GATE SKELETON (12–18 months)
*(These exact phase names, durations, and gate IDs are reused by ALL docs. Total: ~16 months baseline.)*

| Phase | Duration | Primary Goal | Key Deliverables | Go/No-Go Gate (must pass ALL) |
|---|---|---|---|---|
| **P0 — Pre-production** | 6 wks | Lock design, tech, legal frame, asset style | This brief → 6 docs; `current_state.json`; Live2D rig design locked via AI concept; tech stack provisioned; **legal child-directedness determination scoped**; LLM unit-economics model v1 | **G0:** Brief ratified; rig contractor secured; LLM cost/DAU model shows < ARPDAU at projected mix; legal review booked. |
| **P1 — Core-loop prototype** | 8 wks | Prove the daily loop is fun on cheap assets | 1 rig (puppy), 4 Care Meters w/ no-death floor, feed/clean/play, The Bond, 1 placeholder room, local notifications | **G1:** Internal playtest: core loop "feels alive & cozy"; sim deterministic + offline-catch-up tested; no neglect-guilt present. |
| **P2 — Vertical slice** | 10 wks | One polished, emotionally complete experience incl. AI | Rescue Day, Heartmind hybrid (pre-gen bank + structured memory + Memory Book), 3 life-stages, home widget, Keepsake Cards, 2nd species OR cut decision | **G2:** Hand-test of personas (Maya/Tom/David) hit "would tell a friend"; AI memory callback lands reliably; **rig pipeline cost on-budget (else cut 2nd species)**; spinner-free first AI line. |
| **P3 — MVP / Closed beta** | 12 wks | Feature-complete, store-compliant, instrumented | Full MVP feature set (§2 MVP rows), RevenueCat IAP/sub, ads SDK (child-safe config), Rescue Wall, cloud save + migration, analytics (~15 events), **legal sign-off**, localization shell | **G3:** Closed beta D1≥40% / D7≥18%; no child-safety incident; cloud-save restore proven; LLM cost/DAU within model; legal green-light. |
| **P4 — Soft launch** | 8 wks | Validate retention + unit economics in 2–3 markets | Phased geo rollout (e.g. CA/PH/NZ); live LLM gated pilot for adults; donation intermediary live + first disbursement; ASO assets | **G4:** D1≥42% / D7≥20% / D30≥10%; ARPDAU ≥ $0.03 and **LLM cost/DAU < 35% of ARPDAU**; ≥1 viral Keepsake share/DAU-week; donation reconciliation clean. |
| **P5 — Global launch** | 4 wks | Worldwide release | Full localization push, PR around donation/tech-for-good, store featuring pitch, scaled infra | **G5:** Soft-launch KPIs held at scale for 4 wks; infra cost/DAU stable; crash-free ≥99.5%; donation transparency badge live. |
| **P6 — Live ops** | Ongoing | Sustainable cadence; deferred-feature drops | Lock-screen widget, voice mimic (on-device), training, Care Pass, seasonal events, 2nd species (if cut), breed palette-swaps | **G6 (recurring quarterly):** D30 holding ≥10%; sub conversion ≥2%; donation volume + quarterly Impact Report published; content cadence sustainable solo+AI. |

---

## 4. ASSET BUDGET

| Decision | Value |
|---|---|
| **Style** | **Live2D Cubism**, 1 rig per species. Fallback: Spine 2D-skeletal. (NO custom 3D — honors constraint.) |
| **Hero spend** | 2 commissioned Live2D rigs @ $1,200–$2,000 each. Lock design with AI concept (Midjourney) BEFORE paying for rig. Add 15–20% contingency for rig revision rounds. |
| **Total unique authored assets (MVP)** | **~140** (2 rigs + 6 life-stage skins; 12 emotion motions [0 new art]; 4 environments; 25 props; 30 cosmetics; ~52 UI/icons/widgets; 12 FX; ~48 audio; 5 music). **Truly newly-drawn ≈ 65** — rest derived via rig params + palette-swaps. |
| **Total art/audio budget** | **$3,500–$7,550; plan at ~$5,500.** Excludes engine/LLM/infra/store fees/founder time. |
| **Discipline rules** | Cap 2 species; 3 life-stages via scale/param (not new rigs); emotions = param blends (free); day/night/weather = shader tints on same 4 BGs; cosmetics = overlay sprites + palette-swap; reallocate from music/SFX before EVER cutting rig quality. |

---

## 5. ECONOMY & MONETIZATION

**Care Meters (4):** hunger, energy/sleep, hygiene, happiness — 0–100 floats, gentle decay, **hard floor at "sad but safe" (never below; pet can NEVER die/suffer irreversibly).** Drive ~4 mood states; only dampen Bond *gain*, never reverse it.

**Currencies (3):** **Kibble** (soft, abundant, buys delight) · **Heartstones** (premium, IAP + milestones) · **Compassion Coins** (impact; non-tradeable, non-convertible, zero gameplay power, maps 1:1 to real outcomes e.g. 50 Coins = 1 real meal).

**Four revenue streams & est. gross-revenue contribution:**
| Stream | Design | Est. % gross |
|---|---|---|
| Rewarded + sparse interstitial ads | Rewarded-first, opt-in, ~4–6/day cap; max 1 interstitial/session at natural breaks; never mid-emotion; kids see contextual-only or none; every watch mints Compassion Coins | **45–55%** |
| Subscription (Forever Friends) | $5.99/mo · $39.99/yr; removes interstitials, daily Kibble, monthly Heartstones + Coins, cosmetic drip, higher donation match | **30–40%** (LTV anchor) |
| Cosmetic IAP (Heartstone bundles + packs) | Horizontal cosmetics only; direct-purchase; **NO gacha/loot boxes** | **10–20%** |
| Donation-linked Rescue Bundles | Stated split (e.g. 70% donation / 30% cosmetic+fee), disclosed pre-purchase + receipt | **5–10%** (outsized trust/virality) |

**Donation % model:** % of **NET** revenue (net of store fees 15–30%, processing, ad-network cut) — illustrative launch: rewarded-ad 5%, IAP/sub 5–10%, Rescue Bundles ~70% of bundle price. Single version-stamped **Impact Pledge** doc is canonical; "X% of revenue" claims always stated net to avoid misleading.

**Anti-fraud highlights (MVP):** server-side mint-gating (S2S signed ad postbacks; Apple/Google receipt validation); device attestation (App Attest / Play Integrity); per-user/device daily caps; reconcile against network-PAID impressions only; clawback Coins + revoke badges on refund/chargeback (disburse only after settlement window); Compassion Coins non-transferable/non-convertible (kills laundering). Bespoke anomaly ML = Deferred.

**LTV assumptions (conservative, indie):** Blended LTV/install **$0.30–$0.80** at launch, upside $1.00–1.50+. Sub cohort LTV $30–80+ (the profit lever). Sub conversion target 1–3% MAU; IAP-payer 1–2%, ARPPU $8–20. ARPDAU $0.03–0.06. **CAC near-zero at launch — growth must be organic/viral; paid UA only after sub LTV > CAC proven.** **KEY SENSITIVITY: LLM cost/DAU must stay well below ARPDAU** (target <35%) — enforced by caching, hybrid pre-gen, small models, token caps, subscriber-funded live chat.

---

## 6. TECH STACK

| Layer | Decision | Cost control / note |
|---|---|---|
| **Engine** | Unity (2D) **or** Flutter + Live2D SDK — pick at P0; must support Live2D Cubism runtime + native widget interop. | Defer final pick to G0; bias to whichever the founder+AI ship fastest. |
| **Backend** | Managed BaaS — **Firebase or Supabase** (auth, DB, cloud save, remote config). No owned servers. | Near-zero ops; AI agents scaffold migration/restore layer. |
| **LLM strategy** | **Hybrid:** offline LLM pre-generates large human-reviewed dialogue bank; runtime selects by pet-state + injects structured memory facts into cached persona prompt. Live free-form LLM (small/cheap fast model) DEFERRED & gated (adult-verified + subscriber + token caps ~60–100 out + daily turn caps + per-user cost ceiling). | Prompt-cache persona; templated common intents; thin backend proxy for key security + rate-limit + moderation. **This is the make-or-break OPEX model.** |
| **AI memory** | Structured key-value fact store (10–30 durable facts) in BaaS DB + short rolling turn window + batched off-peak fact extraction. Surfaced as the **Memory Book**. | Cheap; reliability > breadth (a few reliable callbacks beat broad flaky recall). |
| **Moderation** | Two-sided: input + output through cheap moderation/classification endpoint; hard system-prompt constraints; fixed safe-fallback line; self-harm → static safe message; full audit logging. | Per-turn cost rides in unit-economics model. Under-13: templated/non-generative only. |
| **On-device vs cloud** | Sim runs client-side (deterministic, elapsed-time, server-validatable). Memory/entitlements/donation-ledger server-side. Voice mimic (deferred) = on-device DSP only, audio never leaves device. | |
| **Save/sync** | Authoritative cloud save keyed to Apple/Google sign-in (+ guest). Local-first, single-device last-write-wins for MVP; **defer true multi-device live sync.** Version every schema + automated migration + restore flow. | No update may orphan a pet. |
| **Payments** | **RevenueCat** — single abstraction over StoreKit + Play Billing; receipt validation, entitlements, restore. | Collapses two billing stacks. |
| **Ads** | Standard mediation SDK (AdMob/ironSource) with COPPA/kids flags; rewarded-first. | Drop personalized ads for under-13. |
| **Widgets** | Native: iOS WidgetKit + Android Glance/AppWidget. Single shared "pet status snapshot" payload feeds widget + notification scheduler. Pre-rendered mood images (not live rig render). | Lock-screen/Live Activities deferred. |
| **Notifications** | Local-scheduled (no push cost) in MVP; FCM/APNs templated pet-voiced lines, 1–2/day cap. | |
| **Analytics** | Managed (Firebase/GameAnalytics), ~15 events mapped to funnel gates, privacy-by-design, no PII. | |

---

## 7. PERSONAS + HEADLINE RETENTION TARGETS

| Persona | One-line | Shares | Role |
|---|---|---|---|
| **Maya** — Gen-Z TikTok Casual | 19, 60–120s bursts, screenshot-first, zero tolerance for cringe/latency/repetition | Comfort moment (D1), memory payoff (D30) | Highest K-factor / install volume |
| **David** — Busy Adult Pet-Lover | 37, real rescue dog, widget-anchored, low-guilt, pays for calm+ad-free | Donation impact + before/after | Highest LTV (sub + bundles) |
| **Priya** — Socially-Conscious Donor | 29, nonprofit, scrutinizes donation mechanics, trust-gated | Verified impact (or public warning) | Trust-credential / anti-cynicism shield |
| **Tom** — Lapsed Tamagotchi Nostalgic | 34, stress-tests AI-memory authenticity, allergic to predatory F2P | "It remembered me" (Reddit/Discord) | Depth advocate or harsh critic |
| **Leo & Parent** — Kid Under Supervision | 9 + cautious parent; parent vets AI safety, wants voice mimic | Parent-to-parent "safe & kind" referral | One-strike safety gate; trusted referral |

**Headline retention targets (blended, brief-canonical):** **D1 ~45% (40–48) · D7 ~20–22% (18–25) · D30 ~10–12% (8–14).** Bimodal — hinges on (a) AI-memory authenticity and (b) forgiving-absence model. Worst case if AI memory disappoints: D30 → ~5–6% (genre median).

---

## 8. VIRALITY MECHANICS SHORTLIST
*(All player-initiated off genuinely felt moments → Keepsake Cards. NO forced popups, NO guilt, NO transactional referral.)*

1. **Unprompted Comfort** — pet notices low mood, offers care unasked → "an AI pet comforted me" card. (Maya)
2. **Long Memory Callback** — surfaces a weeks-old personal fact → "it remembered" card. (Tom — highest WOM)
3. **Before/After Growth** — auto split-card, scared rescue vs. thriving Grown, elapsed days. (David, native transformation format)
4. **Rescue/Gotcha-Day Milestones** — "forever home" ceremony card at peak pride.
5. **Real-Impact Celebration** — verified named-shelter impact badge "I helped real animals." (Priya, David)
6. **Widget Candids** — endearing home/lock-screen moment screenshotted directly; widget IS the ambient ad.
7. **Naming/Personality Reveal** — "only MY pet would say this," singular per player.

**Build native:** 1-tap share, tasteful watermark + pet name + actual line, light CTA "Adopt your own." Distinct shareable artifact per persona.

---

## 9. DONATION TRUST MODEL (summary)

**Model:** "Transparent Pooled Allocation with 1:1 Impact Mapping." % of NET revenue → segregated, auditable **Impact Pool** ledger → disbursed on fixed cadence (monthly/quarterly) through an **established giving-platform intermediary** (PayPal Giving Fund / Percent / Benevity) to **1–3 vetted partners** (registered nonprofit, Charity Navigator/GuideStar rating, audited financials). **NO donation-IAP, NO player tax-deductible donations in MVP** (store-policy + charity-registration compliance). Compassion Coins represent pooled intent, not personal deductible gifts.

**Trust pillars:** (1) single version-stamped Impact Pledge doc = SSOT; (2) segregated ledger + neutral intermediary = trust in process not founder's word; (3) Rescue Wall shows lifetime/personal real $, live campaign bars, dated downloadable receipts, partner acknowledgments; (4) outcome-based claims, always rounded DOWN, under-promise/over-deliver; (5) explicit donated-vs-cosmetic+fee split on every bundle; (6) quarterly co-signed Impact Report; (7) third-party "Impact verified through <date>" badge past volume threshold. **HARD ETHICAL WALL: never tie the virtual pet's wellbeing/survival to real donations; never guilt-frame.** Free players still generate real impact via ad-funded daily "kind act" Coins.

---

## 10. KPI TARGETS PER PHASE

| Phase | Primary KPIs (pass thresholds) |
|---|---|
| **G1** | Loop "fun" qualitative pass; deterministic sim + offline-catch-up tests green; zero neglect-guilt. |
| **G2** | Persona "tell a friend" qualitative pass; AI memory callback reliability ≥95% (no hallucinated facts); first-AI-line latency = 0 spinner; rig cost on-budget. |
| **G3 (Closed beta)** | D1 ≥40% · D7 ≥18%; 0 child-safety incidents; cloud-restore proven; LLM cost/DAU within model; crash-free ≥99%. |
| **G4 (Soft launch)** | D1 ≥42% · D7 ≥20% · D30 ≥10%; ARPDAU ≥$0.03; **LLM cost/DAU < 35% ARPDAU**; ≥1 viral share / DAU-week; clean donation reconciliation. |
| **G5 (Global)** | Soft KPIs held 4 wks at scale; infra cost/DAU stable; crash-free ≥99.5%; transparency badge live. |
| **G6 (Live ops, quarterly)** | D30 ≥10%; sub conversion ≥2%; IAP-payer ≥1.5%; donation volume up + quarterly Impact Report shipped; "noticed AI repetition" & "felt guilt-tripped" leading-churn metrics within bounds; sustainable cadence. |

**Leading churn indicators to instrument (mandatory):** "noticed AI repetition," "felt guilt-tripped about the pet." These predict D7/D30 collapse before raw numbers move.

---

## 11. RISK REGISTER (top 10)

| # | Risk | Sev | Mitigation (canonical) |
|---|---|---|---|
| R1 | **Kids-compliance (COPPA/GDPR-K/store kids policy)** — existential; detonated by AI chat, voice capture, ad targeting. | Critical | Build to child-safe standard for ALL users; hybrid (templated under-13, no free-text storage from minors); no behavioral ad targeting; **mandatory budgeted pre-launch legal review** (gate G3). |
| R2 | **Unbounded LLM OPEX** scales with engagement (anti-F2P economics). | Critical | Hybrid pre-gen + structured memory; small/cheap model; prompt-caching; token + daily-turn caps; live chat subscriber-only & age-gated; gate G4 on cost/DAU < 35% ARPDAU. |
| R3 | **AI-memory authenticity** — the single load-bearing feature; flaky recall = "theater"/"mid"/"unsafe" across personas. | Critical | Engineer narrow+reliable memory over broad+flaky; tangible **Memory Book** artifact as provable trust signal; ≥95% callback reliability gate at G2; anti-repetition rotation system. |
| R4 | **Save loss / pet "death"** = refund + 1-star + broken trust. | High | Authoritative versioned cloud save + automated migration + restore flow; **no-death decay floor** so pet can never suffer irreversibly. |
| R5 | **Donation legal/charity-washing** — vague/coercive = public backlash (Priya) + regulatory. | High | % NET-revenue pledge via vetted intermediary; named partners + receipts + verification badge; hard ethical wall; lawyer review of revenue-share claim; NO donation IAP. |
| R6 | **Neglect-guilt / punitive streaks** churn highest-LTV personas + violate cozy brand. | High | "Pet missed you but is okay" longing model; Streak Warmth (freeze/repair); never punish absence. |
| R7 | **Asset-cost explosion** (multi-species, per-stage animation, cosmetics). | High | 1 modular Live2D rig/species; 3 stages via param/scale; overlay cosmetics + palette-swap; defer 2nd species at G2 if hot; never under-budget the rig. |
| R8 | **Live-ops content treadmill** exceeds solo+AI capacity → post-launch churn. | Medium | Remote-config/data-driven event infra in MVP; honestly low launch cadence (1 small moment / 6–8 wks); core loop retains via bond/memory, not new content. |
| R9 | **Cross-platform native fragmentation** (widgets/notifications/billing). | Medium | RevenueCat for billing; single shared status payload → one widget/platform; local notifications MVP; defer lock-screen/Live Activities. |
| R10 | **Negative virality** — one tone-deaf/unsafe AI screenshot defines the brand. | Medium-High | Hard guardrails + child-safe persona lock + per-turn moderation; many small authentic moments over one engineered spectacle; under-13 templated-only. |

---

## 12. OPEN DECISIONS (resolve by gate noted)

1. **Engine: Unity vs Flutter+Live2D** — decide at **G0** (bias to fastest solo+AI shipping path with native widget interop).
2. **2nd species ship-or-cut** — decide at **G2** based on rig-pipeline cost burn (budget for 2; ship 1 if hot).
3. **LLM provider + exact model tiers** (cheap routine model vs. live-chat model) and final token/turn caps — model at G0, validate at **G3/G4**.
4. **Donation intermediary choice** (PayPal Giving Fund vs Percent vs Benevity) + initial 1–3 partner shelters — decide before **G4** (must be live for soft launch).
5. **Exact donation % per revenue type** (net) — finalize with accounting/legal before **G4**; lock in Impact Pledge doc.
6. **Launch localization languages** (which 4–6 for static UI) — decide by **G3**; AI-dialogue languages stay EN(+1–2), expand post-launch per-language safety validation.
7. **Soft-launch geos** (e.g. CA/PH/NZ candidate) — decide by **G3**.
8. **Subscription final price point** ($5.99 assumed) + Care Pass pricing — validate elasticity in soft launch **G4**.
9. **Under-13 handling: neutral age gate vs. fully child-safe-for-all** — legal determination of child-directedness drives this; resolve at **G3** legal review.
10. **Live free-form chat go/no-go** for adults — pilot in **P4**, decide expand/hold at **G4** on cost + safety data.

---

**FILE NOTE for downstream authors:** This brief is the canonical seed and the SSOT root, committed at `/home/emre/Downloads/my-talking-tom/game-os/KINDREDPAWS_CANONICAL_DECISION_BRIEF.md`. The machine-readable mirror is `/home/emre/Downloads/my-talking-tom/game-os/current_state.json` (live project state SSOT). All six downstream docs cross-link this brief by its exact filename rather than duplicating any fact.
