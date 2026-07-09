/// Ambient companion presence (GE-2): the garden songbird visits while the
/// garden is a happy, played-in place. A pure predicate — presence is a
/// *reflection* of care already given, never a goal, a meter, or a chore
/// (the ethical translation of the genre's mini-pet loop: warmth without
/// a second care burden).
library;

/// True when the Play Garden's songbird should be visiting: the pet is
/// genuinely happy (≥ [visitorHappinessFloor]) and someone played here this
/// session. Session-scoped on purpose — the bird greets play, it never
/// "leaves" as a punishment (closing the app simply ends the visit).
bool gardenVisitorVisible({
  required double happiness,
  required int playsThisSession,
}) => happiness >= visitorHappinessFloor && playsThisSession > 0;

/// The happiness floor for a visit (well above "fine", below "perfect").
const double visitorHappinessFloor = 70;
