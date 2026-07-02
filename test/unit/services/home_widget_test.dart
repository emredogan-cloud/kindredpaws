import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/game/model/mood.dart';
import 'package:kindredpaws/game/model/pet_state.dart';
import 'package:kindredpaws/game/model/pet_status_snapshot.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/sim/sim_config.dart';
import 'package:kindredpaws/services/home_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/harness.dart';

const _day0 = 20000 * 86400000;

PetStatusSnapshot _snap() => PetStatusSnapshot.fromPet(
  pet: PetState.newlyRescued(
    petId: 'p1',
    species: Species.puppy,
    name: 'Biscuit',
    nowMs: _day0,
  ),
  mood: Mood.joyful,
  config: const SimConfig(),
  nowMs: _day0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NoopHomeWidgetService', () {
    test('records the published payload', () async {
      final svc = NoopHomeWidgetService();
      await svc.update(_snap());
      expect(svc.updates, 1);
      expect(svc.lastPublished!.name, 'Biscuit');
    });
  });

  group('PrefsHomeWidgetService', () {
    test(
      'writes the snapshot JSON to the shared key the native widget reads',
      () async {
        SharedPreferences.setMockInitialValues({});
        await PrefsHomeWidgetService().update(_snap());

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(kHomeWidgetKey);
        expect(raw, isNotNull);
        final map = jsonDecode(raw!) as Map<String, dynamic>;
        expect(map['name'], 'Biscuit');
        expect(map['mood'], 'joyful');
        // Round-trips back into a snapshot the widget can render.
        expect(PetStatusSnapshot.fromMap(map).name, 'Biscuit');
      },
    );
  });

  group('GameController pushes to the widget bridge', () {
    test('the home widget is updated on adopt + interact', () async {
      final c = makeController(clock: () => _day0);
      await c.load();
      final widget =
          ServiceLocator.instance.get<HomeWidgetService>()
              as NoopHomeWidgetService;
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      expect(widget.updates, greaterThan(0));
      expect(widget.lastPublished!.name, 'Biscuit');

      final before = widget.updates;
      await c.interact(CareInteraction.feed);
      expect(widget.updates, greaterThan(before));
      c.dispose();
    });
  });
}
