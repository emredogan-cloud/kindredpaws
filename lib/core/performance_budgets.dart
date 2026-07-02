/// Performance budgets (P5-6) — the single source of truth for KindredPaws'
/// performance ceilings, and the runtime gate that flags a breach. Before this,
/// budgets were magic numbers scattered across the perf tests; now the tests,
/// the runtime monitor, and `docs/PERFORMANCE.md` all read the same enum.
///
/// The soft-launch targets (brief §G4, GAMEPLAY_AND_PROGRESSION_BIBLE §3.2):
/// cold start < 2.5 s, a stable 60 fps (16 ms/frame), and a reaction beat
/// ≤ 150 ms. Memory-leak + battery targets are on-device concerns profiled via
/// `flutter drive --profile` (see the doc) — these millisecond budgets are the
/// part we can pin in code + CI.
library;

import '../services/observability.dart';

/// A named performance ceiling. [id] is the stable metric key (matches the
/// `PerformanceMonitor` metric / Firebase Performance trace); [ceilingMs] is the
/// budget the value must stay within.
enum PerfBudget {
  /// Process start → first frame ready. Soft-launch target: < 2.5 s.
  coldStart('cold_start_ms', 2500),

  /// Host-side cold widget build (the CI-safe proxy for cold start).
  coldWidgetBuild('cold_widget_build_ms', 2000),

  /// One frame at 60 fps. On-device frame-pacing target.
  frame('frame_ms', 16),

  /// Tap → the pet's reaction beat begins (GAMEPLAY_BIBLE §3.2: ≤ 150 ms).
  reactionBeat('reaction_beat_ms', 150),

  /// A care interaction resolves (sim + UI feedback) — snappy-loop target.
  interaction('interaction_ms', 100),

  /// The full mood × emotion render sweep (48 rebuilds) — host-side proxy for
  /// "no pathological rebuild cost" on the 60 fps path.
  renderSweep('render_sweep_ms', 4000),

  /// 100k state-machine input mappings — pins the per-frame push is allocation-
  /// light (the only thing pushed to the rig per change).
  inputMapping('input_mapping_ms', 500);

  const PerfBudget(this.id, this.ceilingMs);

  /// The stable metric key (analytics-safe, snake_case).
  final String id;

  /// The budget ceiling in milliseconds (inclusive).
  final int ceilingMs;

  /// Whether [valueMs] is within this budget.
  bool isWithin(int valueMs) => valueMs <= ceilingMs;
}

/// Evaluates measured values against [PerfBudget] ceilings at runtime. A breach
/// is a warn log + a crash breadcrumb (so a slow boot or janky beat surfaces in
/// beta triage / Crashlytics), never a throw — perf monitoring must never
/// disrupt play. The raw value still flows to `PerformanceMonitor` for the
/// dashboard; this is the *gate* on top.
class PerformanceBudgetMonitor {
  const PerformanceBudgetMonitor({required this.observability});

  final ObservabilityFacade observability;

  /// Checks [valueMs] against [budget]. Returns true if within budget; on a
  /// breach, logs + breadcrumbs it and returns false.
  bool check(PerfBudget budget, int valueMs) {
    if (budget.isWithin(valueMs)) return true;
    observability.logger.warn(
      'perf-budget breach',
      fields: {
        'budget': budget.id,
        'value_ms': valueMs,
        'ceiling_ms': budget.ceilingMs,
      },
    );
    observability.crash.addBreadcrumb('perf:${budget.id}:over');
    return false;
  }
}
