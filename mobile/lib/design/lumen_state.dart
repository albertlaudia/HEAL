// HEAL — Lumen global state.
//
// A single Riverpod provider holds the current LumenEmotion, derived from
// what the user is doing right now. Every screen reads from this and Lumen
// becomes a *consistent* presence across the app — not 5 different stickers
// in 5 places.
//
// Usage:
//   final lumen = ref.watch(lumenProvider);
//   LumenSlot(emotion: lumen.emotion, ...)
//
// Updates:
//   ref.read(lumenProvider.notifier).set(LumenEmotion.celebrating);
//   ref.read(lumenProvider.notifier).flash(LumenEmotion.celebrating,
//                                          duration: 1800ms);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lumen.dart';

class LumenState {
  final LumenEmotion emotion;
  final double celebration; // 0..1, decays over time
  final DateTime updatedAt;
  const LumenState({
    this.emotion = LumenEmotion.resting,
    this.celebration = 0,
    required this.updatedAt,
  });

  LumenState copyWith({LumenEmotion? emotion, double? celebration, DateTime? updatedAt}) =>
      LumenState(
        emotion: emotion ?? this.emotion,
        celebration: celebration ?? this.celebration,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class LumenController extends StateNotifier<LumenState> {
  LumenController() : super(LumenState(updatedAt: DateTime.now()));

  void set(LumenEmotion emotion) {
    state = state.copyWith(emotion: emotion, updatedAt: DateTime.now());
  }

  void celebrate({double peak = 1.0}) {
    state = state.copyWith(
      emotion: LumenEmotion.celebrating,
      celebration: peak,
      updatedAt: DateTime.now(),
    );
  }

  /// Decay celebration value (called on every tick from a Listener).
  void tick(double dtSeconds) {
    if (state.celebration > 0) {
      final next = (state.celebration - dtSeconds * 0.6).clamp(0.0, 1.0);
      state = state.copyWith(celebration: next);
      // After celebration, fall back to the previous emotion (resting).
      if (next <= 0 && state.emotion == LumenEmotion.celebrating) {
        state = state.copyWith(emotion: LumenEmotion.resting);
      }
    }
  }
}

final lumenProvider = StateNotifierProvider<LumenController, LumenState>(
  (ref) => LumenController(),
);
