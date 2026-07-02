# CONTENT_OPERATING_SYSTEM.md — KindredPaws (P3-3)

How dialogue content gets **authored → validated → reviewed → shipped → rotated**
without ever putting an unsafe or off-tone line in front of a child. Authority:
`game-os/GAME_CONTENT_FACTORY.md §7/§9/§10`, `GAME_TECHNICAL_SYSTEMS.md §4`,
the canonical brief §10. This doc is the human companion to the code gate in
`lib/content/`.

## 1. Why an OS (not just a file)

The MVP Heartmind is a **hybrid**: dialogue is pre-generated offline (claude-opus
batch), **100% human-reviewed**, then selected on-device at runtime ($0 tokens,
no live LLM). That makes content the product's safety surface — "one tone-deaf
screenshot can define the brand" (Risk R10). So content needs the same rigor as
code: a schema, an automated gate, a review checkpoint, versioning, and a safe
distribution path.

## 2. The content model

A line lives in a `DialogueBankEntry` (`lib/heartmind/dialogue_bank.dart`) keyed
by `intent | lifeStage | mood | bondStage | personalityDial` (`*` = wildcard),
carrying reviewed `lines` that may contain closed-set memory slots like
`{fact:likes_activity}`. Slots resolve to a `FactKey` via `kSlotToFactKey`
(`lib/heartmind/memory_injection.dart`) — the model **never** free-generates a
memory, which is how callback reliability hits ≥95% with zero hallucinations.

Vocabulary is SSOT-derived (the `Mood` / `BondStage` / `HeartmindIntent` enums +
`KindredTerms.lifeStages`), so a typo'd tag is caught, not silently dead.

## 3. The gate — `ContentValidator` (`lib/content/content_validator.dart`)

Every bank — bundled or remote — must pass before it ships. Errors block; warnings
advise. The validator enforces:

- **Vocabulary** — intent/mood/bondStage/lifeStage ∈ the SSOT sets (or `*`).
- **Slots** — every `{fact:slot}` resolves to a closed-set `FactKey`.
- **Safety by construction** — each line (slots filled with a neutral placeholder)
  passes the fail-closed `SafetyFilter` (no banned topics, never empty) **and** the
  never-guilt tone scan (`forbiddenGuiltLanguage`: starving / dying / sick /
  abandon / guilt / miss you / forgot / neglect / punish / lonely without).
- **Shape** — every entry has ≥1 non-empty line.

Run it:

```sh
just content-validate                 # the bundled launch bank
just content-validate path/to/bank.json   # an offline-generated bank, pre-review
```

A unit test (`test/unit/content/content_validator_test.dart`) pins that the
bundled launch bank passes, so CI fails the moment a shipped line regresses.

## 4. Authoring workflow (offline pre-gen, founder-gated)

The line *authoring* itself is an **offline founder/ops op** (it uses claude-opus
and is out of the app — the client ships $0-token, no live LLM):

1. **Draft** — batch-generate N candidates for a `(intent × mood × bondStage ×
   lifeStage × dial)` bucket, constrained by the Tone & Safety Bible
   (`GAME_CONTENT_FACTORY.md §7.5`), auto-tagged + memory slots referenced.
2. **Auto-screen** — run `just content-validate <draft>.json`. Anything with an
   error is quarantined, never advances. (This is the machine half of the gate.)
3. **Human review (mandatory)** — the founder reads / edits / approves. Only
   approved lines enter the bank. Nothing ships unreviewed.
4. **Land** — merge approved entries into the bundled bank, or push them as a
   Remote Config top-up (§5). Re-run the gate.

> Why no in-app generator: MVP has **no live free-form LLM** (decision log), and
> the runtime is $0-token by design. The validator is the durable, testable
> artifact; the LLM drafting is a periodic offline op the founder runs.

## 5. Distribution & live-ops (`content_distribution.dart`)

Live-ops cadence is honest and low (~1 small moment / 6–8 weeks, Risk R8) and ships
**via Remote Config without an app update**. `mergeRemoteContent(bundled, remoteJson)`
merges a remote payload onto the bundled bank but **re-validates every remote entry
through the same gate first**, accepting only the clean ones (fail-safe per entry).
A malformed, off-tone, or unparseable remote push can never corrupt the live bank
or reach a child — it is simply dropped, and the bundled (already-reviewed) bank
stands.

## 6. Keepsakes & cosmetics

Keepsake cards (`lib/keepsake/`) are composed at runtime from a rig snapshot + a
reviewed line + watermark — their *copy* is content too, and the share flow + its
`keepsakeShare` telemetry are wired in the P3-3 share work. Cosmetic palette-swaps
and seasonal events ride the same Remote Config + validation path.

## 7. Invariants (never break these)

- No line ships without passing `ContentValidator` **and** founder review.
- Memory is closed-set only — no free-text from minors is ever stored or surfaced.
- Remote content is validated before it can take effect; the bundled bank is the
  safe floor.
- The never-guilt + banned-topic rules are non-negotiable (Risk R1/R6/R10).

## Content expansion system (P4-0)

The pipeline scales to a large production corpus while staying safe + clean:

- **Versioning + localization-ready format.** `DialogueBank` now carries a
  `schemaVersion` + BCP-47 `locale` and (de)serializes a wrapper
  `{schemaVersion, locale, entries:[…]}` — *and* still accepts the legacy bare
  array (Remote Config top-ups). The dialogue corpus stays EN(+1–2) at launch;
  non-`en` locales ship as separate locale-tagged banks (UI strings localize
  first — brief §6, OD-6).
- **Manifest + categorization** (`lib/content/bank_manifest.dart`). `BankManifest`
  summarizes a bank — entry/line totals, the per-dimension line breakdown
  (intent · mood · bond · life-stage), and the memory-callback line count — for
  the content ledger + `just content-validate` output. Run it to see exactly what
  a bank contains before shipping.
- **Duplicate detection.** The validator now runs a bank-wide pass: a repeated
  entry **key** is an error (ambiguous selection — buckets must be merged), a
  repeated **line** (normalized) is a warning (it weakens the anti-repetition
  rotation that guards the "noticed AI repetition" churn signal, R3).
- **Stronger unsafe-content detection.** The never-guilt scan adds accusatory /
  shaming phrases (`where were you`, `bad pet`) on top of the banned-topic
  `SafetyFilter`. Every line is scanned with its `{fact:…}` slots rendered.

The one slot-token pattern (`{fact:snake_case}`) is now a single shared source of
truth (`kFactSlot`) used by the injector, validator, and manifest.
