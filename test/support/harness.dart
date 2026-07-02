/// Shared test harness: a deterministic [GameController] over an in-memory save
/// store + a fixed clock, with the services bootstrapped into the locator.
library;

import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/controller/game_controller.dart';
import 'package:kindredpaws/game/game_wiring.dart';
import 'package:kindredpaws/services/share_service.dart';

/// A clean midnight-UTC epoch (day 20000) used as a deterministic base clock.
const int kDay0 = 20000 * 86400000;

/// A fresh in-memory save store (share one across controllers to test reopen).
LocalSaveStore makeStore() => InMemoryLocalSaveStore();

/// The fixed test pet id. Chosen so the Daily Kindness pair on [kDay0]'s day
/// is exactly [wellness_ritual, pantry_restock] — the two triggers with the
/// smallest overlap with existing exact-value pins (care verbs, sleep, and
/// mini-games never complete a kindness under this id at kDay0). Determinism
/// matters more than realism here: a random id would make kindness credits
/// flake economy assertions run-to-run.
const String kTestPetId = 'pet-test-47';

GameController makeController({
  LocalSaveStore? store,
  int Function()? clock,
  ShareService? share,
}) {
  ServiceLocator.instance.reset();
  bootstrap();
  if (share != null) {
    ServiceLocator.instance.registerSingleton<ShareService>(share);
  }
  return createGameController(
    sl: ServiceLocator.instance,
    store: store ?? InMemoryLocalSaveStore(),
    clock: clock ?? (() => kDay0),
    idGenerator: () => kTestPetId,
  );
}
