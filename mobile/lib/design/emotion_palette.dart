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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import 'lumen.dart';
import 'lumen_state.dart';

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
    background: HealTokens.backdropPracticing,
    backgroundDeep: HealTokens.backdropPracticingDeep,
    surface: HealTokens.rosewoodLight,
    surfaceGlow: HealTokens.backdropPracticingGlow,
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
    background: HealTokens.backdropEvening,
    backgroundDeep: HealTokens.backdropEveningDeep,
    surface: HealTokens.backdropEveningSurface,
    surfaceGlow: HealTokens.backdropEveningGlow,
    primary: HealTokens.backdropEveningPrimary,
    primarySoft: HealTokens.backdropEveningPrimarySoft,
    onPrimary: HealTokens.backdropEveningOnPrimary,
    text: HealTokens.cream,
    textMuted: HealTokens.creamDim,
    success: HealTokens.backdropEveningSuccess,
    warning: HealTokens.backdropEveningWarning,
  );

  /// Celebration — warm, bright, full of light.
  static const EmotionPalette celebrating = EmotionPalette(
    background: HealTokens.backdropCelebrating,
    backgroundDeep: HealTokens.backdropCelebratingDeep,
    surface: HealTokens.backdropCelebratingSurface,
    surfaceGlow: HealTokens.backdropCelebratingGlow,
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

EmotionPalette _resolveEmotionPalette(Ref ref) {
  final lumen = ref.watch(lumenProvider);
  return EmotionPalette.resolve(lumen.emotion);
}

final emotionPaletteProvider = Provider<EmotionPalette>((ref) {
  return _resolveEmotionPalette(ref);
});
