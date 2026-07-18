// HEAL — Crash reporting service.
//
// Wraps Firebase Crashlytics with the project's standard breadcrumbs:
//   - User identifier (Firebase UID once signed in, random local ID otherwise)
//   - Custom keys: app_version, build_number, environment, session_count,
//     streak_days, last_route, last_practice_kind
//   - Non-fatal log() captures warnings and recoverable errors
//   - Test mode in debug builds (`crash()` from a debug button)
//
// Initialization is safe to call multiple times. All operations are no-ops
// when Crashlytics is not configured (e.g. plain `flutter run` before
// `flutterfire configure`).

import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CrashlyticsService {
  CrashlyticsService();

  bool _initialized = false;
  bool _enabled = true;

  /// True if the underlying Crashlytics instance is ready to accept reports.
  bool get isEnabled => _initialized && _enabled;

  /// Initialize Crashlytics. Safe to call from main(). All operations
  /// silently no-op if Firebase is not configured.
  Future<void> init({
    required String environment,
    String? userIdentifier,
    Map<String, Object?> initialKeys = const {},
  }) async {
    if (_initialized) return;
    try {
      // Catch uncaught Flutter framework errors
      FlutterError.onError = (details) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('FlutterError: ${details.exceptionAsString()}');
        }
        if (isEnabled) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
      };

      // Catch uncaught async errors outside the Flutter framework
      PlatformDispatcher.instance.onError = (error, stack) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('PlatformDispatcher error: $error\n$stack');
        }
        if (isEnabled) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
        return true;
      };

      // Set custom keys for context
      await FirebaseCrashlytics.instance.setCustomKey('environment', environment);
      for (final entry in initialKeys.entries) {
        await FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value ?? '');
      }

      // App version metadata
      try {
        final pkg = await PackageInfo.fromPlatform();
        await FirebaseCrashlytics.instance.setCustomKey('app_version', pkg.version);
        await FirebaseCrashlytics.instance.setCustomKey('build_number', pkg.buildNumber);
        await FirebaseCrashlytics.instance.setCustomKey('package_name', pkg.packageName);
      } catch (_) {
        // package_info_plus not available — non-fatal.
      }

      // User identifier (Firebase UID or random local ID)
      if (userIdentifier != null && userIdentifier.isNotEmpty) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userIdentifier);
      }

      // Disable in debug builds to keep dev experience clean
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('CrashlyticsService.init failed: $e');
      }
      _enabled = false;
    }
  }

  /// Set the user identifier (call after sign-in / sign-out).
  Future<void> setUser(String? identifier) async {
    if (!isEnabled) return;
    try {
      await FirebaseCrashlytics.instance
          .setUserIdentifier(identifier ?? 'anonymous');
    } catch (_) {}
  }

  /// Set a custom key (e.g. `streak_days`, `current_route`).
  Future<void> setKey(String key, Object? value) async {
    if (!isEnabled) return;
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value ?? '');
    } catch (_) {}
  }

  /// Log a non-fatal exception. Use for caught errors that the app handled.
  Future<void> log(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) async {
    if (!isEnabled) return;
    try {
      for (final entry in context.entries) {
        await FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value ?? '');
      }
      await FirebaseCrashlytics.instance.log(message);
      if (error != null) {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: message,
          fatal: false,
        );
      }
    } catch (_) {}
  }

  /// Trigger a non-fatal crash for the user's "Report a problem" entry.
  Future<void> reportProblem(String description) async {
    if (!isEnabled) return;
    try {
      await FirebaseCrashlytics.instance.log('user_report: $description');
      await FirebaseCrashlytics.instance.recordError(
        StateError('User reported problem: $description'),
        StackTrace.current,
        reason: 'user_report',
        fatal: false,
      );
    } catch (_) {}
  }

  /// Send any unsent reports. Call before sign-out or after a session ends.
  Future<void> flush() async {
    if (!isEnabled) return;
    try {
      await FirebaseCrashlytics.instance.sendUnsentReports();
    } catch (_) {}
  }

  /// Test-only: trigger a deliberate crash to verify the wiring works.
  /// Only available in debug builds. NEVER call this in production.
  void debugCrash() {
    assert(kDebugMode, 'debugCrash() can only be called in debug builds');
    throw StateError('Intentional debug crash for Crashlytics verification');
  }
}

final crashlyticsServiceProvider = Provider<CrashlyticsService>((ref) {
  return CrashlyticsService();
});
