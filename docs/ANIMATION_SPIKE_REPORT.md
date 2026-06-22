# Animation Spike Report — Rig Runtime Decision (P1-0)

**Phase 1 · P1-0 (Technical Risk Reduction) · 2026-06-23**
**Decision: lock the rig runtime to Rive (Flutter-native). Live2D Cubism is not viable as a Flutter runtime for a solo+AI MVP.**

> This closes the one open technical risk carried out of Phase 0: *"Live2D Cubism
> has no first-party Flutter runtime — validate a spike at the start of P1"*
> (`docs/LIVE2D_RIG_DESIGN_BRIEF.md` §6). The founder pre-authorized switching the
> rig commission to Rive if the Live2D-on-Flutter spike ran hot. It did. We switch.
> Engine stays **Flutter** (ADR-001); art style stays Live2D-Cubism-*styled*
> (ADR-002) — only the **runtime** changes.

---

## 1. The question

Can we drive the hero pet rig (expressive, param-blended emotions; 3 life stages
via scale; "params, not frames" economics — Risk R7) inside the **Flutter** client
using **Live2D Cubism**? If not, is **Rive** (the pre-authorized fallback) a
working, de-risked substitute that preserves the same economics and the
`PetRenderer` seam?

## 2. Method (real, reproducible — no guessing)

1. **Ecosystem evidence** — queried pub.dev for first-party/community runtimes and
   their adoption/maintenance signals (likes, 30-day downloads, supported platforms).
2. **Integration build** — added the candidate package to this app, ran
   `flutter analyze`, built a real Android APK (`flutter build apk`), and wired a
   concrete `RivePetRenderer` behind the existing `PetRenderer` seam with a widget
   test that renders in the Flutter test harness.

## 3. Evidence

### 3.1 Live2D Cubism on Flutter — not viable for this team
- **No first-party Flutter runtime exists.** Live2D ships native iOS/Android/Web
  SDKs and a Unity plugin — **not** a Flutter one.
- The **only** community Flutter binding on pub.dev is `flutter_live2d` **1.0.2**:
  **1 like**, **~142 downloads/30d**, Android+iOS only. That is an essentially
  unproven, unmaintained package to put on the critical path of the product's hero
  asset.
- Using it would still require integrating the **Cubism Core native SDK** (its own
  licensing terms) through a platform-channel/FFI bridge — significant native work
  and licensing review for a solo+AI team, with no maturity guarantee. This is
  exactly the risk Phase 0 flagged.

### 3.2 Rive on Flutter — first-party, mature, proven here
- **First-party runtime:** `rive` (publisher rive-app, repo `rive-app/rive-flutter`),
  actively maintained (latest published the day of this spike).
- **Adoption / maturity:** **~1,935 likes**, **~404,164 downloads/30d**, supports
  **android, ios, web, windows, macos, linux** (6 platforms vs Live2D-binding's 2).
- **Same economics:** vector skeletal animation with state-machine inputs —
  "params, not frames," life-stages via scale, emotions via blended inputs. Exactly
  the model the rig budget (Risk R7) assumes.
- **It builds here (proof):**
  - `flutter analyze --fatal-infos --fatal-warnings` → **clean**.
  - `flutter build apk` → **APK built** (verified on both the current `rive` line
    and the pinned line below).
  - `RivePetRenderer` (implementing `PetRenderer`) renders in a **widget test** with
    **0 native dependency at test time** (asset-free stand-in path).

## 4. Version decision — pin `rive: ^0.13` (pure-Dart line)

Two `rive` lines exist:
- **0.14.x** introduces `rive_native` (a C++ runtime delivered as **prebuilt
  binaries downloaded from `rive-flutter-artifacts.rive.app` at build time**). It
  builds successfully here, but it adds a **per-build network dependency** to every
  Android/iOS CI build — a supply-chain and CI-reliability cost we do not need while
  there is **no `.riv` asset yet** (the rig is commissioned at P2).
- **0.13.x** is the stable line whose renderer resolves **without** a per-build
  native artifact download, exposes the well-documented `RiveAnimation` /
  `StateMachineController` widget API, and is what the seam is wired against.

**Decision:** pin **`rive: ^0.13.0`** (resolved **0.13.20**) for the seam now;
re-evaluate moving to the `rive_native` line at **P2** when the real rig asset lands
and the richer runtime earns its CI cost. Recorded so the choice is not silently
reversed by a future `pub upgrade`.

## 5. What shipped in this spike (the seam, not the rig)

- `lib/render/rive_pet_renderer.dart` — `RivePetRenderer implements PetRenderer`
  (`backendId == 'rive'`). Renders the commissioned `.riv` artboard when an
  `assetPath` is supplied, scaling per life stage (§3.1: Pup/Kit 0.7 · Young One
  0.85 · Grown 1.0) and driving the state-machine inputs from `PetMood`. With no
  asset (today) it paints a deterministic, native-free stand-in — so CI, golden,
  and widget tests need neither the native runtime nor a binary asset.
- **Rig ↔ client contract (for the P2 commission):** the `.riv` must expose a state
  machine `PetStateMachine` with number inputs `mood` (0..3 = `PetMood.index`) and
  `lifeStage` (0..2). Documented in code so the contractor and client agree before
  the asset exists.
- `KP_PET_RENDERER` flag (`placeholder` | `rive`, default `placeholder`) +
  `createPetRenderer(...)` factory, registered in `bootstrap()`. Default stays
  `placeholder` so existing golden snapshots remain deterministic.

## 6. SSOT impact

- **ADR-001** amended: engine **Flutter** + rig runtime **Rive** (was "Live2D SDK,
  Rive fallback authorized"). The fallback is now the locked choice.
- **D-053** added to `GAME_DECISION_LOG.md`; `current_state.json` techStack updated
  (rig runtime = Rive; the P0 open integration item is **resolved**).
- `docs/LIVE2D_RIG_DESIGN_BRIEF.md` integration-spike risk is **closed** by this
  report; the rig commission targets **Rive** (.riv) deliverables.

## 7. Residual risks / follow-ups
- The actual `.riv` rig (puppy Biscuit) is a **P2** art deliverable; this spike
  proves the *runtime+seam*, not the art.
- If P2 needs the `rive_native` (0.14.x) renderer for performance/features, budget
  the CI cost of its build-time artifact download (mirror or pin the artifact).
- Keep the `PetRenderer` seam the only place rendering is concrete, so a future
  runtime change stays a backend swap with no gameplay edits.
