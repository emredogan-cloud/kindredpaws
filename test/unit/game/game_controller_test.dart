import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/data/kindred_save_state.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/model/bond.dart';
import 'package:kindredpaws/game/model/pet_state.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/bond_engine.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/heartmind/personality.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/share_service.dart';

import '../../support/harness.dart';

/// A share seam that always reports the user dismissed the sheet.
class _DismissingShare implements ShareService {
  @override
  Future<ShareOutcome> shareKeepsake({
    required String title,
    required String caption,
    required String imageRef,
  }) async => ShareOutcome.dismissed;
}

void main() {
  group('GameController', () {
    test('starts with no pet → Rescue Day, then adopt creates one', () async {
      final c = makeController();
      await c.load();
      expect(c.hasPet, isFalse);

      await c.adopt(species: Species.puppy, name: 'Biscuit');
      expect(c.hasPet, isTrue);
      expect(c.pet!.name, 'Biscuit');
      expect(c.pet!.species, Species.puppy);
      // Memory Book is seeded on Rescue Day (the "it remembers" seed).
      expect(c.facts, isNotEmpty);
      expect(c.lastMessage, contains('Welcome home'));
    });

    test('empty name falls back to the canonical default', () async {
      final c = makeController();
      await c.load();
      await c.adopt(species: Species.kitten, name: '   ');
      expect(c.pet!.name, 'Mochi');
    });

    test(
      'interacting grows the Bond + Kibble and surfaces warm feedback',
      () async {
        final c = makeController(clock: () => kDay0);
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit');

        await c.interact(CareInteraction.play); // costs energy, awards Bond
        final bond1 = c.pet!.bond.value;
        // play (+3) + first-care-day streak (+6), mood-modified — bounded range.
        expect(bond1, inInclusiveRange(3, 20));

        await c.interact(CareInteraction.feed);
        expect(c.pet!.wallet.kibble, greaterThan(0));
        expect(c.pet!.bond.value, greaterThanOrEqualTo(bond1));
        // The feedback line must be warm — never guilt-framed (Risk R6 / D-047).
        expect(c.lastMessage, isNotNull);
        final msg = c.lastMessage!.toLowerCase();
        for (final banned in [
          'starving',
          'dying',
          'sick',
          'abandon',
          'guilt',
          'miss you',
        ]) {
          expect(msg, isNot(contains(banned)));
        }
        c.dispose();
      },
    );

    test(
      'SAVE → REOPEN → CONTINUE: a new controller restores the pet',
      () async {
        // Persist with one controller...
        final store = InMemoryLocalSaveStore();
        final first = makeController(store: store, clock: () => kDay0);
        await first.load();
        await first.adopt(species: Species.puppy, name: 'Biscuit');
        await first.interact(CareInteraction.feed);
        final bondBefore = first.pet!.bond.value;
        final kibbleBefore = first.pet!.wallet.kibble;
        first.dispose();

        // ...reopen with a brand-new controller over the SAME local store.
        final second = makeController(store: store, clock: () => kDay0);
        await second.load();
        expect(second.hasPet, isTrue);
        expect(second.pet!.name, 'Biscuit');
        expect(second.pet!.bond.value, bondBefore); // continued, not reset
        expect(second.pet!.wallet.kibble, kibbleBefore);
        second.dispose();
      },
    );

    test('crossing a Bond stage emits bondStageUp exactly once', () async {
      // Seed a save one point below the Friend threshold (250). Same-day clock
      // ⇒ resume awards no greeting bond, so the pet loads still a Stranger.
      final store = InMemoryLocalSaveStore();
      final seeded = PetState.newlyRescued(
        petId: 'p1',
        species: Species.puppy,
        name: 'Biscuit',
        nowMs: kDay0,
      ).copyWith(bond: const Bond(value: 249, stage: BondStage.stranger));
      await store.write(
        KindredSaveState(
          pet: seeded,
          ledger: BondLedger.empty,
          facts: const [],
          keepsakes: const [],
        ).toEnvelope().toJsonString(),
      );

      final c = makeController(store: store, clock: () => kDay0);
      await c.load();
      expect(c.pet!.bond.stage, BondStage.stranger); // not yet crossed

      final analytics = c.observability.analytics as InMemoryAnalyticsService;
      await c.interact(CareInteraction.feed); // pushes Bond over 250
      expect(c.pet!.bond.stage, BondStage.friend);
      expect(analytics.countOf(AnalyticsEvent.bondStageUp), 1);

      // Staying within the same stage does not re-emit the milestone.
      await c.interact(CareInteraction.play);
      expect(analytics.countOf(AnalyticsEvent.bondStageUp), 1);
      c.dispose();
    });

    test(
      'sharing a Keepsake emits keepsakeShare {moment_type, platform}',
      () async {
        final c = makeController(clock: () => kDay0);
        await c.load();
        await c.adopt(
          species: Species.puppy,
          name: 'Biscuit',
        ); // → Rescue Day card
        final card = c.keepsakes.first;

        final outcome = await c.shareKeepsake(card);
        expect(outcome.shared, isTrue); // NoopShareService → system sheet

        final analytics = c.observability.analytics as InMemoryAnalyticsService;
        expect(analytics.countOf(AnalyticsEvent.keepsakeShare), 1);
        final rec = analytics.recorded.firstWhere(
          (e) => e.$1 == AnalyticsEvent.keepsakeShare,
        );
        expect(rec.$2['moment_type'], card.kind.name);
        expect(rec.$2['platform'], 'system_sheet');
        c.dispose();
      },
    );

    test('a dismissed share does NOT emit keepsakeShare', () async {
      final c = makeController(clock: () => kDay0, share: _DismissingShare());
      await c.load();
      await c.adopt(species: Species.kitten, name: 'Mochi');
      final outcome = await c.shareKeepsake(c.keepsakes.first);
      expect(outcome.shared, isFalse);
      expect(
        (c.observability.analytics as InMemoryAnalyticsService).countOf(
          AnalyticsEvent.keepsakeShare,
        ),
        0,
      );
      c.dispose();
    });

    test('personality drift persists across SAVE → REOPEN (P3-4)', () async {
      final store = InMemoryLocalSaveStore();
      final first = makeController(store: store, clock: () => kDay0);
      await first.load();
      await first.adopt(species: Species.puppy, name: 'Biscuit');
      expect(first.personality, PersonalityProfile.neutral); // starts neutral
      // Lots of play drifts playfulness up (deterministic, bounded).
      await first.interact(CareInteraction.play);
      await first.interact(CareInteraction.play);
      final drifted = first.personality;
      expect(drifted.playfulness, greaterThan(2)); // moved off neutral
      expect(drifted.bankKey, 'playful');
      first.dispose();

      // Reopen over the same store: the personality is RESTORED, not reset.
      final second = makeController(store: store, clock: () => kDay0);
      await second.load();
      expect(second.personality.playfulness, drifted.playfulness);
      expect(second.personality.bankKey, 'playful');
      second.dispose();
    });

    test('reopening a day later greets warmly (Bond never drops)', () async {
      final store = InMemoryLocalSaveStore();
      final first = makeController(store: store, clock: () => kDay0);
      await first.load();
      await first.adopt(species: Species.puppy, name: 'Biscuit');
      await first.interact(CareInteraction.feed);
      final bondBefore = first.pet!.bond.value;
      first.dispose();

      // Reopen one day later.
      final next = makeController(
        store: store,
        clock: () => kDay0 + 86400000 + 3600000,
      );
      await next.load();
      // Greeting can only add to the Bond — never subtract (Risk R6).
      expect(next.pet!.bond.value, greaterThanOrEqualTo(bondBefore));
      // Pet decayed but is safe.
      expect(next.pet!.meters.lowest, greaterThanOrEqualTo(15));
      next.dispose();
    });
  });
}
