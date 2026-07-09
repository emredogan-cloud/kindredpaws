# Asset credits & licensing ledger

Canon rule (`KINDREDPAWS_RIVE_CHARACTER_MASTER_BIBLE_TR.md` §5, Content
Factory): every bundled asset is logged here with its origin and license.

## Original by construction (no external source exists)

| Asset | Origin | License |
|---|---|---|
| `assets/audio/*.wav` (10 cues) | Synthesized from pure math by `tool/generate_sfx.dart` (sine partials + envelopes + seeded noise; regenerate any time) | Project-original; no third-party material |
| The vector pet (puppy & kitten) | Hand-authored `CustomPainter` code, `lib/render/vector_pet_renderer.dart` | Project-original; no third-party material |
| Particle/celebration effects | Hand-authored painters, `lib/game/ui/widgets/feel_fx.dart` | Project-original |

## Generated imagery (GPT Image, final validation sprint 2026-07-02)

| Asset | Origin | Notes |
|---|---|---|
| `assets/backgrounds/{kitchen,bedroom,wardrobe,grocery}_scene.png` (4) | Generated via `tool/generate_gpt_assets.py` (gpt-image-1; prompts in the script, storybook style suffix, empty pet spot, no characters) | Original outputs; 1024×1536, ~3 MB each, decoded at screen width |
| `assets/items/*.png` (24 stickers: 7 foods, 6 toys, 3 supplies, 8 cosmetics) | Same pipeline, transparent 1024² → optimized to 512² (36 MB → 4 MB, Lanczos + PNG optimize) | Replace the emoji interim treatment on shelf cards and worn overlays (emoji remains the fallback) |
| `assets/items/decor_*.png` (14 stickers, Cozy Corners GE-3, 2026-07-02) | Same pipeline (`tool/generate_gpt_assets.py`, prompts in the script's décor section), transparent 1024² → optimized to 512² (22 MB → 2.8 MB) | Shelf cards + in-scene décor layer (emoji remains the fallback) |

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
