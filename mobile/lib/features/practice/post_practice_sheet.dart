// HEAL — PostPracticeSheet.
//
// A bottom sheet that appears for 30s after an audio session completes.
// Offers three gentle next-step options:
//
//   1. Sit for 60 seconds (a 1-minute breath — no UI, just a countdown)
//   2. Read today's scripture (opens /sit-with-verse)
//   3. Pick another song (opens /praise)
//
// Brand promise: no streak, no judgment, no urgency. The user is in
// the "after" moment — give them quiet choices, not a checklist.
//
// Architecture: it's a `StateNotifier<PostPracticeEvent?>` that the
// audio completion handler fires. Any screen with a [PostPracticeListener]
// widget in its tree will show the sheet. Mount [PostPracticeListener]
// in app.dart so it works everywhere.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../services/audio_service.dart';

class PostPracticeEvent {
  const PostPracticeEvent({
    required this.trackTitle,
    required this.audioSource,
  });
  final String trackTitle;
  final AudioSource audioSource;
}

class _PostPracticeController extends StateNotifier<PostPracticeEvent?> {
  _PostPracticeController() : super(null);
  void show(PostPracticeEvent event) => state = event;
  void clear() => state = null;
}

final postPracticeProvider =
    StateNotifierProvider<_PostPracticeController, PostPracticeEvent?>(
  (_) => _PostPracticeController(),
);

class PostPracticeListener extends ConsumerStatefulWidget {
  const PostPracticeListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<PostPracticeListener> createState() =>
      _PostPracticeListenerState();
}

class _PostPracticeListenerState extends ConsumerState<PostPracticeListener> {
  ProviderSubscription<PostPracticeEvent?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual<PostPracticeEvent?>(
      postPracticeProvider,
      (prev, next) {
        if (next == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          try {
            showPostPracticeSheet(context, next);
          } catch (e) {
            // Defensive: never let the sheet crash the app.
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

bool _sheetShown = false;

void showPostPracticeSheet(BuildContext context, PostPracticeEvent event) {
  if (_sheetShown) return;
  _sheetShown = true;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (sheetCtx) {
      return _PostPracticeSheet(event: event);
    },
  ).whenComplete(() {
    _sheetShown = false;
  });
}

class _PostPracticeSheet extends StatelessWidget {
  const _PostPracticeSheet({required this.event});
  final PostPracticeEvent event;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: HealTokens.rosewoodDeep,
          borderRadius: BorderRadius.circular(HealTokens.r24),
          border: Border.all(
            color: HealTokens.brass.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: HealTokens.creamDim.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Eyebrow
            Text(
              'A QUIET MOMENT, KEPT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
            const SizedBox(height: 12),
            // Headline — references the track title
            Text(
              'You sat with',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HealTokens.creamDim,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
            const SizedBox(height: 6),
            Text(
              event.trackTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: HealTokens.cream,
                fontSize: 22,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
                height: 1.2,
              ),
            ).animate().fadeIn(delay: 120.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 28),
            // Three options
            _Option(
              icon: Icons.spa_rounded,
              title: 'Sit for 60 seconds',
              subtitle: 'A one-minute breath. No sound, no goal.',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                context.push('/breathe');
              },
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            _Option(
              icon: Icons.menu_book_rounded,
              title: 'Read today\'s verse',
              subtitle: 'A short sit with a single scripture.',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                context.push('/sit-with-verse');
              },
            ).animate().fadeIn(delay: 260.ms, duration: 300.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            _Option(
              icon: Icons.music_note_rounded,
              title: 'Pick another song',
              subtitle: 'Browse the praise library.',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                context.push('/praise');
              },
            ).animate().fadeIn(delay: 320.ms, duration: 300.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            // Dismiss
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Not now',
                style: TextStyle(
                  color: HealTokens.creamDim,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HealTokens.r16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: HealTokens.rosewoodLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(HealTokens.r16),
            border: Border.all(
              color: HealTokens.brass.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HealTokens.brass.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: HealTokens.brass, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: HealTokens.cream,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: HealTokens.creamDim,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: HealTokens.creamDim,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
