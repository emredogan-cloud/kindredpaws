/// Seasons of Us × GameController (GE-5): the hemisphere toggle flips the
/// season, five gentle active days mint the season keepsake exactly once
/// (a window that survives restarts), and the v9→v10 upgrade is invisible.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/data/kindred_save_state.dart';
import 'package:kindredpaws/data/migration_runner.dart';
import 'package:kindredpaws/data/save_envelope.dart';
import 'package:kindredpaws/game/model/season_progress.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/season_engine.dart';
import 'package:kindredpaws/keepsake/keepsake.dart';
import 'package:kindredpaws/services/prefs_service.dart';

import '../../support/harness.dart';

void main() {
  test(
    'kDay0 is an autumn day; the Settings toggle flips it to spring',
    () async {
      final c = makeController();
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      expect(c.season, NatureSeason.autumn); // 2024-10-04

      final prefs = ServiceLocator.instance.get<PrefsService>();
      await prefs.setSouthernHemisphere(true);
      expect(c.season, NatureSeason.spring);
      expect(c.seasonAccent, NatureSeason.spring); // kill-switch off ⇒ dressed
      c.dispose();
    },
  );

  test('five gentle days mint the season keepsake exactly once', () async {
    final store = makeStore();
    var now = kDay0;
    final c = makeController(store: store, clock: () => now);
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    // Adoption day doesn't count (no resume) — five fresh mornings follow.
    for (var day = 1; day <= 5; day++) {
      await c.onAppBackgrounded();
      now = kDay0 + day * Duration.millisecondsPerDay + 3600000;
      c.onAppForegrounded();
      await Future<void>.delayed(Duration.zero); // let the persist settle
    }
    final minted = c.keepsakes
        .where((k) => k.kind == KeepsakeKind.season)
        .toList();
    expect(minted.length, 1);
    expect(minted.single.caption, contains('autumn'));

    // A sixth day never re-mints (the window key is the keepsake id).
    await c.onAppBackgrounded();
    now = kDay0 + 6 * Duration.millisecondsPerDay + 3600000;
    c.onAppForegrounded();
    await Future<void>.delayed(Duration.zero);
    expect(c.keepsakes.where((k) => k.kind == KeepsakeKind.season).length, 1);
    expect(c.pet, isNotNull);
    c.dispose();
  });

  test('the count survives a reopen mid-window', () async {
    final store = makeStore();
    var now = kDay0;
    final first = makeController(store: store, clock: () => now);
    await first.load();
    await first.adopt(species: Species.puppy, name: 'Biscuit');
    for (var day = 1; day <= 2; day++) {
      await first.onAppBackgrounded();
      now = kDay0 + day * Duration.millisecondsPerDay + 3600000;
      first.onAppForegrounded();
      await Future<void>.delayed(Duration.zero);
    }
    await first.onAppBackgrounded();
    first.dispose();

    now = kDay0 + 3 * Duration.millisecondsPerDay + 3600000;
    final second = makeController(store: store, clock: () => now);
    await second.load();
    // Day 3 counted on load; two more mornings finish the window.
    for (var day = 4; day <= 5; day++) {
      await second.onAppBackgrounded();
      now = kDay0 + day * Duration.millisecondsPerDay + 3600000;
      second.onAppForegrounded();
      await Future<void>.delayed(Duration.zero);
    }
    expect(
      second.keepsakes.where((k) => k.kind == KeepsakeKind.season).length,
      1,
      reason: 'three days before + two after the reopen = five',
    );
    second.dispose();
  });

  test('a v9 save upgrades to v10 with no window (counts from next day)', () {
    final v10 = KindredSaveState.newPet(
      petId: 'p-v9',
      species: 'puppy',
      name: 'Biscuit',
      nowMs: 1,
    ).toEnvelope();
    final v9 = SaveEnvelope(
      schemaVersion: 9,
      data: Map<String, dynamic>.from(v10.data)..remove('seasonProgress'),
    );
    final runner = MigrationRunner(KindredSaveState.migrations);
    final up = runner.upgrade(v9, KindredSaveState.currentSchemaVersion);
    // Pinned to the CURRENT schema (not literal 10) — the chain has grown
    // since (v11: care-Kibble faucet tally, KP-014).
    expect(up.schemaVersion, KindredSaveState.currentSchemaVersion);
    final state = KindredSaveState.fromEnvelope(up);
    expect(state.seasonProgress, isNull);
  });

  test('season progress round-trips losslessly (v10)', () {
    const progress = SeasonProgress(windowKey: 'autumn-2024', days: 3);
    final s = KindredSaveState.newPet(
      petId: 'p-v10',
      species: 'kitten',
      name: 'Mochi',
      nowMs: 1,
    ).copyWith(seasonProgress: progress);
    expect(
      KindredSaveState.fromEnvelope(s.toEnvelope()).seasonProgress,
      progress,
    );
  });
}
