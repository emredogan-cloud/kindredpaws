/// Process-level instrumentation activation (P3-7) — installs the global error
/// handlers + records the cold-start metric, so the closed beta produces the
/// crash-free-rate (G3 ≥99%) and startup-perf data the gates need.
///
/// Extracted from `main()` so it is unit-testable (main itself calls runApp and
/// can't run headless). Pure wiring over the [CrashReporter] / [PerformanceMonitor]
/// seams — no Firebase dependency here (the real sinks drop in at provisioning).
library;

import 'package:flutter/foundation.dart';

import '../services/crash_reporter.dart';
import '../services/performance_monitor.dart';

/// Routes uncaught Flutter framework + platform/isolate errors to [crash] so a
/// closed-beta crash is captured (not just printed). Flutter framework errors
/// are reported non-fatal (the framework caught them) and still presented in
/// debug; platform/async errors are reported fatal (they would have crashed the
/// isolate) and marked handled so a beta build degrades instead of dying.
void installCrashHandlers(CrashReporter crash) {
  final priorFlutterOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    crash.recordError(
      details.exception,
      details.stack,
      fatal: false,
      context: 'flutter',
    );
    priorFlutterOnError?.call(
      details,
    ); // keep the red screen / console in debug
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    crash.recordError(error, stack, fatal: true, context: 'platform');
    return true; // handled — don't take the whole isolate down during beta
  };
}

/// Records the cold-start duration (process start → first frame ready) as a
/// performance metric. [elapsedMs] is measured by the caller (main).
void recordColdStart(PerformanceMonitor performance, {required int elapsedMs}) {
  performance.recordMetric('cold_start_ms', elapsedMs);
}
