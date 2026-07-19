// HEAL — Now Playing pill (floating).
//
// A small circular pill in the bottom-right of every screen that shows
// when audio is playing. Tapping it navigates back to the main shell
// (where the bottom mini player is visible) so the user can manage
// playback. Long-press expands the mini player.
//
// Why this exists:
//   The existing `ExpandableMiniPlayer` lives in the bottomNavigationBar
//   of the main Scaffold. When the user navigates to a detail page
//   (song, meditation, scripture, prayer) — which has its own Scaffold —
//   the mini player disappears. Users couldn't tell if the audio was
//   still playing or how to get back to the player.
//
//   A floating pill is the lightest-weight solution: 48x48, bottom-right,
//   doesn't conflict with back buttons, scroll bars, or the bottom mini
//   player when it IS visible. On the main shell the pill hides itself
//   (the mini player is already there).
//
// It's mounted in app.dart via [NowPlayingPill] so it lives OUTSIDE the
// route's Scaffold. Always visible, regardless of which detail page
// the user is on.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../services/audio_service.dart';

class NowPlayingPill extends ConsumerStatefulWidget {
  const NowPlayingPill({super.key});

  @override
  ConsumerState<NowPlayingPill> createState() => _NowPlayingPillState();
}

class _NowPlayingPillState extends ConsumerState<NowPlayingPill> {
  ProviderSubscription<AudioState>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual<AudioState>(
      audioServiceProvider,
      (prev, next) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioServiceProvider);
    final track = audio.track;
    if (track == null) return const SizedBox.shrink();

    // On the main shell, the bottom mini player is already visible.
    // Hide the pill there to avoid duplication.
    final loc = GoRouterState.of(context).uri.toString();
    final isMainShell = loc == '/' ||
        loc == '/home' ||
        loc == '/now' ||
        loc == '/prayer' ||
        loc == '/praise' ||
        loc == '/profile' ||
        loc == '/settings';
    if (isMainShell) return const SizedBox.shrink();

    return Positioned(
      right: 16,
      bottom: 16,
      child: SafeArea(
        top: false,
        left: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              // Pop back to the main shell so the user can see the
              // full mini player and the bottom controls.
              final navState = Navigator.maybeOf(context);
              if (navState != null && navState.canPop()) {
                navState.popUntil((route) => route.isFirst);
              }
            },
            customBorder: const CircleBorder(),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HealTokens.rosewoodDeep,
                border: Border.all(
                  color: HealTokens.brass.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Illustration thumbnail
                  ClipOval(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: track.illustrationUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: track.illustrationUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: HealTokens.rosewood,
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: HealTokens.rosewood,
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  color: HealTokens.brass,
                                  size: 22,
                                ),
                              ),
                            )
                          : Container(
                              color: HealTokens.rosewood,
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: HealTokens.brass,
                                size: 22,
                              ),
                            ),
                    ),
                  ),
                  // Play/pause icon overlay
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: audio.playing
                          ? Colors.black.withValues(alpha: 0.0)
                          : Colors.black.withValues(alpha: 0.55),
                    ),
                    child: audio.playing
                        ? null
                        : Icon(
                            audio.loading
                                ? Icons.hourglass_top_rounded
                                : Icons.play_arrow_rounded,
                            color: HealTokens.brass,
                            size: 26,
                          ),
                  ),
                  // Animated ring when playing
                  if (audio.playing)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _AudioPlayingRing(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle ring of light pulsing around the pill when audio is playing.
class _AudioPlayingRing extends StatefulWidget {
  @override
  State<_AudioPlayingRing> createState() => _AudioPlayingRingState();
}

class _AudioPlayingRingState extends State<_AudioPlayingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return CustomPaint(
          painter: _RingPainter(progress: _ctrl.value),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = HealTokens.brass.withValues(alpha: 0.6);
    final r = (size.width / 2) - 1;
    final center = Offset(size.width / 2, size.height / 2);
    final sweep = (1.0 - progress) * 6.283; // shrink from full circle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -1.5708, // start at top
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
