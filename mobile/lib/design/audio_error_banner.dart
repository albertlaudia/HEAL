// HEAL — Audio error banner.
//
// A non-modal, slide-in-from-bottom banner that appears whenever the audio
// service reports an error (network, decode, session lost, …). The banner
// shows the user-friendly copy from [AudioError] plus a single CTA that
// retries / skips to the next track / etc.
//
// Use [AudioErrorListener] at the root of the app to wire it up — it watches
// [audioServiceProvider] and shows the banner reactively.

import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    ref.listen<AudioState>(audioServiceProvider, (prev, next) {
      if (next.error == null) {
        _shownMessage = null;
        return;
      }
      // Avoid showing the same banner twice in a row (e.g. if state.error
      // sticks around as we navigate).
      if (next.error == _shownMessage) return;
      _shownMessage = next.error;
      // Slight delay so the error doesn't pop during a navigation transition.
      Future.microtask(() {
        if (!mounted) return;
        showAudioErrorBanner(context, ref, next.error!);
      });
    });
    return widget.child;
  }
}

/// Public entry-point so non-listener code (e.g. an explicit retry button)
/// can show the same banner.
void showAudioErrorBanner(BuildContext context, WidgetRef ref, String message) {
  // We do NOT use ScaffoldMessenger to avoid the giant black snackbar feel.
  // Instead, a small overlay banner pinned to the bottom.
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AudioErrorBanner(
      message: message,
      onDismiss: () {
        try {
          ref.read(audioServiceProvider.notifier).clearError();
        } catch (_) {}
        entry.remove();
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
        entry.remove();
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
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HealTokens.rosewood,
                borderRadius: BorderRadius.circular(HealTokens.r16),
                border: Border(
                  left: BorderSide(color: HealTokens.brass, width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hearing_disabled_rounded,
                    color: HealTokens.brass,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: HealTokens.cream,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onAction,
                    child: Text(
                      'Try again',
                      style: TextStyle(
                        color: HealTokens.brass,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: HealTokens.cream.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    onPressed: onDismiss,
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
