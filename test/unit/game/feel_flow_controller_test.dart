/// Feel & Flow controller wiring (GE-6): the pet-side of rhythm notifications
/// and first-visit hints — open-hours recorded on session start, presence
/// scheduled on the household's real rhythm, hints once-only.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/services/notification_scheduler.dart';
import 'package:kindredpaws/services/prefs_service.dart';

import '../../support/harness.dart';

void main() {
  test(
    'opening at 08:00 across days anchors presence on that rhythm',
    () async {
      var now = kDay0 + 8 * Duration.millisecondsPerHour;
      final c = makeController(store: makeStore(), clock: () => now);
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      // Several real mornings at 08:00 build a clear histogram peak on-device.
      for (var d = 1; d <= 4; d++) {
        await c.onAppBackgrounded();
        now = kDay0 + d * Duration.millisecondsPerDay + 8 * 3600000;
        c.onAppForegrounded();
      }
      final prefs = ServiceLocator.instance.get<PrefsService>();
      expect(prefs.openHourHistogram[8], greaterThanOrEqualTo(4));

      final notes = c.notifications as InMemoryNotificationScheduler;
      expect(notes.scheduled, isNotEmpty);
      // The re-armed presence set now anchors on 08:00, not the 19:00 default.
      final hours = notes.scheduled
          .map((n) => (n.whenMs ~/ Duration.millisecondsPerHour) % 24)
          .toSet();
      expect(hours, contains(8));
      for (final n in notes.scheduled) {
        expect(n.body.contains('Biscuit'), isTrue);
      }
      c.dispose();
    },
  );

  test('first-visit hints are once-only and default-hidden in tests', () async {
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    // The harness prefs start with an empty seen-set ⇒ hints CAN show.
    expect(c.shouldShowHint('hint_kitchen'), isTrue);
    c.markHintSeen('hint_kitchen');
    expect(c.shouldShowHint('hint_kitchen'), isFalse);
    // A different hint is independent.
    expect(c.shouldShowHint('hint_bedroom'), isTrue);
    c.dispose();
  });
}
