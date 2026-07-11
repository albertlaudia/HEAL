// HEAL — Motion library
// ============================================================================
// Centralized motion language so screens feel coherent. Three categories:
//
//   springs — natural physics for interactive elements
//   breath   — long, calm curves (4-6s) for the actual breath practice
//   ambient  — short, almost-imperceptible transitions in 150-300ms
//
// Borrowed from: Apple HIG 2025, Material 3 motion study, Calm 2026
// redesign patterns. Feel over flash.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

abstract class HealMotion {
  // ── Spring presets (use SpringSimulation directly with these values) ──
  // Snappy: button press, toggle
  static const SpringDescription snappy = SpringDescription(
    mass: 1.0, stiffness: 380.0, damping: 24.0,
  );

  // Standard: hero transitions, drawer slide
  static const SpringDescription standard = SpringDescription(
    mass: 1.0, stiffness: 220.0, damping: 22.0,
  );

  // Soft: gentle rise on home, modal mount
  static const SpringDescription soft = SpringDescription(
    mass: 1.0, stiffness: 120.0, damping: 18.0,
  );

  // ── Breath (intentionally slow — should feel like exhaling) ──────
  static const Duration breatheIn    = Duration(milliseconds: 4000);
  static const Duration breatheHold  = Duration(milliseconds: 1500);
  static const Duration breatheOut   = Duration(milliseconds: 6000);
  static const Curve breatheCurve    = Cubic(0.45, 0, 0.55, 1); // ease-in-out-sine

  // ── Ambient (invisible-feeling motion that adds life) ───────────
  static const Duration hover       = Duration(milliseconds: 160);
  static const Duration fade        = Duration(milliseconds: 220);
  static const Duration slideShort  = Duration(milliseconds: 280);
  static const Duration slideMedium = Duration(milliseconds: 380);
  static const Duration slideLong   = Duration(milliseconds: 540);

  // Splash + boot timing
  static const Duration splashMin = Duration(milliseconds: 2200);
  static const Duration celebrationHold = Duration(milliseconds: 2200);
  static const Duration bibleCompletionHold = Duration(milliseconds: 1800);

  // ── Curves ─────────────────────────────────────────────────────
  static const Curve standardEasing = Cubic(0.2, 0, 0, 1); // "ease-out-quint"
  static const Curve decelerate     = Cubic(0, 0, 0.2, 1);
  static const Curve accelerate     = Cubic(0.4, 0, 1, 1);
  static const Curve sharp          = Cubic(0.4, 0, 0.6, 1);

  /// Spring simulation helper — use when you need physics-driven motion
  /// that should never feel mechanical.
  static AnimationController snappyController(TickerProvider vsync) {
    final c = AnimationController.unbounded(vsync: vsync);
    c.animateWith(
      SpringSimulation(snappy, 0, 1, 0),
    );
    return c;
  }
}
