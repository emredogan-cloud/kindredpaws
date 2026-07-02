# Asset credits & licensing ledger

Canon rule (`KINDREDPAWS_RIVE_CHARACTER_MASTER_BIBLE_TR.md` §5, Content
Factory): every bundled asset is logged here with its origin and license.

## Original by construction (no external source exists)

| Asset | Origin | License |
|---|---|---|
| `assets/audio/*.wav` (10 cues) | Synthesized from pure math by `tool/generate_sfx.dart` (sine partials + envelopes + seeded noise; regenerate any time) | Project-original; no third-party material |
| The vector pet (puppy & kitten) | Hand-authored `CustomPainter` code, `lib/render/vector_pet_renderer.dart` | Project-original; no third-party material |
| Particle/celebration effects | Hand-authored painters, `lib/game/ui/widgets/feel_fx.dart` | Project-original |

## Generated imagery (GPT Image, UI integration sprint)

| Asset | Origin | Notes |
|---|---|---|
| `assets/backgrounds/`, `assets/ui/`, `assets/icons/`, `assets/cards/`, `assets/illustrations/`, `assets/premium/`, `assets/shop/`, `assets/wardrobe/` (38 PNGs) | Generated via GPT Image from original prompts (`KINDREDPAWS_GPT_IMAGE_PROMPT_LIBRARY_TR.md`), out-of-band | Original outputs; no copyrighted-work imitation prompts; prompts on file |

## Emoji glyphs

Item cards and accessory overlays render Unicode emoji via the platform's
bundled emoji font (Noto Color Emoji on Android — SIL OFL). No emoji artwork
is copied into the repo; interim treatment until bespoke item art lands.

*No asset in this repository is extracted from, traced from, or derivative of
any commercial game or third-party artwork.*
