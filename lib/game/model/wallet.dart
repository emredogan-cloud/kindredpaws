/// The three-currency wallet (GAMEPLAY_AND_PROGRESSION_BIBLE.md §8.1, brief §5).
/// Kibble = soft (earned, buys delight only); Heartstones = premium; Compassion
/// Coins = impact (non-purchasable-for-power, server-minted). In P1 only Kibble
/// moves (care rewards, daily bonus, Streak Repair cost).
library;

class Wallet {
  const Wallet({
    this.kibble = 0,
    this.heartstones = 0,
    this.compassionCoins = 0,
  });

  final int kibble;
  final int heartstones;
  final int compassionCoins;

  static const Wallet empty = Wallet();

  Wallet addKibble(int amount) => copyWith(kibble: kibble + amount);

  /// Spends [amount] Kibble if affordable; returns null if not (caller handles).
  Wallet? spendKibble(int amount) =>
      kibble >= amount ? copyWith(kibble: kibble - amount) : null;

  Wallet copyWith({int? kibble, int? heartstones, int? compassionCoins}) =>
      Wallet(
        kibble: kibble ?? this.kibble,
        heartstones: heartstones ?? this.heartstones,
        compassionCoins: compassionCoins ?? this.compassionCoins,
      );

  Map<String, int> toMap() => {
    'kibble': kibble,
    'heartstones': heartstones,
    'compassionCoins': compassionCoins,
  };

  factory Wallet.fromMap(Map<String, dynamic> m) => Wallet(
    kibble: (m['kibble'] as num?)?.toInt() ?? 0,
    heartstones: (m['heartstones'] as num?)?.toInt() ?? 0,
    compassionCoins: (m['compassionCoins'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      other is Wallet &&
      other.kibble == kibble &&
      other.heartstones == heartstones &&
      other.compassionCoins == compassionCoins;

  @override
  int get hashCode => Object.hash(kibble, heartstones, compassionCoins);
}
