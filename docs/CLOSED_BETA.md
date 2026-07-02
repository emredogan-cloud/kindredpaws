# CLOSED_BETA.md — KindredPaws closed-beta experience (P4-7)

What a closed-beta build needs so testers can report well and the founder can
**remotely mitigate incidents**. Authority: GAME_MASTER_EXECUTION_ROADMAP G3,
GAME_TECHNICAL_SYSTEMS §10.

## Beta mode

`--dart-define=KP_BETA=true` (`AppConfig.betaEnabled`). Off in normal/golden
builds, so the beta feedback + diagnostics entry points add no UI to the shipped
experience. Onboarding stays the same warm Rescue Day cold-open — beta adds the
reporting affordances on top, never changes the core flow.

## Beta feedback UX

`BetaFeedbackSheet` (`lib/game/ui/beta_feedback_sheet.dart`) — a warm sheet: a
1–5 star rating + an optional 280-char note → `GameController.submitBetaFeedback`
→ the `FeedbackService` (`beta_feedback` backend stream; never shown to other
players). **PII-minimized**: rating + a capped, trimmed note, no identifiers.
`showBetaFeedback(context, controller)` opens it from a beta-only entry.

## Diagnostics + support export

`BetaDiagnostics.snapshot()` → a `DiagnosticReport` a tester attaches to a bug
report and the founder reads to triage. **PII-free by construction** — it reads
only build config + the compliance posture + the subscription flag + the live
kill-switch state + schema/content versions. **No player data** (no pet name, no
account id, no save contents). `exportText()` is the copy-paste block.

## Feature flags + remote kill switches (incident mitigation)

The founder mitigates an incident **without an app update** via the LiveOps
control plane (P4-3, `docs/LIVEOPS.md`):

- **Kill-switch** a misbehaving feature (`killswitch.<feature>` → true) — ads,
  notifications, keepsake share, live chat, beta feedback, rescue bundles. The
  diagnostics report surfaces the currently-killed set.
- **Roll back a % rollout** (`rollout.<feature>.pct`) to shrink exposure.
- **Hotfix content** via a validated Remote Config dialogue top-up
  (`mergeRemoteContent`) without shipping a build.
- **Tune balance** live (decay/Bond/caps via Remote Config → `SimConfig`).

## Crash / performance signal

Crash + non-fatal capture is wired at process start (`installCrashHandlers`,
P3-7) → Crashlytics once provisioned; cold-start + traces → Firebase Performance.
These give the G3 crash-free-rate (≥99%) + startup data for the beta dashboard.
