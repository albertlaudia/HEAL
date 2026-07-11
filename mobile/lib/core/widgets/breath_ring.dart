import '../../design/copy.dart';
// HEAL — Breath ring CustomPainter.
// Renders a smooth, glowing ring that expands/contracts with breath phase.
// Color shifts based on phase: amber (inhale) → brass (hold) → ember (exhale).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

enum BreathPhase { ready, inhale, holdIn, exhale, holdOut }

extension BreathPhaseLabel on BreathPhase {
  String get label {
    switch (this) {
      case BreathPhase.ready:
        return 'When you are ready';
      case BreathPhase.inhale:
        return Copy.breathInhale;
      case BreathPhase.holdIn:
        return Copy.breathHold;
      case BreathPhase.exhale:
        return Copy.breathExhale;
      case BreathPhase.holdOut:
        return 'Rest';
    }
  }
  String get instruction {
    switch (this) {
      case BreathPhase.ready:
        return 'Tap to begin';
      case BreathPhase.inhale:
        return 'Fill the belly, not the chest';
      case BreathPhase.holdIn:
        return 'Stillness at the top';
      case BreathPhase.exhale:
        return 'Release what you are carrying';
      case BreathPhase.holdOut:
        return 'A small holy pause';
    }
  }
  Color get glowColor {
    switch (this) {
      case BreathPhase.inhale:
        return HealTokens.brassLight;
      case BreathPhase.holdIn:
        return HealTokens.brass;
      case BreathPhase.exhale:
        return HealTokens.ember;
      case BreathPhase.holdOut:
        return HealTokens.amber;
      case BreathPhase.ready:
        return HealTokens.bronze;
    }
  }
}

class BreathRingPainter extends CustomPainter {
  final double progress; // 0..1 of overall pattern cycle
  final BreathPhase phase;
  final double phaseProgress; // 0..1 within current phase
  final double ringScale; // 0.6..1.6 — driven by inhale/exhale curve
  final double pulse; // 0..1 — subtle continuous pulse for "alive" feel

  BreathRingPainter({
    required this.progress,
    required this.phase,
    required this.phaseProgress,
    required this.ringScale,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // Outer atmospheric glow
    final glowRadius = maxRadius * ringScale * (1 + pulse * 0.05);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          phase.glowColor.withValues(alpha: 0.32),
          phase.glowColor.withValues(alpha: 0.16),
          phase.glowColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    // Background ring (faint)
    final ringPaint = Paint()
      ..color = HealTokens.creamDim.withValues(alpha: 0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, maxRadius * 0.92, ringPaint);

    // Phase progress arc
    final phaseSweep = (phaseProgress * 2 * math.pi);
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
        colors: [
          phase.glowColor,
          phase.glowColor.withValues(alpha: 0.5),
          phase.glowColor,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.92))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius * 0.92),
      -math.pi / 2,
      phaseSweep,
      false,
      progressPaint,
    );

    // Inner solid circle
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          phase.glowColor.withValues(alpha: 0.4),
          phase.glowColor.withValues(alpha: 0.2),
          phase.glowColor.withValues(alpha: 0.04),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.6));
    canvas.drawCircle(center, maxRadius * 0.6 * ringScale, innerPaint);

    // Innermost ring border
    final innerBorder = Paint()
      ..color = phase.glowColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, maxRadius * 0.6 * ringScale, innerBorder);

    // Cycle progress dots around outer ring
    const dotCount = 16;
    for (var i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * math.pi - math.pi / 2;
      final dotRadius = maxRadius * 0.96;
      final dotPos = Offset(
        center.dx + dotRadius * math.cos(angle),
        center.dy + dotRadius * math.sin(angle),
      );
      final isActive = (progress * dotCount).floor() == i;
      final dotPaint = Paint()
        ..color = isActive
            ? phase.glowColor
            : HealTokens.creamDim.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotPos, isActive ? 2.5 : 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(BreathRingPainter old) {
    return old.progress != progress ||
        old.phase != phase ||
        old.phaseProgress != phaseProgress ||
        old.ringScale != ringScale ||
        old.pulse != pulse;
  }
}