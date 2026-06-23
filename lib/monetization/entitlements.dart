/// What the player currently owns (P3-5a). Deliberately tiny + cosmetic/QoL
/// only: the subscription flag drives an ad-light experience + delight bonuses,
/// and **never** touches the Bond, Care Meters, memory, or the no-death floor
/// (ethical wall §18: cancelling Forever Friends never harms the pet).
library;

class Entitlements {
  const Entitlements({this.foreverFriends = false});

  /// Whether the Forever Friends subscription is active.
  final bool foreverFriends;

  /// QoL: subscribers get the calm, ad-light experience. Ads are never a
  /// punishment for not paying; this only removes interstitials.
  bool get removesInterstitials => foreverFriends;

  /// Delight: subscribers get a small daily Kibble top-up (cosmetic currency).
  bool get dailyKibbleBonus => foreverFriends;

  static const Entitlements none = Entitlements();

  Entitlements copyWith({bool? foreverFriends}) =>
      Entitlements(foreverFriends: foreverFriends ?? this.foreverFriends);

  @override
  bool operator ==(Object other) =>
      other is Entitlements && other.foreverFriends == foreverFriends;

  @override
  int get hashCode => foreverFriends.hashCode;
}
