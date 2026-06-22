# LLM Unit-Economics Model v1 — KindredPaws

**Phase-0 / G0 pass criterion #3:** *"LLM cost/DAU model shows < ARPDAU at
projected mix."* This document is the model write-up; the executable model is
`lib/tooling/llm_cost_model.dart` (run `dart run tool/llm_cost_model.dart`) with
unit tests in `test/unit/llm_cost_model_test.dart`.

> Canonical numbers (ARPDAU, the < 35% gate, currency model) come from
> `game-os/KINDREDPAWS_CANONICAL_DECISION_BRIEF.md` and
> `game-os/GAME_TECHNICAL_SYSTEMS.md` §12. Pricing is verified Anthropic list
> price (claude-api reference, 2026).

## 1. The guard equation (GAME_TECHNICAL_SYSTEMS.md §12.3)

```
LLM_cost_per_DAU = amortized_pregen_per_DAU
                 + live_chat_share × avg_turns × per_turn_token_cost
                 + live_chat_share × avg_turns × moderation_per_turn
REQUIRE:  LLM_cost_per_DAU < 0.35 × ARPDAU          (hard gate G4)
```

Target ARPDAU is $0.03–0.06; the model uses the conservative $0.03.

## 2. Locked models & verified pricing ($/MTok)

| Model | Role | Input | Output | Cache read (~0.1×) | Cache write (1.25×, 5-min) |
|---|---|---|---|---|---|
| `claude-haiku-4-5` | runtime / live chat (founder: "Claude Haiku 4") | $1.00 | $5.00 | $0.10 | $1.25 |
| `claude-opus-4-8` | offline pre-generation (paid once) | $5.00 | $25.00 | $0.50 | $6.25 |

Batch API (off-peak fact extraction, Deferred): −50%.

## 3. The structural insight

The MVP hybrid path uses **zero runtime tokens** — every line is selected from
the on-device, pre-reviewed bank, and "it remembers" is structured-memory
injection, not generation. So MVP LLM cost/DAU ≈ the amortized one-time pre-gen
pass, which is structurally tiny per DAU. The only metered path is the
**Deferred** live chat (#6b), which is subscriber-funded, age-gated, persona-
cached, and capped.

## 4. Scenarios & results (from the executable model)

| Scenario | live share | turns/DAU | persona cache | cost/DAU | ratio | gate |
|---|---|---|---|---|---|---|
| **MVP launch** (hybrid, no live chat) | 0% | 0 | — | $0.00080 | **2.7%** | ✅ PASS |
| **Soft-launch live pilot** (capped) | 5% | 8 | cached | $0.00117 | **3.9%** | ✅ PASS |
| Uncapped stress (control) | 50% | 40 | uncached | $0.0888 | 296% | ❌ FAIL (by design) |

Assumptions: pre-gen one-time $40 amortized over 50,000 installs ($0.0008/DAU);
persona prefix 1,500 tokens (cache-read on each live turn); per-turn input 120
tokens, output capped at 90; moderation $0.0002/turn. The control scenario
(uncapped, uncached, mass live chat) is included to prove the guard catches the
unbounded-OPEX trap (Risk R2) the hybrid architecture exists to avoid.

## 5. G0 verdict

**PASS.** At MVP the LLM cost/DAU is ~2.7% of ARPDAU; even the soft-launch live
pilot stays at ~3.9% — both far under the 35% gate, with ~9× headroom before
the gate would bind. The seven cost controls (hybrid pre-gen, structured-memory
injection, persona prompt-cache, small model, output caps, daily-turn caps,
subscriber-gated live chat) are encoded as the model's defaults and the
remote-config keys in `lib/services/remote_config_service.dart`.

## 6. Sensitivities to re-validate at G3/G4 (Open Decision #3)

- Live-chat **DAU share** and **turns/DAU** under real traffic (the dominant levers).
- Actual **moderation** endpoint price per turn.
- **Cache hit rate** on the persona prefix (must stay byte-stable to hold ~0.1×).
- Realized **ARPDAU** (re-run with measured value, not $0.03).
- Pre-gen bank size / refresh cadence (re-amortize over the real install base).

Re-run `dart run tool/llm_cost_model.dart` with measured inputs at each gate.
