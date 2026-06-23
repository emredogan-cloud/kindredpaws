/// Shared test harness: a deterministic [GameController] over an in-memory save
/// store + a fixed clock, with the services bootstrapped into the locator.
library;

import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/controller/game_controller.dart';
import 'package:kindredpaws/game/game_wiring.dart';

/// A clean midnight-UTC epoch (day 20000) used as a deterministic base clock.
const int kDay0 = 20000 * 86400000;

/// A fresh in-memory save store (share one across controllers to test reopen).
LocalSaveStore makeStore() => InMemoryLocalSaveStore();

GameController makeController({LocalSaveStore? store, int Function()? clock}) {
  ServiceLocator.instance.reset();
  bootstrap();
  return createGameController(
    sl: ServiceLocator.instance,
    store: store ?? InMemoryLocalSaveStore(),
    clock: clock ?? (() => kDay0),
  );
}
