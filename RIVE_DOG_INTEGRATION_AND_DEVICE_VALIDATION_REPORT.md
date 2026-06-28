# Rive Dog Integration & Real-Device Validation Report

**Sprint:** KindredPaws — Rive Dog Integration & Real Device Validation
**Date:** 2026-06-28
**Repo:** `emredogan-cloud/kindredpaws`
**Branch / PR:** `feature/rive-dog-integration-seam` → **PR #62** (open, green, mergeable)
**Scope guard:** This was **not** a gameplay phase. No new gameplay systems were
added. Work was limited to the Rive runtime seam, the canonical asset drop-in
location, home-screen character-area validation, and on-device validation.

> Evidence policy: every claim below is backed by a command output, a screenshot,
> a test result, or a code reference. Where something could **not** be verified
> (e.g. PIN-locked device, paid export), it is stated plainly as a limitation
> rather than glossed over.

---

## 1. Executive summary

The interactive-dog Rive mascot **cannot be shipped yet**, for one decisive
reason that is **not** an engineering gap: the supplied reference is a Rive
**editor** link, and exporting a runtime `.riv` from the Rive editor requires a
**paid plan** (Cadet, $9/seat/mo) — which matches the founder's report that "the
editor requests an upgrade." No `.riv` file exists in the repo, and obtaining one
by bypassing the paywall is explicitly out of bounds. So this sprint did the next
best, fully-honest thing:

1. **Investigated** the asset/licensing/download situation and documented the
   exact founder action required (§2–§5).
2. **Confirmed the runtime integration seam is already production-grade** and
   pinned by tests — the rig will drop in with **zero code changes** (§6–§7).
3. **Made the founder's canonical drop-in path real**: `assets/rive/` is now a
   bundled asset directory, so `assets/rive/interactive_dog.riv` will be picked up
   the instant it is supplied (PR #62).
4. **Validated the home-screen character area** and ran the app **on a real
   Android device** plus an emulator, with screenshots, logcat, and performance
   numbers (§8–§11).
5. Found **no app-code bugs** (§12–§13). The one error seen — an ARM64 APK
   refusing to load on an x86_64 emulator — is an ABI/packaging mismatch, not a
   defect; building for the right ABI resolves it.

**Bottom line:** Engineering is **done and green**; the only blocker is a
**business/licensing action by the founder** to obtain a license-clean `.riv`
(§5, §14). CI is 9/9 green on PR #62.

---

## 2. Rive asset investigation findings

**Supplied reference:**
`https://editor.rive.app/file/interactive-dog-mascot-for-mobile-apps-rive-state-machine/2393358`

Findings:

- The URL is an **`editor.rive.app/file/...` link** — i.e. an **in-editor file
  view**, not a `rive.app/community/...` public listing. Opened unauthenticated,
  it returns only the editor's JavaScript shell (title "Rive — Editor"); the
  file's owner, license, and contents are **not publicly exposed**. The asset is
  therefore **not demonstrably public**.
- The Rive **editor and runtimes are free to use**, but producing a **runtime
  `.riv`** (the binary the app loads) is an **Export** action that is **gated
  behind a paid plan** (see §3). This is consistent with the founder seeing an
  upgrade prompt on download.
- I did **not** attempt to bypass, scrape, reverse-engineer, or automate around
  the paywall, per the sprint's explicit rules and Rive's Terms of Service. Once
  it was clear the file could not be obtained legitimately on a free plan, I
  **stopped trying to obtain it** and proceeded with preparation + validation.

---

## 3. Licensing findings

- **Rive pricing** (rive.app/pricing, observed 2026-06):
  | Plan | Price | `.riv` runtime export? |
  |---|---|---|
  | Free | $0 | **No** |
  | **Cadet** | **$9/seat/mo** | **Yes — first tier that can export `.riv`** |
  | Voyager | $32/seat/mo | Yes |
  | Enterprise | $120/seat/mo | Yes |
- **Editor file (the supplied link):** exporting its `.riv` requires the owner's
  account to be on **Cadet or higher**. There is no free, ToS-compliant way to
  pull a `.riv` out of someone else's editor file.
- **Rive Community files** are licensed **CC BY** — commercial use is permitted
  **with attribution**. Some community listings expose a direct `.riv` download
  without an upgrade. **However**, the supplied link is an *editor* view, so it
  **cannot be confirmed** to be that same freely-downloadable community listing.
- **Project policy (decisive, overrides the above):**
  `KINDREDPAWS_RIVE_CHARACTER_MASTER_BIBLE_TR.md` §3.2/§3.3 requires the **core
  shipped mascot to be original / drawn from scratch**. Community rigs may be used
  **only** as a temporary placeholder or reference, **never** as the shipped pet
  (brand identity + derivative-work risk). So even a free CC-BY dog rig would
  **not** be a valid *shipped* Biscuit — it could only ever be a placeholder.

**Net:** the license-clean path for the *shipped* mascot is an **original rig**
the founder owns (commissioned work-for-hire, or self-authored and exported from a
paid Rive seat). Any third-party community rig is placeholder-only and must be
credited in `assets/CREDITS.md`.

---

## 4. Download availability findings

| Question | Answer | Basis |
|---|---|---|
| Is the asset public? | **Not demonstrably.** It is an editor file view, not a public community page. | §2 |
| Downloadable on a free plan? | **No.** Runtime `.riv` export is paid (Cadet+). | §3 |
| Is download restricted? | **Yes** — by Rive plan gating on the owning account. | §3 |
| Is purchase/subscription required? | **Yes** — Cadet ($9/mo) is the minimum to export `.riv`. | §3 |
| Officially supported export path? | **Yes:** Rive Editor → **Export → Download for runtime (`.riv`)**, available on **Cadet+**. | rive.app docs/pricing |

The `.riv` was **not** obtained. No `interactive_dog.riv` exists in the repo
(`assets/rive/` is bundled but currently empty of rigs). This is by design, not
omission — see §5.

---

## 5. Required founder actions

Pick **one** (in order of recommendation):

1. **Commission an original rig (preferred, license-clean for shipping).**
   Hand `docs/RIVE_CONTRACTOR_HANDOFF.md` to a Rive artist. It specifies the exact
   `PetStateMachine` contract (§7). Deliverables: `interactive_dog.riv` (or
   `biscuit.riv` / `mochi.riv`) satisfying the contract, **< 400 KB**, 60 fps.
   Drop into `assets/rive/` → ships with zero code change.
2. **Upgrade the Rive account to Cadet ($9/mo) and export your own rig.** Only
   valid for shipping if the rig is **original to you** (not someone else's editor
   file). Then Export → Download for runtime → place at
   `assets/rive/interactive_dog.riv`.
3. **Placeholder-only (non-shipping):** download a **CC-BY community** dog `.riv`
   from its **community page** (no upgrade needed), place it at
   `assets/rive/interactive_dog.riv`, and **record the author + URL in
   `assets/CREDITS.md`**. Per bible §3.2/§3.3 this may be used only for
   demo/placeholder, never as the released mascot.

After any of the above, activation is:

```sh
flutter run \
  --dart-define=KP_PET_RENDERER=rive \
  --dart-define=KP_RIV_ASSET=assets/rive/interactive_dog.riv
```

No further pubspec or Dart changes are required.

---

## 6. Runtime integration status

**Status: prepared, production-grade, test-pinned — waiting only on the `.riv`.**

- **rive package:** `^0.13.0`, resolving to **0.13.20** (pinned deliberately;
  0.14.x changes native-artifact handling). `flutter: 3.41.9 stable`.
- **Renderer architecture:** a clean abstraction seam (`lib/render/pet_renderer.dart`
  defines the `PetRenderer` interface; `pet_renderer_factory.dart` selects a
  backend). Two backends exist:
  - `PlaceholderPetRenderer` (default, `KP_PET_RENDERER=placeholder`).
  - `RivePetRenderer` (`lib/render/rive_pet_renderer.dart`, `KP_PET_RENDERER=rive`).
- **Lifecycle & dispose (verified in code):** `_RiveRig` is a `StatefulWidget`:
  - `initState` → `_load`: `RiveFile.asset(assetPath)` → `mainArtboard` →
    `StateMachineController.fromArtboard(artboard, 'PetStateMachine')` →
    `findInput<double>` ×3 → `addController` → `_apply`.
  - `didUpdateWidget` → re-drives inputs reactively when mood / emotion /
    lifeStage change (the reactive contract).
  - `dispose` → `smc.dispose()` (controller released; no leak).
- **Graceful degradation (verified):** any failure — asset missing, state machine
  missing, an input misnamed, or a parse error — falls back to a deterministic,
  native-free **stand-in** and emits a `rive_*` diagnostic
  (`rive_load_failed` / `rive_state_machine_missing` / `rive_inputs_missing`),
  and on success records a `rive_loaded{asset, ms}` perf signal. **It never
  crashes play.** This is why the app runs today with no `.riv` present.
- **Build-time wiring:** `lib/core/app_config.dart` reads `KP_PET_RENDERER`
  (`placeholder` | `rive`) and `KP_RIV_ASSET` (path) via `String.fromEnvironment`,
  so the backend and asset path are chosen at build time with **no code edits**.
- **PR #62 change:** added `assets/rive/` to `pubspec.yaml` assets and created
  `assets/rive/README.md`. Previously only `assets/rigs/` was bundled; now the
  **founder-canonical** `assets/rive/interactive_dog.riv` path works as a literal
  drop-in. A regression test pins this exact path to graceful fallback so the seam
  can never silently stop honoring it.

**Reconciliation — sprint "expected inputs" vs. canonical code.** The sprint brief
listed mood {joyful, content, sleepy, curious, lonely}, needs {hunger, hygiene,
fun}, interactions {feed, clean, play, pet}, lifecycle {idle, celebrate, greeting,
sleeping}. The canonical, code-pinned contract (the SSOT) expresses all of these
as **3 numeric inputs**:

- The brief's `sleepy` / `curious` / `lonely` are **emotions** (indices 7 / 8 / 9
  of the 12-emotion enum), not separate moods.
- `greeting` / `celebrate` / `sleeping` are **triggered emotion uses** (happy /
  excited / proud / sleepy) per bible §6.4, not distinct inputs.
- `hunger` / `hygiene` / `fun` are **CareMeters** that *drive* mood/emotion; they
  are gameplay state, not state-machine inputs.

The code is the single source of truth; the brief's list is a human-readable
**superset description** of the same behavior. Full mapping in §7.

---

## 7. State machine contract

One state machine, **`PetStateMachine`**, with **three `number` inputs**
(pinned by `test/.../rive_pet_renderer_test.dart` and the contract test):

| Input | Range | Meaning | Code mapping |
|---|---|---|---|
| `mood` | 0–3 | `PetMood.index` — joyful / content / wistful / low | `riveMoodValue(mood) = mood.index` |
| `lifeStage` | 0–2 | pupKit / youngOne / grown (render scale 0.7 / 0.85 / 1.0) | `riveLifeStageValue('pupKit'\|'youngOne'\|'grown')` |
| `emotion` | 0–11 | `PetEmotion.index` — the 12 emotion motions | `riveEmotionValue(emotion) = emotion.index` |

The 12 emotions (enum order, index 0–11): happy, excited, playful, affectionate,
content, proud, calm, sleepy, curious, lonely, hungry, comforted.

Rig authoring expectations (for the contractor): a **per-mood idle loop** (4) plus
a **one-shot reaction state per emotion** (12, each < 2 s, returning to the mood
idle). Expression is via **authored parameters** (eyes / mouth / ears / tail /
blush), **never new art per emotion** — data, not frames (cost lever R7).
`lifeStage` is a bone-scale blend, not per-stage meshes. Full spec:
`docs/RIVE_CONTRACTOR_HANDOFF.md`.

**Game → render mapping** (`lib/game/ui/mood_visuals.dart`):
`petMoodFor(...)`, `petEmotionForReaction(...)` (feed → happy/comforted,
clean → proud, play → playful), `currentPetEmotion(...)` (last reaction → ambient
nudge → resting emotion for the mood).

---

## 8. Home screen integration status

**Status: validated, production-ready.** Source: `lib/game/ui/companion_home_screen.dart`.

Layout: `CozyBackground` (scene by time of day) + `Stack` [160 px top scrim] +
`SafeArea` → `Column`:
- bond bar (`💖 <tier> next: <next>`)
- optional `_SpeechBubble` (above the pet)
- `Expanded` → `LayoutBuilder` → `Align(0, 0.35)` → `GestureDetector`
  (`controller.nudgeAmbient`) → `CareRing(size: maxHeight.clamp(0, 232))` →
  `rig.build(mood, lifeStage, emotion)`
- mood chip, feedback chip, verb bar (Feed / Clean / Play)

Validation against the sprint checklist:

| Criterion | Result | Evidence |
|---|---|---|
| Safe areas | ✅ | `SafeArea` + 160 px scrim behind the translucent app bar |
| Scaling | ✅ | pet box = `size(160) × lifeStageScale`; `CareRing`'s `Center` gives loose constraints so the pet is clamped to `min(160·scale, ringSize)` |
| Aspect ratio | ✅ | square render box; no distortion |
| Responsiveness | ✅ | `LayoutBuilder` + `clamp` → no overflow/clip on short screens (a 360×740 regression test exists) |
| Hero positioning | ✅ | `Align(0, 0.35)` keeps the pet the centered emotional anchor, seated on the knitted bed |
| Speech bubble | ✅ | rendered above the pet, no overlap (screenshots 09/11) |
| Button overlap | ✅ | verb bar sits below the bounded `Expanded`; no overlap with pet or chips |

The dog remains the **emotional center** of the screen in every captured frame.
**Minor cosmetic note (not a bug, out of scope):** the pet box is a fixed 160
logical px and does not scale *up* on large tablets — purely aesthetic; tracked as
a low-priority future polish item, not addressed here to honor "no new systems."

---

## 9. Device validation evidence

**Physical device:** Xiaomi **Redmi 22095RA98C**, **Android 13 (SDK 33)**, ARM64
(mt6833), 1080×2408, serial `jfzxugsgnnvsrsg6`.
**Emulator (visual capture):** `sdk_gphone64_x86_64`, **Android 14 (SDK 34)**,
x86_64, 1080×2400.

> **Honest limitation:** the physical Redmi is **PIN-secured** (`secure=true`,
> `deviceLocked=1`). Without the founder's PIN, the screen could not be unlocked,
> so **on-device screen capture was blocked** (frames came back black / lockscreen
> only). The physical device therefore provides **install / launch / process /
> memory / log** evidence; the **visual** UI evidence (§10) was captured on the
> emulator, where the identical build renders the identical UI.

Pre-flight per sprint STEP 6 (all run):

- `adb devices` → physical device + emulator detected.
- `flutter clean` → `flutter pub get` → `flutter analyze --fatal-infos
  --fatal-warnings` (clean) → `flutter test` (**461 tests pass**, coverage 88.5%).
- `flutter build apk --debug` (+ `--dart-define=KP_PET_RENDERER=rive`) →
  `app-debug.apk` built (ARM64, ~231 MB debug).
- `adb install -r -t -g .../app-debug.apk` → **Success** on the Redmi.

Physical-device runtime evidence (Rive seam active):

- App launched, process alive, **no FATAL / no ANR** while foregrounded
  (`artifacts/rive-device/logcat-smoke.txt`; crash/ANR scan returned **0**).
- Cold start (debug build) `am start -W` → **WaitTime ≈ 3082 ms**.
- The instrumentation smoke run (adopt → interact → save → reopen) was driven via
  `flutter test -d jfzxugsgnnvsrsg6`; it began correctly and the app behaved
  normally, but the run **did not complete on the physical device** because the
  PIN-locked screen put the device to sleep mid-run (the Flutter engine pauses
  when the screen sleeps, so `pumpAndSettle` stalls). This is a **harness
  limitation of an unattended locked phone**, not an app failure — the **same
  smoke + full-journey tests pass green** in CI's emulator
  (`integration-android`, §15) and locally (§6).

Functional UI validation (emulator, identical build, `KP_PET_RENDERER=rive`):
onboarding → notification permission → 3-beat Rescue Day → species pick → naming
("Biscuit") → **Companion Home** → Feed/Play reactions. Character area: **layout
correct, responsive, no overflow, no clipping, no crashes.** Screenshots §10.

---

## 10. Screenshots summary

All under `artifacts/`. Filenames are literal.

**`artifacts/rive-emu/` (emulator, `KP_PET_RENDERER=rive`, the visual record):**

| File | What it shows |
|---|---|
| `01-onboarding.png` | Launcher / first frame |
| `02-perm-dialog.png` | Notification permission prompt |
| `03-onboarding-rescue.png` | Rescue Day beat 1 ("A cold, rainy evening") |
| `04-beat2.png` | Beat 2 ("You kneel down and reach out") |
| `05-beat3.png` | Beat 3 ("a hopeful wag" / "Will you help?") |
| `06-species.png` | Species selection |
| `07-naming.png` | Naming screen |
| `08-after-puppy.png` | Named "Biscuit" |
| `09-home.png` | **Companion Home** — app bar, bond bar, greeting bubble, CareRing + pet on the knitted bed, mood/feedback chips, Feed/Clean/Play. No overlaps. |
| `10-play-reaction.png` | Home after a Play interaction |
| `11-feed-reaction.png` | **Feed reaction** — bubble "Wheee! I feel wonderful! ✨", feedback "Biscuit gobbled it right up! 🍽"; the Rive seam **reactively** re-rendered the new emotion. |

The pet in 09/10/11 renders as the **Rive seam stand-in** (a soft-green disc with
the current emotion icon, labeled **"rive"**). This is the **expected, honest**
behavior with `KP_PET_RENDERER=rive` and **no `.riv` present**: it proves the rive
backend is active and degrading gracefully — the live rig will occupy this exact
spot when supplied.

**`artifacts/rive-device/` (physical Redmi):**

| File | What it shows |
|---|---|
| `01-onboarding.png` | Device frame (lockscreen — see §9 PIN limitation) |
| `_unlock_probe.png` | Lockscreen unlock probe (confirms PIN gating) |
| `logcat-smoke.txt` | Full logcat of the on-device smoke run (no FATAL/ANR) |

---

## 11. Performance observations

| Metric | Observation | Source / caveat |
|---|---|---|
| Cold start (Redmi, debug, Rive on) | **≈ 3.08 s** (WaitTime 3082 ms) | `am start -W`; debug build — release will be faster |
| Cold start (emulator, debug) | ≈ 3.5 s | `am start -W` |
| Total memory (Redmi, under test, Rive on) | **PSS ≈ 147 MB** (150 539 KB); Graphics ≈ 4.5 MB; modest native/Dalvik heap | `dumpsys meminfo`; no spike |
| Full-walkthrough memory (prior) | ≈ 235 MB, bounded by `cacheWidth` decode caps | prior UI-validation run |
| Frame pacing | **Not precisely measurable here** | `gfxinfo` reported **0 frames** (Impeller/Vulkan surface isn't tracked by the legacy profiler) — consistent across runs |
| Raster cost | Bounded | Cozy scenes are **static** images; **no infinite/looping animations** in the home widgets, so raster work is bounded |
| Jank / dropped frames | None observed interactively | no stutter in capture; precise numbers need a profile run (below) |

**Honest gap & recommended next step:** exact frame-pacing / dropped-frame numbers
require a profile-mode trace on an **unlocked** device:
`flutter run --profile --dart-define=KP_PET_RENDERER=rive` then the DevTools
performance overlay, or `flutter drive --profile`. This was **not** completed
because the physical device is PIN-locked and the seam currently renders the
lightweight stand-in (the meaningful frame budget to measure is the **real rig**,
once supplied). No optimization was required for what is currently rendered.

---

## 12. Bugs found

**No application-code bugs were found** during integration or validation.

One **environment/packaging issue** (explicitly *not* an app defect) was observed
and is documented for completeness:

- **ARM64 APK will not load on an x86_64 emulator** —
  `dlopen failed: "libflutter.so" is for EM_AARCH64 (183) instead of
  EM_X86_64 (62)`. This is an **ABI mismatch** between an ARM-built APK and an
  x86 emulator image, i.e. a *build-target* choice, not a code bug. It does not
  affect real ARM devices (the Redmi ran the ARM64 APK fine).

The earlier-noted home-screen "app-bar / bond-bar spacing" concern was checked on
device and found **clean — no overlap** (screenshots 09/11). No fix needed.

---

## 13. Bugs fixed

- No app-code bug required a code fix.
- The **ABI mismatch** (§12) was resolved operationally by building for the
  emulator's architecture:
  `flutter build apk --debug --target-platform android-x64
  --dart-define=KP_PET_RENDERER=rive` (or simply `flutter run`, which builds the
  correct ABI for the attached device). After that, the app launched and ran on
  the emulator normally (all §10 emulator screenshots).
- **Hardening shipped in PR #62 (defends future integration):** added the
  `assets/rive/` bundle + `README.md` and a regression test pinning
  `assets/rive/interactive_dog.riv` to graceful fallback, so the founder's
  documented drop-in path can never silently break.

---

## 14. Remaining blockers

1. **`.riv` asset not available — the single real blocker.** Needs a **founder
   business/licensing action** (§5): commission an original rig, **or** upgrade to
   Cadet ($9/mo) and export an original rig, **or** drop a CC-BY community rig as a
   *placeholder only* (credited). Engineering needs **no further changes** once a
   contract-satisfying `.riv` lands in `assets/rive/`.
2. **Physical-device visual capture is PIN-gated.** Final on-device *visual* sign-
   off and a profile-mode frame trace require the founder to run the build on an
   **unlocked** phone (or share a screen-unlock). Functional + memory + log
   evidence on the locked device is already captured.
3. **PR #62 is open, green, and awaiting a one-click founder merge.** The agent's
   self-merge was correctly blocked by the two-party-review guard; per CLAUDE.md
   the agent did **not** push to `develop` or bypass the check. See §16.
4. **Low-priority cleanup (non-blocking):** two rig directories (`assets/rive/`
   and `assets/rigs/`) coexist by intent; consolidating to one is a future tidy-up
   (documented in `assets/rive/README.md`), deferred to avoid churning
   test-pinned docs.

---

## 15. CI evidence

**PR #62 — all 9 required checks GREEN** (verified 2026-06-28):

| Check | Workflow | Result |
|---|---|---|
| analyze | PR CI | ✅ SUCCESS |
| test | PR CI | ✅ SUCCESS |
| build-android | PR CI | ✅ SUCCESS |
| integration-android | PR CI | ✅ SUCCESS (emulator smoke/journey — the green counterpart to §9's locked-device stall) |
| secret-scan | Security | ✅ SUCCESS |
| dependency-scan | Security | ✅ SUCCESS |
| osv-scanner | — | ✅ SUCCESS |
| sbom | Security | ✅ SUCCESS |
| workflow-hardening | Security | ✅ SUCCESS |

`mergeable: MERGEABLE`. Local gate (`just verify`) also green: **461 tests pass,
line coverage 88.5%** (threshold 60%).

---

## 16. PR numbers

- **PR #62** — `feat(render): bundle canonical assets/rive/ mascot drop-in for the
  Rive dog seam` → base `develop`. **Open, green, mergeable.** Contains the seam
  bundling, `assets/rive/README.md`, the regression test, **and this report**.
  URL: `https://github.com/emredogan-cloud/kindredpaws/pull/62`.

This sprint is **exactly one report** in **one PR**, per the brief. No second PR
was opened. The PR is left for the **founder's one-click merge** because the
agent's self-merge was (correctly) blocked by the two-party-review requirement,
and CLAUDE.md forbids pushing to `develop` or disabling the check.

---

## 17. Commit hashes

- **`0e29647`** — `feat(render): bundle canonical assets/rive/ mascot drop-in for
  the Rive dog seam` (pubspec `assets/rive/`, `assets/rive/README.md`, regression
  test).
- **`f553477`** — `docs(rive): Rive dog integration & real-device validation
  report` (this file). The authoritative hash is the latest report commit on
  branch `feature/rive-dog-integration-seam` in the **PR #62** commit list (it
  may shift by one if the commit is amended on push).
- Branch base: **`268e003`** (develop tip; PR #61 "integrate premium GPT assets").

---

## 18. Final recommendation

**Ship the seam, then commission the rig.**

1. **Merge PR #62** (one click — it is green and mergeable). This bakes in the
   canonical `assets/rive/` drop-in path and its regression guard, so the asset
   can land later with zero further engineering.
2. **Commission an original interactive-dog rig** to the `PetStateMachine`
   contract in `docs/RIVE_CONTRACTOR_HANDOFF.md` (§7) — this is the **only
   license-clean path for the shipped mascot** (bible §3.2/§3.3). If you only need
   a temporary demo, a **Cadet upgrade** or a **credited CC-BY community rig** is
   fine as a placeholder, but **not** for release.
3. **Drop the file** at `assets/rive/interactive_dog.riv` and run with
   `--dart-define=KP_PET_RENDERER=rive --dart-define=KP_RIV_ASSET=assets/rive/interactive_dog.riv`.
   The seam loads it, drives mood/emotion/lifeStage, and the stand-in disappears —
   **no code change**.
4. **Final on-device sign-off:** run that build on an **unlocked** phone and grab a
   `--profile` frame trace to close §11's measurement gap.

There is **no engineering work blocking the mascot** — only the licensing action
to obtain a clean `.riv`. The integration is prepared, validated, tested, and
green.

---

*Prepared with honest evidence only. Unverifiable items (paid export contents,
PIN-locked visual capture, precise frame pacing) are labeled as limitations rather
than asserted. No licensing, scraping, or platform rules were bypassed at any
point.*
