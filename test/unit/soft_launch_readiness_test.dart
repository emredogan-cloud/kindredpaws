import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/performance_budgets.dart';
import 'package:kindredpaws/services/live_ops.dart';
import 'package:kindredpaws/services/remote_config_service.dart';

/// Drift-guard for `docs/SOFT_LAUNCH_READINESS.md` (P5-7): the runbooks name
/// concrete rollback levers + numbers. This pins those claims to the code so a
/// rename can't silently make the runbook lie — a failure here means update the
/// doc (and vice versa).
void main() {
  group('Soft-launch rollback levers exist as documented', () {
    test('the kill-switch features match the incident runbook list', () {
      final keys = LiveFeature.values.map((f) => f.key).toSet();
      expect(keys, {
        'live_chat',
        'rewarded_ads',
        'keepsake_share',
        'notifications',
        'beta_feedback',
        'rescue_bundles',
      });
    });

    test('the experiment keys match the rollback runbook list', () {
      final keys = Experiment.values.map((e) => e.key).toSet();
      expect(keys, {'paywall_copy', 'onboarding_pace', 'notification_cadence'});
    });

    test('each rollback primitive resolves against safe defaults', () {
      const ops = LiveOps(DefaultRemoteConfig());
      // Kill-switches default OFF (features live) — the founder opts into a kill.
      expect(ops.isKilled(LiveFeature.rewardedAds), isFalse);
      // Rollouts default to fully-shipped.
      expect(ops.isInRollout(LiveFeature.keepsakeShare, unitId: 'u'), isTrue);
      // Experiments default to control (the safe baseline + rollback state).
      expect(
        ops.assignVariant(Experiment.paywallCopy, unitId: 'u'),
        ExperimentVariant.control,
      );
    });
  });

  test('the checklist startup number is the cold-start budget', () {
    // §1 checklist: "Cold start < 2.5 s" ⇒ PerfBudget.coldStart.
    expect(PerfBudget.coldStart.ceilingMs, 2500);
  });
}
