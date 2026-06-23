# RIVE_CONTRACTOR_HANDOFF.md — KindredPaws pet rig (P4-2)

The **exact, drop-in specification** a Rive artist delivers so the commissioned
rig activates with **zero code changes**. The runtime integration is complete and
shipped (`lib/render/rive_pet_renderer.dart`, P3-2); this is the only remaining
piece — the `.riv` art itself. Pair this with the art direction in
`docs/LIVE2D_RIG_DESIGN_BRIEF.md` and the architecture in
`docs/PET_RENDERER_ARCHITECTURE.md`. The interface below is **pinned by a test**
(`rive_contract_test.dart`) so it cannot silently drift from the code.

## 1. Deliverables (per species: puppy "Biscuit", kitten "Mochi")

- **One `.riv` file** per species (`biscuit.riv`, `mochi.riv`) — **not** one per
  life-stage. All 3 life-stages live in the single rig, driven by an input.
- Source `.rev`/editor files + work-for-hire IP assignment.
- The rig authored against the **state machine contract** in §2–§4 below.
- Budget + style per the design brief; **all expression via parameter blending**
  (no new art per emotion — the Risk R7 cost lever).

## 2. State machine (exact names — case-sensitive)

| Thing | Value |
|---|---|
| State machine name | **`PetStateMachine`** |
| Input 1 | **`mood`** — NUMBER, range `0.0 … 3.0` |
| Input 2 | **`lifeStage`** — NUMBER, range `0.0 … 2.0` |
| Input 3 | **`emotion`** — NUMBER, range `0.0 … 11.0` |

The client loads the file's **main artboard**, finds `PetStateMachine` by name,
and drives these three NUMBER inputs every time the gameplay state changes. If
the state machine or any input is missing/misnamed, the app logs a diagnostic
(`rive_state_machine_missing` / `rive_inputs_missing`) and falls back to a
stand-in — so a wrong name fails safe but visibly. Match these names exactly.

## 3. Input encodings (exact integer → meaning)

**`mood`** (drives the idle loop):
| Value | Mood |
|---|---|
| 0 | joyful |
| 1 | content |
| 2 | wistful |
| 3 | low (sad-but-safe — never sick/distressed; gentle, never alarming) |

**`lifeStage`** (drives proportion/texture; the client *also* applies a render
scale of 0.7 / 0.85 / 1.0):
| Value | Stage |
|---|---|
| 0 | Pup/Kit (infancy) |
| 1 | Young One (juvenile) |
| 2 | Grown (adult) |

**`emotion`** (drives a one-shot reaction, then returns to the current mood idle):
| Value | Emotion | Mood family |
|---|---|---|
| 0 | Happy | joyful |
| 1 | Excited | joyful |
| 2 | Playful | joyful |
| 3 | Affectionate | joyful |
| 4 | Content | content |
| 5 | Proud | content |
| 6 | Calm | content |
| 7 | Sleepy | wistful |
| 8 | Curious | wistful |
| 9 | Lonely | wistful (wistful longing — NOT distress) |
| 10 | Hungry | low (a gentle "could use a snack," never suffering) |
| 11 | Comforted | low |

## 4. Required states + transitions

- **4 idle states**, one per `mood` value (breathing / ambient motion, loops
  indefinitely). Slightly randomize so it doesn't read as a repeating GIF.
- **12 reaction states**, one per `emotion` value — short (**< 2 s**), one-shot,
  then transition back to the idle for the *current* `mood`.
- Inputs must take effect **within one frame** (no perceptible lag).
- The `low` mood + `lonely`/`hungry` reactions must stay **cozy and gentle**
  (the pet is "sad but safe" — never sick, scared, or distressing; child-safe).

## 5. Performance budget (mid-tier Android target: stable 60 fps)

- Keep the artboard mesh/bone count modest; target **< 16 ms/frame** on a
  mid-tier device. Prefer mesh deforms + bones over heavy clipping.
- Reactions are short and return to idle to bound active animation cost.
- Single artboard per species; life-stage textures swap within it (no extra
  artboards/files).
- The client measures cold asset-load and emits a `rive_loaded {asset, ms}`
  diagnostic for the perf dashboard.

## 6. Activate (no code change required)

Drop `biscuit.riv` / `mochi.riv` into `assets/rigs/` (already bundled — see
`assets/rigs/README.md`) and run with the flags:

```bash
flutter run \
  --dart-define=KP_PET_RENDERER=rive \
  --dart-define=KP_RIV_ASSET=assets/rigs/biscuit.riv
```

## 7. Acceptance checklist (how we verify the delivered `.riv`)

- [ ] Loads with no `rive_*` error diagnostic (state machine + all 3 inputs found).
- [ ] `mood` 0→3 switches the idle; `emotion` 0→11 each plays a distinct reaction
      then returns to idle; `lifeStage` 0→2 changes proportion/texture.
- [ ] No reaction exceeds ~2 s; inputs respond within a frame.
- [ ] Holds ~60 fps on a mid-tier Android device through a full mood/emotion sweep.
- [ ] `low`/`lonely`/`hungry` read as gentle + cozy (child-safe review pass).
- [ ] 3 life-stage textures present in the one artboard; IP assigned.
