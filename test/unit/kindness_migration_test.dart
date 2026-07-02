/// Save schema v8 (Daily Kindnesses): the v7→v8 upgrade is invisible (no
/// slate yet — the next session offers one), and a live slate round-trips
/// losslessly. No update may orphan a pet (Risk R4).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/data/kindred_save_state.dart';
import 'package:kindredpaws/data/migration_runner.dart';
import 'package:kindredpaws/data/save_envelope.dart';
import 'package:kindredpaws/game/model/kindness.dart';

void main() {
  final runner = MigrationRunner(KindredSaveState.migrations);

  test('a v7 save upgrades to v8 with no slate (offered on next session)', () {
    // A minimal but realistic v7 envelope (what the previous release wrote).
    final v7 = KindredSaveState.newPet(
      petId: 'p-v7',
      species: 'puppy',
      name: 'Biscuit',
      nowMs: 1,
    ).toEnvelope();
    final downgraded = SaveEnvelope(
      schemaVersion: 7,
      data: Map<String, dynamic>.from(v7.data)..remove('kindness'),
    );

    final up = runner.upgrade(
      downgraded,
      KindredSaveState.currentSchemaVersion,
    );
    expect(up.schemaVersion, 8);
    expect(up.data.containsKey('kindness'), isTrue);
    final state = KindredSaveState.fromEnvelope(up);
    expect(state.pet.name, 'Biscuit');
    expect(state.kindness, isNull); // quietly filled by the next session
  });

  test('a live kindness slate round-trips losslessly (v8)', () {
    const slate = KindnessState(
      dayEpoch: 20000,
      offered: ['kind_share_a_meal', 'kind_bubble_bath'],
      completed: ['kind_share_a_meal'],
    );
    final s = KindredSaveState.newPet(
      petId: 'p-v8',
      species: 'kitten',
      name: 'Mochi',
      nowMs: 1,
    ).copyWith(kindness: slate);

    final back = KindredSaveState.fromEnvelope(s.toEnvelope());
    expect(back.kindness, slate);
  });
}
