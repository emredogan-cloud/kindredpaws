# MASTER PRODUCT EVOLUTION REPORT

**Mission:** Genre Research → Product Evolution (`mytalkingtom_mission.md`).
**Subject:** KindredPaws — a cozy, child-safe virtual-companion game (Flutter).
**Date:** 2026-07-02 · **Branch:** `feature/genre-evolution` → PR #66 (rolling, stacked on #65) · **Author:** engineering agent (Claude).

Every claim below is backed by a commit, a test count, or a named file. Where something is incomplete or unverified, it is called out as such — no progress is exaggerated.

---

## 1. Executive summary

The mission asked to study a research corpus on the virtual-pet genre, extract transferable design principles, compare them honestly against KindredPaws, produce a single new master roadmap, and then implement every engineering-owned phase.

All of that was done. Five research agents digested the full corpus (runtime analyses, a 68-screenshot timeline, structural analyses of two decompiled market-leading titles, and the KindredPaws codebase). Their findings became `MASTER_KINDREDPAWS_PRODUCT_ROADMAP.md` — 35 transferable principles, an Ethical Translation Charter, an honest gap analysis (G1–G15), and seven engineering phases (GE-1…GE-7).

**Six feature phases shipped** (GE-1…GE-6), each as a green micro-commit batch on the rolling PR, each `just verify`-green and CI-green. The seventh (GE-7) is this hardening pass + report.

- **Tests:** 553 at program start → **642 passing** (89 added across 18 new test files). **0 analyzer issues** (`--fatal-infos --fatal-warnings`).
- **Coverage:** 91.0 % at start → **91.0 % now** (6110/6716 lines), well above the 60 % CI floor, held flat while the codebase grew ~6.0k lines.
- **Save schema:** v7 → **v10**, three forward migrations, every one proven not to orphan a pet.
- **CI:** all 9 checks green on PR #66 (analyze, test, build-android, integration-android incl. emulator E2E, secret-scan, osv-scanner, dependency-scan, sbom, workflow-hardening).
- **Original assets:** 14 new décor stickers generated via the documented OpenAI pipeline, optimized 22 MB → 2.8 MB, logged in `assets/CREDITS.md`.
- **Legal boundary honored:** the research produced *principles*; no code, art, audio, or expression was copied from the studied titles.

**The one honest gap in the engineering scope:** the physical-device walkthrough is blocked by the device owner's MIUI per-install confirmation (`INSTALL_FAILED_USER_RESTRICTED`), which needs a human tap on the phone. Device-*class* validation still happens every push via the `integration-android` emulator E2E job. See §14.

---

## 2. Research summary

Sources read in full (mission "read everything before a line of code"):

| Source | Coverage |
|---|---|
| Runtime research (`OTHER-RESEARCH/decompile/live-test/research`) | All 16 non-image files: 4 reports (runtime analyses of both titles, systems comparison, original-mechanics blueprint), 84 observations, timelines, logs, 2 view-hierarchy dumps |
| Screenshot timeline | All 68 readable screenshots (49 title-1, 19 title-2) in chronological order |
| Decompiled title 1 | Manifest, asset taxonomy, IL2CPP type/field map, SDK roster — structure only |
| Decompiled title 2 | Manifest, Starlite asset-container taxonomy, symbol/string digests — structure only |
| KindredPaws repo | All authoritative docs, `game-os/` canon, full `lib/`, tests, CI, open PRs |

The two studied titles run on a proprietary native stack (title 1: Unity + IL2CPP under Outfit7's "Felis"; title 2: the C++ "Starlite" engine) with heavily ad-driven monetization (6–17 mediated ad networks, interstitial "navigation tolls," store-redirecting close buttons). KindredPaws is the deliberate inverse: Flutter, premium, ad-free, child-safe.

## 3. Genre principles extracted

Full list of 35 in the roadmap (§2). The load-bearing ones that shaped this program:

- **Differential need decay** creates natural task rotation (observed ≈ 4× spread between fastest/slowest need).
- **Tangible state beats hidden stats** — a visibly mussed or drowsy pet reads better than a gauge.
- **Daily variety comes from rotating objectives**, not just a streak counter.
- **A frequent, visible unlock drumbeat** sustains momentum between milestones.
- **Themed collection sets** create completion joy; sets spanning slots raise perceived value.
- **A hub + real minigames** multiplies session variety.
- **Seasonal content** multiplies from a (surface × season) matrix over shared stages.
- **Onboarding is staged per feature** at its unlock moment, not one up-front wall.
- **Notifications keyed to real rhythm** beat fixed timers — and must stay gentle and capped.
- **The genre's monetization is the anti-pattern**: interstitial tolls, dark-pattern close buttons, guilt/FOMO, gacha. Each was consciously inverted (Charter, §5 here).

## 4. Gap analysis (recap)

The roadmap classified 15 gaps. Engineering-owned, now-closed:

| Gap | Phase | Status |
|---|---|---|
| G1 no daily varied objectives | GE-1 | ✅ Daily Kindnesses |
| G2 no décor/sets | GE-3 | ✅ Cozy Corners |
| G3 shallow/similar minigames | GE-4 | ✅ engine kit + 2 games |
| G4 pet shows no low-need state | GE-2 | ✅ tangible care cues |
| G5 static rooms | GE-2 | ✅ ambient life + visitor |
| G6 no seasonal layer | GE-5 | ✅ Seasons of Us |
| G7 no camera intimacy | GE-6 | ✅ care-beat push-in |
| G9 inconsistent first-visit hints | GE-6 | ✅ one-time hints |
| G10 fixed-window notifications | GE-6 | ✅ rhythm-aware |
| G11 no legible saving goal | GE-3 | ✅ wish-jar |
| G8 no ambient audio | GE-6 | ⏸ deferred (device-audio-gated; seam ready) |

Founder-gated (out of engineering scope, unchanged): G12 localization strategy, G13 Rive rig commission, G14 backend/IAP provisioning, G15 iOS.

## 5. Ethical Translation Charter (applied)

Every adopted mechanic passed the Charter (roadmap §4). Concretely enforced this program:

- **Daily Kindnesses** replace daily-challenge/key-chest loops — deterministic visible rewards, no countdowns, uncompleted work fades silently.
- **The wish-jar** replaces gacha/FOMO saving pressure — one wished item, a visible fill bar, no nag, no badge, no notification.
- **Themed décor sets** replace rarity/loot — contents fully visible upfront, completion mints a keepsake, zero chance mechanics.
- **Tangible care cues** replace red-panic guilt — a mussed coat and drowsy lids, warm not alarming, cleared the instant care lands.
- **Seasons** are anti-FOMO by construction — every season and seasonal keepsake returns next year; nothing ever expires.
- **Notifications** stay ≤ 2/day, guilt-scanned, kill-switchable; rhythm data never leaves the device.
- No new currency sink can buy Bond/growth; nothing costs real money in a room; illness/vet stays excluded (cozy canon).

## 6. Completed phases

| Phase | Commit | What shipped | Tests · coverage |
|---|---|---|---|
| Roadmap | `446ff2b` | `MASTER_KINDREDPAWS_PRODUCT_ROADMAP.md` (execution authority) | — |
| GE-1 Daily Kindnesses | `941b1b1` | Deterministic daily-objective engine, save v8, Home chip+sheet, `kindnessComplete` telemetry | 574 · 91.2 % |
| GE-2 Living Pet & Rooms | `e6f77be` | Tangible care cues, autonomous idle beats, ambient room life + garden visitor | 588 · 91.4 % |
| GE-3 Cozy Corners | `795f35d` | Décor slots + themed sets + wish-jar, save v9, 14 original stickers | 604 · 91.6 % |
| GE-4 Playtime Expansion | `b0cd703` | `MiniGameEngine` kit + Bubble Drift + Starlight Trail | 615 · 91.2 % |
| GE-5 Seasons of Us | `3506fe7` | Nature-season engine, accents, seasonal kindnesses, save v10, `seasons` kill-switch | 630 · 91.2 % |
| GE-6 Feel & Flow | `7dd090f` | Camera intimacy, first-visit hints, rhythm-aware notifications | 642 · 91.0 % |
| GE-7 Hardening | this report | Full-suite + perf + a11y + adversarial review + report | 642 · 91.0 % |

## 7. Implemented systems (architecture)

All new systems follow the repo's existing seam discipline (pure domain/sim, injected clocks, service seams with in-memory defaults):

- **Kindness** (`game/model/kindness.dart`, `game/sim/kindness_engine.dart`): const template catalog + pure engine (FNV-1a seed of petId × epoch day; pair = distinct trigger AND room). Completion detected from real interaction hooks, never a claim button.
- **Care cues** (`render/pet_renderer.dart` `PetCareCues`, `game/ui/care_cues.dart`): a renderer-side layer derived from meters — deliberately NOT part of the Rive `PetStateMachine` contract (which stays exactly mood/lifeStage/emotion), so the future rig inherits it as a Flutter composite like cosmetics.
- **Ambient life** (`game/ui/widgets/ambient_scene.dart`, `game/ui/widgets/ambient_life_driver.dart`, `game/sim/ambient_presence.dart`): budgeted, deterministic, `motionEnabled`-gated decorative layers + a bounded autonomous-behavior driver + a pure garden-visitor predicate.
- **Décor** (`game/model/decor.dart`, `game/ui/rooms/decor_ui.dart`): 12 fixed slots, 14 pieces, 2 sets, wish-jar; placement/ownership in `Inventory`; set completion mints a once-only keepsake.
- **Minigame kit** (`game/minigames/mini_games.dart` `MiniGameEngine`): no-fail by type (monotone score, timer-only end); one generalized stage over four engines.
- **Seasons** (`game/sim/season_engine.dart`, `game/model/season_progress.dart`): pure date→season (hemisphere-aware), season-window keys that survive New Year, 5-day keepsake, kill-switchable.
- **Feel & Flow**: `PetStage` camera push-in; `FirstVisitHint`; `preferredNotificationHours()` pure picker over an on-device open-hour histogram in `PrefsService`.

State mgmt, DI (`ServiceLocator`), and the save/migration chain are unchanged in shape — every phase extended them without rewrites.

## 8. Gameplay evolution

The core loop (need → room → interaction → refill → Bond → keepsake) is unchanged and untouched; the program added **texture around it**: a reason to visit two specific rooms today (Kindnesses), a visible pet-state read that makes care legible (cues), a self-expression sink with a saving goal (décor + wish-jar), more ways to play (4 minigames), a world that turns with the year (Seasons), and warmth in the small moments (camera, hints, ambient life, rhythm notifications).

## 9. Character evolution

The pet now visibly carries its state — a gently mussed coat below hygiene 45, heavier lids and slower breathing below energy 35, a wistful tummy-glance below hunger 40 — all warm, never alarming, and cleared the instant care lands. It also stirs on its own a few times a sitting (stretch/ear-flick/look-around) via the existing ambient-emotion path, and never while asleep. All expressed through the shipped `VectorPetRenderer` (the Rive rig remains a founder commission; the contract stayed intact).

## 10. Room evolution

Every room gained ambient life (kitchen steam, bedroom starlight, garden butterflies + songbird, hearth motes) and a seasonal accent layer; four rooms gained décor slots that compose placed pieces into the scene; three gained a first-visit verb hint. The Play Garden gained two more world-prop games.

## 11. Animation evolution

New motion is uniformly budgeted, deterministic, and test-safe: a single master `AmbientScene.motionEnabled` switch keeps all ambient/pulse loops OFF in tests/CI (so `pumpAndSettle` always settles) and the system reduced-motion setting always overrides it. Care-beat camera push-in is a transform-only `AnimatedScale`. The render perf sweep (48 mood×emotion combinations, now with cue layers) stays within budget.

## 12. Asset generation summary

14 new décor stickers via `tool/generate_gpt_assets.py` (gpt-image-1), prompts in the script's décor section (storybook style, transparent, no characters). Transparent 1024² → optimized to 512² (22 MB → 2.8 MB). All logged in `assets/CREDITS.md` with origin + license (project-original, no copyrighted-work imitation). Emoji remains the graceful fallback if any sticker is missing.

**Not generated:** ambient-audio pads (GE-6 sub-item b, deferred — device-audio-gated).

## 13. Testing summary

- **642 tests** across unit (77 files), widget (27), golden (3), performance (2), integration (4).
- **89 new tests in 18 new files** this program, covering: engine determinism (same seed → identical session tick-for-tick), migration round-trips (v7→v10, each step invisible to old saves), completion/keepsake idempotency (no double-credit, no double-mint), Charter compliance (copy scanned for guilt/urgency/loss vocabulary), reduced-motion + master-motion gating, and the rhythm-hours picker across signal/no-signal/tie cases.
- **Determinism guard:** a fixed test pet id (`kTestPetId`) pins the daily-kindness pair so kindness Kibble credits never flake economy assertions.

## 14. Real-device validation summary

**Device-class (automated, every push):** the `integration-android` CI job installs the app on an emulator and drives `integration_test/` (app smoke, full journey, rooms journey, notifications) — green on PR #66.

**Physical device (blocked on device owner):** the connected Android is a MIUI device. A clean release APK builds and is present at `build/app/outputs/flutter-apk/app-release.apk`, but `adb install` returns `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user` — MIUI's per-install USB-confirm dialog requires a human tap on the phone, which an agent cannot supply. This is a device-owner gate (like the merge/rig/provisioning gates), not an engineering defect. The founder can complete it by approving the on-device prompt, or run `just e2e-android` on an emulator locally.

## 15. Performance summary

`test/performance` green: cold widget build within budget; the full mood×emotion render sweep (with the new cue layers) within the `renderSweep` budget; state-machine input mapping pure + cheap. Runtime budgets SSOT unchanged (`lib/core/performance_budgets.dart`: cold start ≤ 2500 ms, frame ≤ 16 ms, reaction ≤ 150 ms). New ambient/particle work is capped (≤ ~12 shapes/room) and fully disabled under the master motion switch and reduced-motion.

## 16. CI summary

PR #66, all 9 checks green: `analyze`, `test`, `build-android`, `integration-android`, `secret-scan`, `osv-scanner`, `dependency-scan`, `sbom`, `workflow-hardening`. No check disabled, no red left behind at any phase.

## 17. Bug-fix summary (issues found + fixed during the program)

Found and fixed *during* the phases:
- **Secret-leak hazard:** the real OpenAI key had been pasted into the committed `.env.example`; reverted (key lives only in gitignored `.env`, never committed).
- **Telemetry totality:** `kindnessComplete` needed an `EventSpec` in the taxonomy SSOT — added (retention gate).
- **RC defaults:** the `seasons` kill-switch key had to be registered in the remote-config defaults + the readiness test + the incident runbook — done.
- **First-visit hint overlay** initially covered the bedroom tuck-in button (stole its tap); repositioned to the clear "sky" band above all room controls.
- **Test determinism:** several exact-value pins broke when kindness credits landed; fixed by pinning the test pet id and updating the two affected purchase pins deliberately (with comments).
- Assorted lint/format fixes (raw types, const, unused locals) resolved before each push.

Found by the **GE-7 adversarial review** (an independent skeptical pass over the whole `develop...HEAD` diff) and fixed before this report was committed:
- **[MEDIUM] Starlight Trail hold control** failed the moment a finger drifted — the pan recognizer won the gesture arena and dropped the hold, so the firefly sank while the child was still pressing. Rewired from `GestureDetector` to raw `Listener` pointer events (bypasses the arena); a drag now keeps the firefly rising. This was the one issue that degraded a shipped feature in normal use.
- **[LOW] Camera push-in was a visual no-op** — a next-frame post-frame callback reset the scale before `AnimatedScale` could travel. Now dwells via a 460 ms timer, so the push-in is actually visible; a strengthened test guards the dwell.
- **[LOW] `_PulseChip`** didn't stop pulsing if reduced-motion flipped on mid-show; now mirrors `AmbientScene` and disposes the controller.
- **[LOW] Divide-by-zero guard** added to the kindness pair picker for a hypothetical single-entry pool (not reachable today; protects a future catalog trim).
- **[LOW] Docs aligned to behavior:** the first-visit hint is "shows until acknowledged with a tap" (tap-dismiss is deliberate — a PageView-kept-alive neighbour room must not consume its hint before the child arrives); the open-hour comment and the save-state header (v10) corrected.

The review's verdict was **safe to ship behind a founder merge** with no high-severity defects; it independently confirmed migration/save safety, reward idempotency (no double-credit, no double-mint), determinism (no `Random`/`hashCode`/`DateTime.now()` in sim/engines), the anti-FOMO/no-pay-to-win charter, and accessibility (labels + reduced-motion + disposal) all hold.

## 18. Remaining founder decisions

1. **Merge** PR #65 (final-validation), PR #62 (Rive seam), and this program PR #66. (Agent self-merge is blocked by the harness — the same guard that held prior PRs.)
2. **Rive rig commission** (G13) — the drop-in seam is ready and test-pinned; only the `.riv` art is outstanding.
3. **Service provisioning** (G14) — Firebase, RevenueCat, Play Console, signing keys.
4. **iOS** (G15) — macOS runner + Apple account.
5. **Language strategy** (G12) — which locales, before an i18n phase.
6. **Holiday/event content policy** — whether cultural/religious holidays join the nature seasons.
7. **Physical-device install approval** — approve the MIUI USB-install prompt (or accept emulator E2E as the validation of record).

## 19. Remaining legal decisions

- COPPA/GDPR-K counsel review before public release (pre-existing gate, unchanged).
- Rive rig licensing terms (founder ↔ contractor).
- No new legal exposure introduced: all new art/audio is original via the documented pipeline; no expression was copied from the research subjects.

## 20. Remaining paid dependencies

- OpenAI image API (used for asset generation; key present locally, gitignored).
- RevenueCat, Firebase, Play Console, Apple Developer — all founder-provisioned, all still behind inert seams.

## 21. Production-readiness assessment

**For the evolved feature set specifically:** ready to merge behind founder review. Every phase is CI-green, test-covered, coverage-held, perf-checked, Charter-compliant, and migration-safe.

**For public launch overall:** unchanged from the prior audit — still gated on the founder-owned items (Rive rig, live backend/IAP provisioning, iOS, counsel review, store assets). This program deepened the *experience*; it did not (and could not) clear those gates.

## 22. Recommendations

1. Merge #65 → #62 → #66 in that order; each is independently green.
2. Approve the on-device install (or bless emulator E2E) so a physical walkthrough of the evolved build is on record.
3. Commission the Rive rig — it is now the single biggest visible-quality lever, and the seam is ready.
4. When language strategy is set, run an i18n phase — the copy is centralized and Charter-scanned, so extraction is mechanical.
5. Ship ambient-audio pads as a small follow-up once a device is available to hear them.
6. Decide the holiday-content policy so Seasons can optionally gain cultural moments.

---

*This report is evidence-backed and does not overstate progress. Six engineering-owned feature phases are complete and merge-ready; the remaining items are founder-owned by definition.*
