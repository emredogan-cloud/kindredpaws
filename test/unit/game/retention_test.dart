import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/content/content_validator.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/services/analytics_service.dart';

import '../../support/harness.dart';

const int _day = Duration.millisecondsPerDay;

void main() {
  group('retention beats (P5-2) — never guilt', () {
    // Adopt at kDay0, then reopen at kDay0 + [days] (a fresh session that day).
    Future<({int? milestoneDay, String? line})> reopenAfter(int days) async {
      final store = makeStore();
      final c1 = makeController(store: store, clock: () => kDay0);
      await c1.load();
      await c1.adopt(species: Species.puppy, name: 'Biscuit');
      c1.dispose();

      final c2 = makeController(store: store, clock: () => kDay0 + days * _day);
      await c2.load();
      final analytics = c2.observability.analytics as InMemoryAnalyticsService;
      final milestone = analytics.recorded
          .where((e) => e.$1 == AnalyticsEvent.retentionMilestone)
          .map((e) => e.$2['day'] as int?)
          .toList();
      final line = c2.petLine;
      c2.dispose();
      return (
        milestoneDay: milestone.isEmpty ? null : milestone.last,
        line: line,
      );
    }

    test('a D7 return emits retentionMilestone {day: 7}', () async {
      expect((await reopenAfter(7)).milestoneDay, 7);
    });

    test('a non-milestone day (D5) emits no retentionMilestone', () async {
      expect((await reopenAfter(5)).milestoneDay, isNull);
    });

    test(
      'Gotcha Day (the adoption anniversary) celebrates + signals',
      () async {
        final r = await reopenAfter(365);
        expect(r.milestoneDay, 365);
        expect(r.line, isNotNull); // the pet says a warm milestone line
      },
    );

    test('a returning beat after any absence is warm, never guilt', () async {
      // D7 return ⇒ a "returning" greeting line is surfaced.
      final r = await reopenAfter(7);
      expect(r.line, isNotNull);
      final lower = r.line!.toLowerCase();
      for (final w in ContentValidator.forbiddenGuiltLanguage) {
        expect(lower.contains(w), isFalse, reason: '"$lower" contains "$w"');
      }
    });
  });
}
