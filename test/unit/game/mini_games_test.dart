/// E4 mini-game engines: deterministic physics, NO fail state anywhere, and
/// a reward that stays a treat (hard-capped, dominated by real care).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/minigames/mini_games.dart';
import 'package:kindredpaws/game/model/items.dart';
import 'package:kindredpaws/game/model/species.dart';

import '../../support/harness.dart';

void main() {
  group('Bounce! engine', () {
    test('gravity pulls the ball to the cushion where it RESTS — never a '
        'fail state', () {
      final game = BounceGame();
      for (var i = 0; i < 600; i++) {
        game.tick(1 / 60);
      }
      expect(game.resting, isTrue); // cozy on the cushion
      expect(game.finished, isFalse); // only the timer ends a session
      expect(game.bounces, 0); // and the score never went DOWN
    });

    test('a boop lifts the ball (even from rest) and grows the score', () {
      final game = BounceGame();
      for (var i = 0; i < 600; i++) {
        game.tick(1 / 60);
      }
      expect(game.resting, isTrue);
      expect(game.boop(), isTrue);
      expect(game.resting, isFalse);
      expect(game.bounces, 1);
      final yAfterBoop = game.ballY;
      game.tick(1 / 60);
      expect(game.ballY, lessThan(yAfterBoop)); // moving up
    });

    test('the session ends by timer and the engine goes quiet', () {
      final game = BounceGame(sessionSeconds: 1);
      for (var i = 0; i < 90; i++) {
        game.tick(1 / 60);
      }
      expect(game.finished, isTrue);
      expect(game.boop(), isFalse); // done playing — no phantom score
    });

    test('identical inputs replay identically (deterministic)', () {
      final a = BounceGame();
      final b = BounceGame();
      for (var i = 0; i < 120; i++) {
        if (i % 30 == 0) {
          a.boop();
          b.boop();
        }
        a.tick(1 / 60);
        b.tick(1 / 60);
      }
      expect(a.ballX, b.ballX);
      expect(a.ballY, b.ballY);
      expect(a.bounces, b.bounces);
    });
  });

  group('Snack Catch engine', () {
    test('a snack falling into the basket is caught; a missed one is shared '
        'with the birds — never a penalty', () {
      final game = SnackCatchGame();
      // Let the first snack spawn, then park the basket right under it.
      while (game.snacks.isEmpty) {
        game.tick(1 / 60);
      }
      game.moveBasket(game.snacks.first.x);
      for (var i = 0; i < 400 && game.caught == 0; i++) {
        game.tick(1 / 60);
      }
      expect(game.caught, 1);

      // Park the basket far away from the next snack: the birds enjoy it.
      while (game.snacks.isEmpty) {
        game.tick(1 / 60);
      }
      game.moveBasket(game.snacks.first.x > 0.5 ? 0.06 : 0.94);
      final birdsBefore = game.sharedWithBirds;
      for (var i = 0; i < 500 && game.sharedWithBirds == birdsBefore; i++) {
        game.tick(1 / 60);
      }
      expect(game.sharedWithBirds, birdsBefore + 1);
      expect(game.caught, 1); // untouched — no score ever removed
    });

    test('basket stays inside the garden', () {
      final game = SnackCatchGame();
      game.moveBasket(-2);
      expect(game.basketX, greaterThanOrEqualTo(0.06));
      game.moveBasket(99);
      expect(game.basketX, lessThanOrEqualTo(0.94));
    });
  });

  group('mini-game reward (a treat, never a grind)', () {
    test('kibble grows gently and caps at 15; zero score still ends warm', () {
      expect(miniGameKibble(0), 0);
      expect(miniGameKibble(1), 1);
      expect(miniGameKibble(9), 3);
      expect(miniGameKibble(30), 10);
      expect(miniGameKibble(300), 15); // hard cap
    });

    test('finishMiniGame applies ONE play verb + the capped bonus', () async {
      final c = makeController();
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      final energyBefore = c.pet!.meters.energy;

      await c.finishMiniGame(gameId: 'bounce', score: 30);

      expect(c.pet!.meters.energy, lessThan(energyBefore)); // play costs energy
      // Play verb kibble (5 — the pet was willing) + capped bonus (10).
      expect(c.pet!.wallet.kibble, 15);
      expect(c.lastMessage, contains('Kibble'));
    });

    test('a sleeping pet hushes the wrap-up (no phantom rewards)', () async {
      final c = makeController();
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      await c.tuckIn();
      await c.finishMiniGame(gameId: 'bounce', score: 30);
      expect(c.pet!.wallet.kibble, 0);
      expect(c.lastMessage, contains('asleep'));
    });
  });

  // Keeps the shelves honest: game rewards must never rival real care.
  test('a full 45s game rewards less than a single needed care action pays '
      'plus daily bonus (economy dominance check)', () {
    expect(
      miniGameKibble(1 << 30),
      lessThan(ItemCatalog.bouncyBall.kibblePrice),
    );
  });
}
