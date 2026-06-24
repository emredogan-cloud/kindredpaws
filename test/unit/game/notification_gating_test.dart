import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/game_wiring.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/services/live_ops.dart';
import 'package:kindredpaws/services/notification_scheduler.dart';
import 'package:kindredpaws/services/remote_config_service.dart';

import '../../support/harness.dart';

void main() {
  setUp(ServiceLocator.instance.reset);

  group('notifications respect the LiveOps kill-switch (P4 audit)', () {
    test('a killed notifications feature suppresses scheduling', () async {
      bootstrap();
      // Founder kills notifications live (incident mitigation, no app update).
      ServiceLocator.instance.registerSingleton<LiveOps>(
        const LiveOps(DefaultRemoteConfig({'killswitch.notifications': true})),
      );
      final c = createGameController(
        sl: ServiceLocator.instance,
        store: InMemoryLocalSaveStore(),
        clock: () => kDay0,
      );
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      // The bond-stage celebration + daily presence are both suppressed.
      expect(
        (c.notifications as InMemoryNotificationScheduler).scheduled,
        isEmpty,
      );
      c.dispose();
    });

    test('by default (not killed) notifications schedule normally', () async {
      bootstrap();
      final c = createGameController(
        sl: ServiceLocator.instance,
        store: InMemoryLocalSaveStore(),
        clock: () => kDay0,
      );
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      expect(
        (c.notifications as InMemoryNotificationScheduler).scheduled,
        isNotEmpty,
      );
      c.dispose();
    });
  });
}
