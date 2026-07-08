/// The aggregate runtime pet state — the deterministic simulation operates on
/// this immutable value (copyWith returns the next state). Persistence mapping
/// to the versioned save envelope lives in the data layer.
library;

import 'bond.dart';
import 'care_meters.dart';
import 'care_streak.dart';
import 'life_stage.dart';
import 'species.dart';
import 'wallet.dart';
import '../../core/local_day.dart';

class PetState {
  const PetState({
    required this.petId,
    required this.species,
    required this.name,
    required this.lifeStage,
    required this.meters,
    required this.bond,
    required this.careStreak,
    required this.wallet,
    required this.activeDays,
    required this.lastActiveDayEpoch,
    required this.createdAtMs,
    required this.lastSimTimestampMs,
    this.sleepingSinceMs,
  });

  final String petId;
  final Species species;
  final String name;
  final LifeStage lifeStage;
  final CareMeters meters;
  final Bond bond;
  final CareStreak careStreak;
  final Wallet wallet;

  /// Count of distinct days (UTC) with ≥1 session — the elapsed-days half of
  /// the life-stage dual gate (§6.1).
  final int activeDays;
  final int? lastActiveDayEpoch;

  /// Rescue Day anchor (Gotcha Day = createdAt + 365d).
  final int createdAtMs;

  /// Last time the deterministic sim was resolved (for offline catch-up §5.7).
  final int lastSimTimestampMs;

  /// When the pet was tucked in (Bedroom), or null while awake. Sleep persists
  /// across app restarts — energy regenerates for the whole nap on wake.
  final int? sleepingSinceMs;

  bool get isSleeping => sleepingSinceMs != null;

  /// Tucked in at [nowMs] (no-op if already sleeping — sleep start is kept).
  PetState tuckedIn(int nowMs) => isSleeping ? this : _sleep(nowMs);

  /// Awake again (the wake-time energy credit is the simulation's job).
  PetState wokenUp() => _sleep(null);

  PetState _sleep(int? sinceMs) => PetState(
    petId: petId,
    species: species,
    name: name,
    lifeStage: lifeStage,
    meters: meters,
    bond: bond,
    careStreak: careStreak,
    wallet: wallet,
    activeDays: activeDays,
    lastActiveDayEpoch: lastActiveDayEpoch,
    createdAtMs: createdAtMs,
    lastSimTimestampMs: lastSimTimestampMs,
    sleepingSinceMs: sinceMs,
  );

  /// A freshly-rescued pet: topped meters, Bond=Stranger, Pup/Kit, day 0.
  factory PetState.newlyRescued({
    required String petId,
    required Species species,
    required String name,
    required int nowMs,
    UtcOffsetAt utcOffsetAt = utcOffsetNone,
  }) {
    // The adoption-day anchor lives in the player's local frame so the first
    // "new day" flips at their midnight, consistent with the sim (KP-018).
    final dayEpoch = localDayOf(nowMs, utcOffsetAt);
    return PetState(
      petId: petId,
      species: species,
      name: name,
      lifeStage: LifeStage.pupKit,
      meters: CareMeters.full,
      bond: Bond.initial,
      careStreak: CareStreak.initial,
      wallet: Wallet.empty,
      activeDays: 1,
      lastActiveDayEpoch: dayEpoch,
      createdAtMs: nowMs,
      lastSimTimestampMs: nowMs,
    );
  }

  PetState copyWith({
    String? name,
    LifeStage? lifeStage,
    CareMeters? meters,
    Bond? bond,
    CareStreak? careStreak,
    Wallet? wallet,
    int? activeDays,
    int? lastActiveDayEpoch,
    int? lastSimTimestampMs,
  }) => PetState(
    petId: petId,
    species: species,
    name: name ?? this.name,
    lifeStage: lifeStage ?? this.lifeStage,
    meters: meters ?? this.meters,
    bond: bond ?? this.bond,
    careStreak: careStreak ?? this.careStreak,
    wallet: wallet ?? this.wallet,
    activeDays: activeDays ?? this.activeDays,
    lastActiveDayEpoch: lastActiveDayEpoch ?? this.lastActiveDayEpoch,
    createdAtMs: createdAtMs,
    lastSimTimestampMs: lastSimTimestampMs ?? this.lastSimTimestampMs,
    sleepingSinceMs: sleepingSinceMs,
  );

  @override
  bool operator ==(Object other) =>
      other is PetState &&
      other.petId == petId &&
      other.species == species &&
      other.name == name &&
      other.lifeStage == lifeStage &&
      other.meters == meters &&
      other.bond == bond &&
      other.careStreak == careStreak &&
      other.wallet == wallet &&
      other.activeDays == activeDays &&
      other.lastActiveDayEpoch == lastActiveDayEpoch &&
      other.createdAtMs == createdAtMs &&
      other.lastSimTimestampMs == lastSimTimestampMs &&
      other.sleepingSinceMs == sleepingSinceMs;

  @override
  int get hashCode => Object.hash(
    petId,
    species,
    name,
    lifeStage,
    meters,
    bond,
    careStreak,
    wallet,
    activeDays,
    lastActiveDayEpoch,
    createdAtMs,
    lastSimTimestampMs,
    sleepingSinceMs,
  );
}
