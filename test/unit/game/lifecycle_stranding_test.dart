/// KP-021 — offline catch-up must survive a `hidden`-only background.
///
/// Some OS/embedder versions background the app delivering only `hidden`
/// (treated as transient, correctly — notification shades and app-switcher
/// peeks must not end sessions). But then `_sessionStartMs` never cleared,
/// so the next `resumed` skipped catch-up + greeting entirely. The fix: a
/// wall-clock staleness fallback — an "active" session that has been silent
/// past [GameController.kStaleSessionGapMs] is closed at its last provably-
/// alive instant and the resume resolves for real.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/core/service_locator.dart';

import '../../support/harness.dart';

const int _hour = Duration.millisecondsPerHour;
const int _day = Duration.millisecondsPerDay;

void main() {
  test('hidden-only background: a stale session still gets catch-up', () async {
    var now = kDay0;
    final c = makeController(clock: () => now);
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    final analytics =
        ServiceLocator.instance.get<ObservabilityFacade>().analytics
            as InMemoryAnalyticsService;
    final sessionsBefore = analytics.countOf(AnalyticsEvent.sessionStart);
    final energyBefore = c.pet!.meters.energy;

    // The platform backgrounds us for a day+ delivering ONLY `hidden`
    // (no onAppBackgrounded call), then the player returns.
    now = kDay0 + _day + _hour;
    c.onAppForegrounded();

    // The stale session was closed and a REAL resume ran: a fresh
    // sessionStart beat, offline decay applied, the new day granted.
    expect(
      analytics.countOf(AnalyticsEvent.sessionStart),
      sessionsBefore + 1,
      reason: 'catch-up must run after a hidden-only background',
    );
    expect(c.pet!.meters.energy, lessThan(energyBefore));
    expect(c.pet!.activeDays, 2);
    c.dispose();
  });

  test('a transient blip (shade peek) still never re-greets', () async {
    var now = kDay0;
    final c = makeController(clock: () => now);
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await c.interact(CareInteraction.feed);
    final analytics =
        ServiceLocator.instance.get<ObservabilityFacade>().analytics
            as InMemoryAnalyticsService;
    final sessionsBefore = analytics.countOf(AnalyticsEvent.sessionStart);

    // 30 seconds in the notification shade → resumed.
    now += 30000;
    c.onAppForegrounded();

    expect(
      analytics.countOf(AnalyticsEvent.sessionStart),
      sessionsBefore,
      reason: 'a transient resume must not restart the session',
    );
    c.dispose();
  });

  test('the stale-session close reports an honest duration', () async {
    var now = kDay0;
    final c = makeController(clock: () => now);
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    // Two minutes of real play, then a hidden-only background for 8 hours.
    now += 2 * 60000;
    await c.interact(CareInteraction.feed);
    now += 8 * _hour;
    c.onAppForegrounded();

    final analytics =
        ServiceLocator.instance.get<ObservabilityFacade>().analytics
            as InMemoryAnalyticsService;
    final quality = analytics.recorded
        .where((r) => r.$1 == AnalyticsEvent.sessionQuality)
        .last;
    // The closed session ends at its last provably-alive instant (~2 min),
    // not at the return instant (~8 h) — retention data stays honest.
    expect(quality.$2['duration_s'], lessThanOrEqualTo(3 * 60));
    c.dispose();
  });
}
