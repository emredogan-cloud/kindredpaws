import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/app_config.dart';
import 'package:kindredpaws/core/compliance_config.dart';
import 'package:kindredpaws/monetization/billing_service.dart';
import 'package:kindredpaws/monetization/monetization_controller.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/backend_service.dart';
import 'package:kindredpaws/services/beta_diagnostics.dart';
import 'package:kindredpaws/services/beta_feedback_pipeline.dart';
import 'package:kindredpaws/services/beta_triage.dart';
import 'package:kindredpaws/services/crash_reporter.dart';
import 'package:kindredpaws/services/feedback_service.dart';
import 'package:kindredpaws/services/live_ops.dart';
import 'package:kindredpaws/services/logger.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/services/performance_monitor.dart';
import 'package:kindredpaws/services/remote_config_service.dart';
import 'package:kindredpaws/services/sentiment.dart';

/// Captures what was submitted to the feedback stream.
class _CapturingFeedback implements FeedbackService {
  final List<BetaFeedback> submitted = [];
  @override
  Future<void> submit(BetaFeedback feedback) async => submitted.add(feedback);
}

class _Harness {
  _Harness()
    : analytics = InMemoryAnalyticsService(),
      feedback = _CapturingFeedback() {
    observability = ObservabilityFacade(
      logger: InMemoryLogger(),
      crash: InMemoryCrashReporter(),
      performance: InMemoryPerformanceMonitor(),
      analytics: analytics,
    );
    pipeline = BetaFeedbackPipeline(
      feedback: feedback,
      diagnostics: BetaDiagnostics(
        appConfig: AppConfig.fromEnvironment(),
        compliance: const ComplianceConfig(),
        monetization: MonetizationController(
          billing: NoopBillingService(),
          observability: observability,
          backend: InMemoryBackendService(),
        ),
        liveOps: const LiveOps(DefaultRemoteConfig()),
      ),
      observability: observability,
    );
  }

  final InMemoryAnalyticsService analytics;
  final _CapturingFeedback feedback;
  late final ObservabilityFacade observability;
  late final BetaFeedbackPipeline pipeline;

  Map<String, Object?> get betaEvent => analytics.recorded
      .firstWhere((r) => r.$1 == AnalyticsEvent.betaFeedback)
      .$2;
}

void main() {
  group('BetaFeedbackPipeline — the full beta-ops pass', () {
    test('happy feedback ⇒ praise, persisted, PII-free telemetry', () async {
      final h = _Harness();
      final item = await h.pipeline.ingest(
        rating: 5,
        comment: 'I love this cozy little game',
      );

      expect(item.sentiment, Sentiment.positive);
      expect(item.triage.category, TriageCategory.praise);
      expect(item.hadCrash, isFalse);

      // The raw feedback was persisted to the stream.
      expect(h.feedback.submitted.single.rating, 5);

      // Telemetry carries the triage tags — and NOT the note text.
      expect(h.betaEvent, {
        'rating': 5,
        'category': 'praise',
        'severity': 'p3',
        'sentiment': 'positive',
        'had_crash': false,
      });
      expect(h.betaEvent.containsKey('comment'), isFalse);
      expect(
        h.betaEvent.values.whereType<String>(),
        isNot(contains('I love this cozy little game')),
      );
    });

    test('a session crash correlates ⇒ P1 crashReport even on 5★', () async {
      final h = _Harness();
      // Something errored earlier this session (routed through the funnel).
      h.observability.recordError(
        StateError('tick failed'),
        StackTrace.current,
        context: 'sim_tick',
      );

      final item = await h.pipeline.ingest(rating: 5, comment: 'great!');
      expect(item.hadCrash, isTrue);
      expect(item.triage.category, TriageCategory.crashReport);
      expect(item.triage.severity, TriageSeverity.p1);
      expect(h.betaEvent['had_crash'], isTrue);
      expect(h.betaEvent['category'], 'crashReport');
    });

    test('an unhappy note ⇒ detractor', () async {
      final h = _Harness();
      final item = await h.pipeline.ingest(
        rating: 2,
        comment: 'it is so buggy and boring',
      );
      expect(item.sentiment, Sentiment.negative);
      expect(item.triage.category, TriageCategory.detractor);
    });

    test('exportText bundles the note + the correlated diagnostics', () async {
      final h = _Harness();
      final item = await h.pipeline.ingest(
        rating: 1,
        comment: 'so frustrating',
      );
      final text = item.exportText();
      expect(
        text,
        contains('so frustrating'),
      ); // the note (internal triage console)
      expect(text, contains('KindredPaws diagnostics')); // diagnostics block
      expect(text, contains('detractor')); // the triage header (1★ ⇒ detractor)
    });
  });
}
