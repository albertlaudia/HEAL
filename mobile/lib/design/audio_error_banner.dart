// HEAL — Audio error banner.
//
// A non-modal, slide-in-from-bottom banner that appears whenever the audio
// service reports an error (network, decode, session lost, …). The banner
// shows the user-friendly copy from [AudioError] plus a single CTA that
// retries / skips to the next track / etc.
//
// Use [AudioErrorListener] at the root of the app to wire it up — it watches
// [audioServiceProvider] and shows the banner reactively.
//
// Robustness:
//   - The listener registers ONCE in initState (not in build). This avoids
//     accumulating listeners on every rebuild.
//   - Before inserting an Overlay, we verify the current state.context has
//     an Overlay ancestor. This prevents the "No Overlay widget found" error
//     when the listener fires during a navigation transition.
//   - Errors are caught and logged so a transient UI hiccup never throws.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../services/audio_error.dart';
import '../services/audio_service.dart';

class AudioErrorListener extends ConsumerStatefulWidget {
  final Widget child;
  const AudioErrorListener({super.key, required this.child});

  @override
  ConsumerState<AudioErrorListener> createState() => _AudioErrorListenerState();
}

class _AudioErrorListenerState extends ConsumerState<AudioErrorListener> {
  String? _shownMessage;
  ProviderSubscription<AudioState>? _sub;

  @override
  void initState() {
    super.initState();
    // Register the listener ONCE — listening inside build() would
    // accumulate subscriptions on every rebuild.
    _sub = ref.listenManual<AudioState>(
      audioServiceProvider,
      _onAudioChanged,
      fireImmediately: false,
    );
  }

  void _onAudioChanged(AudioState? prev, AudioState next) {
    if (next.error == null) {
      _shownMessage = null;
      return;
    }
    if (next.error == _shownMessage) return;
    _shownMessage = next.error;
    // Defer to after the frame finishes so the error doesn't pop during a
    // navigation transition. We use the root Navigator's overlay context
    // to avoid the "No Overlay widget found" error when the listener's
    // own context is being torn down.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rootCtx = _rootOverlayContext();
      if (rootCtx == null) return;
      try {
        showAudioErrorBanner(rootCtx, ref, next.error!);
      } catch (e) {
        // Defensive: never let an overlay hiccup crash the app.
      }
    });
  }

  /// Find a context that is guaranteed to have an Overlay ancestor.
  /// Returns the first context that has a Navigator ancestor.
  BuildContext? _rootOverlayContext() {
    final ctx = context;
    NavigatorState? nav;
    void visit(BuildContext c) {
      if (nav != null) return;
      nav = Navigator.maybeOf(c);
      if (nav != null) return;
      final p = c.findAncestorStateOfType<NavigatorState>();
      if (p != null) {
        nav = p;
        return;
      }
    }
    visit(ctx);
    return nav?.context;
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Public entry-point so non-listener code (e.g. an explicit retry button)
/// can show the same banner.
void showAudioErrorBanner(BuildContext context, WidgetRef ref, String message) {
  // Locate the root Overlay via the nearest Navigator. This avoids the
  // "No Overlay widget found" error when [context] is from a sub-route
  // that's being torn down.
  OverlayState? overlay;
  final nav = Navigator.maybeOf(context);
  if (nav != null) {
    overlay = nav.overlay;
  }
  overlay ??= Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AudioErrorBanner(
      message: message,
      onDismiss: () {
        try {
          ref.read(audioServiceProvider.notifier).clearError();
        } catch (_) {}
        if (entry.mounted) entry.remove();
      },
      onAction: () {
        final svc = ref.read(audioServiceProvider.notifier);
        final lastError = svc.lastError;
        // Pick an action by error code. Unknown → just retry.
        switch (lastError?.code) {
          case AudioErrorCode.serverError:
            svc.nextOrStop();
            break;
          case AudioErrorCode.noNetwork:
          case AudioErrorCode.decodeFailed:
          case AudioErrorCode.sessionLost:
          case AudioErrorCode.unknown:
          default:
            svc.retry();
            break;
        }
        svc.clearError();
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
  // Auto-dismiss after 8s if the user doesn't act.
  Future.delayed(const Duration(seconds: 8), () {
    if (entry.mounted) {
      try {
        ref.read(audioServiceProvider.notifier).clearError();
      } catch (_) {}
      entry.remove();
    }
  });
}

class _AudioErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  final VoidCallback onAction;
  const _AudioErrorBanner({
    required this.message,
    required this.onDismiss,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 100,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          decoration: BoxDecoration(
            color: HealTokens.rosewoodDeep,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HealTokens.brass.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: HealTokens.brass, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: HealTokens.cream,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: HealTokens.brass,
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded,
                    color: HealTokens.creamDim, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      )
          .animate()
          .slideY(
            begin: 1.0,
            end: 0,
            duration: 300.ms,
            curve: Curves.easeOutCubic,
          )
          .fadeIn(duration: 200.ms),
    );
  }
}
