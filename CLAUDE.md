# CLAUDE.md — Agent operating manual for KindredPaws

You are an autonomous engineering agent on **KindredPaws** (Flutter mobile game).
This file is your contract. Read it fully before acting. It is auto-loaded by
Claude Code.

## 0. Prime directives

1. **Stay in scope.** Do only the task you were given. No scope creep into future
   roadmap phases. If you discover adjacent work, file an issue, don't do it.
2. **Never commit secrets.** Public repo. See `SECURITY.md`.
3. **Green or stop.** Never merge, never push to `main`/`develop`, never disable a
   check. If CI is red or you're unsure, label `agent: needs-human` and stop.
4. **One command surface.** Use `just` recipes (mirrored exactly by CI). If you
   need a new command, add it to the `Justfile` so CI and humans get it too.

## 1. The inner loop (every change)

```bash
just doctor      # one-time / when env seems off — verifies the toolchain
just setup       # flutter pub get
# ... make your change ...
just format      # dart format (write)
just analyze     # flutter analyze --fatal-infos --fatal-warnings
just test        # unit+widget+golden+perf with coverage gate
just verify      # = format-check + analyze + test (the PR gate, run before pushing)
```

Device / E2E (needs Android SDK + emulator, or a connected device):

```bash
just emulator        # boot the kp_pixel_api34 AVD (KVM-accelerated)
just run-android     # run the app on the emulator
just e2e-android     # install + drive integration_test, capture screenshots+video+logcat
just screenshots     # capture screenshots of key screens
```

If you changed UI: `just goldens-update` then eyeball `test/golden/goldens/*.png`
before committing.

## 2. The outer loop (shipping a task)

```bash
git switch develop && git pull
git switch -c feature/<issue#>-slug
# work + just verify (green)
git add -A && git commit -m "feat(scope): concise description"   # Conventional Commits
git push -u origin HEAD
gh pr create --base develop --fill                 # title MUST be a Conventional Commit
# wait for CI:
gh pr checks --watch
# when ALL required checks are green and not labeled needs-human/do-not-merge:
gh pr merge --squash --delete-branch
```

Self-merge is allowed **only** under the conditions in `CONTRIBUTING.md §5`.
Releases are automated (Release Please) — do not hand-edit versions or tags.

## 3. Where things live

| Need | Look in |
|---|---|
| Product/design truth | `game-os/` (roadmap, gameplay bible, decision log, canonical brief) |
| Engineering architecture | `PRE_PHASE0_ENGINEERING_FOUNDATION_MASTER_REPORT.md` |
| Commands | `Justfile` (canonical) / `Makefile` (thin mirror) |
| App code | `lib/` |
| Tests | `test/{unit,widget,golden,performance}`, `integration_test/` |
| Device automation | `tool/*.sh` |
| CI/CD | `.github/workflows/` |

## 4. Testing layers — pick the right one

- **unit** (`test/unit`): pure Dart logic, no widgets. Fast, always add these.
- **widget** (`test/widget`): a widget/screen in isolation via `WidgetTester`.
- **golden** (`test/golden`): pixel snapshots; Linux-rendered to match CI. Update
  intentionally with `just goldens-update`.
- **performance** (`test/performance`): coarse host-side budgets.
- **integration** (`integration_test/`): full-app flows on a real device/emulator.

Add tests at the lowest layer that proves the behavior. Keep coverage ≥ the
threshold in `pr-ci.yml` (`MIN_COVERAGE`).

## 5. Hard guardrails

- Do **not** add gameplay/features unless the task is an approved roadmap-phase task.
- Do **not** introduce a custom 3D pipeline, multiplayer, UGC, or live free-form LLM
  chat in MVP (see `game-os/` constraints).
- Do **not** add heavy dependencies without justification in the PR body.
- Prefer editing the walking skeleton's structure over rewriting it.

## 6. When blocked

Apply `agent: needs-human`, write a comment stating exactly what's blocking
(missing credential, ambiguous spec, failing check you can't fix, irreversible
action), and stop. Do not guess on irreversible or outward-facing actions.
