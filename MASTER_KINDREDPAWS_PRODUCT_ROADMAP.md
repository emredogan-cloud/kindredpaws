# MASTER KINDREDPAWS PRODUCT ROADMAP

**Genre Research → Product Evolution program — execution authority.**
Date: 2026-07-02 · Branch program: `feature/genre-evolution` (stacked on PR #65) · Supersedes `MASTER_PRODUCT_ROADMAP.md` (E1–E6, completed) as the active roadmap. That document remains the record of the prior program.

This roadmap was produced by the founder-approved **Genre Research → Product Evolution** mission: study the research corpus (runtime analyses, screenshot timelines, and structural analyses of two market-leading virtual-pet titles), extract transferable design principles, compare them honestly against KindredPaws, and implement every engineering-owned phase.

**Legal boundary honored throughout:** the research extracted gameplay structure, interaction flows, pacing, economy shapes, UX patterns, and architecture lessons only. No code, assets, artwork, audio, animations, character designs, UI artwork, or proprietary data were copied, and none may ever be. KindredPaws remains an original work — the goal is the modern evolution of the genre, not a clone.

---

## 1. Research base (evidence)

| Source | What was read | What it yielded |
|---|---|---|
| Runtime research (`live-test/research`) | All 16 non-image files: 4 reports (runtime analyses of both titles, systems comparison, original-mechanics blueprint), 84 observations, timelines, logs, 2 view-hierarchy dumps | Observed loop pacing, need-decay table, room interactions, economy numbers, ad-placement map, 40 transferable principles |
| Screenshot timeline | All 68 readable screenshots (49 title-1, 19 title-2), in chronological order | HUD anatomy, per-room interaction UI, shop/minigame/celebration patterns, 25 UX principles |
| Decompiled title 1 (structure only) | Manifest, asset taxonomy, IL2CPP type/field identifier map, SDK roster | Data-model patterns (meters with thresholds, AddOn cosmetics framework, Campaign/Calendar/Challenge LiveOps engine), 20 architecture lessons |
| Decompiled title 2 (structure only) | Manifest, Starlite asset container taxonomy, symbol/string digests | Sequel depth systems (quests, star/tile events, seasonal matrices, minigame reskin engine), 20 sequel lessons |
| KindredPaws repo | All authoritative docs, `game-os/` canon, full `lib/` map, tests, CI, open PRs | Current-state inventory (§3), constraints, quality baseline |

Quality baseline at program start (verified locally): **553 tests green, 91.0 % line coverage (5053/5553), 9/9 CI checks green on PR #65**, release APK builds, full physical-device walkthrough passed (see `FINAL_PRODUCT_VALIDATION_REPORT.md`).

---

## 2. Genre analysis — transferable principles

Consolidated from all sources; tags: **RT** runtime reports, **SS** screenshots, **D1/D2** decompiled structure. Principles conflicting with KindredPaws canon are inverted in §4 (Ethical Translation Charter).

### 2.1 Core loop & needs
1. The retention engine is wall-clock need decay pulling players back; the emotional anchor (a responsive creature) is what makes them *want* to return. (RT)
2. Needs decay at deliberately different rates (observed spread ≈ 4× between fastest and slowest), creating natural task rotation instead of one chore. (RT)
3. State is shown on demand (tap/room change), urgency by color; the pet — not gauges — stays the visual focus. (RT, SS)
4. Meters are parameterized data: {current, max, high/low thresholds, default, decay}; mood is a *derived, blended* state. (D1)
5. Care verbs are direct manipulation (drag food/sponge/brush onto the pet) with the camera pushing in during the act. (SS)
6. Every care action gives instant multi-channel feedback: meter fill + floating delta + color flip + themed animation + sound. (RT, SS)
7. Pet state must be *tangible*: visible smudges when dirty, droop when tired — concrete visuals beat abstract stats. (RT, D2)

### 2.2 Feeling alive
8. Idle life is continuous (breathing, additive micro-motion); reactions come from a weighted pool so repetition never repeats. (RT, D1)
9. Interactions are object-specific: each prop maps declaratively to a verb and a reaction (data table, not code). (RT, D1)
10. Reactions stay playful — even spammed taps never produce anger in a care game. (RT)
11. Audio attaches to animation states via pooled, data-defined events on separate Music/SFX buses. (D1, D2)
12. A populated home (companion creatures, animate props, ambient life) makes the world warm beyond the pet itself. (SS, D2)
13. Environmental state change is itself a reward: room dims for sleep, sparkle transitions, seasonal dressing. (SS)

### 2.3 Progression & retention
14. A frequent "unlock drumbeat" (level → small reward + cosmetic unlock, credited instantly and visibly) sustains momentum between big milestones. (RT, SS)
15. Daily variety comes from rotating objectives (daily challenges/quests with typed actions), not just streak counters. (RT, D2)
16. Escalating multi-day reward ladders with a visible countdown drive return visits; a mid-ladder spike pulls players over the hump. (RT, SS)
17. Standing, legible goals (fillable piggy bank, key-locked chest "0/1") give children concrete saving/return objectives. (SS)
18. Collections and themed sets create completion joy; sets spanning multiple slots raise perceived value. (D1, D2)
19. Meta-progressions at different tempos (session quests, daily ladder, longer collection boards) layer without colliding. (D2)
20. Seasonal content multiplies from a (surface × season) matrix over shared stages; one reskinnable engine can power many event games. (D2)
21. Onboarding is staged per feature at its unlock moment (a pointing hand on the first verb), not one up-front tutorial. (SS, D2)
22. Notifications keyed to behavioral rhythm (active days, session-time averages) outperform fixed timers — and must stay gentle and capped. (D2, RT)

### 2.4 Architecture & production
23. Content is data, not code: catalogs, tuning, events, and localization live in typed data objects with paired serializers, remote-overridable with cached defaults. (D1, D2)
24. One uniform template per feature (Data → Manager/Controller → State → UI) is what lets small teams ship dozens of systems without entropy. (D2)
25. Rooms are independently loadable scenes behind a map/host; a global state machine gates input during transitions. (D1)
26. Cosmetics unify under one AddOn abstraction (locked → earn/buy → owned → equipped) shared by clothes, décor, and wallpapers. (D1)
27. Animation is a state machine with interruptible transitions + additive layers; frame-synced events fire audio/VFX. (D1, D2)
28. Minigames isolate as modules with a shared kit; deterministic engines test headlessly. (RT, D2)
29. A steady 60 fps single surface sells "alive" more than visual complexity; budgets are enforced, not aspired to. (RT)
30. LiveOps hooks (feature flags, kill switches, config overlays) exist from day one even if content ships later. (D1, D2)

### 2.5 What the market leaders get wrong (deliberate inversions)
31. Interstitial "navigation tolls" at every valuable transition — replaced in KindredPaws by intrinsic beats (celebration, tip, pet delight). (RT, SS)
32. Close buttons that open stores, ads that eject the player from the app (even killing the session) — never acceptable, doubly so for children. (RT, SS)
33. Always-on banners and ads dressed as room objects (gift boxes, brushes, dream bubbles) — KindredPaws reserves every surface for game value. (RT, SS)
34. Need-panic + guilt as retention (red icons, "your pet is starving") — inverted into the punishment-free canon. (RT)
35. Gacha-shaped reward bags and rarity-tier chase — replaced by deterministic, visible rewards and anti-FOMO availability. (D2)

---

## 3. KindredPaws current state (honest inventory)

Full detail in `IMMERSIVE_PET_EXPERIENCE_REPORT.md`, `MASTER_PRODUCT_EXECUTION_REPORT.md`, `FINAL_PRODUCT_VALIDATION_REPORT.md`. Summary:

**Shipped and device-validated:** 8-room swipeable home (Grocery, Kitchen, Bathroom, Home, Play Garden, Bedroom, Care Corner, Wardrobe) over one `GameController`; original `VectorPetRenderer` (puppy + kitten, 4 mood idles, 12 emotion reactions, 3 life stages, exact Rive `PetStateMachine` contract for the future rig); punishment-free care meters (no-death floor 15, offline grace); monotonic 5-stage Bond with daily soft-cap; Kibble/Heartstones/Compassion-Coin economy (cosmetic/QoL only, type-enforced); 24-item catalog with generated sticker art; 2 no-fail deterministic minigames; Care Streak + Warmth + Repair + Milestone Book + Gotcha Day; 5-kind guilt-free notifications capped 2/day; Heartmind memory/dialogue with safety filter; Settings/Profile incl. right-to-be-forgotten; synthesized-audio/haptics/particles feel layer; save schema v7 with 6-step migration chain; 553 tests / 91 % coverage; 9 CI jobs.

**Canon constraints (locked):** no illness/vet mechanic, no death, no guilt/FOMO/gacha/loot boxes, never pay-to-win, no multiplayer/UGC, no live free-form LLM chat, no custom 3D, no voice-mimicry; Rive is the locked animation runtime (rig is a founder commission — vector renderer is the shipped stand-in); Firebase backend + RevenueCat (provisioning founder-gated); child-safe for all users.

**In flight (founder to merge):** PR #65 (asset pipeline + held-sleep fix + validation report), PR #62 (Rive drop-in seam assets).

---

## 4. Ethical Translation Charter

Every genre mechanic adopted below passes through this filter. It is part of the roadmap's acceptance criteria.

| Genre mechanic (observed) | KindredPaws translation | Why |
|---|---|---|
| Daily challenge + key/chest | **Daily Kindnesses**: 2 gentle, varied care intents per day; deterministic visible rewards; nothing is lost if skipped | No FOMO, no gacha; variety without pressure |
| Escalating streak calendar with countdown | Existing Care Streak + Warmth (kept); Kindness completion feeds it — no countdown clocks anywhere | Warmth already models "life happens" |
| Red panic icons, guilt copy | Soft state cues on the pet (droop, mussed fur) + warm invitations ("a bath would feel lovely") | Tangible state without alarm |
| Level+XP unlock drumbeat | Bond keepsakes at milestone days + set-completion keepsakes; décor/cosmetic unlock cadence via affordable Kibble prices | Progress joy without grind numbers |
| Rarity tiers / loot bags | Themed **sets** with visible contents and a completion keepsake | Collection joy, zero chance mechanics |
| Furniture/wallpaper AddOn store | **Cozy Corners** décor system (Kibble only, owned forever) | Expression pillar, no real-money path |
| Ad-gated premium food / refills | Time, care, streaks, and minigame play grant everything | No ads exist at all |
| Interstitials on transitions | Sparkle micro-transitions, first-visit hints, pet-delight beats | Friction points become warmth points |
| Behavioral-cohort notifications | On-device rhythm awareness only; cap stays 2/day; guilt-scan stays | Privacy-first, gentle |
| Seasonal skins matrix | **Seasons of Us**: nature-season accents (spring/summer/autumn/winter) as data; every seasonal keepsake returns yearly | Anti-FOMO; no holiday/religious commitments (founder decision) |
| Sickness/BooBoo doctor puzzles | **Excluded** — canon removes illness; Care Corner stays always-reassuring | Cozy promise |
| Mini-pet second care loop | Ambient **garden visitor** (appears when the garden is well-kept); no second meter set | Warmth without chore duplication |

---

## 5. Gap analysis

Classification: how far current KindredPaws is from best-in-class *for its own premium/child-safe positioning*. Effort: S ≤ ½ day, M ≈ 1 day, L ≥ 2 days of focused agent work incl. tests. "Founder" = blocked on founder action.

| # | Gap | Class | Eng. effort | Art | Animation | Backend | Testing | Founder dep. |
|---|---|---|---|---|---|---|---|---|
| G1 | No daily varied objectives (only streaks) | **Critical** | M | — | — | — | M | — |
| G2 | No décor/furnishing system; 8 cosmetics, no sets | **Critical** | L | Generated stickers (pipeline exists) | — | — | M | — |
| G3 | 2 similar minigames; no shared kit; low variety | **Critical** | L | Vector-drawn | S | — | M | — |
| G4 | Pet shows no visible low-need state; no autonomous micro-behaviors | **High** | M | — | M (vector) | — | S | — |
| G5 | Rooms static outside interactions; no ambient life/companion presence | **High** | M | — | M (particles) | — | S | — |
| G6 | LiveOps infra without content cadence; no seasonal layer | **High** | L | Palette/particle accents | S | — | M | — |
| G7 | No camera intimacy on care verbs; transitions unadorned | Medium | S | — | S | — | S | — |
| G8 | No ambient audio (SFX only) | Medium | S | Synthesized | — | — | S | — |
| G9 | First-visit verb hints inconsistent across rooms | Medium | S | — | — | — | S | — |
| G10 | Notification timing is fixed-window, not rhythm-aware | Medium | S | — | — | — | S | — |
| G11 | No legible child-facing saving goal (wishlist/jar) | Medium | S | — | — | — | S | — |
| G12 | Localization: English only | Medium | L | — | — | — | M | **Founder** (language strategy) |
| G13 | Final pet art is a vector stand-in | High | — (seam done) | **Rive rig** | — | — | — | **Founder** (commission) |
| G14 | Live backend/IAP inert (Noop seams) | High | — (seams done) | — | — | Provisioning | — | **Founder** (Firebase/RevenueCat/Play) |
| G15 | iOS build & store presence | High | — | — | — | — | — | **Founder** (macOS/Apple) |

G12–G15 are founder-gated and excluded from engineering phases. G1–G11 define the program below.

---

## 6. Engineering phases

Program rules (apply to every phase):

- **Process:** micro-commits on `feature/genre-evolution` (stacked on PR #65 — founder merges #65 first, then the rolling program PR; CI runs on every push). Conventional Commits. `just verify` green before every push. Never a red CI left behind, never a known regression.
- **Quality bar:** coverage never drops below the running baseline (≥ 91 % target, hard floor 60 % in CI); every new system gets unit + widget tests at minimum; goldens updated intentionally only.
- **Performance:** budgets in `lib/core/performance_budgets.dart` are the SSOT — cold start ≤ 2500 ms, frame ≤ 16 ms, reaction ≤ 150 ms. New ambient/particle work must idle at 60 fps with reduced-motion fallbacks.
- **Accessibility:** every new control gets semantics + ≥ 48 dp target; reduced-motion honored (ambient layers off); color never the sole signal; copy passes the guilt-language validator.
- **Device validation:** after each phase, install the release APK on the connected Android device (uninstall-first, md5-verified, `flutter clean` before build) and walk through the new surface. Never drive scripted taps while the owner may be using the phone.
- **Legal:** no copied expression, ever. Generated art documents prompt + path + optimization in `assets/CREDITS.md`.

### GE-1 · Daily Kindnesses (G1) — retention variety, canon-safe

- **Objectives:** a data-driven daily-objective engine offering exactly 2 varied, gentle "kindnesses" per day (e.g., *share a meal*, *bubble-bath time*, *a little game together*), deterministic from the date + pet id; completing one credits Kibble (+10–20) and an affectionate celebration beat (cue + the pet's own words — not a Memory Book write: the Memory Book is a closed validated fact set by canon, and stays that way); skipping costs nothing and is never mentioned again.
- **UX goals:** a warm "Today's kindnesses" chip on Home (next to the streak chip) opening a two-card sheet; cards show the verb, the room, and the visible reward; completion celebrates inline (particles + chime), never modally interrupts.
- **Architecture:** `lib/game/model/kindness.dart` (template catalog, const + code-defined like `ItemCatalog`), `lib/game/sim/kindness_engine.dart` (pure: pick-of-day via seeded hash, progress detection from existing `Interaction` events, no new timers), state persisted in save **schema v8** (`kindness` map: date, offered ids, completed ids) with `V7ToV8` migration; wired in `GameController` beside the daily-bonus hook.
- **Dependencies:** none beyond current tree.
- **Acceptance criteria:** same date+pet always offers the same pair; pair varies across days and rooms; completion detected from real interactions only (no manual claim); rewards credited once; uncompleted kindnesses vanish silently at midnight; Charter (§4) respected in every string.
- **Testing:** unit (engine determinism, rollover, double-credit guard, migration v7→v8 incl. old-save gift), widget (chip + sheet + completion state), golden if visuals warrant.
- **Performance:** engine is O(1) per interaction; no new tickers.
- **Accessibility:** sheet cards fully labeled; chip announces count; no countdowns.
- **DoD:** `just verify` green, coverage ≥ baseline, device walkthrough shows offer→complete→celebrate→persist across restart.
- **Founder/legal blockers:** none.

### GE-2 · Living Pet & Living Rooms (G4, G5) — tangible state, ambient life

- **Objectives:** the pet visibly carries its state — gentle smudges/mussed coat below hygiene 45, droopy eyes + slower idle below energy 35, a soft tummy-gurgle glance below hunger 40 (all warm, never alarming); autonomous micro-behaviors on idle (stretch, ear-flick, look-around, curl-up — species-aware, weighted pool); ambient room life (kitchen kettle steam, bedroom drifting stars/fireflies at night, garden butterflies; a **garden visitor** songbird appears while happiness ≥ 70 and the garden was played in today).
- **UX goals:** at a glance, a child reads the pet's state from the pet itself; rooms feel inhabited; nothing moves aggressively; reduced-motion yields a calm static scene.
- **Architecture:** extend `VectorPetRenderer` with a state-layer pass (paint-level, no new widget tree); `lib/game/ui/widgets/ambient_life.dart` (per-room ambient particle configs, driven by existing particle system + `TickerMode`); autonomous behaviors as timed emotion injections through the existing reaction path (respecting the ≤ 2 s one-shot contract, never during sleep); visitor logic pure in `lib/game/sim/` (derived, not persisted).
- **Dependencies:** none. (Purely presentational; no schema change.)
- **Acceptance criteria:** thresholds match sim constants; layers disappear the moment care fixes the meter (bath instantly clears smudges — cause→effect); Rive contract untouched (vector-only layers); reduced-motion disables ambient + autonomous motion; sleep is never interrupted.
- **Testing:** unit (threshold mapping, visitor predicate, behavior scheduler determinism under fake clock), widget (state layers render per meter band; ambient respects reduced-motion), goldens for the 3 state looks per species.
- **Performance:** ambient layers budgeted ≤ 12 concurrent particles/room; renderer sweep budget unchanged (4000 ms / 48 combos).
- **Accessibility:** state also announced via existing status semantics (e.g., "Biscuit could use a bath"); no flashing.
- **DoD:** verify green, goldens reviewed, device walkthrough confirms 60 fps idle in all 8 rooms.
- **Founder/legal blockers:** none.

### GE-3 · Cozy Corners (G2, G11) — décor, sets, and a child-legible saving goal

- **Objectives:** a décor system: `ItemKind.decor` items placeable in fixed slots per room (Home ×3, Bedroom ×3, Play Garden ×3, Kitchen ×2, Bathroom ×1 — 12 slots); launch catalog ≈ 14 décor items incl. two themed **sets** (e.g., *Starry Night* bedroom set, *Sunny Meadow* garden set); set completion mints a Keepsake + celebration; a **Wishlist jar**: the child marks one item as wished-for, the shop shows a gentle fill-toward-price jar from the Kibble balance.
- **UX goals:** decorating is two taps (slot → owned item); décor persists and shows in the room scene; sets read as a warm collection page, contents fully visible upfront; the jar makes saving legible without pressure.
- **Architecture:** extend `ItemDef` with `decorRoom`/`decorSlot`; `DecorState` (slot → itemId) persisted in save **schema v9** (`V8ToV9`); placement UI via existing `ShelfPanel`/`ItemCard` kit in a per-room "decorate" sheet from the room scaffold; render as positioned stickers in room scenes (same `artPath` + emoji fallback pattern); wishlist id + jar in v9; shop surfaces gain a Homeware shelf (Grocery) and a set page.
- **Dependencies:** GE-1's migration precedent (chain now …V8ToV9); **asset generation** via `tool/generate_gpt_assets.py` (key present) for ~14 décor stickers — prompts/paths documented in `assets/CREDITS.md`; emoji fallback keeps UI safe if generation is deferred.
- **Acceptance criteria:** Kibble-only prices within canon bands (décor 40–260); owned-forever, re-buy blocked; placement survives restart + room swipes; set completion exactly once; wishlist never nags (no notifications, no badges — just the jar when visiting the shelf); catalog stays const/reviewable.
- **Testing:** unit (purchase/placement reducers, set-completion detection, v8→v9 migration, wishlist math), widget (decorate sheet, slot rendering, jar), goldens for one decorated room per set.
- **Performance:** décor renders as static positioned images — zero per-frame cost; slot count capped (12).
- **Accessibility:** slots and items labeled ("Place the Star Lamp on the bedside table"); jar announces progress in words.
- **DoD:** verify green, migration proven on a real v8 save, device walkthrough decorates two rooms, completes a set, sees the keepsake.
- **Founder/legal blockers:** none (generated art is original; pipeline documented).

### GE-4 · Playtime Expansion (G3) — shared minigame kit + two new games

- **Objectives:** extract the shared deterministic engine pattern into `lib/game/minigames/kit/` (fixed-step loop, seeded rng, score→Kibble mapping, session guard); add two original no-fail games with distinct verbs: **Bubble Drift** (tap drifting bubbles before they float off; combos raise sparkle joy; nothing pops "wrong") and **Starlight Trail** (one-touch glide through a gentle star path collecting glimmers; releasing just drifts — no crash state); both entered as world props in the Play Garden (a bubble wand and a star lantern toy), per the world-integrated principle.
- **UX goals:** each game teaches itself in one hint; sessions are 45–90 s; endings always celebrate what was collected; the pet visibly enjoys watching/joining.
- **Architecture:** pure-Dart engines (`bubble_drift_game.dart`, `starlight_trail_game.dart`) under the kit; UI screens reuse `mini_game_screen.dart` scaffolding generalized to N games; entries added to the Play Garden toy shelf as world props; rewards flow through the existing `miniGameKibble` cap (1–15) — economy untouched.
- **Dependencies:** GE-2's ambient/particle utilities (visual garnish), none hard.
- **Acceptance criteria:** engines deterministic under seed (goldens on tick sequences); no fail/lose language anywhere; energy cost + sleepy-pet hush rules match existing games; play counts feed kindness templates ("teach a new game") from GE-1.
- **Testing:** unit (engine determinism, scoring bounds, reward cap, session guard), widget (both screens incl. reduced-motion), performance (fixed-step under budget on host).
- **Performance:** engines allocate nothing per tick after warm-up; 60 fps on device.
- **Accessibility:** both games playable with single taps anywhere (no precision demands); reduced-motion slows drift speeds; semantics announce collect events sparsely.
- **DoD:** verify green, device session of each game, rewards + kindness integration observed.
- **Founder/legal blockers:** none.

### GE-5 · Seasons of Us (G6) — a local, anti-FOMO seasonal layer

- **Objectives:** a season engine deriving the current nature season (N/S-hemisphere aware via Settings override, default northern) with per-season room accents (palette tint, ambient particle variant, one prop sticker per key room), 2 seasonal kindness templates per season, one seasonal Memory line, and a per-season keepsake earnable by any 5 active days in that season — earnable again every year, nothing ever expires forever.
- **UX goals:** the home subtly turns with the year (autumn leaves drift in the garden, winter frost corners the window); returning after months feels like the world lived too; zero countdowns or "limited!" copy.
- **Architecture:** `lib/game/sim/season_engine.dart` (pure date→season), `lib/content/seasons.dart` (all 4 seasons as const data: accents, templates, keepsake defs); accent application via GE-2's ambient layer + existing background art (no new images required — tint/particle/prop composition); gated by the existing LiveOps kill-switch; seasonal-keepsake progress in save **schema v10** (`V9ToV10`, a small per-season active-day counter).
- **Dependencies:** GE-1 (kindness templates plug-in), GE-2 (ambient layer), GE-3 migration precedent.
- **Acceptance criteria:** season flips are pure functions of date (testable across boundaries incl. Feb 29); all 4 seasons' content ships as data in one PR; kill-switch reverts to neutral instantly; keepsakes re-earnable next year; hemisphere override in Settings.
- **Testing:** unit (season math incl. boundaries + hemisphere, keepsake accrual, v9→v10), widget (accent rendering per season with reduced-motion), golden (one room across 4 seasons).
- **Performance:** accents reuse ambient budget; zero cost when kill-switched.
- **Accessibility:** accents are decorative (semantics-silent); season named in Profile ("Our first summer together").
- **DoD:** verify green, device walkthrough with forced season overrides.
- **Founder/legal blockers:** none (nature seasons avoid cultural/religious holiday decisions, which stay founder-owned).

### GE-6 · Feel & Flow (G7–G10) — intimacy, ambience, guidance, rhythm

- **Objectives:** (a) camera intimacy: gentle scale/ease push-in on the pet during feeding/brushing/washing beats, pull-back on completion; (b) ambient audio: 4 synthesized, license-clean room pads (soft loops ≤ 45 s, generated by extending `tool/generate_sfx.dart`), behind the existing sound toggle + a new "ambient sounds" sub-toggle; (c) first-visit verb hints: one-time soft pulse + pointing sparkle on each room's primary prop (persisted seen-set in prefs, not save); (d) rhythm-aware notifications: on-device preferred-hour band learned from session opens (rolling average), applied inside the existing 2/day cap and guilt-free templates.
- **UX goals:** care feels intimate; rooms hum quietly; a first-time child always knows the one thing to try; notifications arrive when this household actually plays.
- **Architecture:** camera push via `PetStage` transform (reduced-motion: cross-fade only); `AmbientAudioService` on the existing `AudioSink` seam (Noop in CI); hints as a tiny overlay in `room_scaffold.dart` driven by `PrefsService`; rhythm window in the notification scheduler (pure function over a stored open-hours histogram, fully unit-testable, privacy: never leaves device).
- **Dependencies:** GE-2 (stage/ambient utilities); audio asset generation local-only.
- **Acceptance criteria:** push-in never fights user scroll/drag; pads duck under SFX and stop when backgrounded; each hint shows exactly once per install; scheduler still guilt-scanned, capped, kill-switchable; all toggles persist.
- **Testing:** unit (rhythm histogram→window math, hint seen-set, audio service states), widget (hint overlay once-ness, settings toggles), integration touch on notification scheduling path.
- **Performance:** pads decoded once, looped; no jank on push-in (transform-only).
- **Accessibility:** hints have semantic labels and auto-dismiss; ambient audio always user-controllable, off when the sound toggle is off.
- **DoD:** verify green; device walkthrough covering all four features.
- **Founder/legal blockers:** none.

### GE-7 · Hardening & Evolution Validation — prove it, honestly

- **Objectives:** full-suite verification (unit/widget/golden/perf/integration), coverage report, performance budget re-run, accessibility audit of every new surface, fresh release-APK real-device walkthrough of the complete evolved experience (all phases), regression pass over the pre-existing 553 tests, and the final evidence-backed `MASTER_PRODUCT_EVOLUTION_REPORT.md`.
- **Acceptance criteria:** 0 analyzer issues, all tests green, coverage ≥ 91 %, budgets met, device walkthrough crash-free with screenshots archived, report contains every mission-required section with evidence and no exaggeration.
- **DoD:** rolling PR green and ready for founder merge; report committed; memory updated.
- **Founder/legal blockers:** the merge itself (harness forbids agent self-merge).

---

## 7. Founder-only ledger (unchanged by this program)

1. **Merge PRs** #62, #65, and the program PR (agent self-merge is blocked by the harness).
2. **Rive rig commission** (G13): contract per `docs/RIVE_CONTRACTOR_HANDOFF.md`; drop-in seam is ready and test-pinned.
3. **Service provisioning** (G14): Firebase project, RevenueCat, Play Console, signing keys.
4. **iOS** (G15): macOS runner + Apple account; Codemagic seam exists.
5. **Language strategy** (G12): which locales; then engineering can execute an i18n phase.
6. **Holiday/event content policy**: whether cultural/religious holidays join the nature seasons.
7. **Store listing assets & copy** final approval; Compassion Coin USD rate + net-% (pre-G4 gate of the prior roadmap).

## 8. Legal / licensing ledger

- No copied expression from research subjects (enforced in review each phase; this document is the audit trail of what was *learned*, not taken).
- Generated art/audio: original, produced by our documented pipeline (`tool/generate_gpt_assets.py`, `tool/generate_sfx.dart`), logged in `assets/CREDITS.md`.
- COPPA/GDPR-K counsel review remains founder-gated before public release (pre-existing G3 gate).
- Rive rig licensing terms — founder negotiation with contractor.

## 9. Definition of program completion

Every GE phase merged-ready (green rolling PR), device-validated, documented in the final report, with only §7/§8 items outstanding — at which point the program prints **WAITING FOR FOUNDER ACTION** (the honest end-state while merges/commissions/provisioning remain human-owned).
