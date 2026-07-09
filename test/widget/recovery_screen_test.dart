/// KP-010 — the save-recovery screen routes and guards correctly: an
/// unreadable save never lands on Rescue Day, retry re-runs the load, and
/// "start over" is double-confirmed before adoption re-opens.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/data/kindred_save_state.dart';
import 'package:kindredpaws/data/save_envelope.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/ui/game_root.dart';
import 'package:kindredpaws/game/ui/rescue_day_screen.dart';

import '../support/harness.dart';

void main() {
  Future<void> pumpRoot(WidgetTester tester, LocalSaveStore store) async {
    final controller = makeController(store: store);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: GameRoot(controller: controller)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('corrupt save shows recovery, not Rescue Day', (tester) async {
    final store = InMemoryLocalSaveStore();
    await store.write('{"schemaVersion": 10, "data": {"petId": "p1", tru');
    await pumpRoot(tester, store);

    expect(find.byKey(const Key('save-recovery')), findsOneWidget);
    expect(find.byType(RescueDayScreen), findsNothing);
    expect(find.byKey(const Key('recovery-retry')), findsOneWidget);
    expect(find.byKey(const Key('recovery-fresh-start')), findsOneWidget);
  });

  testWidgets('newer-schema save shows update copy without fresh-start', (
    tester,
  ) async {
    final store = InMemoryLocalSaveStore();
    await store.write(
      const SaveEnvelope(
        schemaVersion: KindredSaveState.currentSchemaVersion + 1,
        data: {'petId': 'p1'},
      ).toJsonString(),
    );
    await pumpRoot(tester, store);

    expect(find.byKey(const Key('save-recovery')), findsOneWidget);
    expect(find.textContaining('newer version'), findsOneWidget);
    expect(find.byKey(const Key('recovery-fresh-start')), findsNothing);
  });

  testWidgets('retry heals once the store reads clean again', (tester) async {
    final store = InMemoryLocalSaveStore();
    await store.write('garbage');
    await pumpRoot(tester, store);
    expect(find.byKey(const Key('save-recovery')), findsOneWidget);

    // The blob becomes readable (e.g. transient I/O hiccup resolved).
    await store.write(
      KindredSaveState.newPet(
        petId: kTestPetId,
        species: 'puppy',
        name: 'Biscuit',
        nowMs: kDay0,
      ).toEnvelope().toJsonString(),
    );
    await tester.tap(find.byKey(const Key('recovery-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('save-recovery')), findsNothing);
    expect(find.byType(RescueDayScreen), findsNothing); // the pet is home
  });

  testWidgets('start over demands confirmation, then opens Rescue Day', (
    tester,
  ) async {
    final store = InMemoryLocalSaveStore();
    await store.write('garbage');
    await pumpRoot(tester, store);

    await tester.tap(find.byKey(const Key('recovery-fresh-start')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('recovery-fresh-start-confirm')),
      findsOneWidget,
    );

    // Cancelling keeps the recovery screen (and the quarantined blob).
    await tester.tap(find.byKey(const Key('recovery-fresh-start-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('save-recovery')), findsOneWidget);

    // Confirming routes to Rescue Day; the backup still holds the old blob.
    await tester.tap(find.byKey(const Key('recovery-fresh-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recovery-fresh-start-yes')));
    await tester.pumpAndSettle();
    expect(find.byType(RescueDayScreen), findsOneWidget);
    expect(await store.readBackup(), 'garbage');
  });
}
