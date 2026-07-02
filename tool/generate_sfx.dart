// Synthesizes KindredPaws' original sound-effect set from pure math —
// warm sine partials, gentle envelopes, and soft filtered noise. Because the
// cues are generated (not sampled or downloaded), every byte is original and
// license-clean by construction (assets/CREDITS.md logs them as such).
//
// Run: dart run tool/generate_sfx.dart
// Output: assets/audio/*.wav (16-bit PCM mono @ 22050 Hz, each a few KB).
//
// Sound design language (matches the visual bible): soft attacks, rounded
// decays, pentatonic-warm intervals, never harsh/startling — child-safe ears.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sampleRate = 22050;

void main() {
  final out = Directory('assets/audio');
  out.createSync(recursive: true);

  final cues = <String, List<double>>{
    // Feed — two warm marimba-ish notes (G5→C6) with a soft body.
    'feed_chime': seq([
      tone(784, 0.16, partials: marimba, gain: 0.55),
      tone(1046.5, 0.22, partials: marimba, gain: 0.6),
    ], gap: 0.02),
    // Generic cozy tap/pop (UI + pet boop).
    'soft_pop': pop(330, 0.09),
    // Bath splash — lowpassed noise swell with a droplet blip on top.
    'splash': mix([
      noise(0.28, lowpass: 0.22, gain: 0.4, fadeIn: 0.03),
      delay(pop(1200, 0.05, gain: 0.25), 0.16),
    ]),
    // Play — a happy little up-boing (pitch glide).
    'boing': glide(392, 660, 0.22, gain: 0.5),
    // Tuck-in — descending dreamy pair (E5→A4) with long tails.
    'lullaby_dip': seq([
      tone(659.3, 0.28, partials: soft, gain: 0.4, release: 0.6),
      tone(440, 0.4, partials: soft, gain: 0.38, release: 0.7),
    ], gap: 0.05),
    // Wake — bright chirpy pair (C6→E6), short and sunny.
    'morning_chirp': seq([
      tone(1046.5, 0.09, partials: chirp, gain: 0.4),
      tone(1318.5, 0.14, partials: chirp, gain: 0.45),
    ], gap: 0.015),
    // Milestone — a warm C-major arpeggio sparkle (C5 E5 G5 C6).
    'tada': seq([
      tone(523.25, 0.12, partials: marimba, gain: 0.5),
      tone(659.3, 0.12, partials: marimba, gain: 0.5),
      tone(784, 0.12, partials: marimba, gain: 0.5),
      tone(1046.5, 0.34, partials: marimba, gain: 0.55, release: 0.5),
    ], gap: 0.012),
    // Purchase — soft basket thump + tiny coin tick.
    'basket': mix([
      tone(140, 0.16, partials: thump, gain: 0.6),
      delay(tone(1568, 0.05, partials: chirp, gain: 0.18), 0.09),
    ]),
    // Comfort — a slow warm swell (A4 + E5 held together).
    'heart_glow': mix([
      tone(440, 0.5, partials: soft, gain: 0.3, attack: 0.12, release: 0.5),
      tone(659.3, 0.5, partials: soft, gain: 0.22, attack: 0.16, release: 0.5),
    ]),
    // Sparkle — brief high shimmer (two tiny high notes).
    'sparkle': seq([
      tone(2093, 0.06, partials: chirp, gain: 0.22),
      tone(2637, 0.1, partials: chirp, gain: 0.2),
    ], gap: 0.01),
  };

  cues.forEach((name, samples) {
    final f = File('${out.path}/$name.wav');
    f.writeAsBytesSync(wav(samples));
    stdout.writeln('wrote ${f.path} (${f.lengthSync()} bytes)');
  });
}

// ── timbres (partial: [multiple, relativeGain]) ─────────────────────────────
const marimba = [(1.0, 1.0), (4.0, 0.25), (9.2, 0.08)];
const soft = [(1.0, 1.0), (2.0, 0.18), (3.0, 0.06)];
const chirp = [(1.0, 1.0), (2.0, 0.35)];
const thump = [(1.0, 1.0), (1.5, 0.4), (2.2, 0.15)];

// ── synthesis primitives ────────────────────────────────────────────────────
List<double> tone(
  double freq,
  double sustain, {
  List<(double, double)> partials = soft,
  double gain = 0.5,
  double attack = 0.012,
  double release = 0.25,
}) {
  final n = ((sustain + release) * sampleRate).round();
  final out = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = _envelope(t, attack, sustain, release);
    var s = 0.0;
    for (final (mult, g) in partials) {
      // Slight per-partial decay keeps highs from ringing (rounded feel).
      s +=
          math.sin(2 * math.pi * freq * mult * t) *
          g *
          math.exp(-t * (mult - 1) * 3);
    }
    out[i] = s * env * gain;
  }
  return out;
}

/// A percussive pop: a fast sine blip with an exponential decay.
List<double> pop(double freq, double dur, {double gain = 0.5}) {
  final n = (dur * sampleRate).round();
  return List.generate(n, (i) {
    final t = i / sampleRate;
    return math.sin(2 * math.pi * freq * t * (1 - t * 2)) *
        math.exp(-t * 30) *
        gain;
  });
}

/// A pitch glide (playful boing) with a soft envelope.
List<double> glide(double f0, double f1, double dur, {double gain = 0.5}) {
  final n = (dur * sampleRate).round();
  var phase = 0.0;
  return List.generate(n, (i) {
    final t = i / sampleRate;
    final k = t / dur;
    final f = f0 + (f1 - f0) * Curves.easeOut(k);
    phase += 2 * math.pi * f / sampleRate;
    return math.sin(phase) * _envelope(t, 0.01, dur * 0.6, dur * 0.4) * gain;
  });
}

/// Soft filtered noise (one-pole lowpass) for water/whoosh textures.
List<double> noise(
  double dur, {
  double lowpass = 0.2,
  double gain = 0.4,
  double fadeIn = 0.01,
}) {
  final n = (dur * sampleRate).round();
  final rng = math.Random(7); // fixed seed — deterministic output bytes
  var y = 0.0;
  return List.generate(n, (i) {
    final t = i / sampleRate;
    final x = rng.nextDouble() * 2 - 1;
    y += lowpass * (x - y);
    final env = math.min(t / fadeIn, 1) * math.exp(-t * 6);
    return y * env * gain * 3;
  });
}

List<double> seq(List<List<double>> parts, {double gap = 0.02}) {
  final silence = List<double>.filled((gap * sampleRate).round(), 0.0);
  return parts.expand((p) => [...p, ...silence]).toList();
}

List<double> mix(List<List<double>> layers) {
  final n = layers.map((l) => l.length).reduce(math.max);
  final out = List<double>.filled(n, 0);
  for (final l in layers) {
    for (var i = 0; i < l.length; i++) {
      out[i] += l[i];
    }
  }
  return out;
}

List<double> delay(List<double> s, double seconds) => [
  ...List<double>.filled((seconds * sampleRate).round(), 0.0),
  ...s,
];

double _envelope(double t, double attack, double sustain, double release) {
  if (t < attack) return t / attack;
  if (t < attack + sustain) return 1;
  final r = (t - attack - sustain) / release;
  return r >= 1 ? 0 : math.exp(-r * 4) * (1 - r);
}

// A tiny ease-out (avoids importing Flutter into a CLI tool).
abstract final class Curves {
  static double easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();
}

// ── WAV writer (16-bit PCM mono) ────────────────────────────────────────────
Uint8List wav(List<double> samples) {
  // Normalize with soft headroom, then clamp.
  final peak = samples.fold<double>(0.0001, (m, s) => math.max(m, s.abs()));
  final norm = peak > 0.9 ? 0.9 / peak : 1.0;
  final data = ByteData(44 + samples.length * 2);
  void str(int off, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i] * norm).clamp(-1.0, 1.0);
    data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}
