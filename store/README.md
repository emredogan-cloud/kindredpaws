# store/ — App Store + Google Play readiness (P4-8)

The **version-controlled source of truth** for the store listings — so the
metadata is reviewed, validated, and diffable like code, not pasted ad-hoc into a
console. **Prepare only — do not publish** (closed/internal testing track at most;
see `checklist.md`). Authority: roadmap P3/P4, `docs/COMPLIANCE.md`.

## Layout (fastlane-compatible)

```
store/
  metadata/en-US/        # one .txt per store field (fastlane `supply` / `deliver` shape)
    title.txt subtitle.txt short_description.txt keywords.txt
    promotional_text.txt description.txt release_notes.txt
  privacy/data_safety.md # App Store nutrition + Play Data Safety source of truth
  checklist.md           # the submission checklist (assets, products, gates)
```

Localized listings ship as sibling `metadata/<locale>/` folders (Open Decision #6;
AI-translate + human spot-check, like the dialogue localization path).

## Validation (gated)

Every field is length-checked against the **strictest** App Store / Play limit by
`tool/validate_store_metadata.dart` and pinned by `store_metadata_test.dart` (runs
in CI) — so an over-length title or "What's New" can never reach a submission. The
description test also guards the on-message pillars (rescue · memory · child-safe)
and forbids overclaiming (no "tax-deductible").

## Pipelines

- **Screenshots** — captured from the real app via `just screenshots` /
  `just e2e-android` (Rescue Day, the companion + memory callback, a Keepsake, the
  Nest, the Rescue Wall). One pillar per caption.
- **Release notes** — Release Please generates the changelog from Conventional
  Commits; `release_notes.txt` is the curated, player-facing "What's New" derived
  from it (no hand-edited versions/tags).
- **Privacy** — fill the App Store nutrition + Play Data Safety forms directly from
  `privacy/data_safety.md` (honest: minimal PII, no behavioral ad targeting,
  on-device-only voice, deletion path).

## Gate before any listing

The **G3 child-directedness legal sign-off** (Open Decision #9) blocks public
listing and drives the Made-for-Kids / age-rating / Kids-Category choices. Store
products (RevenueCat), AdMob kids-config, Firebase, signing, and the giving
partner are credentialed founder steps (REQUIRED_ENVIRONMENTS).
