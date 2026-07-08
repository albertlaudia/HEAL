// HEAL — Lightweight sound effects service.
//
// Plays short ambient tones (bell, breath chime, exhale release) without
// needing network. Sounds are synthesized on-the-fly by generating 8-bit
// PCM WAV bytes in-memory and feeding them to a one-shot AudioPlayer.
// This works on mobile and web without bundled assets.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundKind {
  inhaleStart,    // soft rising tone
  exhaleStart,    // soft falling tone
  bell,           // meditation bell ding
  hold,           // subtle phase-shift chime
  praiseIntro,    // high pluck
  praiseOutro,    // low decay
  unlockChime,    // sticker-award bright
  stickerMoment,  // iconic moment sticker (slightly fuller bell)
  stickerPractice,// first-time practice sticker
  stickerStreak,  // streak milestone (chime triplet)
  stickerBible,   // Bible iconic moment
}

class SoundService {
  bool enabled = true;
  bool _initialized = false;
  final AudioPlayer _player = AudioPlayer(playerId: 'heal-fx');
  final math.Random _rng = math.Random();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool('heal.sound_enabled') ?? true;
    await _player.setReleaseMode(ReleaseMode.release);
  }

  Future<void> setEnabled(bool v) async {
    enabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('heal.sound_enabled', v);
  }

  Future<void> play(SoundKind kind) async {
    if (!enabled) return;
    if (kIsWeb) return;  // Browser autoplay policies need a user-gesture.
    try {
      final bytes = _synthesize(kind);
      await _player.play(BytesSource(bytes));
    } catch (_) {
      // Swallow — sounds are decoration, never block UI.
    }
  }

  /// Generate a short PCM WAV byte stream for the given sound.
  /// 22.05 kHz mono, 8-bit. ~150-1500ms each.
  Uint8List _synthesize(SoundKind kind) {
    const sampleRate = 22050;
    double seconds;
    double startFreq;
    double endFreq;
    int harmonics;
    double attack;
    double release;
    double amplitude;

    switch (kind) {
      case SoundKind.inhaleStart:
        seconds = 0.25; startFreq = 320; endFreq = 480; harmonics = 1;
        attack = 0.08; release = 0.17; amplitude = 0.16; break;
      case SoundKind.exhaleStart:
        seconds = 0.32; startFreq = 480; endFreq = 280; harmonics = 1;
        attack = 0.10; release = 0.22; amplitude = 0.16; break;
      case SoundKind.hold:
        seconds = 0.12; startFreq = 600; endFreq = 600; harmonics = 1;
        attack = 0.04; release = 0.08; amplitude = 0.10; break;
      case SoundKind.bell:
        seconds = 1.2;  startFreq = 660; endFreq = 660; harmonics = 5;
        attack = 0.005; release = 1.1; amplitude = 0.30; break;
      case SoundKind.praiseIntro:
        seconds = 0.18; startFreq = 1200; endFreq = 1400; harmonics = 1;
        attack = 0.005; release = 0.17; amplitude = 0.18; break;
      case SoundKind.praiseOutro:
        seconds = 0.4;  startFreq = 540; endFreq = 220; harmonics = 2;
        attack = 0.02; release = 0.38; amplitude = 0.18; break;
      case SoundKind.unlockChime:
        seconds = 0.6;  startFreq = 880; endFreq = 1320; harmonics = 3;
        attack = 0.005; release = 0.55; amplitude = 0.22; break;
      case SoundKind.stickerStreak:
        seconds = 0.9;  startFreq = 660; endFreq = 990; harmonics = 2;
        attack = 0.005; release = 0.85; amplitude = 0.22; break;
      case SoundKind.stickerPractice:
        seconds = 0.5;  startFreq = 740; endFreq = 880; harmonics = 1;
        attack = 0.005; release = 0.45; amplitude = 0.18; break;
      case SoundKind.stickerMoment:
        seconds = 1.6;  startFreq = 220; endFreq = 880; harmonics = 4;
        attack = 0.005; release = 1.5; amplitude = 0.28; break;
      case SoundKind.stickerBible:
        seconds = 1.2;  startFreq = 330; endFreq = 660; harmonics = 3;
        attack = 0.005; release = 1.1; amplitude = 0.26; break;
    }

    final samples = (sampleRate * seconds).round();
    final data = Int8List(samples);
    for (var i = 0; i < samples; i++) {
      final t = i / sampleRate;
      final freq = startFreq + (endFreq - startFreq) * (i / samples);
      double sample = 0.0;
      for (var h = 1; h <= harmonics; h++) {
        sample += math.sin(2 * math.pi * freq * h * t) / h;
      }
      sample /= harmonics.toDouble();

      double env;
      if (t < attack) {
        env = t / attack;
      } else if (t < seconds - release) {
        env = 1.0;
      } else {
        env = (seconds - t) / release;
      }
      env = env.clamp(0.0, 1.0);

      if (kind == SoundKind.inhaleStart || kind == SoundKind.exhaleStart) {
        sample += (_rng.nextDouble() - 0.5) * 0.05;
      }

      data[i] = (sample * env * amplitude * 127).round().clamp(-127, 127);
    }

    return _wrapAsWav(data, sampleRate);
  }

  /// Wrap 8-bit PCM samples as a 22.05 kHz mono WAV.
  Uint8List _wrapAsWav(Int8List samples, int sampleRate) {
    final byteRate = sampleRate;
    final dataSize = samples.length;
    final totalSize = 36 + dataSize;
    final bytes = <int>[];

    // RIFF header
    bytes.addAll(_ascii('RIFF'));
    bytes.addAll(_intBytes(totalSize, 4));
    bytes.addAll(_ascii('WAVE'));

    // fmt subchunk
    bytes.addAll(_ascii('fmt '));
    bytes.addAll(_intBytes(16, 4));
    bytes.addAll(_intBytes(1, 2));
    bytes.addAll(_intBytes(1, 2));
    bytes.addAll(_intBytes(sampleRate, 4));
    bytes.addAll(_intBytes(byteRate, 4));
    bytes.addAll(_intBytes(1, 2));
    bytes.addAll(_intBytes(8, 2));

    // data subchunk
    bytes.addAll(_ascii('data'));
    bytes.addAll(_intBytes(dataSize, 4));
    bytes.addAll(samples.buffer.asUint8List());

    return Uint8List.fromList(bytes);
  }

  List<int> _ascii(String s) => s.codeUnits;

  List<int> _intBytes(int value, int byteCount) {
    final out = <int>[];
    for (var i = byteCount - 1; i >= 0; i--) {
      out.add((value >> (i * 8)) & 0xFF);
    }
    return out;
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final svc = SoundService();
  // ignore: discarded_futures
  svc.init();
  return svc;
});
