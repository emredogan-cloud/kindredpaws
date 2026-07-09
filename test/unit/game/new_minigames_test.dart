/// GE-4 engines — Bubble Drift & Starlight Trail: deterministic under seed,
/// no-fail by construction (counters only ever grow, misses become warm
/// notes), one-touch friendly, and timer-ended like every garden game.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/minigames/mini_games.dart';

void main() {
  group('the kit contract', () {
    test('every garden game is a MiniGameEngine (no-fail by type)', () {
      final engines = <MiniGameEngine>[
        BounceGame(),
        SnackCatchGame(),
        BubbleDriftGame(),
        StarlightTrailGame(),
      ];
      for (final e in engines) {
        expect(e.score, 0);
        expect(e.finished, isFalse);
        expect(e.sessionSeconds, greaterThan(0));
      }
    });
  });

  group('Bubble Drift', () {
    test('same seed + same script ⇒ the same session, tick for tick', () {
      final a = BubbleDriftGame(seed: 5);
      final b = BubbleDriftGame(seed: 5);
      for (var i = 0; i < 240; i++) {
        a.tick(1 / 60);
        b.tick(1 / 60);
        if (i == 90 || i == 180) {
          // Pop whatever is nearest to mid-field in both worlds.
          a.popAt(0.5, 0.7);
          b.popAt(0.5, 0.7);
        }
      }
      expect(a.popped, b.popped);
      expect(a.cloudBound, b.cloudBound);
      expect(a.bubbles.length, b.bubbles.length);
    });

    test('a close tap pops exactly one bubble; empty air just ripples', () {
      final g = BubbleDriftGame(seed: 3);
      // Let two bubbles spawn and rise into the field.
      for (var i = 0; i < 150; i++) {
        g.tick(1 / 60);
      }
      expect(g.bubbles, isNotEmpty);
      final target = g.bubbles.first;
      final before = g.popped;
      expect(g.popAt(target.x, target.y), isTrue);
      expect(g.popped, before + 1);
      // Far-away tap: friendly nothing.
      expect(g.popAt(0.001, 0.001), isFalse);
      expect(g.popped, before + 1);
    });

    test('an unpopped bubble floats off to see the clouds — never a miss', () {
      final g = BubbleDriftGame(seed: 3, sessionSeconds: 600);
      // Long enough for early bubbles to cross the whole sky.
      for (var i = 0; i < 60 * 12; i++) {
        g.tick(1 / 60);
      }
      expect(g.cloudBound, greaterThan(0));
      expect(g.popped, 0, reason: 'nothing popped, nothing lost');
    });

    test('the timer is the only ending; ticks after it are no-ops', () {
      final g = BubbleDriftGame(sessionSeconds: 1);
      for (var i = 0; i < 90; i++) {
        g.tick(1 / 60);
      }
      expect(g.finished, isTrue);
      final popped = g.popped;
      g.tick(1);
      expect(g.popAt(0.5, 0.5), isFalse);
      expect(g.popped, popped);
    });
  });

  group('Starlight Trail', () {
    test('hold rises, release drifts — softly, within the sky', () {
      final g = StarlightTrailGame();
      final start = g.fireflyY;
      g.setHolding(true);
      for (var i = 0; i < 30; i++) {
        g.tick(1 / 60);
      }
      expect(g.fireflyY, lessThan(start));
      final high = g.fireflyY;
      g.setHolding(false);
      for (var i = 0; i < 30; i++) {
        g.tick(1 / 60);
      }
      expect(g.fireflyY, greaterThan(high));
      // Never out of the sky, no matter how long the hold.
      g.setHolding(true);
      for (var i = 0; i < 600; i++) {
        g.tick(1 / 60);
      }
      expect(g.fireflyY, greaterThanOrEqualTo(0.08));
    });

    test('flying the path collects glimmers; the rest twinkle on', () {
      final g = StarlightTrailGame(seed: 9, sessionSeconds: 600);
      // Fly a gentle sweep: alternate hold/drift to cross many heights.
      for (var i = 0; i < 60 * 30; i++) {
        g.setHolding((i ~/ 45).isEven);
        g.tick(1 / 60);
      }
      expect(g.collected + g.twinkledOn, greaterThan(0));
      expect(g.score, g.collected);
    });

    test('same seed + same flight ⇒ the same constellation', () {
      final a = StarlightTrailGame(seed: 4);
      final b = StarlightTrailGame(seed: 4);
      for (var i = 0; i < 600; i++) {
        final hold = (i ~/ 30).isOdd;
        a.setHolding(hold);
        b.setHolding(hold);
        a.tick(1 / 60);
        b.tick(1 / 60);
      }
      expect(a.collected, b.collected);
      expect(a.twinkledOn, b.twinkledOn);
      expect(a.fireflyY, b.fireflyY);
    });
  });

  test('the shared reward cap holds for every engine score', () {
    expect(miniGameKibble(0), 0);
    expect(miniGameKibble(2), 1);
    expect(miniGameKibble(45), 15);
    expect(miniGameKibble(1 << 20), 15);
  });
}
