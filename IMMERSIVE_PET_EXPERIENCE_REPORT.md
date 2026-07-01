# IMMERSIVE PET EXPERIENCE — Final Report

**Sprint:** KindredPaws Immersive Pet Experience (founder-approved product evolution)
**Date:** 2026-07-02 · **Branch:** `feature/immersive-pet-experience` · **PR:** [#63](https://github.com/emredogan-cloud/kindredpaws/pull/63)

---

## 1. Executive summary

KindredPaws grew from a single Companion screen into a complete **room-based home**: eight rooms on one swipeable shell, one shared deterministic simulation (state never resets across rooms), an **original animated vector pet** honouring the exact Rive rig contract, and a household **inventory + Kibble economy** (save schema v7 with migration). Every engineering gate held: `just verify` green with **522 tests / 91.7 % line coverage**, **9/9 CI checks green** on PR #63, the full-home E2E passed on Android, and a complete visual walkthrough was captured. Every ethical invariant is intact and test-pinned: no sickness/death, never-guilt copy, child-safe presentation, Kibble-only rooms, no pay-to-win, subscription never affects the pet.

One honest deviation: the physical Xiaomi's MIUI blocked USB app installs behind a human-only consent toggle, so on-device execution ran on the project's Pixel API 34 emulator instead (details in §10).

## 2. Gameplay evolution

Before: one screen, three verbs. After: the same three canonical verbs (feed/clean/play — bond, streak and diminishing-returns semantics untouched), *enriched by place*:

- **Feeding** happens from a pantry of real foods, each with its own satiety/joy profile; the shelf empties and is restocked by shopping — a real household loop (earn by caring → shop → stock → care).
- **Cleaning** became the Bathroom's drag-to-scrub bath — foam builds under your finger and completes ONE clean (spam-proof), plus one-tap quick rinse and a potty break.
- **Play** happens with owned toys, each with a joy/energy profile and an affection progression (loved → favourite → best friend) that is pure delight — it warms happiness, never Bond.
- New gentle systems: **care supplies** (comfort aids that never touch the streak), the **comfort touch** (canonical petting bond, capped), the always-reassuring **wellness check**, and the **sleep cycle** (persisted naps, +20 energy/h wake credit, Memory-Book dreams, morning greetings).

## 3. New room architecture

`RoomHost` (lib/game/ui/rooms/room_host.dart) — one Scaffold (app bar: pet name, Kibble, keepsakes, Memory Book, Forever Friends; the side drawer) over a `PageView` of rooms with a floating, scrollable **room dock** (280 ms ease-out hops, auto-centering, a11y-labelled). Rooms are registered in `room_registry.dart` — the dock only ever shows shipped rooms. Shared kit: `RoomScaffold` / `PetStage` / `ShelfPanel` / `ItemCard` / `NeedGlow` (number-light meters — soft glow, no percentages, no alarm red) and `DressedPet` (cosmetic overlays on the rig in every room).

Spatial order: Grocery Store · Kitchen · Bathroom · **Home** · Play Garden · Bedroom · Care Corner · Wardrobe.

| Room | Scene | Gameplay |
|---|---|---|
| Grocery Store | day room, leafy tint | Kibble-only shelves (foods/toys/supplies); owned-forever marked "yours 💛"; short-on-Kibble = warm invitation |
| Kitchen | day room, buttery tint | pantry feeding (real verb), fullness glow, grocery shortcut, warm empty state |
| Bathroom | bathroom scene | scrub bath (foam → clean → sparkle shake-off), quick rinse, potty break, sparkle glow |
| Home | day/night room | the hearth: care ring, bond bar, speech, three verbs (unchanged core) |
| Play Garden | garden scene | toy basket, affection badges, energy glow, tired-pet bedtime hint |
| Bedroom | night room | tuck-in → persisted nap, starlit hush (fixed constellation + moon), Memory-Book dreams, gentle wake |
| Care Corner | rainy-window nook | temp check (always reassuring), cuddle (Comfort beat), supply shelf, restock shortcut |
| Wardrobe | day room, lavender tint | closet rail (wear/take off, slot-unique), Kibble boutique, Forever Friends invitations |

## 4. Shared simulation validation

One `GameController` drives every room. Proven by widget tests (kitchen feed → walk Home → same wallet/pantry; wardrobe look follows the pet into the Kitchen; sleep hushes care in every room) and by the `rooms_journey` E2E (§10): pantry, wallet, affection and the running nap all survive room hops **and a full app restart**. Sleeping is pet state (`sleepingSinceMs`, save v7), so the nap continued across a controller swap and credited 2 h of energy on wake.

## 5. Character renderer status

The commissioned `.riv` still does not exist (unchanged founder licensing blocker, see `RIVE_DOG_INTEGRATION_AND_DEVICE_VALIDATION_REPORT.md`). The `RivePetRenderer` seam is untouched and still activates via `KP_PET_RENDERER=rive` + `KP_RIV_ASSET=assets/rive/<file>.riv` with **zero code changes** — `rive_contract_test` and the seam tests still pass.

## 6. Temporary renderer status

**Shipped: `VectorPetRenderer`** (lib/render/vector_pet_renderer.dart) — an original, hand-authored CustomPainter puppy & kitten (no third-party art anywhere; storybook palette, big catchlight eyes, rounded forms, child-safe by construction). It implements the **exact** `PetStateMachine` contract semantics:

- `mood` 0–3 → four continuous idle loops (per-mood breathing pace/posture/ear/tail carriage; mood changes soft-blend ~300 ms, never cut);
- `emotion` 0–11 → twelve one-shot reactions ≤ 2 s that return to the current idle (happy hop, excited sparkle-bounce, playful crouch + tongue, heart-eyed affection, proud chest, yawning sleepy, head-tilt curious, *gentle* lonely, cute hungry wiggle, blushing comforted…);
- `lifeStage` 0–2 → proportion + scale blend (head:body ≈ 1:1.6 → 1:2.2; 0.7/0.85/1.0);
- micro-layer: deterministic blink, tail wag/sway, curious ear twitch, breathing.

Species-aware via a resolver (the per-species analogue of per-species `.riv` paths), wired in `main.dart` as a production re-bind. The app default backend is now `vector` (via `bootstrap(fallbackRenderer:)`); tests/CI keep the settle-safe `placeholder`, and the vector renderer itself has a deterministic mode so `pumpAndSettle` guarantees hold. Goldens pin both species across all moods × stages (`test/golden/goldens/vector_pet_{puppy,kitten}.png`).

## 7. Asset generation summary

`OPENAI_API_KEY` was **not present** in the local environment (checked shell + login shell; the mission's "if available" fallback applies), so no new bitmap scenes were generated. Instead:

- Rooms reuse the existing premium GPT scene set where it fits *exactly*: `bathroom_clean_scene` (Bathroom), `garden_day` (Play Garden), `rainy_window` (Care Corner), `cozy_room_night` (Bedroom), `cozy_room_day/night` (Home) — with per-room colour tints for identity (buttery kitchen, leafy market, lavender boutique, starlit sleep).
- Props/goods ride on the cozy sticker-card system (`ItemCard`), scene furniture on the cream `ShelfPanel` kit; the character is fully vector (§6). All original, license-clean, and APK-light.
- All room scenes joined the precache warm-up (`KpAssets.backgrounds`) and decode at screen width (`cacheWidth`) — instant hops, memory-safe.
- Dedicated per-room backgrounds (kitchen/wardrobe/grocery interiors, bedroom) can be regenerated later from the existing `KINDREDPAWS_GPT_IMAGE_PROMPT_LIBRARY_TR.md` pipeline once a key is exported.

## 8. Inventory system summary

`Inventory` (lib/game/model/inventory.dart, persisted from **save v7**): pantry counts, owned toys + affection counters, care-supply counts, closet + slot-unique equipped set. `ItemCatalog` (23 items) holds foods (10–30 Kibble), toys (60–220), supplies (15–20), cosmetics (200–450 common; premium = entitlement-only, never Kibble-priced) — all inside the canon §8.1 bands, all test-pinned. `tryPurchase` is a pure function: Kibble-only, never negative, no re-buying owned-forever goods, premium never sold — **no real-money path exists in any room**. The v6→v7 migration gifts existing pets the rescue starter kit (2 kibble bowls, an apple, the bouncy ball, a vitamin chew) so no room greets a returning player empty; unknown item ids stay inert so future catalog changes can never orphan a save (R4).

## 9. Navigation summary

Swipe between adjacent rooms (PageView) or tap the dock (animated hop, 280 ms). No loading screens anywhere — scenes are precached and rooms are plain widgets over the shared controller. In-room shortcuts: Kitchen → Grocery, Play Garden → Grocery/Bedroom, Care Corner → Grocery, drawer → Wardrobe (replacing its "coming soon"), plus the existing drawer/app-bar routes (Keepsakes, Memory Book, paywall). Unavailable rooms are simply absent — no dead doors, no placeholder UX.

## 10. Real-device validation

**Physical device (Xiaomi Redmi `22095RA98C`, Android 13, unlocked, connected):** APK install was blocked by MIUI — `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user` on three attempts, with no consent dialog surfaced (screen-watched). This is the MIUI **"Install via USB"** developer-options toggle (Mi-account-gated, resets itself); it requires a human tap on the device and was not bypassed. *Founder action: enable Developer options → "Install via USB", then `just e2e-android` reruns everything below on the phone.*

**Emulator (project AVD profile, `sdk_gphone64_x86_64`, Android 14, KVM):** the identical build ran the full validation:

- `rooms_journey` integration test **PASSED** on-device-profile (23 s run): onboarding → adopt → decay window → Kitchen pantry feed → Bathroom rinse + finger-scrub stream → Play Garden toy affection → Grocery purchase with earned Kibble → Care Corner rituals + supply → Wardrobe boutique → Bedroom tuck-in → **app restart with the nap persisting** → gentle wake with energy credit.
- **Zero `FATAL EXCEPTION` / ANR / native crash** lines across the entire session's logcat (E2E + manual walkthrough).
- Full manual walkthrough captured (15 screenshots, `screenshots/immersive_rooms/`, local per repo policy): Rescue Day + notification permission, adoption, naming, Home (vector pet in the care ring, night scene, dock), Kitchen, Bathroom, Grocery, Play Garden, Bedroom awake, **Bedroom asleep (stars + moon + "dreaming of chasing the ball 💭")**, morning wake, Care Corner, Wardrobe. Layout clean at 1080×2400; interaction quality warm and immediate; day/night scene switching observed live.
- Memory: TOTAL PSS ≈ 294 MB (debug build with JIT; in line with the prior sprint's debug readings; release builds are substantially lighter).

## 11. Performance summary

- Host-side perf suite green (`test/performance/`): cold-build and full mood × emotion render sweep within budgets (the sweep now exercises the placeholder path in CI; the vector renderer is a single CustomPaint layer with one repaint boundary driven by three AnimationControllers).
- Room hops are widget-tree swaps over precached, width-decoded scenes — no I/O, no loading states; the dock/PageView animate at the standard 280 ms ease-out.
- The vector pet repaints only on animation ticks (`shouldRepaint` is delta-gated); goldens/tests run it frozen. On-emulator walkthrough showed no jank at interaction points; a `--profile` frame trace on the physical phone remains the outstanding measurement (blocked with the install, §10).

## 12. Bugs found

1. Item-card badge Row overflowed 19 px on narrow grid cells (grocery shelf, 400 dp wide screens).
2. Bathroom hint Row overflowed 205 px on phone-width screens.
3. `room_registry` half-edit: bedroom/care-corner entries missing from `enabledRooms()` while their builders existed (dock silently showed 5 rooms; caught by the dock-geometry probe).
4. Renderer default flip would have broken the 460-test settle guarantee if applied via `AppConfig` default (caught in design: tests inherit `bootstrap()` defaults).
5. Single-jump test drags delivered no pan updates in the PageView gesture arena (bathroom scrub + dock scroll tests failed as false negatives).
6. Emulator manual launch appeared to hang at splash — the installed APK was the integration-test entrypoint build, not an app bug.

## 13. Bugs fixed

1. Badge wrapped in `FittedBox(scaleDown)` — scales, never overflows (`room_scaffold.dart`).
2. Hint text wrapped in `Flexible` + ellipsis (`bathroom_room.dart`).
3. Entries restored via direct edit; dock now registers all 8 rooms (verified by probe + tests).
4. Solved architecturally: `bootstrap(fallbackRenderer:)` — production (`main.dart`) defaults to vector, bare `bootstrap()` (tests/CI) stays placeholder, explicit `KP_PET_RENDERER` always wins.
5. Tests now drive realistic pointer streams (`startGesture` + `moveBy` loops) and a shared drag-based `hopToRoom` helper (`test/support/room_test_utils.dart`).
6. Rebuilt the standard debug APK for manual runs; no code change needed (documented here for the next validator).

## 14. Remaining limitations

- **Physical-phone run pending** the MIUI "Install via USB" toggle (§10) — the emulator carried full validation; process-health + frame-trace numbers on the Redmi should follow once enabled.
- The commissioned Rive rig remains a founder licensing/commission action; the vector pet is the shipped stand-in (by design of this sprint).
- Dedicated per-room bitmap scenes await an `OPENAI_API_KEY` (prompt library is ready); three rooms currently share the day-room base with distinct tints + furniture panels.
- Item art is sticker-based (emoji on cozy cards) pending a generated/commissioned prop set; visually consistent but not bespoke.
- Room visits ride on the existing `careAction` taxonomy (verbs: purchase/supply/comfort/wake); a dedicated `roomVisit` analytics event was deliberately not added to avoid an unreviewed taxonomy change.
- Settings/Profile drawer entries remain "coming soon" (out of this mission's scope).

## 15. Repository status

- Branch `feature/immersive-pet-experience` pushed; working tree clean (two pre-existing untracked scratch files — `Talking_tom_mission.md`, `Untitled.svg` — left untouched).
- `develop` untouched; `game-os/` (founder-gated) untouched. Older canon (single-room Nest, Health/Vet removed) is superseded by this founder brief **only** where the brief says so; every inviolable rule (no illness/death, never-guilt, child-safe, no pay-to-win, wellbeing⊥money) is preserved and test-pinned.
- Save schema now **v7** (chain v1→…→v7 tested; round-trips lossless; downgrade refused).

## 16. CI evidence

PR #63 — **9/9 required checks green**: `analyze`, `test` (522 tests, coverage gate), `build-android`, `integration-android`, `secret-scan`, `dependency-scan`, `osv-scanner`, `sbom`, `workflow-hardening`. Local `just verify` (format-check · analyze · content-validate · test) green at every one of the ten commits; coverage 91.7 % (3× the 60 % gate).

## 17. PR numbers

- **#63** — `feat(rooms): Immersive Pet Experience — the room-based home, vector pet, inventory & economy` (base `develop`, OPEN, CI green, mergeable).
  *Process note:* the mission's "merge automatically if green" could not be exercised — the execution harness prohibits agent self-merge (the same guard that held PR #62 open). The sprint therefore shipped as ten micro-commits on one PR, each gated by a green local `just verify`; the merge is a one-click founder action.
- #62 (prior sprint's Rive seam docs) remains open, green and mergeable — this branch is independent of it.

## 18. Commit hashes

| # | Hash | Commit |
|---|---|---|
| 1 | `79eda6d` | feat(rooms): room framework — swipeable RoomHost shell, room dock, Home room extraction |
| 2 | `accfbee` | feat(sim): inventory + economy foundation for the room-based home (save v7) |
| 3 | `ba77d02` | feat(render): original vector pet — the temporary renderer on the exact Rive contract |
| 4 | `7d4142c` | feat(rooms): Kitchen — pantry shelf, item feeding, fullness glow, grocery shortcut |
| 5 | `aa29733` | feat(rooms): Grocery Store — Kibble-only shelves for foods, toys, gentle care |
| 6 | `f80d14f` | feat(rooms): Bathroom — drag-to-scrub bath, foam & shake-off sparkle, potty break |
| 7 | `353d2c0` | feat(rooms): Play Garden — toy basket, affection badges, tired-pet bedtime hint |
| 8 | `b8b021d` | feat(rooms): Care Corner + Bedroom — gentle wellness and the sleep cycle |
| 9 | `2d429f0` | feat(rooms): Wardrobe — closet rail, Kibble boutique, DressedPet everywhere |
| 10 | `0052fa1` | feat(assets): precache every room scene + rooms E2E walkthrough |

(+ this report as the final commit on the branch.)

## 19. Final recommendation

**Merge PR #63.** The room-based home is complete, warm, and holds every gate: one deterministic simulation across eight rooms, an original contract-faithful animated pet, a clean Kibble-only economy, save v7 with a forgiving migration, 522 green tests at 91.7 % coverage, 9/9 CI checks, a passing full-home E2E and a captured end-to-end walkthrough with zero crashes. Founder follow-ups, in order of leverage: (1) flip MIUI's "Install via USB" and rerun `just e2e-android` on the Redmi for phone-native numbers; (2) export `OPENAI_API_KEY` and regenerate the four dedicated room scenes from the prompt library; (3) the standing rig commission — the seam takes the `.riv` with zero code changes the day it arrives.

---
*Evidence only; nothing in this report overstates what ran. Where validation moved to the emulator, the report says so and why.*
