/// The single shared "pet status snapshot" (GAME_TECHNICAL_SYSTEMS.md §6.1).
/// ONE payload, written on every meaningful change, that feeds the whole
/// Companion Presence layer: the home widget, the (Deferred) lock-screen widget,
/// and the notification scheduler. One source → no drift, minimal native code.
///
/// It is intentionally tiny + serialization-only (no Flutter), so it can cross
/// the platform-channel / app-group boundary to a native widget unchanged.
library;

import 'care_meters.dart';
import 'life_stage.dart';
import 'mood.dart';
import 'pet_state.dart';
import 'species.dart';
import '../sim/sim_config.dart';

class PetStatusSnapshot {
  const PetStatusSnapshot({
    required this.name,
    required this.species,
    required this.lifeStage,
    required this.bondStage,
    required this.mood,
    required this.preRenderedMoodImageRef,
    required this.careStreakCount,
    required this.streakWarmthBanked,
    required this.nextSuggestedCareAtMs,
    required this.updatedAtMs,
  });

  final String name;
  final String species; // 'puppy' | 'kitten'
  final String lifeStage; // 'pupKit' | 'youngOne' | 'grown'
  final String bondStage; // 'Stranger'..'Soulmate'
  final String mood; // 'joyful' | 'content' | 'wistful' | 'low'

  /// Reference into the small pre-rendered mood-image set the native widget
  /// shows (NOT a live rig render — §6.2). Shape: `<species>_<lifeStage>_<mood>`.
  final String preRenderedMoodImageRef;

  final int careStreakCount;
  final int streakWarmthBanked;

  /// When the soonest meter is expected to dip into the "needs care" band —
  /// drives notification scheduling (never to guilt, only to invite, §6.4).
  final int nextSuggestedCareAtMs;
  final int updatedAtMs;

  /// Fallback when no meter is decaying (hours) + the minimum lead time so a
  /// suggestion is never effectively "now".
  static const double _defaultCareHours = 12.0;
  static const double _minCareLeadHours = 0.5;

  /// Builds the snapshot from the runtime [pet] + its derived [mood], estimating
  /// [nextSuggestedCareAtMs] from the meter that will reach the needs-care
  /// threshold soonest under [config].
  factory PetStatusSnapshot.fromPet({
    required PetState pet,
    required Mood mood,
    required SimConfig config,
    required int nowMs,
  }) {
    return PetStatusSnapshot(
      name: pet.name,
      species: pet.species.id,
      lifeStage: pet.lifeStage.id,
      bondStage: pet.bond.stage.displayName,
      mood: mood.name,
      preRenderedMoodImageRef:
          '${pet.species.id}_${pet.lifeStage.id}_${mood.name}',
      careStreakCount: pet.careStreak.count,
      streakWarmthBanked: pet.careStreak.warmthBanked,
      nextSuggestedCareAtMs: _nextCareAt(pet.meters, config, nowMs),
      updatedAtMs: nowMs,
    );
  }

  /// Hours until the soonest meter reaches the "needs care" threshold, → an
  /// absolute timestamp. Clamped so it is always in the (near) future.
  static int _nextCareAt(CareMeters m, SimConfig config, int nowMs) {
    double soonestHours = double.infinity;
    for (final need in CareNeed.values) {
      final rate = config.decayPerHour[need] ?? 0;
      if (rate <= 0) continue;
      final hours = (m.of(need) - config.needsCareThreshold) / rate;
      if (hours < soonestHours) soonestHours = hours;
    }
    if (!soonestHours.isFinite) soonestHours = _defaultCareHours;
    final clamped = soonestHours < _minCareLeadHours
        ? _minCareLeadHours
        : soonestHours;
    return nowMs + (clamped * Duration.millisecondsPerHour).round();
  }

  /// Convenience re-derivations for the widget/UI (kept off the wire).
  Species get speciesEnum => Species.fromId(species);
  LifeStage get lifeStageEnum => LifeStage.fromId(lifeStage);

  Map<String, dynamic> toMap() => {
    'name': name,
    'species': species,
    'lifeStage': lifeStage,
    'bondStage': bondStage,
    'mood': mood,
    'preRenderedMoodImageRef': preRenderedMoodImageRef,
    'careStreakCount': careStreakCount,
    'streakWarmthBanked': streakWarmthBanked,
    'nextSuggestedCareAtMs': nextSuggestedCareAtMs,
    'updatedAtMs': updatedAtMs,
  };

  factory PetStatusSnapshot.fromMap(Map<String, dynamic> m) =>
      PetStatusSnapshot(
        name: m['name'] as String,
        species: m['species'] as String,
        lifeStage: m['lifeStage'] as String,
        bondStage: m['bondStage'] as String,
        mood: m['mood'] as String,
        preRenderedMoodImageRef: m['preRenderedMoodImageRef'] as String,
        careStreakCount: (m['careStreakCount'] as num).toInt(),
        streakWarmthBanked: (m['streakWarmthBanked'] as num).toInt(),
        nextSuggestedCareAtMs: (m['nextSuggestedCareAtMs'] as num).toInt(),
        updatedAtMs: (m['updatedAtMs'] as num).toInt(),
      );

  @override
  bool operator ==(Object other) =>
      other is PetStatusSnapshot &&
      other.name == name &&
      other.species == species &&
      other.lifeStage == lifeStage &&
      other.bondStage == bondStage &&
      other.mood == mood &&
      other.preRenderedMoodImageRef == preRenderedMoodImageRef &&
      other.careStreakCount == careStreakCount &&
      other.streakWarmthBanked == streakWarmthBanked &&
      other.nextSuggestedCareAtMs == nextSuggestedCareAtMs &&
      other.updatedAtMs == updatedAtMs;

  @override
  int get hashCode => Object.hash(
    name,
    species,
    lifeStage,
    bondStage,
    mood,
    preRenderedMoodImageRef,
    careStreakCount,
    streakWarmthBanked,
    nextSuggestedCareAtMs,
    updatedAtMs,
  );
}
