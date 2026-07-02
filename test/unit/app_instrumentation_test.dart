import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/app_instrumentation.dart';
import 'package:kindredpaws/services/crash_reporter.dart';
import 'package:kindredpaws/services/performance_monitor.dart';

void main() {
  group('installCrashHandlers (P3-7 crash activation)', () {
    // Save + restore the global handlers so this test never leaks into others.
    final priorFlutterOnError = FlutterError.onError;
    final priorPlatformOnError = PlatformDispatcher.instance.onError;
    tearDown(() {
      FlutterError.onError = priorFlutterOnError;
      PlatformDispatcher.instance.onError = priorPlatformOnError;
    });

    test('a Flutter framework error is reported non-fatal', () {
      final crash = InMemoryCrashReporter();
      installCrashHandlers(crash);

      FlutterError.onError!(
        FlutterErrorDetails(
          exception: StateError('boom'),
          stack: StackTrace.empty,
        ),
      );

      expect(crash.errors, hasLength(1));
      expect(crash.errors.single.fatal, isFalse);
      expect(crash.errors.single.context, 'flutter');
    });

    test('a platform/isolate error is reported fatal + marked handled', () {
      final crash = InMemoryCrashReporter();
      installCrashHandlers(crash);

      final handled = PlatformDispatcher.instance.onError!(
        ArgumentError('async boom'),
        StackTrace.empty,
      );

      expect(handled, isTrue);
      expect(crash.errors, hasLength(1));
      expect(crash.errors.single.fatal, isTrue);
      expect(crash.errors.single.context, 'platform');
    });
  });

  group('recordColdStart (P3-7 perf activation)', () {
    test('records the cold-start metric', () {
      final perf = InMemoryPerformanceMonitor();
      recordColdStart(perf, elapsedMs: 1234);
      expect(perf.metrics['cold_start_ms'], 1234);
    });
  });
}
