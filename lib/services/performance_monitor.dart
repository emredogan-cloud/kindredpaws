/// Performance monitoring seam (P1-2 observability → Firebase Performance).
///
/// Tracks named traces (e.g. `rescue_day`, `cold_start`, `sim_resolve`) and
/// counter/metric values. Wired now; the Firebase Performance body drops in once
/// provisioned. The reaction-beat budget is ≤150 ms and cold-start matters
/// (GAMEPLAY_AND_PROGRESSION_BIBLE.md §3.2) — these traces make that measurable.
library;

/// A single timing trace. Duration is recorded explicitly (deterministic +
/// testable) via [stopWith], or measured via [stop] using a [Stopwatch].
class PerfTrace {
  PerfTrace(this.name);

  final String name;
  final Map<String, int> metrics = {};
  final Stopwatch _watch = Stopwatch();
  int? durationMs;

  void start() => _watch.start();

  /// Stop and record elapsed wall time.
  void stop() {
    _watch.stop();
    durationMs = _watch.elapsedMilliseconds;
  }

  /// Stop with an explicit duration (deterministic; for tests / replayed sims).
  void stopWith(int ms) {
    if (_watch.isRunning) _watch.stop();
    durationMs = ms;
  }

  void setMetric(String name, int value) => metrics[name] = value;
  void incrementMetric(String name, [int by = 1]) =>
      metrics[name] = (metrics[name] ?? 0) + by;
}

abstract interface class PerformanceMonitor {
  /// Begin a trace. Caller stops it; the monitor records it on stop via
  /// [completeTrace].
  PerfTrace startTrace(String name);

  /// Record a finished trace (called by the app after `trace.stop()`).
  void completeTrace(PerfTrace trace);

  /// Record a standalone metric value (e.g. frame_build_ms).
  void recordMetric(String name, int value);
}

/// In-memory implementation: functional for dev/CI; keeps finished traces +
/// metrics for inspection/tests.
class InMemoryPerformanceMonitor implements PerformanceMonitor {
  final List<PerfTrace> completed = [];
  final Map<String, int> metrics = {};

  @override
  PerfTrace startTrace(String name) => PerfTrace(name)..start();

  @override
  void completeTrace(PerfTrace trace) => completed.add(trace);

  @override
  void recordMetric(String name, int value) => metrics[name] = value;

  PerfTrace? traceNamed(String name) {
    for (final t in completed) {
      if (t.name == name) return t;
    }
    return null;
  }
}
