// HEAL — Lumen "Done." overlay.
//
// Shows for ~2.4 seconds when an audio session completes. Lumen is large,
// centered, in a "celebrating" state. The text below reads "Done." with a
// short brand voice line. No streak, no number, no judgment. Just
// acknowledgment that the moment happened.
//
// The overlay sits inside an Overlay via showLumenDone(). It auto-dismisses
// after the animation. Tapping anywhere dismisses it immediately.
//
// This is the single highest-leverage emotional change in the app:
// HEAL's brand promise is "a quiet practice" and "no streak-shame" — but
// without *any* completion feedback, finishing a meditation can feel
// anticlimactic. A gentle Lumen wave with "Done." closes the loop without
// turning the app into a leaderboard.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import 'lumen.dart';

/// A small "Done." event with the track title (optional).
class LumenDoneEvent {
  const LumenDoneEvent({this.trackTitle});
  final String? trackTitle;

  @override
  bool operator ==(Object other) =>
      other is LumenDoneEvent && other.trackTitle == trackTitle;
  @override
  int get hashCode => (trackTitle ?? '').hashCode;
}

class _LumenDoneController extends StateNotifier<LumenDoneEvent?> {
  _LumenDoneController() : super(null);
  void show(LumenDoneEvent event) => state = event;
  void clear() => state = null;
}

final lumenDoneProvider =
    StateNotifierProvider<_LumenDoneController, LumenDoneEvent?>(
  (_) => _LumenDoneController(),
);

class _DoneOverlayState {
  _DoneOverlayState();
  bool shown = false;
  OverlayEntry? entry;
}

/// Module-level guard so the overlay is shown at most once at a time.
final _DoneOverlayState _state = _DoneOverlayState();

/// A Lumen overlay that animates in, sits for ~2.4s, then fades out.
/// Used by the audio completion callback.
OverlayEntry? showLumenDone(
  BuildContext context, {
  String? trackTitle,
}) {
  // Use a module-level guard so we never stack two "Done." overlays.
  if (_state.shown) return null;
  _state.shown = true;

  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _LumenDoneSurface(
      trackTitle: trackTitle,
      onDismiss: () {
        if (entry.mounted) entry.remove();
        _state.shown = false;
      },
    ),
  );
  overlay.insert(entry);

  // Auto-dismiss after the surface animation finishes (2.4s).
  Future.delayed(const Duration(milliseconds: 2400), () {
    if (entry.mounted) entry.remove();
    _state.shown = false;
  });
  return entry;
}

/// A widget that listens to [lumenDoneProvider] and shows the overlay when
/// the provider emits a new event. Mount this once near the root of the app
/// (e.g. in `app.dart` just under `MaterialApp`). It has zero visual cost
/// unless an event fires.
class LumenDoneListener extends ConsumerStatefulWidget {
  const LumenDoneListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LumenDoneListener> createState() => _LumenDoneListenerState();
}

class _LumenDoneListenerState extends ConsumerState<LumenDoneListener> {
  ProviderSubscription<LumenDoneEvent?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual<LumenDoneEvent?>(
      lumenDoneProvider,
      (prev, next) {
        if (next == null) return;
        // Defer to the next frame so navigation transitions don't fight us.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          try {
            showLumenDone(context, trackTitle: next.trackTitle);
          } catch (e) {
            // Defensive: never let an overlay hiccup crash the app.
          }
        });
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _LumenDoneSurface extends StatefulWidget {
  const _LumenDoneSurface({required this.trackTitle, required this.onDismiss});
  final String? trackTitle;
  final VoidCallback onDismiss;

  @override
  State<_LumenDoneSurface> createState() => _LumenDoneSurfaceState();
}

class _LumenDoneSurfaceState extends State<_LumenDoneSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _lumenScale;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    // Lumen: in 0..600ms scale 0.6→1.0, hold 1.0 until 2000ms, fade 2000..2400ms
    _lumenScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 15),
    ]).animate(_ctrl);

    // Text: slide up + fade in 300..700ms, hold, fade out 2000..2400ms
    _textSlide = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 12),
      TweenSequenceItem(
        tween: Tween<double>(begin: 12, end: 0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 17,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 55),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 16,
      ),
    ]).animate(_ctrl);

    _textFade = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: 12),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 17,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 16,
      ),
    ]).animate(_ctrl);

    // Backdrop fade: 0..300ms in, 2000..2400ms out
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onDismiss();
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          // Backdrop opacity: 0 until 0.125 (300ms), full 0.4, fade out at 0.83
          final t = _ctrl.value;
          double backdropOpacity;
          if (t < 0.125) {
            backdropOpacity = (t / 0.125) * 0.4;
          } else if (t < 0.833) {
            backdropOpacity = 0.4;
          } else {
            backdropOpacity = 0.4 * (1.0 - (t - 0.833) / 0.167);
          }
          backdropOpacity = backdropOpacity.clamp(0.0, 0.4);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              _ctrl.reverse();
            },
            child: Container(
              color: Colors.black.withValues(alpha: backdropOpacity),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _lumenScale.value,
                    child: Lumen(
                      emotion: LumenEmotion.celebrating,
                      size: 132,
                      celebration: 1.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Opacity(
                    opacity: _textFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Column(
                        children: [
                          const Text(
                            'Done.',
                            style: TextStyle(
                              color: HealTokens.cream,
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.5,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (widget.trackTitle != null &&
                              widget.trackTitle!.isNotEmpty)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: Text(
                                'You sat with ${widget.trackTitle}.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: HealTokens.creamDim,
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            )
                          else
                            const Text(
                              'A quiet moment, kept.',
                              style: TextStyle(
                                color: HealTokens.creamDim,
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
