// HEAL — Haptic feedback service.
//
// Wraps Flutter's HapticFeedback with HEAL-specific patterns:
//   - phase transitions (soft tap on inhale/exhale change)
//   - in-tune moment (success notification pattern)
//   - navigation (light impact)
//   - long press / destructive (heavy impact)

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HapticPattern {
  phaseChange,   // light tap — used on breath phase transitions
  inTune,        // success — praise in-tune moment
  tap,           // selection click — generic button feedback
  heavy,         // heavy impact — destructive
  error,         // vibrate — error
}

class HapticService {
  Future<void> play(HapticPattern pattern) async {
    try {
      switch (pattern) {
        case HapticPattern.phaseChange:
          await HapticFeedback.lightImpact();
        case HapticPattern.inTune:
          await HapticFeedback.mediumImpact();
        case HapticPattern.tap:
          await HapticFeedback.selectionClick();
        case HapticPattern.heavy:
          await HapticFeedback.heavyImpact();
        case HapticPattern.error:
          await HapticFeedback.vibrate();
      }
    } catch (_) {
      // Haptics not available — silently ignore
    }
  }

  Future<void> inhale() => play(HapticPattern.phaseChange);
  Future<void> exhale() => play(HapticPattern.phaseChange);
  Future<void> inTune() => play(HapticPattern.inTune);
  Future<void> tap() => play(HapticPattern.tap);
}

final hapticServiceProvider = Provider<HapticService>((ref) => HapticService());