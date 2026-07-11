// HEAL — Emotional palette
// ============================================================================
// The app's background gradient, accent glow, and surface tints all shift
// with the user's current emotional context. This is what makes the app
// feel like it *reacts* to the user instead of just rendering screens.
//
// The palette is a function of (time-of-day, lumenEmotion). We never
// override the brass identity completely — we tint it.
// ============================================================================

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'lumen.dart';

class EmotionPalette {
  /// Page background — slight gradient, dark, never pitch-black.
  final Color background;
  final Color backgroundDeep;
  final Color surface;
  final Color surfaceGlow;
  final Color primary;
  final Color primarySoft;
  final Color onPrimary;
  final Color text;
  final Color textMuted;
  final Color success;
  final Color warning;

  const EmotionPalette({
    required this.background,
    required this.backgroundDeep,
    required this.surface,
    required this.surfaceGlow,
    required this.primary,
    required this.primarySoft,
    required this.onPrimary,
    required this.text,
    required this.textMuted,
    required this.success,
    required this.warning,
  });

  /// Default — resting state, no emotion tint.
  static const EmotionPalette resting = EmotionPalette(
    background: HealTokens.rosewoodDeep,
    backgroundDeep: HealTokens.charcoal,
    surface: HealTokens.rosewood,
    surfaceGlow: HealTokens.rosewoodLight,
    primary: HealTokens.brass,
    primarySoft: HealTokens.brassLight,
    onPrimary: HealTokens.oxblood,
    text: HealTokens.cream,
    textMuted: HealTokens.creamDim,
    success: HealTokens.amber,
    warning: HealTokens.ember,
  );

  /// Active practice — slightly brighter, more saturated.
  static const EmotionPalette practicing = EmotionPalette(
    background: Color(0xFF1F1310),
    backgroundDeep: Color(0xFF150A09),
    surface: HealTokens.rosewoodLight,
    surfaceGlow: Color(0xFF4A2C26),
    primary: HealTokens.amber,
    primarySoft: HealTokens.brassLight,
    onPrimary: HealTokens.oxblood,
    text: HealTokens.cream,
    textMuted: HealTokens.creamDim,
    success: HealTokens.amber,
    warning: HealTokens.ember,
  );

  /// Evening — warmer, dimmer, more indigo.
  static const EmotionPalette evening = EmotionPalette(
    background: Color(0xFF160D17),
    backgroundDeep: Color(0xFF0A0610),
    surface: Color(0xFF221830),
    surfaceGlow: Color(0xFF2E1F40),
    primary: Color(0xFF8FA8B0),
    primarySoft: Color(0xFFA5BCC4),
    onPrimary: Color(0xFF0A0610),
    text: HealTokens.cream,
    textMuted: HealTokens.creamDim,
    success: Color(0xFFB5C5B5),
    warning: Color(0xFFB08C7A),
  );

  /// Celebration — warm, bright, full of light.
  static const EmotionPalette celebrating = EmotionPalette(
    background: Color(0xFF1A1308),
    backgroundDeep: Color(0xFF0F0B05),
    surface: Color(0xFF3A2810),
    surfaceGlow: Color(0xFF5A3C1A),
    primary: HealTokens.amber,
    primarySoft: HealTokens.brassLight,
    onPrimary: HealTokens.oxblood,
    text: HealTokens.cream,
    textMuted: HealTokens.creamDim,
    success: HealTokens.amber,
    warning: HealTokens.ember,
  );

  /// Resolves a palette from the current emotion + time of day.
  static EmotionPalette resolve(LumenEmotion emotion, {DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    final isEvening = hour >= 19 || hour < 6;
    if (emotion == LumenEmotion.celebrating) return celebrating;
    if (emotion == LumenEmotion.breathing ||
        emotion == LumenEmotion.attentive ||
        emotion == LumenEmotion.listening ||
        emotion == LumenEmotion.offering ||
        emotion == LumenEmotion.encouraging) {
      return isEvening ? evening : practicing;
    }
    return resting;
  }
}


// Riverpod provider: resolves the active emotion palette from lumen state
// + time-based palette (which captures time-of-day).
//
// Usage: final palette = ref.watch(emotionPaletteProvider(timePalette));

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'emotion_palette.dart';
import 'lumen_state.dart';

EmotionPalette _resolveEmotionPalette(Ref ref) {
  final lumen = ref.watch(lumenProvider);
  return EmotionPalette.resolve(lumen.emotion);
}

final emotionPaletteProvider = Provider<EmotionPalette>((ref) {
  return _resolveEmotionPalette(ref);
});
