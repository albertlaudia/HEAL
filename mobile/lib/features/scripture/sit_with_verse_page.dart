// HEAL — "Sit with one verse" mode.
//
// A full-screen contemplative reading mode:
//   - one verse, typeset large in Cormorant Garamond
//   - auto-fades in slowly over 6 seconds
//   - subtle "candle flame" particles drift upward (just visual, no physics)
//   - tap the screen to keep the verse visible; if you stop, the verse
//     slowly fades to the candle flame and a small meditation timer counts up
//   - re-types itself every 30 seconds with a subtle character-by-character
//     shimmer (delight, not distraction)

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/theme.dart';
import '../../core/time_palette.dart';
import '../../services/streak_service.dart';
import '../../data/pb_models.dart';

class SitWithVersePage extends HookConsumerWidget {
  final Scripture scripture;
  const SitWithVersePage({super.key, required this.scripture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(timePaletteProvider);
    final lastInteraction = useState<DateTime>(DateTime.now());
    final sessionStart = useState<DateTime>(DateTime.now());
    final isFaded = useState<bool>(false);
    final particles = useState<List<_Particle>>(_seedParticles());
    final phase = useState<double>(0); // 0..1 — for shimmer cycling

    // Particle drift loop
    final frameController = useAnimationController(
      duration: const Duration(seconds: 60),
    )..repeat();

    // Track interaction (any tap resets the timer)
    useEffect(() {
      void onTap() {
        lastInteraction.value = DateTime.now();
        isFaded.value = false;
        HapticFeedback.selectionClick();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Listen for taps
      });
      return null;
    }, []);

    // Fade after 8 seconds of no interaction
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final since = DateTime.now().difference(lastInteraction.value).inSeconds;
        isFaded.value = since >= 8;
      });
      return timer.cancel;
    }, []);

    // Re-type cycle (every 30 seconds)
    final retypeTick = useState<int>(0);
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) {
        retypeTick.value++;
        phase.value = 0;
      });
      return timer.cancel;
    }, []);

    // Update phase animation (for shimmer effect)
    useEffect(() {
      final timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        phase.value = (phase.value + 0.016) % 1.0;
        // Drift particles
        final next = particles.value.map((p) {
          var newY = p.y - 0.0015; // upward
          var newX = p.x + math.sin(phase.value * 2 * math.pi + p.phase) * 0.0003;
          var opacity = p.opacity - 0.002;
          if (newY < -0.05 || opacity < 0) {
            // Reset to bottom
            newY = 1.05;
            newX = math.Random().nextDouble();
            opacity = 0.6;
          }
          return _Particle(x: newX, y: newY, phase: p.phase, opacity: opacity, size: p.size);
        }).toList();
        particles.value = next;
      });
      return timer.cancel;
    }, []);

    return Scaffold(
      backgroundColor: palette.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          lastInteraction.value = DateTime.now();
          isFaded.value = false;
          HapticFeedback.selectionClick();
        },
        child: Stack(
          children: [
            // Subtle radial gradient
            Positioned.fill(
              child: AnimatedContainer(
                duration: HealTokens.d1200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      palette.glow.withValues(alpha: 0.12),
                      palette.background,
                    ],
                  ),
                ),
              ),
            ),

            // Candle-flame particles drifting up
            Positioned.fill(
              child: CustomPaint(
                painter: _CandlePainter(
                  particles: particles.value,
                  color: palette.accent,
                  time: phase.value,
                ),
              ),
            ),

            // The verse (centered, large, slow-fading)
            Center(
              child: AnimatedOpacity(
                duration: HealTokens.d800,
                opacity: isFaded.value ? 0.0 : 1.0,
                curve: HealTokens.easeOutQuart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: HealTokens.s40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Reference (small, brass)
                      AnimatedSwitcher(
                        duration: HealTokens.d800,
                        child: Text(
                          scripture.reference.toUpperCase(),
                          key: ValueKey('${scripture.id}_ref_$retypeTick'),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: palette.primary,
                                letterSpacing: 4.0,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: HealTokens.s32),

                      // The verse (large, contemplative)
                      _ReTypingText(
                        text: scripture.text,
                        key: ValueKey('verse_$retypeTick'),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: HealTokens.cream,
                              fontWeight: FontWeight.w300,
                              height: 1.4,
                              letterSpacing: 0.3,
                            ),
                        phase: phase.value,
                      ),

                      const SizedBox(height: HealTokens.s32),

                      // Reflection prompt (smaller, italic)
                      if (scripture.reflectionPrompt != null)
                        AnimatedSwitcher(
                          duration: HealTokens.d800,
                          child: Text(
                            scripture.reflectionPrompt!,
                            key: ValueKey('${scripture.id}_prompt_$retypeTick'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: palette.accent.withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                  height: 1.6,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // When faded: a single candle flame in the center
            AnimatedOpacity(
              duration: HealTokens.d2000,
              opacity: isFaded.value ? 1.0 : 0.0,
              child: Center(
                child: _CandleFlame(color: palette.accent),
              ),
            ),

            // Top bar: exit + elapsed timer
            Positioned(
              top: HealTokens.s48,
              left: HealTokens.s24,
              right: HealTokens.s24,
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: HealTokens.creamDim.withValues(alpha: 0.6)),
                      onPressed: () {
                        _recordSession(ref, DateTime.now().difference(sessionStart.value).inSeconds);
                        Navigator.of(context).pop();
                      },
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: HealTokens.s16,
                        vertical: HealTokens.s8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: palette.primary.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: palette.primary),
                          const SizedBox(width: HealTokens.s8),
                          Text(
                            _formatElapsed(
                                DateTime.now().difference(sessionStart.value)),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: palette.primary,
                                  letterSpacing: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom hint (only visible at start)
            Positioned(
              bottom: HealTokens.s32,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: HealTokens.d500,
                opacity: isFaded.value ? 0.0 : 0.6,
                child: Center(
                  child: Text(
                    'tap to stay · drift if you wish',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: HealTokens.creamDim,
                          letterSpacing: 2.0,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _recordSession(WidgetRef ref, int seconds) {
    if (seconds < 10) return; // too short, don't count
    // ignore: discarded_futures
    ref.read(streakServiceProvider.notifier).recordSession(SessionRecord(
          timestamp: DateTime.now(),
          type: SessionType.scripture,
          durationSeconds: seconds,
        ));
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static List<_Particle> _seedParticles() {
    final rng = math.Random(42);
    return List.generate(18, (i) => _Particle(
          x: rng.nextDouble(),
          y: rng.nextDouble() * 1.0,
          phase: rng.nextDouble() * 2 * math.pi,
          opacity: 0.3 + rng.nextDouble() * 0.5,
          size: 1.5 + rng.nextDouble() * 2.0,
        ));
  }
}

class _Particle {
  final double x;       // 0..1 (relative to width)
  final double y;       // 0..1 (relative to height, drifts down→up)
  final double phase;   // sine phase for x oscillation
  final double opacity;
  final double size;

  const _Particle({
    required this.x,
    required this.y,
    required this.phase,
    required this.opacity,
    required this.size,
  });
}

class _CandlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double time;

  _CandlePainter({required this.particles, required this.color, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final p in particles) {
      paint.color = color.withValues(alpha: p.opacity * 0.4);
      final pos = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(pos, p.size, paint);
      // Glow
      paint.color = color.withValues(alpha: p.opacity * 0.08);
      canvas.drawCircle(pos, p.size * 4, paint);
    }
  }

  @override
  bool shouldRepaint(_CandlePainter old) => true;
}

class _CandleFlame extends StatelessWidget {
  final Color color;
  const _CandleFlame({required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.05),
      duration: const Duration(milliseconds: 2400),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.95),
                  color.withValues(alpha: 0.6),
                  color.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 48,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReTypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double phase;
  const _ReTypingText({
    super.key,
    required this.text,
    this.style,
    required this.phase,
  });

  @override
  State<_ReTypingText> createState() => _ReTypingTextState();
}

class _ReTypingTextState extends State<_ReTypingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late String _visibleText;
  static const _revealDuration = Duration(milliseconds: 6000);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _revealDuration);
    _visibleText = '';
    _controller.addListener(() {
      final charsToShow = (widget.text.length * _controller.value).round();
      if (charsToShow != _visibleText.length && charsToShow <= widget.text.length) {
        setState(() {
          _visibleText = widget.text.substring(0, charsToShow);
        });
      }
    });
    _controller.forward();
  }

  @override
  void didUpdateWidget(_ReTypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.reset();
      _visibleText = '';
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _visibleText,
      style: widget.style,
      textAlign: TextAlign.center,
    );
  }
}