/// The Play Garden's mini games (Product Evolution E4 + GE-4) — tiny, warm,
/// and **no-fail by design**: nothing can be lost, sessions end by a gentle
/// timer, and every ending is a celebration. Engines are pure Dart with
/// fixed-step ticks and seeded pseudo-randomness (index-hashed, no
/// `dart:math` Random) so every frame of gameplay is deterministic and
/// unit-testable; the UI layer stays a thin painter.
library;

import 'dart:math' as math;

/// Deterministic pseudo-random stream (same hash family the painters use).
double _hashFrac(int seed, int i) {
  var x = (seed + i * 2654435761) & 0x7FFFFFFF;
  x ^= x >> 13;
  x *= 0x5bd1e995;
  x ^= x >> 15;
  return (x & 0xFFFF) / 0xFFFF;
}

/// The shared engine contract (GE-4 kit): every garden game is a pure,
/// fixed-step, seeded simulation with a monotone score and a timer-only
/// ending — no-fail by TYPE, not just by convention. The UI stays a thin
/// painter + gesture shim over one of these.
abstract interface class MiniGameEngine {
  double get sessionSeconds;
  double get elapsed;

  /// Joy scored so far. Only ever grows.
  int get score;

  /// True once the gentle timer has run out (the only way a session ends).
  bool get finished;

  /// Advances the simulation by [dt] seconds (fixed-step from the UI ticker).
  void tick(double dt);
}

/// ── Bounce! ────────────────────────────────────────────────────────────────
/// Keep the ball happily in the air: tap to boop it back up. If it lands, it
/// just rests on the cushion until the next tap — resting is cozy, not
/// failure. The session ends by timer; the score only ever grows.
class BounceGame implements MiniGameEngine {
  BounceGame({this.sessionSeconds = 45, this.seed = 7});

  @override
  final double sessionSeconds;
  final int seed;

  @override
  int get score => bounces;

  /// Normalized field: x,y ∈ 0..1 (y grows downward; 1 = the cushion).
  double ballX = 0.5;
  double ballY = 0.55;
  double vx = 0.12;
  double vy = -0.2;
  @override
  double elapsed = 0;
  int bounces = 0;
  bool get resting => _resting;
  bool _resting = false;
  @override
  bool get finished => elapsed >= sessionSeconds;

  static const double _gravity = 0.55; // field-units / s²
  static const double _boost = -0.62; // tap impulse
  static const double _ballRadius = 0.055;

  /// Advances the simulation by [dt] seconds (fixed-step from the UI ticker).
  @override
  void tick(double dt) {
    if (finished) return;
    elapsed += dt;
    if (_resting) return; // cozy on the cushion, waiting for a boop
    vy += _gravity * dt;
    ballX += vx * dt;
    ballY += vy * dt;
    // Soft side walls.
    if (ballX < _ballRadius) {
      ballX = _ballRadius;
      vx = vx.abs();
    } else if (ballX > 1 - _ballRadius) {
      ballX = 1 - _ballRadius;
      vx = -vx.abs();
    }
    // The cushion: landing is a rest, never a loss.
    if (ballY >= 1 - _ballRadius) {
      ballY = 1 - _ballRadius;
      vy = 0;
      vx = 0;
      _resting = true;
    }
    // A gentle ceiling so boops can't fly the ball away.
    if (ballY < _ballRadius) {
      ballY = _ballRadius;
      vy = vy.abs() * 0.5;
    }
  }

  /// A boop! Any tap lifts the ball (wherever it is) — generosity by design.
  /// Returns true (the score grew) so the UI can sparkle.
  bool boop() {
    if (finished) return false;
    bounces++;
    _resting = false;
    vy = _boost;
    // A seeded sideways nudge keeps the arc lively but reproducible.
    vx = (_hashFrac(seed, bounces) - 0.5) * 0.5;
    return true;
  }
}

/// ── Snack Catch ────────────────────────────────────────────────────────────
/// Snacks drift down the garden; slide the basket to catch them. A missed
/// snack is simply shared with the garden birds (🐦 no penalty, ever). Timer
/// ends the session in a celebration of everything caught.
class SnackCatchGame implements MiniGameEngine {
  SnackCatchGame({this.sessionSeconds = 45, this.seed = 11});

  @override
  final double sessionSeconds;
  final int seed;

  double basketX = 0.5;
  @override
  double elapsed = 0;
  int caught = 0;
  int sharedWithBirds = 0;
  final List<FallingSnack> snacks = [];
  int _spawned = 0;
  double _sinceSpawn = 0;
  @override
  bool get finished => elapsed >= sessionSeconds;

  @override
  int get score => caught;

  static const double _fallSpeed = 0.28; // field-units / s
  static const double _spawnEvery = 1.4; // s
  static const double _basketHalfWidth = 0.11;
  static const double _catchLine = 0.86;

  void moveBasket(double x) => basketX = x.clamp(0.06, 0.94);

  @override
  void tick(double dt) {
    if (finished) return;
    elapsed += dt;
    _sinceSpawn += dt;
    if (_sinceSpawn >= _spawnEvery) {
      _sinceSpawn -= _spawnEvery;
      snacks.add(
        FallingSnack(
          x: 0.1 + 0.8 * _hashFrac(seed, _spawned),
          y: -0.05,
          emojiIndex: _spawned % FallingSnack.faces.length,
        ),
      );
      _spawned++;
    }
    for (final snack in snacks) {
      snack.y += _fallSpeed * dt;
      if (!snack.settled && snack.y >= _catchLine) {
        if ((snack.x - basketX).abs() <= _basketHalfWidth) {
          snack.settled = true;
          snack.caught = true;
          caught++;
        } else if (snack.y >= 1.02) {
          snack.settled = true;
          sharedWithBirds++; // the garden birds say thank you
        }
      }
    }
    snacks.removeWhere((s) => s.settled && !s.caught);
    snacks.removeWhere((s) => s.caught && s.y > 1.2);
  }
}

class FallingSnack {
  FallingSnack({required this.x, required this.y, required this.emojiIndex});

  static const faces = ['🍎', '🥕', '🍇', '🍪', '🐟'];

  final double x;
  double y;
  final int emojiIndex;
  bool settled = false;
  bool caught = false;

  String get face => faces[emojiIndex];
}

/// ── Bubble Drift (GE-4) ────────────────────────────────────────────────────
/// Bubbles rise through the garden air; tap one to pop it into sparkles.
/// A bubble that floats past simply goes off to see the clouds (☁️ no
/// penalty, ever). Tapping empty air makes a friendly little ripple.
class BubbleDriftGame implements MiniGameEngine {
  BubbleDriftGame({this.sessionSeconds = 45, this.seed = 13});

  @override
  final double sessionSeconds;
  final int seed;

  @override
  double elapsed = 0;
  int popped = 0;

  /// Bubbles that drifted off to see the clouds (a warm note, never a miss).
  int cloudBound = 0;

  final List<DriftBubble> bubbles = [];
  int _spawned = 0;
  double _sinceSpawn = 0;

  @override
  bool get finished => elapsed >= sessionSeconds;
  @override
  int get score => popped;

  static const double _spawnEvery = 1.05; // s
  static const double _popRadius = 0.11; // generous for small hands

  @override
  void tick(double dt) {
    if (finished) return;
    elapsed += dt;
    _sinceSpawn += dt;
    if (_sinceSpawn >= _spawnEvery) {
      _sinceSpawn -= _spawnEvery;
      bubbles.add(
        DriftBubble(
          baseX: 0.12 + 0.76 * _hashFrac(seed, _spawned),
          y: 1.06,
          r: 0.045 + 0.03 * _hashFrac(seed + 1, _spawned),
          rise: 0.14 + 0.08 * _hashFrac(seed + 2, _spawned),
          swayPhase: _hashFrac(seed + 3, _spawned) * 6.283,
          hueIndex: _spawned % DriftBubble.tints.length,
        ),
      );
      _spawned++;
    }
    for (final b in bubbles) {
      if (b.popped) {
        b.popAge += dt; // sparkle bloom, then gone
        continue;
      }
      b.y -= b.rise * dt;
      b.swayPhase += dt * 1.7;
      if (b.y < -0.08) {
        b.gone = true;
        cloudBound++; // off to see the clouds
      }
    }
    bubbles.removeWhere((b) => b.gone || b.popAge > 0.45);
  }

  /// A tap at normalized ([x], [y]): pops the nearest bubble within reach.
  /// Returns true when one popped (the UI sparkles); empty air just ripples.
  bool popAt(double x, double y) {
    if (finished) return false;
    DriftBubble? nearest;
    var best = double.infinity;
    for (final b in bubbles) {
      if (b.popped || b.gone) continue;
      final dx = b.x - x;
      final dy = b.y - y;
      final d2 = dx * dx + dy * dy;
      if (d2 < best) {
        best = d2;
        nearest = b;
      }
    }
    if (nearest == null) return false;
    final reach = _popRadius + nearest.r;
    if (best > reach * reach) return false;
    nearest.popped = true;
    popped++;
    return true;
  }
}

class DriftBubble {
  DriftBubble({
    required this.baseX,
    required this.y,
    required this.r,
    required this.rise,
    required this.swayPhase,
    required this.hueIndex,
  });

  static const tints = [0xAAB8DCF0, 0xAAF0D8B8, 0xAADCC8F0, 0xAAC8F0D2];

  final double baseX;
  double y;
  final double r;
  final double rise;
  double swayPhase;
  final int hueIndex;
  bool popped = false;
  double popAge = 0;
  bool gone = false;

  /// Sway is pure math over the phase — deterministic (no Random anywhere).
  double get x => baseX + 0.03 * math.sin(swayPhase);
}

/// ── Starlight Trail (GE-4) ─────────────────────────────────────────────────
/// One-touch night glide: hold anywhere and the little glow-firefly rises;
/// let go and it drifts softly down (drifting is floating, never falling).
/// Glimmers stream by — passing close collects them; the rest simply
/// twinkle on across the night. No walls, no crash, no fail state.
class StarlightTrailGame implements MiniGameEngine {
  StarlightTrailGame({this.sessionSeconds = 45, this.seed = 17});

  @override
  final double sessionSeconds;
  final int seed;

  @override
  double elapsed = 0;

  /// The firefly's height (0 top … 1 bottom); x is fixed at [fireflyX].
  double fireflyY = 0.5;
  bool holding = false;
  int collected = 0;

  /// Glimmers that twinkled on across the night (a warm note, no penalty).
  int twinkledOn = 0;

  final List<TrailGlimmer> glimmers = [];
  int _spawned = 0;
  double _sinceSpawn = 0;

  @override
  bool get finished => elapsed >= sessionSeconds;
  @override
  int get score => collected;

  static const double fireflyX = 0.28;
  static const double _riseSpeed = 0.26; // held: gentle climb
  static const double _driftSpeed = 0.17; // released: soft float down
  static const double _streamSpeed = 0.23; // glimmer travel
  static const double _spawnEvery = 0.95; // s
  static const double _collectRadius = 0.085;

  /// Press = rise, release = drift. One verb, any finger, anywhere.
  // ignore: use_setters_to_change_properties
  void setHolding(bool value) => holding = value;

  @override
  void tick(double dt) {
    if (finished) return;
    elapsed += dt;
    fireflyY += (holding ? -_riseSpeed : _driftSpeed) * dt;
    fireflyY = fireflyY.clamp(0.08, 0.9);
    _sinceSpawn += dt;
    if (_sinceSpawn >= _spawnEvery) {
      _sinceSpawn -= _spawnEvery;
      glimmers.add(
        TrailGlimmer(x: 1.06, y: 0.12 + 0.72 * _hashFrac(seed, _spawned)),
      );
      _spawned++;
    }
    for (final g in glimmers) {
      g.x -= _streamSpeed * dt;
      if (!g.collected) {
        final dx = g.x - fireflyX;
        final dy = g.y - fireflyY;
        if (dx * dx + dy * dy <= _collectRadius * _collectRadius) {
          g.collected = true;
          collected++;
        }
      }
      if (g.collected) g.collectAge += dt;
    }
    glimmers.removeWhere((g) {
      if (g.collected && g.collectAge > 0.4) return true;
      if (!g.collected && g.x < -0.06) {
        twinkledOn++;
        return true;
      }
      return false;
    });
  }
}

class TrailGlimmer {
  TrailGlimmer({required this.x, required this.y});

  double x;
  final double y;
  bool collected = false;
  double collectAge = 0;
}

/// The session reward shared by every garden game: a small Kibble thank-you
/// that grows gently with joy but is capped hard (a game is a treat, never a
/// grind: canonical earn-rates stay dominated by real care).
int miniGameKibble(int score) => score <= 0 ? 0 : (score ~/ 3).clamp(1, 15);
