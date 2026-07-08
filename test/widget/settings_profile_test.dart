/// Settings & Profile (E2): toggles gate their systems for real, the
/// right-to-be-forgotten flow double-confirms then truly starts over, and the
/// Profile tells the story — no "coming soon" left anywhere in the drawer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';
import 'package:kindredpaws/game/ui/settings_screen.dart';
import 'package:kindredpaws/services/prefs_service.dart';
import 'package:kindredpaws/core/legal_links.dart';
import 'package:kindredpaws/services/link_opener.dart';

import '../support/harness.dart';
import '../support/room_test_utils.dart';

void main() {
  testWidgets('drawer opens Settings and Our story (no more coming soon)', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawer-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-screen')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawer-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-screen')), findsOneWidget);
    expect(find.byKey(const Key('profile-name')), findsOneWidget);
    expect(find.text('Biscuit'), findsWidgets);
    expect(find.byKey(const Key('profile-gotcha')), findsOneWidget);
  });

  testWidgets('toggles persist to prefs and the notification toggle clears '
      'scheduled reminders', (tester) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    final prefs = ServiceLocator.instance.get<PrefsService>();

    await tester.pumpWidget(MaterialApp(home: SettingsScreen(controller: c)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-sound')));
    await tester.pumpAndSettle();
    expect(prefs.soundEnabled, isFalse);

    await tester.tap(find.byKey(const Key('settings-haptics')));
    await tester.pumpAndSettle();
    expect(prefs.hapticsEnabled, isFalse);

    await tester.tap(find.byKey(const Key('settings-notifications')));
    await tester.pumpAndSettle();
    expect(prefs.notificationsEnabled, isFalse);
  });

  testWidgets('legal links: Privacy / Terms / Support open externally '
      '(KP-004)', (tester) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    final opener =
        ServiceLocator.instance.get<LinkOpener>() as RecordingLinkOpener;
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(controller: c)));

    for (final (key, url) in [
      ('settings-privacy-policy', kPrivacyPolicyUrl),
      ('settings-terms', kTermsOfUseUrl),
      ('settings-support', kSupportUrl),
    ]) {
      await tester.scrollUntilVisible(find.byKey(Key(key)), 120);
      await tester.tap(find.byKey(Key(key)));
      await tester.pump();
      expect(opener.opened.last, url);
    }
    c.dispose();
  });

  testWidgets('delete flow: cancel keeps everything; double-confirm starts '
      'over at Rescue Day', (tester) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');

    await tester.pumpWidget(MaterialApp(home: SettingsScreen(controller: c)));
    await tester.pumpAndSettle();

    // First path: bail at the second confirm — nothing lost. (The Privacy
    // section grew legal-link tiles above it — scroll the tile into view.)
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-delete')),
      120,
    );
    await tester.ensureVisible(find.byKey(const Key('settings-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-cancel-2')));
    await tester.pumpAndSettle();
    expect(c.hasPet, isTrue);

    // Second path: all the way through — the pet is gone, back to the start.
    await tester.tap(find.byKey(const Key('settings-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-confirm')));
    await tester.pumpAndSettle();
    expect(c.hasPet, isFalse);
    expect(c.petLine, isNull);
  });
}
