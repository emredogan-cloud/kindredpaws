/// The garden songbird (GE-2 ambient presence): visits a happy, played-in
/// garden; never a meter, never a chore, never a punishment for leaving.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/sim/ambient_presence.dart';

void main() {
  test('visits when the pet is happy AND someone played this session', () {
    expect(gardenVisitorVisible(happiness: 80, playsThisSession: 1), isTrue);
    expect(
      gardenVisitorVisible(
        happiness: visitorHappinessFloor,
        playsThisSession: 3,
      ),
      isTrue, // at the floor counts — presence is generous
    );
  });

  test('stays away without play or without real happiness', () {
    expect(gardenVisitorVisible(happiness: 90, playsThisSession: 0), isFalse);
    expect(gardenVisitorVisible(happiness: 50, playsThisSession: 2), isFalse);
    expect(
      gardenVisitorVisible(
        happiness: visitorHappinessFloor - 0.1,
        playsThisSession: 1,
      ),
      isFalse,
    );
  });
}
