import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/bond.dart';
import 'package:kindredpaws/game/model/life_stage.dart';
import 'package:kindredpaws/game/sim/life_stage_engine.dart';

void main() {
  const engine = LifeStageEngine();

  test('a fresh pet stays Pup/Kit', () {
    final u = engine.evaluate(
      current: LifeStage.pupKit,
      bondStage: BondStage.stranger,
      activeDays: 1,
    );
    expect(u.stage, LifeStage.pupKit);
    expect(u.advanced, isFalse);
  });

  group('DUAL gate — needs BOTH Bond stage AND active days', () {
    test('Friend + 5 active days → Young One', () {
      final u = engine.evaluate(
        current: LifeStage.pupKit,
        bondStage: BondStage.friend,
        activeDays: 5,
      );
      expect(u.stage, LifeStage.youngOne);
      expect(u.advanced, isTrue);
    });

    test('Friend but only 4 days → still Pup/Kit (days gate fails)', () {
      final u = engine.evaluate(
        current: LifeStage.pupKit,
        bondStage: BondStage.friend,
        activeDays: 4,
      );
      expect(u.stage, LifeStage.pupKit);
    });

    test('10 days but only Stranger → still Pup/Kit (bond gate fails)', () {
      final u = engine.evaluate(
        current: LifeStage.pupKit,
        bondStage: BondStage.stranger,
        activeDays: 10,
      );
      expect(u.stage, LifeStage.pupKit);
    });

    test('Companion + 28 days → Grown', () {
      final u = engine.evaluate(
        current: LifeStage.youngOne,
        bondStage: BondStage.companion,
        activeDays: 28,
      );
      expect(u.stage, LifeStage.grown);
      expect(u.advanced, isTrue);
    });
  });

  group('one-directional & terminal at Grown (§6.4)', () {
    test('never regresses even if inputs would suggest a lower stage', () {
      final u = engine.evaluate(
        current: LifeStage.grown,
        bondStage: BondStage.stranger,
        activeDays: 1,
      );
      expect(u.stage, LifeStage.grown);
      expect(u.advanced, isFalse);
    });

    test('Young One does not drop back to Pup/Kit', () {
      final u = engine.evaluate(
        current: LifeStage.youngOne,
        bondStage: BondStage.stranger,
        activeDays: 1,
      );
      expect(u.stage, LifeStage.youngOne);
    });
  });
}
