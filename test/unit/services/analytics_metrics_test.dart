import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/services/analytics_metrics.dart';
import 'package:kindredpaws/services/analytics_service.dart';

(AnalyticsEvent, Map<String, Object?>) _e(
  AnalyticsEvent e, [
  Map<String, Object?> p = const {},
]) => (e, p);

void main() {
  group('AnalyticsMetrics — product-health derivation (P5-0)', () {
    test('onboarding completion rate = completes / starts', () {
      final m = AnalyticsMetrics([
        _e(AnalyticsEvent.onboardingStep, {'step': 'reach_out'}),
        _e(AnalyticsEvent.onboardingStep, {'step': 'reach_out'}),
        _e(AnalyticsEvent.onboardingStep, {'step': 'reach_out'}),
        _e(AnalyticsEvent.onboardingStep, {'step': 'reach_out'}),
        _e(AnalyticsEvent.rescueDayComplete, {'species': 'puppy'}),
        _e(AnalyticsEvent.rescueDayComplete, {'species': 'kitten'}),
        _e(AnalyticsEvent.rescueDayComplete, {'species': 'puppy'}),
      ]);
      expect(m.onboardingCompletionRate, closeTo(0.75, 1e-9)); // 3/4
    });

    test('empty-session rate (the daily-retention churn lever)', () {
      final m = AnalyticsMetrics([
        _e(AnalyticsEvent.sessionQuality, {'empty': true}),
        _e(AnalyticsEvent.sessionQuality, {'empty': false}),
        _e(AnalyticsEvent.sessionQuality, {'empty': false}),
        _e(AnalyticsEvent.sessionQuality, {'empty': false}),
      ]);
      expect(m.emptySessionRate, closeTo(0.25, 1e-9));
    });

    test('memory-callback landed rate ("it remembered me")', () {
      final m = AnalyticsMetrics([
        _e(AnalyticsEvent.memoryCallback, {'facts': 1, 'landed': true}),
        _e(AnalyticsEvent.memoryCallback, {'facts': 1, 'landed': true}),
        _e(AnalyticsEvent.memoryCallback, {'facts': 1, 'landed': false}),
      ]);
      expect(m.memoryCallbackLandedRate, closeTo(2 / 3, 1e-9));
    });

    test('leading-churn rates per session + paywall conversion', () {
      final m = AnalyticsMetrics([
        _e(AnalyticsEvent.sessionStart, {'offline_hours': 0}),
        _e(AnalyticsEvent.sessionStart, {'offline_hours': 0}),
        _e(AnalyticsEvent.aiRepetitionFlag),
        _e(AnalyticsEvent.guiltFlag),
        _e(AnalyticsEvent.paywallStep, {'step': 'shown'}),
        _e(AnalyticsEvent.paywallStep, {'step': 'shown'}),
        _e(AnalyticsEvent.monetizationEvent, {
          'stream': 'subscription',
          'sku': 's',
          'value': 5.99,
        }),
      ]);
      expect(m.aiRepetitionRate, closeTo(0.5, 1e-9)); // 1 / 2 sessions
      expect(m.guiltRate, closeTo(0.5, 1e-9));
      expect(
        m.paywallConversionRate,
        closeTo(0.5, 1e-9),
      ); // 1 purchase / 2 shown
    });

    test('notification opens + retention milestones group correctly', () {
      final m = AnalyticsMetrics([
        _e(AnalyticsEvent.notificationOpened, {'kind': 'celebration'}),
        _e(AnalyticsEvent.notificationOpened, {'kind': 'reEngagement'}),
        _e(AnalyticsEvent.notificationOpened, {'kind': 'celebration'}),
        _e(AnalyticsEvent.retentionMilestone, {'day': 1}),
        _e(AnalyticsEvent.retentionMilestone, {'day': 7}),
        _e(AnalyticsEvent.retentionMilestone, {'day': 7}),
      ]);
      expect(m.notificationOpensByKind, {'celebration': 2, 'reEngagement': 1});
      expect(m.retentionMilestonesByDay, {1: 1, 7: 2});
    });

    test('churn-risk score blends the leading indicators into 0..1', () {
      final healthy = AnalyticsMetrics([
        _e(AnalyticsEvent.sessionStart, {'offline_hours': 0}),
        _e(AnalyticsEvent.sessionQuality, {'empty': false}),
      ]);
      expect(healthy.churnRiskScore, 0.0);

      final atRisk = AnalyticsMetrics([
        _e(AnalyticsEvent.sessionStart, {'offline_hours': 0}),
        _e(AnalyticsEvent.sessionQuality, {'empty': true}),
        _e(AnalyticsEvent.aiRepetitionFlag),
        _e(AnalyticsEvent.guiltFlag),
      ]);
      expect(atRisk.churnRiskScore, greaterThan(healthy.churnRiskScore));
      expect(atRisk.churnRiskScore, inInclusiveRange(0.0, 1.0));
    });

    test('empty event stream yields zeroed metrics (no divide-by-zero)', () {
      const m = AnalyticsMetrics([]);
      expect(m.onboardingCompletionRate, 0);
      expect(m.emptySessionRate, 0);
      expect(m.paywallConversionRate, 0);
      expect(m.churnRiskScore, 0);
    });
  });
}
