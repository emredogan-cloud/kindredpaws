/// GameController × Daily Kindnesses (GE-1): the slate greets every session,
/// real care moments complete it (with the Kibble thank-you paid once), and a
/// new day quietly brings a fresh pair. All copy stays warm.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/data/kindred_save_state.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/model/kindness.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';

import '../../support/harness.dart';

/// Seeds a store with a pet whose slate is exactly [offered] for kDay0's day.
Future<LocalSaveStore> seededStore(List<String> offered) async {
  final store = makeStore();
  final state =
      KindredSaveState.newPet(
        petId: 'pet-fixed',
        species: 'puppy',
        name: 'Biscuit',
        nowMs: kDay0,
      ).copyWith(
        kindness: KindnessState(dayEpoch: kDay0 ~/ 86400000, offered: offered),
      );
  await store.write(state.toEnvelope().toJsonString());
  return store;
}

void main() {
  group('Daily Kindnesses in the controller', () {
    test('adopting offers today\'s pair immediately', () async {
      final c = makeController();
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      final slate = c.kindnessToday;
      expect(slate, isNotNull);
      expect(slate!.offered.length, 2);
      expect(c.todaysKindnesses.length, 2);
      expect(slate.completed, isEmpty);
      c.dispose();
    });

    test('the offered pair persists across a reopen (same day)', () async {
      final store = makeStore();
      final first = makeController(store: store, clock: () => kDay0);
      await first.load();
      await first.adopt(species: Species.puppy, name: 'Biscuit');
      final offered = first.kindnessToday!.offered;
      first.dispose();

      final second = makeController(store: store, clock: () => kDay0 + 3600000);
      await second.load();
      expect(second.kindnessToday!.offered, offered);
      second.dispose();
    });

    test('a real care moment completes the kindness and pays the thank-you '
        'exactly once', () async {
      final store = await seededStore([
        'kind_share_a_meal',
        'kind_bubble_bath',
      ]);
      final c = makeController(store: store, clock: () => kDay0 + 3600000);
      await c.load();
      final before = c.pet!.wallet.kibble;

      await c.interact(CareInteraction.feed);
      final slate = c.kindnessToday!;
      expect(slate.isCompleted('kind_share_a_meal'), isTrue);
      // The feed's own small Kibble + the kindness thank-you (12).
      expect(c.pet!.wallet.kibble - before, greaterThanOrEqualTo(12));
      expect(c.lastMessage, contains('kindness'));

      // A second feed never double-credits the kindness.
      final afterFirst = c.pet!.wallet.kibble;
      await c.interact(CareInteraction.feed);
      expect(c.kindnessToday!.completed.length, 1);
      expect(c.pet!.wallet.kibble - afterFirst, lessThan(12));
      c.dispose();
    });

    test('completing both celebrates the whole day warmly', () async {
      final store = await seededStore([
        'kind_share_a_meal',
        'kind_bubble_bath',
      ]);
      final c = makeController(store: store, clock: () => kDay0 + 3600000);
      await c.load();

      await c.interact(CareInteraction.feed);
      await c.interact(CareInteraction.clean);
      expect(c.kindnessToday!.allDone, isTrue);
      expect(c.lastMessage, contains('Every kindness done today'));
      // Warm always — never guilt vocabulary.
      final msg = c.lastMessage!.toLowerCase();
      for (final banned in ['starving', 'sick', 'guilt', 'abandon']) {
        expect(msg, isNot(contains(banned)));
      }
      c.dispose();
    });

    test(
      'the wellness ritual completes from the Care Corner (sync path)',
      () async {
        final store = await seededStore([
          'kind_wellness_ritual',
          'kind_bubble_bath',
        ]);
        final c = makeController(store: store, clock: () => kDay0 + 3600000);
        await c.load();
        final before = c.pet!.wallet.kibble;

        c.wellnessCheck();
        expect(c.kindnessToday!.isCompleted('kind_wellness_ritual'), isTrue);
        expect(c.pet!.wallet.kibble - before, 10);
        c.dispose();
      },
    );

    test(
      'a new day quietly brings a fresh pair (yesterday just fades)',
      () async {
        final store = await seededStore([
          'kind_share_a_meal',
          'kind_bubble_bath',
        ]);
        const day0 = kDay0 + 3600000;
        final c = makeController(store: store, clock: () => day0);
        await c.load();
        await c.interact(CareInteraction.feed); // one completed yesterday
        await c.onAppBackgrounded();
        c.dispose();

        const nextDay = kDay0 + 86400000 + 3600000;
        final c2 = makeController(store: store, clock: () => nextDay);
        await c2.load();
        final slate = c2.kindnessToday!;
        expect(slate.dayEpoch, (kDay0 ~/ 86400000) + 1);
        expect(slate.completed, isEmpty);
        expect(slate.offered.length, 2);
        c2.dispose();
      },
    );
  });
}
