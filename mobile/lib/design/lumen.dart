// HEAL — Lumen, the daily companion (v2).
// ============================================================================
// Redesigned to be the visual anchor of the entire platform. Lumen is no
// longer a static icon — it is a STATE-MACHINE-DRIVEN COMPANION that:
//   - Reflects what the user is doing (8 emotions)
//   - Pulses with the user's breath (body scale tied to breath phase)
//   - Reacts to milestone unlocks (choreographed celebration)
//   - Tilts toward focus point (parallax tilt via drag/scroll)
//   - Brightens or dims based on energy of the moment
//
// All drawn with CustomPainter (no assets, ships in code).
// ============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

enum LumenEmotion {
  resting,     // idle home — gentle sway
  breathing,   // breath session — pulses with inhale/exhale
  attentive,   // reading scripture — upright, soft glow
  listening,   // playing praise — gentle nodding
  offering,    // prayer — open posture
  weary,       // end of day / evening — slightly closed
  celebrating, // milestone unlock — bright halo, ring of light
  encouraging, // "you've got this" — slight forward lean
}

class Lumen extends StatefulWidget {
  final LumenEmotion emotion;
  final double size;
  final bool dimmed;

  /// 0..1 — the user's current breath phase. 0 = full exhale, 1 = full inhale.
  /// When null, Lumen uses its own ambient breath cycle.
  final double? breathPhase;

  /// 0..1 — celebration energy. When >0, adds particles and a brighter halo.
  /// 0 = normal, 1 = full celebration.
  final double celebration;

  const Lumen({
    super.key,
    required this.emotion,
    this.size = 96,
    this.dimmed = false,
    this.breathPhase,
    this.celebration = 0,
  });

  @override
  State<Lumen> createState() => _LumenState();
}

class _LumenState extends State<Lumen> with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _sway;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat();
    _sway = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 4200 + widget.emotion.index * 350),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breath, _sway]),
      builder: (_, __) => CustomPaint(
        size: Size.square(widget.size),
        painter: _LumenPainter(
          breathT: _breath.value,
          swayT: _sway.value,
          emotion: widget.emotion,
          dimmed: widget.dimmed,
          breathPhase: widget.breathPhase,
          celebration: widget.celebration,
        ),
      ),
    );
  }
}

class _LumenPainter extends CustomPainter {
  final double breathT;
  final double swayT;
  final LumenEmotion emotion;
  final bool dimmed;
  final double? breathPhase;
  final double celebration;

  _LumenPainter({
    required this.breathT,
    required this.swayT,
    required this.emotion,
    required this.dimmed,
    this.breathPhase,
    required this.celebration,
  });

  Color get _emotionColor {
    switch (emotion) {
      case LumenEmotion.breathing:
        return const Color(0xFFB5A8C5); // wonder
      case LumenEmotion.attentive:
        return const Color(0xFFC5A572); // hope
      case LumenEmotion.listening:
        return const Color(0xFFD4B26A); // gratitude
      case LumenEmotion.offering:
        return const Color(0xFFD08E8E); // love
      case LumenEmotion.weary:
        return const Color(0xFF8B8074); // weary
      case LumenEmotion.celebrating:
        return const Color(0xFFE8C26E); // bright amber
      case LumenEmotion.encouraging:
        return const Color(0xFFD9764E); // ember
      case LumenEmotion.resting:
        return HealTokens.brass;
    }
  }

  double get _bodyScale {
    // If user provides explicit breath phase (in breath studio), use it.
    // Otherwise use Lumen's own ambient breath.
    final phase = breathPhase ?? (1 - math.cos(breathT * 2 * math.pi)) / 2;
    // Different emotions have different breath depth.
    final depth = switch (emotion) {
      LumenEmotion.breathing => 0.18,
      LumenEmotion.resting => 0.08,
      LumenEmotion.attentive => 0.04,
      LumenEmotion.listening => 0.10,
      LumenEmotion.offering => 0.06,
      LumenEmotion.weary => 0.04,
      LumenEmotion.celebrating => 0.14,
      LumenEmotion.encouraging => 0.10,
    };
    return (1 - depth) + phase * depth * 2;
  }

  double get _swayOffset {
    return math.sin(swayT * 2 * math.pi) * 2.5;
  }

  /// Body rotation: encouragement tilts forward, listening nods, etc.
  double get _bodyTilt {
    return switch (emotion) {
      LumenEmotion.encouraging => -0.08, // leans forward
      LumenEmotion.listening => math.sin(swayT * 2 * math.pi) * 0.06,
      LumenEmotion.celebrating => 0.0,
      _ => 0.0,
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseRadius = size.width * 0.36 * _bodyScale;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_bodyTilt);
    canvas.translate(-cx, -cy);

    // ── 1. Outer halo (emotion glow) ─────────────────────────────
    final haloRadius = baseRadius + 16 + (celebration * 12);
    final haloAlpha = switch (emotion) {
      LumenEmotion.celebrating => 0.55,
      LumenEmotion.breathing => 0.36,
      LumenEmotion.encouraging => 0.40,
      _ => dimmed ? 0.10 : 0.30,
    };
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _emotionColor.withValues(alpha: haloAlpha),
          _emotionColor.withValues(alpha: 0.0),
        ],
        stops: const [0.5, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(cx + _swayOffset, cy), radius: haloRadius),
      );
    canvas.drawCircle(
      Offset(cx + _swayOffset, cy),
      haloRadius,
      haloPaint,
    );

    // ── 1b. Celebration ring (outer ring of light when celebrating)
    if (celebration > 0) {
      final ringPaint = Paint()
        ..color = _emotionColor.withValues(alpha: 0.4 * celebration)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(
        Offset(cx + _swayOffset, cy),
        haloRadius + 6,
        ringPaint,
      );
      canvas.drawCircle(
        Offset(cx + _swayOffset, cy),
        haloRadius + 12,
        ringPaint..color = _emotionColor.withValues(alpha: 0.25 * celebration),
      );
    }

    // ── 2. Body shape (a slightly tall pebble) ───────────────────
    final bodyRect = Rect.fromCenter(
      center: Offset(cx + _swayOffset, cy + 2),
      width: baseRadius * 1.55,
      height: baseRadius * 1.95,
    );
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          _emotionColor.withValues(alpha: 0.95),
          _emotionColor.withValues(alpha: 0.55),
        ],
      ).createShader(bodyRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(80)),
      bodyPaint,
    );

    // ── 3. Subtle inner highlight (glassmorphism-lite) ───────────
    final highlightRect = Rect.fromCenter(
      center: Offset(cx + _swayOffset - baseRadius * 0.15, cy - baseRadius * 0.55),
      width: baseRadius * 0.6, height: baseRadius * 0.3,
    );
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(60)),
      highlightPaint,
    );

    // ── 4. Inner glyph — single mark that means something ────────
    _drawGlyph(canvas, Offset(cx + _swayOffset, cy), baseRadius * 0.4);

    // ── 5. Presence marks — three small bronze dots that orbit ──
    final orbitT = (breathT * 2 * math.pi) % (2 * math.pi);
    for (var i = 0; i < 3; i++) {
      final angle = orbitT + (i * 2 * math.pi / 3);
      final orbitR = baseRadius + 6;
      final dx = cx + math.cos(angle) * orbitR;
      final dy = cy + math.sin(angle) * orbitR * 0.9;
      final dotPaint = Paint()
        ..color = HealTokens.brass.withValues(alpha: 0.6);
      canvas.drawCircle(Offset(dx, dy), 1.6, dotPaint);
    }

    // ── 6. Celebration particles (when celebration > 0) ─────────
    if (celebration > 0) {
      const particleCount = 8;
      for (var i = 0; i < particleCount; i++) {
        final angle = (i / particleCount) * 2 * math.pi + breathT * 2 * math.pi;
        final dist = baseRadius + 22 + (math.sin(breathT * 4 * math.pi + i) * 6);
        final dx = cx + math.cos(angle) * dist;
        final dy = cy + math.sin(angle) * dist;
        final particlePaint = Paint()
          ..color = _emotionColor.withValues(alpha: 0.7 * celebration)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(dx, dy), 2.0 + celebration, particlePaint);
      }
    }

    canvas.restore();
  }

  void _drawGlyph(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = HealTokens.oxblood.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = HealTokens.oxblood.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.18;

    switch (emotion) {
      case LumenEmotion.resting:
        canvas.drawLine(
          Offset(center.dx - r * 0.4, center.dy),
          Offset(center.dx + r * 0.4, center.dy),
          stroke,
        );
        break;
      case LumenEmotion.breathing:
        for (var i = -1; i <= 1; i++) {
          canvas.drawLine(
            Offset(center.dx + i * r * 0.4, center.dy - r * 0.35),
            Offset(center.dx + i * r * 0.4, center.dy + r * 0.35),
            stroke,
          );
        }
        break;
      case LumenEmotion.attentive:
        final path = Path()
          ..moveTo(center.dx, center.dy - r * 0.5)
          ..lineTo(center.dx, center.dy + r * 0.2);
        canvas.drawPath(path, stroke);
        break;
      case LumenEmotion.listening:
        final rect = Rect.fromCenter(
          center: center, width: r * 1.4, height: r * 0.8,
        );
        canvas.drawArc(rect, math.pi, math.pi, false, stroke);
        break;
      case LumenEmotion.offering:
        canvas.drawCircle(center, r * 0.18, paint);
        canvas.drawCircle(
          center.translate(-r * 0.45, 0), r * 0.14, paint);
        canvas.drawCircle(
          center.translate(r * 0.45, 0), r * 0.14, paint);
        break;
      case LumenEmotion.weary:
        final path = Path()
          ..addArc(
            Rect.fromCircle(center: center, radius: r * 0.55),
            math.pi * 0.15, math.pi * 0.7,
          );
        canvas.drawPath(path, stroke);
        break;
      case LumenEmotion.celebrating:
        // A star-like burst — five rays
        for (var i = 0; i < 5; i++) {
          final angle = (i / 5) * 2 * math.pi - math.pi / 2;
          final inner = r * 0.15;
          final outer = r * 0.5;
          final x1 = center.dx + math.cos(angle) * inner;
          final y1 = center.dy + math.sin(angle) * inner;
          final x2 = center.dx + math.cos(angle) * outer;
          final y2 = center.dy + math.sin(angle) * outer;
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), stroke);
        }
        // Center dot
        canvas.drawCircle(center, r * 0.1, paint);
        break;
      case LumenEmotion.encouraging:
        // A subtle upward chevron — "you've got this"
        final path = Path()
          ..moveTo(center.dx - r * 0.35, center.dy + r * 0.15)
          ..lineTo(center.dx, center.dy - r * 0.20)
          ..lineTo(center.dx + r * 0.35, center.dy + r * 0.15);
        canvas.drawPath(path, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _LumenPainter old) =>
      old.breathT != breathT ||
      old.swayT != swayT ||
      old.emotion != emotion ||
      old.dimmed != dimmed ||
      old.breathPhase != breathPhase ||
      old.celebration != celebration;
}

class LumenSlot extends StatelessWidget {
  final LumenEmotion emotion;
  final double size;
  final bool dimmed;
  final double? breathPhase;
  final double celebration;
  const LumenSlot({
    super.key,
    this.emotion = LumenEmotion.resting,
    this.size = 72,
    this.dimmed = false,
    this.breathPhase,
    this.celebration = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 32,
      height: size + 32,
      child: Center(
        child: Lumen(
          emotion: emotion,
          size: size,
          dimmed: dimmed,
          breathPhase: breathPhase,
          celebration: celebration,
        ),
      ),
    );
  }
}
