/// KP-024 / KP-025 / KP-026 — flow-level UX fixes: no stranded spinner,
/// onboarding skip/back for repeat players, swipe discoverability.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/game_root.dart';
import 'package:kindredpaws/game/ui/rescue_day_screen.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';

import '../support/harness.dart';
import '../support/room_test_utils.dart';

/// A store whose read never completes — a hung platform channel.
class _HangingStore implements LocalSaveStore {
  @override
  Future<String?> read() => Completer<String?>().future;
  @override
  Future<void> write(String json) async {}
  @override
  Future<void> delete() async {}
  @override
  Future<void> writeBackup(String blob) async {}
  @override
  Future<String?> readBackup() async => null;
}

void main() {
  group('KP-024 — the load can never strand the player', () {
    testWidgets('a hung load times out into the retry surface', (tester) async {
      final c = makeController(store: _HangingStore());
      addTearDown(c.dispose);
      await tester.pumpWidget(MaterialApp(home: GameRoot(controller: c)));
      await tester.pump();
      expect(find.byKey(const Key('game-loading')), findsOneWidget);

      // The watchdog fires after the timeout — spinner → gentle retry.
      await tester.pump(const Duration(seconds: 13));
      expect(find.byKey(const Key('game-load-stuck')), findsOneWidget);
      expect(find.byKey(const Key('game-load-retry')), findsOneWidget);

      // Retry restarts the watchdog cycle (still hung → stuck again).
      await tester.tap(find.byKey(const Key('game-load-retry')));
      await tester.pump();
      expect(find.byKey(const Key('game-loading')), findsOneWidget);
      await tester.pump(const Duration(seconds: 13));
      expect(find.byKey(const Key('game-load-stuck')), findsOneWidget);
    });

    testWidgets('a fast load never shows the stuck surface', (tester) async {
      final c = makeController();
      addTearDown(c.dispose);
      await tester.pumpWidget(MaterialApp(home: GameRoot(controller: c)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('game-load-stuck')), findsNothing);
      expect(find.byType(RescueDayScreen), findsOneWidget);
    });
  });

  group('KP-025 — onboarding skip + back', () {
    testWidgets('skip jumps to the species choice; back steps a beat', (
      tester,
    ) async {
      phoneView(tester);
      final c = makeController();
      addTearDown(c.dispose);
      await c.load();
      await tester.pumpWidget(
        MaterialApp(home: RescueDayScreen(controller: c)),
      );
      await tester.pumpAndSettle();

      // Beat 0: no back affordance yet; advance to beat 1 → back appears.
      expect(find.byKey(const Key('rescue-back')), findsNothing);
      await tester.tap(find.byKey(const Key('rescue-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rescue-back')), findsOneWidget);

      // Back returns to beat 0.
      await tester.tap(find.byKey(const Key('rescue-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rescue-back')), findsNothing);

      // Skip lands straight on the species choice.
      await tester.tap(find.byKey(const Key('rescue-skip')));
      await tester.pumpAndSettle();
      expect(find.text('Puppy'), findsOneWidget);
      expect(find.text('Kitten'), findsOneWidget);
    });
  });

  group('KP-026 — swipe discoverability', () {
    testWidgets('the nudge shows once, then never again', (tester) async {
      phoneView(tester);
      final c = makeController();
      addTearDown(c.dispose);
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('swipe-nudge')), findsOneWidget);

      // Discovering the swipe (a page change) retires it for good.
      await tester.fling(
        find.byKey(const Key('room-pages')),
        const Offset(-400, 0),
        1200,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('swipe-nudge')), findsNothing);

      // A rebuild (fresh visit) never brings it back — device-persistent.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('swipe-nudge')), findsNothing);
    });
  });
}
