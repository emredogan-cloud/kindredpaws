import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/services/analytics_service.dart';

import '../../support/harness.dart';

void main() {
  group('session lifecycle → sessionQuality (P3-7)', () {
    test(
      'backgrounding emits sessionQuality with the tally + duration',
      () async {
        var now = kDay0;
        final c = makeController(clock: () => now);
        await c.load();
        await c.adopt(
          species: Species.puppy,
          name: 'Biscuit',
        ); // session begins
        final analytics = c.observability.analytics as InMemoryAnalyticsService;

        await c.interact(CareInteraction.feed);
        await c.interact(CareInteraction.play);

        now = kDay0 + 45000; // +45s of play
        await c.onAppBackgrounded();

        expect(analytics.countOf(AnalyticsEvent.sessionQuality), 1);
        final rec = analytics.recorded.firstWhere(
          (e) => e.$1 == AnalyticsEvent.sessionQuality,
        );
        expect(rec.$2['empty'], isFalse);
        expect(rec.$2['interactions_n'], 2);
        expect(rec.$2['duration_s'], 45);
        c.dispose();
      },
    );

    test('a session with no care interactions reports empty=true', () async {
      var now = kDay0;
      final c = makeController(clock: () => now);
      await c.load();
      await c.adopt(species: Species.kitten, name: 'Mochi');
      final analytics = c.observability.analytics as InMemoryAnalyticsService;

      now = kDay0 + 5000;
      await c.onAppBackgrounded();

      final rec = analytics.recorded.firstWhere(
        (e) => e.$1 == AnalyticsEvent.sessionQuality,
      );
      expect(rec.$2['empty'], isTrue);
      expect(rec.$2['interactions_n'], 0);
      c.dispose();
    });

    test(
      'no session active (Rescue Day, no pet) ⇒ no sessionQuality',
      () async {
        final c = makeController(clock: () => kDay0);
        await c.load(); // no save ⇒ no pet ⇒ no session clock armed
        await c.onAppBackgrounded();
        expect(
          (c.observability.analytics as InMemoryAnalyticsService).countOf(
            AnalyticsEvent.sessionQuality,
          ),
          0,
        );
        c.dispose();
      },
    );

    test(
      'a second background before foreground does not double-emit',
      () async {
        final c = makeController(clock: () => kDay0);
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit');
        final analytics = c.observability.analytics as InMemoryAnalyticsService;

        await c.onAppBackgrounded();
        await c.onAppBackgrounded(); // idempotent
        expect(analytics.countOf(AnalyticsEvent.sessionQuality), 1);
        c.dispose();
      },
    );

    test(
      'foregrounding starts a fresh session (new sessionStart + quality)',
      () async {
        var now = kDay0;
        final c = makeController(clock: () => now);
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit');
        final analytics = c.observability.analytics as InMemoryAnalyticsService;

        await c.onAppBackgrounded(); // ends session #1 (quality #1)
        now = kDay0 + 3600000; // an hour later
        c.onAppForegrounded(); // starts session #2 (a fresh sessionStart)
        now = kDay0 + 3600000 + 10000;
        await c.onAppBackgrounded(); // ends session #2 (quality #2)

        expect(analytics.countOf(AnalyticsEvent.sessionQuality), 2);
        // Onboarding emits rescueDayComplete (not sessionStart); the foreground
        // resume is the one returning-session sessionStart here.
        expect(analytics.countOf(AnalyticsEvent.sessionStart), 1);
        c.dispose();
      },
    );

    test(
      'a foreground while a session is still active is a no-op (P3-8 fix)',
      () async {
        final c = makeController(clock: () => kDay0);
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit'); // session armed
        final analytics = c.observability.analytics as InMemoryAnalyticsService;
        final startsBefore = analytics.countOf(AnalyticsEvent.sessionStart);

        // A transient resumed (after `inactive`, no real background) must NOT
        // re-resolve catch-up or emit a fresh sessionStart — the session is live.
        c.onAppForegrounded();

        expect(analytics.countOf(AnalyticsEvent.sessionStart), startsBefore);
        expect(analytics.countOf(AnalyticsEvent.sessionQuality), 0);
        c.dispose();
      },
    );
  });
}
