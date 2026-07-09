// HEAL — Lumen, the daily companion.
//
// Design philosophy: not a sticker, not a logo — a quiet presence that
// reacts to what the user is doing. Lives in the corner of the home
// screen and breathes with them.
//
// The character is intentionally abstract: a rounded body with no
// face details hard-coded into anatomy. Emotion is communicated via:
//   - body shape (closed/open posture)
//   - glow halo (emotion color)
//   - inner glyph (a single symbol that means something)
//   - breath sync (subtle scale animation on the user's inhale cycle)
//
// Six emotion states map to six app states:
//   resting    — idle / home
//   breathing  — user in breath phase
//   attentive  — reading scripture
//   listening  — playing praise
//   offering   — opening prayer
//   resting    — back from practice
//
// All drawn with CustomPainter so we ship without an asset pipeline.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

enum LumenEmotion {
  resting,    // idle home — gentle sway
  breathing,  // breath session — pulses with inhale/exhale
  attentive,  // reading scripture — upright, soft glow
  listening,  // playing praise — gentle nodding
  offering,   // prayer — open posture
  weary,      // end of day / evening — slightly closed
}

class Lumen extends StatefulWidget {
  final LumenEmotion emotion;
  final double size;
  final bool dimmed;

  const Lumen({
    super.key,
    required this.emotion,
    this.size = 96,
    this.dimmed = false,
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
    // Breath cycle: ~4s inhale + 1s hold + 6s exhale — matches the rest
    // room default. Easing on the cosine curve feels organic.
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat();

    // Sway is slower, ambient. Different period per emotion so the two
    // animations never lock-step — feels alive instead of mechanical.
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
        ),
      ),
    );
  }
}

class _LumenPainter extends CustomPainter {
  final double breathT; // 0..1
  final double swayT;   // 0..1
  final LumenEmotion emotion;
  final bool dimmed;

  _LumenPainter({
    required this.breathT,
    required this.swayT,
    required this.emotion,
    required this.dimmed,
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
      case LumenEmotion.resting:
      default:
        return HealTokens.brass;
    }
  }

  /// Body scale modulated by breath phase. Inhale expands, exhale contracts.
  double get _bodyScale {
    // Cosine 0..1..0 over the cycle
    final breath = (1 - math.cos(breathT * 2 * math.pi)) / 2;
    return 0.94 + breath * 0.10;
  }

  /// Sway — small left-right oscillation, slightly out of phase per emotion
  double get _swayOffset {
    return math.sin(swayT * 2 * math.pi) * 2.5;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseRadius = size.width * 0.36 * _bodyScale;

    // ── 1. Outer halo (emotion glow) ─────────────────────────────
    final haloRadius = baseRadius + 14;
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _emotionColor.withValues(alpha: dimmed ? 0.10 : 0.32),
          _emotionColor.withValues(alpha: 0.0),
        ],
        stops: const [0.55, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(cx + _swayOffset, cy), radius: haloRadius),
      );
    canvas.drawCircle(
      Offset(cx + _swayOffset, cy),
      haloRadius,
      haloPaint,
    );

    // ── 2. Body shape (a slightly tall pebble — anatomical, not humanoid)
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

    // ── 5. Tiny dots — "presence marks" around the silhouette ────
    // Three small bronze dots that orbit slightly. They make Lumen
    // feel like a *being* rather than a static icon.
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
  }

  void _drawGlyph(Canvas canvas, Offset center, double r) {
    // Each emotion gets ONE inner mark:
    // resting    → a single horizontal line (stillness)
    // breathing  → three vertical lines (in-hold-out)
    // attentive  → a small upward tick (light)
    // listening  → a small arc (curve of a note)
    // offering   → a soft heart-ish dot cluster
    // weary      → a thin crescent (wane)
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
        // A small upward arc / ray of light
        final path = Path()
          ..moveTo(center.dx, center.dy - r * 0.5)
          ..lineTo(center.dx, center.dy + r * 0.2);
        canvas.drawPath(path, stroke);
        break;
      case LumenEmotion.listening:
        // An arc that suggests a melody
        final rect = Rect.fromCenter(
          center: center,
          width: r * 1.4, height: r * 0.8,
        );
        canvas.drawArc(rect, math.pi, math.pi, false, stroke);
        break;
      case LumenEmotion.offering:
        // Three soft dots — like held breath made visible
        canvas.drawCircle(center, r * 0.18, paint);
        canvas.drawCircle(
          center.translate(-r * 0.45, 0), r * 0.14, paint);
        canvas.drawCircle(
          center.translate(r * 0.45, 0), r * 0.14, paint);
        break;
      case LumenEmotion.weary:
        // A thin crescent
        final path = Path()
          ..addArc(
            Rect.fromCircle(center: center, radius: r * 0.55),
            math.pi * 0.15, math.pi * 0.7,
          );
        canvas.drawPath(path, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _LumenPainter old) =>
      old.breathT != breathT ||
      old.swayT != swayT ||
      old.emotion != emotion ||
      old.dimmed != dimmed;
}

/// Lumen placement widget — wraps Lumen in a soft container with the
/// right padding for the home-screen corner slot.
class LumenSlot extends StatelessWidget {
  final LumenEmotion emotion;
  final double size;
  final bool dimmed;
  const LumenSlot({
    super.key,
    this.emotion = LumenEmotion.resting,
    this.size = 72,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 32,
      height: size + 32,
      child: Center(
        child: Lumen(emotion: emotion, size: size, dimmed: dimmed),
      ),
    );
  }
}
