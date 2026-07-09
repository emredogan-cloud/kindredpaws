# MASTER PRODUCT ROADMAP — KindredPaws Product Evolution

> **PROGRAM COMPLETE — historical record.** The E1–E6 program shipped and was superseded by `MASTER_KINDREDPAWS_PRODUCT_ROADMAP.md` (GE-series, also complete). The active execution backlog is **`PRE_RELEASE_REMEDIATION_ROADMAP.md`** (since 2026-07-08); strategic phases/gates remain canonical in `game-os/GAME_MASTER_EXECUTION_ROADMAP.md`.

**Execution authority** for the founder-approved Product Evolution program (supersedes sprint briefs; canon guardrails from `game-os/` remain binding where not explicitly evolved by the founder).
**Baseline:** post-Immersive-Pet-Experience (PR #63, CI green): 8-room home, vector pet on the Rive contract, inventory + Kibble economy, save v7, 522 tests / 91.7 % coverage.
**Benchmark:** My Talking Tom — gameplay/UX/progression patterns only. No assets, code, animations, or protected content are ever copied or extracted.

---

## Part 1 — Gap analysis (KindredPaws today vs premium virtual-pet benchmark)

Method: subsystem-by-subsystem comparison of the current app (validated on emulator 2026-07-02) against the benchmark's product qualities (room loops, juice/feedback, mini games, audio, retention surfaces) *filtered through KindredPaws canon* (cozy, child-safe, never-guilt, no gacha/FOMO, wellbeing ⊥ money, solo-founder asset budget).

### Subsystem status & gaps

| Subsystem | Today | Gap → target | Rank |
|---|---|---|---|
| Home | Complete (hearth, ring, verbs, speech) | streak surface missing; no petting stroke | High |
| Kitchen | Complete (pantry loop) | no eat animation (food → mouth); no audio | High |
| Bathroom | Complete (scrub bath, potty) | no water/audio feedback | Medium |
| Bedroom | Complete (persisted sleep, dreams) | no lullaby/ambient audio | Medium |
| Medical (Care Corner) | Complete (warm wellness) | fine as-is (canon caps depth: no illness) | Low |
| Play Room (Garden) | Toys + affection | **no mini games** (benchmark's core play depth) | **Critical** |
| Wardrobe | Complete (closet/boutique/premium arch.) | more slots/looks later (art-budget bound) | Low |
| Inventory | Complete (v7) | — | — |
| Shop/Economy | Kibble loop complete | daily first-open +50 Kibble (canon §8.1) not implemented; streak-repair surface missing; Heartstones = founder/IAP | High |
| Memory/Heartmind | Complete (bank, callbacks, dreams) | content top-ups are Content-Factory governed | Low |
| Notifications | Complete (local, capped, warm) | — validated | — |
| Widgets | Service + snapshot wired | needs a validation pass (native side) | Medium |
| Achievements | **None** (keepsakes adjacent) | warm Milestone Book (no FOMO, no pressure) | High |
| Mini games | **None** | 2 original no-fail games (see E4) | **Critical** |
| Particle effects | Bath foam, bedroom stars only | hearts/crumbs/confetti/ambient per room | High |
| **Audio** | **None** (no SFX, no ambience) | biggest premium-feel gap; original synthesized SFX + toggles | **Critical** |
| Haptics | **None** (bible requires soft haptics) | soft haptic on every care action + toggle | High |
| Animation | Pet reactions complete; room hops | feed fly-to-mouth, celebration overlays | High |
| Emotional quality | Strong (Heartmind, comfort beats) | celebrations for bond/growth milestones under-staged | High |
| Accessibility | Semantics broadly present | audit pass (48 dp, contrast, TalkBack flow, reduced-motion) | Medium |
| Performance | Budgets green (host); emulator smooth | vector-renderer + particle budgets; release-build smoke | Medium |
| Retention | Streak engine + notifications exist | **no streak UI anywhere**; daily bonus; comeback surfaces | High |
| Content | Launch dialogue bank validated | growth via Content Factory (governed) | Low |
| LiveOps | Kill-switches/experiments seams live | founder-gated activation (Firebase) | Blocked (founder) |
| Progression | Bond/life-stage/affection complete | milestone celebrations (→ E1/E3) | Medium |
| Safety | Test-pinned (never-guilt, no illness…) | keep pinning on all new surfaces | Continuous |
| Store readiness | Metadata + validator exist | release-build smoke in CI-lite (E6); publishing = founder | Medium |
| Compliance | Config + deletion path in data layer | **no user-facing privacy/deletion UI** (Settings) | **Critical** |
| Settings/Profile | **"Coming soon" stubs** | full Settings + Profile (E2) | **Critical** |

### Technical debt (honest)

1. Item art is emoji-sticker based (consistent, but not bespoke) — regenerate/commission when the asset credential/budget lands.
2. Three rooms share the day-room scene with tints (dedicated interiors blocked on `OPENAI_API_KEY`).
3. `RoomHost` PageView rebuilds all live pages on controller notify (fine at 8 rooms; revisit if rooms × complexity grows).
4. Dock icons are Material glyphs, not the bespoke icon set (asset-budget bound).
5. `test/support` gesture helpers duplicate `phoneView` in older room tests (cosmetic).
6. Physical-device numbers (frame trace, battery) pending the MIUI "Install via USB" toggle — validation currently emulator-carried.

### Blocked outside engineering (tracked, not executed)

| Item | Blocker |
|---|---|
| Dedicated room scenes / bespoke item art via GPT | `OPENAI_API_KEY` absent from environment (mission asserts it; verified absent in shell + login shell) |
| Rive rig integration | founder commission/licensing (seam ready, zero-code drop-in) |
| Firebase/RevenueCat/store provisioning, real ads | founder credentials + paid services |
| iOS build/validation | macOS host + Apple account (Linux host) |
| Physical-device validation | MIUI "Install via USB" human toggle |
| Heartstones purchases / premium catalog | founder monetization activation |

---

## Part 2 — Execution phases (engineering-owned)

Sequencing: feel-foundation first (E1 raises the ceiling for everything), then surface completeness + compliance (E2), then depth (E3–E5), then hardening (E6).

**Process per phase (fixed):** implement → `just verify` (format/analyze/content/test incl. goldens) → integration test on Android emulator profile → adversarial review (independent reviewer pass on the diff; findings fixed) → push (CI re-runs on the rolling PR — must be green) → real-device walkthrough → update this roadmap → next phase.
**PR model (documented adaptation):** CI triggers only on PRs targeting `develop`/`main`, and the harness prohibits agent self-merge — so phases land as commit batches on the rolling PR **#63** (each push re-gates CI green); the founder merges once. "Merge automatically if green" is therefore founder-executed; nothing red is ever pushed.

### Phase E1 — Feel & Feedback foundation (audio · haptics · particles · celebrations)
- **Objectives:** the app *sounds* and *feels* alive: original SFX on every interaction, soft haptics, particle joy (hearts/crumbs/sparkles/confetti), staged milestone celebrations (bond-stage & life-stage), user toggles.
- **Architecture:** `AudioService` seam (leaf, Noop default in tests; `audioplayers` impl in prod) + `FeelKit` (haptics + sound facade read by controllers/UI); **synthesized original WAVs** generated by `tool/generate_sfx.dart` (pure sine/noise envelope synthesis — license-clean by construction, ~10 cues, <15 KB each) bundled under `assets/audio/`; `ParticleOverlay` (deterministic CustomPainter bursts, one-shot controllers — settle-safe); `CelebrationOverlay` (bond/growth: confetti + banner + pet `proud` trigger); `PrefsService` (sound/haptics booleans, SharedPreferences).
- **Dependencies:** `audioplayers` (pub, free); nothing founder-gated.
- **Complexity:** M–L. **Risk:** audio plugin behaviour in tests (mitigated: Noop in CI; goldens unaffected).
- **Acceptance:** every care verb + purchase + milestone has sound + haptic + particle response; toggles persist and silence everything; celebrations play once per milestone; `just verify` green; no `pumpAndSettle` regressions.
- **Testing:** unit (FeelKit gating, prefs), widget (toggle → no sound calls; celebration fires once), golden (celebration overlay frame), perf (particle painter budget), integration (verbs still green).
- **DoD:** CI green on push; emulator walkthrough shows audio/haptics/particles; roadmap updated.
- **Founder-only:** none.

### Phase E2 — Settings, Profile & compliance surfaces
- **Objectives:** kill the last "coming soon"s; ship user-facing privacy controls (child-safety posture demands it).
- **Architecture:** `SettingsScreen` (sound/haptics via PrefsService; notifications toggle wired to scheduler; privacy: **delete my data** → existing `SaveRepository.deleteAccount` flow with double-confirm + farewell copy; about/licenses); `ProfileScreen` (vector pet portrait, name/species/stage, bond tier + progress, care streak + warmth freezes, Gotcha Day, active days); drawer entries wired.
- **Dependencies:** E1 (PrefsService). **Complexity:** M. **Risk:** deletion flow correctness (guarded by existing account-deletion tests + new widget tests).
- **Acceptance:** all drawer items functional; deletion returns to Rescue Day with identifiers reset; toggles round-trip; a11y labels on every control.
- **Testing:** widget (toggles, deletion confirm flow, profile facts), unit (prefs), golden (both screens), integration (delete → re-onboard).
- **DoD:** CI green; emulator walkthrough; roadmap updated. **Founder-only:** none.

### Phase E3 — Retention & progression surfaces
- **Objectives:** the caring rhythm becomes visible and rewarding — never punitive.
- **Architecture:** daily first-open **+50 Kibble** in `resolveOnResume` (canon §8.1) with warm message; Home streak chip (count + Streak Warmth freezes, soft copy); streak-repair offer (100 Kibble, once per lapse — canon) surfaced only post-lapse; **Milestone Book** on Profile (derived, warm: first bath/meal/play, streak 3/7/30, bond stages, growth, best-friend toy) — read-only celebrations, no checklists/pressure.
- **Dependencies:** E1 (celebration/sfx), E2 (Profile). **Complexity:** M. **Risk:** economy inflation (+50/day is canon; sinks already priced for it).
- **Acceptance:** new-day open grants +50 with message; streak visible + freeze states honest; milestones appear once, celebrate via E1; no guilt copy anywhere (test-pinned).
- **Testing:** sim unit (daily bonus, idempotent per day), widget (chip states, book), integration (multi-day clock walk).
- **DoD:** CI green; emulator walkthrough; roadmap updated. **Founder-only:** none.

### Phase E4 — Mini games (Play Garden arcade)
- **Objectives:** the benchmark's play depth, KindredPaws-shaped: short, no-fail, warm.
- **Architecture:** two original games behind `MiniGame` cards in the Play Garden, each a **pure-Dart deterministic engine** (tick(state, input) → state; injectable RNG seed) + thin painter UI: **“Bounce!”** (keep the ball happily in the air — taps bounce it; pet tracks and reacts; session ends by gentle timer, never by "failure") and **“Snack Catch”** (drag the basket; every catch delights; misses are simply "the birds got one 🐦" — no penalty). Rewards: small Kibble drip (capped/session, diminishing — no farming), happiness up, energy cost via the play verb.
- **Dependencies:** E1 (sfx/particles). **Complexity:** L. **Risk:** determinism in tests (seeded RNG, fixed-tick engines).
- **Acceptance:** both games playable, no fail state, rewards capped, pet reacts (playful/excited), quits cleanly mid-game; engines 100 % unit-covered.
- **Testing:** engine unit suites (physics/spawn/reward caps), widget (launch/play/quit), integration (a full game on emulator), perf (painter budget).
- **DoD:** CI green; emulator walkthrough; roadmap updated. **Founder-only:** none.

### Phase E5 — Living-pet polish
- **Objectives:** the pet feels touchable and the world breathes.
- **Architecture:** petting **stroke** gesture on `PetStage`/Home pet (pan → `comfortPet` with throttle + heart trail + `affectionate`); feed **fly-to-mouth** animation (item sticker arcs from card to pet, munch pop + crumbs); per-room **ambient particles** (garden butterflies/leaves, kitchen steam wisp, bedroom fireflies — deterministic, `continuousMotion`-gated); reduced-motion: `MediaQuery.disableAnimations` ⇒ static idle + no ambient particles; widget snapshot validation on emulator.
- **Dependencies:** E1. **Complexity:** M. **Risk:** gesture arena vs PageView (already solved pattern from the bath scrub).
- **Acceptance:** stroking produces hearts + tiny capped bond; feeding animates food to mouth; ambience per room; `disableAnimations` honoured (test-pinned); widget shows current mood.
- **Testing:** widget (stroke → comfort called ≤ throttle; fly animation settles), golden (ambient off in goldens), integration walkthrough.
- **DoD:** CI green; emulator walkthrough; roadmap updated. **Founder-only:** none.

### Phase E6 — Performance, accessibility & release hardening
- **Objectives:** premium doesn't jank, excludes no one, and release-builds clean.
- **Architecture/steps:** a11y audit + fixes (≥48 dp targets, semantics on all new controls, contrast on chips over scenes, TalkBack walkthrough on emulator); perf: extend budgets to vector renderer + particles + mini-game painters (host suite), `flutter build apk --release` smoke (tree-shake/proguard sanity) added to the phase gate; golden set expansion (settings/profile/celebration/mini-games); full-home emulator E2E rerun + walkthrough; physical-device rerun if MIUI toggle enabled by then.
- **Complexity:** M. **Risk:** release build surfacing debug-only assumptions (that's the point).
- **Acceptance:** zero a11y violations from the audit checklist; release APK builds + boots on emulator; all budgets green; goldens complete.
- **Testing:** the full pyramid + release smoke + E2E.
- **DoD:** CI green; roadmap updated; validation artifacts stored. **Founder-only:** physical phone toggle (if still blocked, documented).

### Phase E7 — Close-out
- `MASTER_PRODUCT_EXECUTION_REPORT.md` (all mission sections, evidence only) → final output line per mission (`PRODUCT EVOLUTION COMPLETE` if E1–E6 land clean; otherwise `WAITING FOR FOUNDER ACTION` with the precise blocker list).

---

## Part 3 — Progress ledger

| Phase | Status | Evidence |
|---|---|---|
| Baseline (rooms program) | ✅ Complete | PR #63 CI 9/9 green; IMMERSIVE_PET_EXPERIENCE_REPORT.md |
| E1 Feel & Feedback | ✅ Complete | a594c3b (+review fixes in E3 commit); adversarial review: 1 High (stale-burst replay) found & fixed, copy + same-tick-bond fixes applied |
| E2 Settings/Profile/Compliance | ✅ Complete | 8df8f39 — Settings (toggles, right-to-be-forgotten), Our story profile, drawer complete |
| E3 Retention surfaces | ✅ Complete | daily +50 Kibble (§8.1), streak chip + Warmth, one-time Streak Repair (§11.2), Milestone Book |
| E4 Mini games | ✅ Complete | d37794f — Bounce! + Snack Catch (no-fail engines, capped treat rewards, sleeping-pet hush) |
| E5 Living-pet polish | ✅ Complete | a0d795a/18e009b — stroke-to-pet cuddles, shelf-to-snoot meal flight, reduced-motion a11y |
| E6 Hardening | ✅ Complete | release APK builds (122.5MB; concurrent-Gradle race documented); Settings/Profile goldens; emulator E2E PASS on full evolution build; kitten-species walkthrough (Settings/Profile/games live); 0 crashes/ANRs; CI green |
| E7 Master report | ✅ Complete | MASTER_PRODUCT_EXECUTION_REPORT.md |

*Updated at every phase boundary. Never allowed to drift.*
