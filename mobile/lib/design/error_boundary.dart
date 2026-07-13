// HEAL — ErrorBoundary
// ============================================================================
// Wraps a child widget tree and shows a reverent fallback when a render
// error occurs. Critical for production:
//   - User sees a kind message, not a red error screen
//   - Error is captured for the crash reporter (when Firebase Crashlytics
//     is wired, we'll post here)
//   - App stays interactive (the user can navigate to a working screen)
//
// Wrap the entire app with this in main.dart's MaterialApp.builder.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import 'lumen.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stack;

  @override
  void initState() {
    super.initState();
    // Capture Flutter framework errors that happen during build/layout/paint.
    FlutterError.onError = (details) {
      if (kReleaseMode) {
        // In release: do NOT print. Send to Crashlytics when wired.
        // TODO: FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } else {
        // In debug: dev-friendly print.
        // ignore: avoid_print
        print('FlutterError: ${details.exception}\n${details.stack}');
      }
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stack = details.stack;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorScreen(
        error: _error!,
        stack: _stack,
        onRetry: () => setState(() {
          _error = null;
          _stack = null;
        }),
      );
    }
    return widget.child;
  }
}

class _ErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace? stack;
  final VoidCallback onRetry;
  const _ErrorScreen({
    required this.error,
    this.stack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealTokens.rosewoodDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HealTokens.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LumenSlot(
                emotion: LumenEmotion.weary,
                size: 96,
              ),
              const SizedBox(height: HealTokens.s24),
              const Text(
                'Something went quietly wrong.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HealTokens.cream,
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: HealTokens.s12),
              Text(
                'We\'ve been told. Try again, or come back in a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HealTokens.creamDim.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: HealTokens.s32),
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onRetry();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HealTokens.s24, vertical: HealTokens.s12,
                  ),
                  side: BorderSide(color: HealTokens.brass.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: HealTokens.brass,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: HealTokens.s32),
                Container(
                  padding: const EdgeInsets.all(HealTokens.s12),
                  decoration: BoxDecoration(
                    color: HealTokens.rosewoodLight,
                    borderRadius: BorderRadius.circular(HealTokens.r12),
                  ),
                  child: Text(
                    '$error',
                    style: const TextStyle(
                      color: HealTokens.creamDim,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
