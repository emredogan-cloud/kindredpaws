# Pet Renderer Architecture & Rig Contract (P2-1)

How the game drives the pet rig, and the **exact `.riv` deliverables** the Rive
contractor must hand back. Engine/runtime locked to **Rive** (ADR-001 / D-053,
`docs/ANIMATION_SPIKE_REPORT.md`); art *style* stays Live2D-Cubism-styled
(ADR-002, `docs/LIVE2D_RIG_DESIGN_BRIEF.md`).

## 1. The seam

All rendering goes through `PetRenderer` (`lib/render/pet_renderer.dart`):

```dart
Widget build(BuildContext context, {
  required PetMood mood,        // joyful | content | wistful | low
  required String lifeStage,    // pupKit | youngOne | grown
  PetEmotion? emotion,          // the current expression (reaction or idle)
});
```

Two backends implement it:
- **`PlaceholderPetRenderer`** (`backendId: 'placeholder'`, default) — an
  expressive, deterministic, **test-safe** stand-in: it shows the current
  emotion, tints by mood, and plays a one-shot "pop" when the expression
  changes (implicit/one-shot animations only → `pumpAndSettle` always settles;
  no infinite loop). This is what ships until the `.riv` arrives.
- **`RivePetRenderer`** (`backendId: 'rive'`) — loads the commissioned `.riv`
  and drives its state machine. With no asset yet it paints the same kind of
  expressive stand-in (badged `rive`).

Selected by the `KP_PET_RENDERER` flag (default `placeholder` for golden
determinism); `createPetRenderer()` factory + `bootstrap()`.

## 2. The state machine (the 12-emotion vocabulary)

`PetEmotion` (`GAME_CONTENT_FACTORY.md` §5.1) — 12 named param-blend motions,
each mapped to one of the 4 `PetMood`s:

| Mood | Emotions |
|---|---|
| joyful | happy · excited · playful · affectionate |
| content | content · proud · calm |
| wistful | sleepy · curious · lonely |
| low (sad-but-safe) | hungry · comforted |

The game maps care verbs → reactions (`mood_visuals.dart`): **feed → happy**
(or **comforted** when comforting a Low pet), **clean → proud**, **play →
playful**; ambient idle + resting use `PetEmotion.restingFor(mood)`. The
Companion Presence layer (P2-4) drives idle/contextual emotions.

## 3. Rig ↔ client contract — what the `.riv` MUST expose

State machine name: **`PetStateMachine`** with three **number** inputs:

| Input | Range | Meaning |
|---|---|---|
| `mood` | 0–3 | `PetMood.index` — joyful(0) / content(1) / wistful(2) / low(3) |
| `lifeStage` | 0–2 | pupKit(0) / youngOne(1) / grown(2) — scale 0.7 / 0.85 / 1.0 |
| `emotion` | 0–11 | `PetEmotion.index` — the 12 motions, in enum order |

Behaviour the rig must implement:
- A **per-mood idle loop** (breathing/ambient), playing while no reaction fires.
- A **one-shot reaction** state per emotion that plays then returns to idle.
- **Life-stage scale/proportion** driven by `lifeStage` (param/scale, **no new
  rig per stage** — Risk R7).
- All expression via the authored param set (eye/mouth/ear/tail/blush/etc.);
  **0 new art** per emotion (data, not frames).

## 4. Contractor deliverables (per species — Biscuit puppy, Mochi kitten)

- `<species>.riv` with the `PetStateMachine` above wired to the 12 emotions and
  the 3 life-stage scales (6 skins total = 2 species × 3 stages, via
  param/scale + one texture pass per stage — not new rigs).
- The pre-rendered mood-image set referenced by `PetStatusSnapshot.
  preRenderedMoodImageRef` (`<species>_<lifeStage>_<mood>`) for the home widget
  (the widget shows a static image, never a live render — §6.2).
- Source files + full work-for-hire IP assignment (see the rig design brief).

Until these land, the placeholder renderer exercises the entire mood × emotion ×
life-stage state machine end-to-end, so dropping in the `.riv` is a backend swap
with zero gameplay change.
