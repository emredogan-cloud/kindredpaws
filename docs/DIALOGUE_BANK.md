# DIALOGUE_BANK.md — KindredPaws production corpus (P4-1)

The large, human-reviewed dialogue corpus that gives the companion its voice —
**warm, safe, cozy, encouraging, non-judgmental** (GAMEPLAY_BIBLE §18), child-safe
by construction, **never guilt / shame / manipulation**. This is the
"offline-pre-generated + reviewed" half of the hybrid Heartmind (no live LLM in
MVP). Authority: `GAME_CONTENT_FACTORY.md §7/§10`, `GAME_TECHNICAL_SYSTEMS.md §4`,
brief §10, Risk R3/R6/R10.

## What ships

- **`lib/heartmind/dialogue_corpus.dart`** — `buildDialogueCorpus()`, the corpus
  as compiled Dart data (sync, $0 runtime tokens, spinner-free). `defaultDialogueBank()`
  now returns it; Remote Config tops it up live (`mergeRemoteContent`).
- **`> 1000` reviewed lines** across the 8 intents, keyed by
  `intent × mood × bondStage × lifeStage × personalityDial` (wildcards keep
  coverage broad). Run `dart run tool/validate_content.dart` to see the live
  manifest breakdown.

| Prompt category | Maps to intent |
|---|---|
| greetings | `greeting` (per mood + bond + life-stage + personality voice) |
| goodbyes | `goodbye` |
| absence / return reactions | `returning` (warm, never guilt) |
| celebration + life-stage + milestone | `milestone` (bond-ups, life-ups, Gotcha Day, streak warmth) |
| memory callbacks | `memoryCallback` (slot-templated; only chosen when the fact exists) |
| encouragement | `careAck` / `comfort` (affirming, "you did your best") |
| cozy idle chatter + weather/daypart | `idle` (ambient vignettes; daypart/weather flavor) |

The spoken intents (greeting/returning/goodbye/careAck/comfort/milestone/
memoryCallback) are individually hand-authored for genuine variety (the
high-salience "what the pet says" surface — Maya's repetition radar). The `idle`
pool is the naturally-large ambient layer: low-salience stage-directions
(`*action setting*`) composed from curated micro-actions × curated daypart/weather
settings, deduped — the pet is *doing* little things, not *speaking*.

## Generation workflow (CONTENT_FACTORY §10.2)

1. **Author / extend** curated lines in `dialogue_corpus.dart`, following the
   Tone & Safety Bible (warm, never-guilt; no banned topics; every `{fact:…}`
   slot is a closed-set key).
2. **Validate** — `dart run tool/generate_bank.dart` (or `just content-validate`)
   gates the whole corpus through `ContentValidator`: vocabulary, slot
   resolution, safety-by-construction, never-guilt scan, **duplicate detection**.
   Any error aborts — no unsafe or duplicate-key content ships.
3. **Human checkpoint** — the founder reviews any new/changed lines (the
   irreplaceable review gate). Only approved lines stay.
4. **Ship** — compiled in via `buildDialogueCorpus()`, and/or export the
   versioned/localized JSON (`tool/generate_bank.dart out.json`) for localization
   or a Remote Config top-up.

## Safety + quality invariants (enforced by tests)

- **0 validator errors** on the full corpus (`dialogue_corpus_test.dart`).
- **≥ 1000 lines**, every intent covered, all four moods covered, a real
  memory-callback corpus (≥ 20 slot lines).
- **No duplicate entry keys** (P4-0 dedup), **no banned topics**, **no never-guilt
  language** — including substring traps (e.g. no word containing `die`/`sick`).
- **Anti-repetition** rotation in the selector keeps a recent line from repeating
  (guards the "noticed AI repetition" churn signal, R3).
- **Localization** — the corpus is `en`; other locales ship as separate
  locale-tagged JSON banks (the P4-0 format), translated from the exported JSON.
  Dialogue stays EN(+1–2) at launch; each new language re-opens the child-safety
  surface and is re-validated per-language (brief §6, OD-6).
