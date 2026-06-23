# assets/rigs — Rive pet rigs

The commissioned `.riv` pet rigs go here (P2 art deliverable). This directory is
bundled by `pubspec.yaml` so adding a rig needs **no** pubspec change.

## Contract (the rig must satisfy this)

Each `.riv` artboard must expose a state machine named **`PetStateMachine`** with
three **number** inputs (see `lib/render/rive_pet_renderer.dart`):

| Input | Range | Meaning |
|---|---|---|
| `mood` | 0–3 | `PetMood.index` — joyful / content / wistful / low |
| `lifeStage` | 0–2 | pupKit / youngOne / grown (scale 0.7 / 0.85 / 1.0) |
| `emotion` | 0–11 | `PetEmotion.index` — the 12 emotion motions |

Plus: a per-mood idle loop and a one-shot reaction state per emotion that returns
to idle. Expression is via authored params (eyes/mouth/ears/tail/blush) — **never
new art per emotion** (data, not frames; Risk R7 cost lever).

## Activating a rig

```sh
flutter run \
  --dart-define=KP_PET_RENDERER=rive \
  --dart-define=KP_RIV_ASSET=assets/rigs/<species>.riv
```

Until a rig is present the app runs the deterministic, native-free **stand-in**
(default `KP_PET_RENDERER=placeholder`), so CI, golden tests, and dev stay
asset-free and offline. If a rig is supplied but the asset is missing, the state
machine is absent, or an input is missing, the renderer **falls back to the
stand-in** and emits a `rive_*` diagnostic (logged via observability) — it never
crashes play.
