<!--
Title MUST follow Conventional Commits, e.g.:
  feat(app): add pet mood indicator
  fix(ci): correct coverage threshold parsing
The squash-merge commit uses this PR title, so Release Please depends on it.
-->

## What & why

<!-- One paragraph: what this changes and the motivation. Link issues: Closes #123 -->

## Type of change

- [ ] feat — new capability
- [ ] fix — bug fix
- [ ] perf / refactor
- [ ] build / ci / chore
- [ ] docs / test

## How it was verified

<!-- Commands run and results. Agents: paste the relevant `just` output. -->

- [ ] `just format` clean
- [ ] `just analyze` clean
- [ ] `just test` green (coverage ≥ threshold)
- [ ] `just build-android` succeeds
- [ ] (if UI changed) goldens updated & reviewed
- [ ] (if device-affecting) `just e2e-android` green / screenshots attached

## Risk & rollout

- [ ] No secrets committed (this is a **public** repo)
- [ ] No breaking change **OR** marked `feat!`/`fix!` with `BREAKING CHANGE:` footer
- [ ] Scope limited to the linked issue (no unrelated changes)

## Agent self-merge checklist

> Per CONTRIBUTING.md, an AI agent may merge this PR itself **only when ALL required CI checks are green**. If any check is red, or this touches a path requiring founder sign-off, apply `agent: needs-human` and stop.

- [ ] All required checks green
- [ ] Not labeled `do-not-merge` / `agent: needs-human`
