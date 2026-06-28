# assets/rive — canonical mascot rig drop-in

This is the location named by the **founder brief** and the design SSOT
(`KINDREDPAWS_RIVE_CHARACTER_MASTER_BIBLE_TR.md` §5: *"Export … `.riv` olarak
`assets/rive/<tür>.riv`"*). Drop the commissioned/approved mascot rig here, e.g.:

```
assets/rive/interactive_dog.riv
```

The directory is bundled by `pubspec.yaml`, so adding a `.riv` needs **no**
pubspec or code change. The same runtime seam (`lib/render/rive_pet_renderer.dart`)
and `KP_RIV_ASSET` build flag serve both this directory and `assets/rigs/` — they
differ only by intent (see *Two locations*, below).

## Contract (the rig MUST satisfy this — pinned by `rive_contract_test.dart`)

One state machine named **`PetStateMachine`** with three **number** inputs:

| Input | Range | Meaning |
|---|---|---|
| `mood` | 0–3 | `PetMood.index` — joyful / content / wistful / low |
| `lifeStage` | 0–2 | pupKit / youngOne / grown (render scale 0.7 / 0.85 / 1.0) |
| `emotion` | 0–11 | `PetEmotion.index` — the 12 emotion motions |

Plus a per-mood idle loop and a one-shot reaction state per emotion that returns
to idle. Expression is via authored params (eyes/mouth/ears/tail/blush) — **never
new art per emotion** (data, not frames; Risk R7 cost lever). The full spec is in
`docs/RIVE_CONTRACTOR_HANDOFF.md`.

## Activating the rig (zero code change)

```sh
flutter run \
  --dart-define=KP_PET_RENDERER=rive \
  --dart-define=KP_RIV_ASSET=assets/rive/interactive_dog.riv
```

Until a `.riv` is present here the app runs the deterministic, native-free
**stand-in** (default `KP_PET_RENDERER=placeholder`). If a rig is supplied but the
asset is missing, the state machine is absent, or an input is misnamed, the
renderer **falls back to the stand-in** and emits a `rive_*` diagnostic (logged
via observability) — it never crashes play.

## Licensing (record every external rig here + in `assets/CREDITS.md`)

KindredPaws is a **commercial** product, so only **commercial-OK** licenses are
permitted (bible §3.1):

- **Original commissioned rig (preferred):** work-for-hire, IP assigned. No
  third-party license. This is the only license-clean path for the *shipped*
  mascot (bible §3.2/§3.3 — the core pet must be original, not a remix).
- **Rive Community file (placeholder/reference only):** Community files are
  **CC BY** — commercial use is allowed **but attribution is required**. If a
  community `.riv` is ever bundled here, record the author + file URL in
  `assets/CREDITS.md`. Per bible §3.2/§3.3 a community rig may serve only as a
  **temporary placeholder or reference**, never as the final shipped mascot.

> Exporting a `.riv` from the Rive editor is a **paid** action (Cadet plan, see
> `RIVE_DOG_INTEGRATION_AND_DEVICE_VALIDATION_REPORT.md` §3–§5). The editor +
> runtimes are free to use; only the runtime **export** is gated. Never bypass
> licensing or the export paywall — upgrade, purchase, or commission instead.

## Two locations (intentional, reconcile later)

- `assets/rive/` — **this dir**: the founder/brief-canonical mascot drop-in.
- `assets/rigs/` — the original engineering convention for commissioned species
  rigs (`biscuit.riv`, `mochi.riv`; `assets/rigs/README.md`).

Both are bundled and both work via `KP_RIV_ASSET`. Consolidating to a single
directory is a recommended low-priority cleanup (tracked in the integration
report) — kept separate now to avoid churning the test-pinned engineering docs.
