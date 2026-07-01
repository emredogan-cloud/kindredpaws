/// The Play Garden's mini games (Product Evolution E4) — tiny, warm, and
/// **no-fail by design**: nothing can be lost, sessions end by a gentle
/// timer, and every ending is a celebration. Engines are pure Dart with
/// fixed-step ticks and seeded pseudo-randomness (index-hashed, no
/// `dart:math` Random) so every frame of gameplay is deterministic and
/// unit-testable; the UI layer stays a thin painter.
library;

/// Deterministic pseudo-random stream (same hash family the painters use).
double _hashFrac(int seed, int i) {
  var x = (seed + i * 2654435761) & 0x7FFFFFFF;
  x ^= x >> 13;
  x *= 0x5bd1e995;
  x ^= x >> 15;
  return (x & 0xFFFF) / 0xFFFF;
}

/// ── Bounce! ────────────────────────────────────────────────────────────────
/// Keep the ball happily in the air: tap to boop it back up. If it lands, it
/// just rests on the cushion until the next tap — resting is cozy, not
/// failure. The session ends by timer; the score only ever grows.
class BounceGame {
  BounceGame({this.sessionSeconds = 45, this.seed = 7});

  final double sessionSeconds;
  final int seed;

  /// Normalized field: x,y ∈ 0..1 (y grows downward; 1 = the cushion).
  double ballX = 0.5;
  double ballY = 0.55;
  double vx = 0.12;
  double vy = -0.2;
  double elapsed = 0;
  int bounces = 0;
  bool get resting => _resting;
  bool _resting = false;
  bool get finished => elapsed >= sessionSeconds;

  static const double _gravity = 0.55; // field-units / s²
  static const double _boost = -0.62; // tap impulse
  static const double _ballRadius = 0.055;

  /// Advances the simulation by [dt] seconds (fixed-step from the UI ticker).
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
class SnackCatchGame {
  SnackCatchGame({this.sessionSeconds = 45, this.seed = 11});

  final double sessionSeconds;
  final int seed;

  double basketX = 0.5;
  double elapsed = 0;
  int caught = 0;
  int sharedWithBirds = 0;
  final List<FallingSnack> snacks = [];
  int _spawned = 0;
  double _sinceSpawn = 0;
  bool get finished => elapsed >= sessionSeconds;

  static const double _fallSpeed = 0.28; // field-units / s
  static const double _spawnEvery = 1.4; // s
  static const double _basketHalfWidth = 0.11;
  static const double _catchLine = 0.86;

  void moveBasket(double x) => basketX = x.clamp(0.06, 0.94);

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

  static const faces = ['🍎', '🥕', '🫐', '🍪', '🐟'];

  final double x;
  double y;
  final int emojiIndex;
  bool settled = false;
  bool caught = false;

  String get face => faces[emojiIndex];
}

/// The session reward shared by both games: a small Kibble thank-you that
/// grows gently with joy but is capped hard (a game is a treat, never a
/// grind: canonical earn-rates stay dominated by real care).
int miniGameKibble(int score) => score <= 0 ? 0 : (score ~/ 3).clamp(1, 15);
