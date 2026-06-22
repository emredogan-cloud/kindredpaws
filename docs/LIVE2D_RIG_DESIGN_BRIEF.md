# Live2D Rig Design Brief — KindredPaws (P0 deliverable)

The concept-lock spec + contractor scope for the two hero rigs. The **G0 pass
criterion** "rig contractor secured" is a founder action; this brief is what you
hand the contractor and what locks the AI concept BEFORE paying for a rig
(Brief §4, Risk R7: *never under-budget the rig; lock design with AI concept
first*).

> Canonical art numbers/style: `game-os/GAME_CONTENT_FACTORY.md` §2–§5 and
> `game-os/KINDREDPAWS_CANONICAL_DECISION_BRIEF.md` §4. This brief restates the
> rig-specific requirements for the contractor; the docs win on any conflict.

## 1. What's being commissioned
- **2 Live2D Cubism rigs**: one **puppy** (Biscuit), one **kitten** (Mochi).
- Budget: **$1,200–$2,000 each + 15–20% revision contingency**. Total art/audio
  budget caps at ~$5,500; the rig is the hero spend — reallocate from music/SFX
  before ever cutting rig quality.
- Deliverables per rig: source `.cmo3` + exported `.can3`/`.moc3`, all parameters,
  3 life-stage texture variants, full work-for-hire IP assignment to the founder.

## 2. Art direction (must match the style guide)
- Cozy, soft, hand-illustrated, slightly chunky-cute; large expressive eyes (the
  bonding surface). Friendly to a 9-year-old, not cringe to a 19-year-old. No
  realism, no uncanny/horror detail (child-safe brand).
- Palette: the locked ~16-swatch master palette + warm/cool day/night tint pair
  (see CONTENT_FACTORY §2.2). Puppy = golden/brown range; kitten = grey/cream.

## 3. Required rig parameters (expressivity is data, not new art)
Eye open/squint, eye smile, pupil, mouth (open/smile/frown/o), head angle X/Y/Z,
ear position/droop, tail wag/curl, body breathe, paw raise, blush, tear/sparkle.
These must blend to cover the **12 emotion motions** (Happy, Content, Sleepy,
Hungry, Lonely/Longing, Comforted, Excited, Curious, Affectionate, Playful,
Proud, Calm) → the 4 derived mood states (`PetMood` in `lib/render/pet_renderer.dart`).

## 4. Life-stages via param/scale — NOT new rigs (Risk R7, the #1 cut lever)
Pup/Kit → Young One → Grown delivered by body scale + proportion params + one
texture pass per stage (6 skins total = 3 × 2 species). No per-stage re-rig.

## 5. P0 concept-lock workflow (do this before paying)
1. Generate concept sheets in Midjourney in the locked palette (front/side,
   expression range, 3 life-stage silhouettes) for puppy + kitten.
2. Founder curates the **locked concept sheet**.
3. Hand the locked sheet + this brief to the contractor at **G0** (no rig paid
   for before the concept is locked).

## 6. Integration spike result (P0 — engineering)
**Risk flagged:** Live2D Cubism has **no first-party Flutter runtime**. Options
assessed for the Flutter client (engine = Flutter + Live2D, ADR-001; art style ADR-002):
- **Live2D Cubism via platform view / FFI bridge** — preferred to honor the
  locked style; requires a community/custom binding (`flutter_live2d`-class
  plugins exist but maturity varies). Validate a spike at start of P1.
- **Rive (Flutter-native)** — the de-risked fallback the founder pre-authorized.
  First-class Flutter runtime, vector skeletal animation, same "params not frames"
  economics. If the Live2D-on-Flutter spike runs hot at P1, switch the rig
  commission to Rive — the `PetRenderer` abstraction (`lib/render/pet_renderer.dart`)
  makes this a backend swap with no gameplay changes.

**Decision:** keep Live2D as the locked target; the `PetRenderer` seam +
`PlaceholderPetRenderer` ship now so the actual rig (Live2D or Rive) drops in at
P1/P2 without touching gameplay. The rig backend is confirmed at the start of P1
after the integration spike. This is logged as an open item (OD-related) for P1.
