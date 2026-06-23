import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/services/live_ops.dart';
import 'package:kindredpaws/services/remote_config_service.dart';

LiveOps _liveOps([Map<String, Object> overrides = const {}]) =>
    LiveOps(DefaultRemoteConfig(overrides));

void main() {
  group('LiveOps kill-switches (incident off-switch)', () {
    test('a feature lives by default and dies when killed', () {
      expect(_liveOps().isKilled(LiveFeature.rewardedAds), isFalse);
      expect(
        _liveOps({
          'killswitch.rewarded_ads': true,
        }).isKilled(LiveFeature.rewardedAds),
        isTrue,
      );
    });

    test('a killed feature is never live, regardless of rollout', () {
      final ops = _liveOps({
        'killswitch.notifications': true,
        'rollout.notifications.pct': 100,
      });
      expect(ops.isLive(LiveFeature.notifications, unitId: 'u1'), isFalse);
    });
  });

  group('LiveOps %-rollout (deterministic + sticky)', () {
    test('pct 100 ⇒ everyone in; pct 0 ⇒ no one in', () {
      final full = _liveOps({'rollout.keepsake_share.pct': 100});
      final none = _liveOps({'rollout.keepsake_share.pct': 0});
      for (final id in ['a', 'b', 'c', 'd']) {
        expect(full.isInRollout(LiveFeature.keepsakeShare, unitId: id), isTrue);
        expect(
          none.isInRollout(LiveFeature.keepsakeShare, unitId: id),
          isFalse,
        );
      }
    });

    test('the same unit is sticky (never flip-flops)', () {
      final ops = _liveOps({'rollout.keepsake_share.pct': 50});
      final first = ops.isInRollout(
        LiveFeature.keepsakeShare,
        unitId: 'stable',
      );
      for (var i = 0; i < 5; i++) {
        expect(
          ops.isInRollout(LiveFeature.keepsakeShare, unitId: 'stable'),
          first,
        );
      }
    });

    test('a 50% rollout splits a population roughly in half', () {
      final ops = _liveOps({'rollout.keepsake_share.pct': 50});
      var inCount = 0;
      for (var i = 0; i < 1000; i++) {
        if (ops.isInRollout(LiveFeature.keepsakeShare, unitId: 'user-$i')) {
          inCount++;
        }
      }
      expect(inCount, inInclusiveRange(400, 600)); // ~50% ± slack
    });

    test('isLive = not killed AND in rollout', () {
      final ops = _liveOps({'rollout.rewarded_ads.pct': 100});
      expect(ops.isLive(LiveFeature.rewardedAds, unitId: 'u'), isTrue);
    });
  });

  group('rolloutBucket', () {
    test('is in 0..99 and deterministic', () {
      for (final id in ['x', 'y', 'z', 'longer-unit-id-123']) {
        final b = rolloutBucket(id, 'salt');
        expect(b, inInclusiveRange(0, 99));
        expect(rolloutBucket(id, 'salt'), b); // stable
      }
    });

    test('the salt influences the hash (rollouts decorrelate)', () {
      // Across several feature salts the same unit must NOT land in one bucket —
      // proves rollouts are independent, not all-or-nothing together.
      final buckets = {
        for (final s in ['s1', 's2', 's3', 's4', 's5', 's6'])
          rolloutBucket('same-unit', s),
      };
      expect(buckets.length, greaterThan(1));
    });
  });

  group('content version', () {
    test('reads the live content version', () {
      expect(_liveOps().contentVersion, 1);
      expect(_liveOps({'liveops.content_version': 7}).contentVersion, 7);
    });
  });
}
