// HEAL — Analytics service.
//
// Central analytics bus. Wraps Firebase Analytics (the actual SDK) with
// a single typed API so callers don't import firebase_analytics directly.
//
// Event naming follows the convention: snake_case, present-tense verb.
// Examples: `app_open`, `onboarding_complete`, `track_play_start`,
// `sticker_unlocked`, `auth_signin`, `auth_signout`, `notification_tap`.
//
// All calls are async + no-throw. A failure to log never breaks the app.

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';

class AnalyticsEvent {
  /// Snake_case event name. e.g. `track_play_start`.
  final String name;

  /// Free-form parameters. Values must be String, num, or null.
  /// (Firebase rejects bool — convert to 0/1 if needed.)
  final Map<String, Object?> params;

  const AnalyticsEvent(this.name, {this.params = const {}});
}

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;
  bool _initialized = false;

  /// Whether analytics events are being forwarded to Firebase.
  bool get isEnabled => _initialized;

  /// Enable analytics collection. No-op on web (we keep disabled there
  /// to keep the dev experience clean and the web bundle slim).
  Future<void> init() async {
    if (_initialized) return;
    try {
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('AnalyticsService.init failed: $e');
      }
    }
  }

  /// Set the user identifier (Firebase UID or anonymous local ID).
  /// Call after sign-in / sign-out.
  Future<void> setUser(String? identifier) async {
    if (!isEnabled) return;
    try {
      await _analytics.setUserId(identifier ?? 'anonymous');
    } catch (_) {}
  }

  /// Set a user property (e.g. `current_streak: 5`).
  Future<void> setUserProperty(String name, String? value) async {
    if (!isEnabled) return;
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (_) {}
  }

  /// Log a single event.
  Future<void> log(AnalyticsEvent event) async {
    if (!isEnabled) return;
    try {
      // Firebase Analytics requires parameter values to be String or num.
      // Coerce booleans to 0/1 and strip nulls.
      final clean = <String, Object>{};
      event.params.forEach((k, v) {
        if (v == null) return;
        if (v is bool) {
          clean[k] = v ? 1 : 0;
        } else if (v is num || v is String) {
          clean[k] = v;
        } else {
          clean[k] = v.toString();
        }
      });
      await _analytics.logEvent(name: event.name, parameters: clean);
    } catch (_) {}
  }

  /// Log a screen view. Use sparingly — Firebase auto-tracks
  /// `screen_view` events for MaterialApp routes.
  Future<void> logScreen(String name, {Map<String, Object?> params = const {}}) {
    return log(AnalyticsEvent('screen_view', params: {'screen_name': name, ...params}));
  }
}

// ──────────────────────────  Typed event helpers  ──────────────────────────

/// Standard analytics events. Use these rather than raw log() so the event
/// names stay consistent across the codebase.
class HealEvents {
  static const appOpen = 'app_open';
  static const onboardingStart = 'onboarding_start';
  static const onboardingComplete = 'onboarding_complete';
  static const onboardingSkipped = 'onboarding_skipped';

  static const trackPlayStart = 'track_play_start';
  static const trackPlayComplete = 'track_play_complete';
  static const trackPlayPaused = 'track_play_paused';
  static const trackPlaySkipped = 'track_play_skipped';
  static const trackPlayError = 'track_play_error';

  static const stickerUnlocked = 'sticker_unlocked';
  static const stickerViewed = 'sticker_viewed';

  static const authSignIn = 'auth_signin';
  static const authSignOut = 'auth_signout';
  static const authSignInFailed = 'auth_signin_failed';
  static const authProviderChosen = 'auth_provider_chosen';

  static const notificationTap = 'notification_tap';
  static const notificationScheduled = 'notification_scheduled';
  static const notificationPermissionAsked = 'notification_permission_asked';
  static const notificationPermissionGranted = 'notification_permission_granted';
  static const notificationPermissionDenied = 'notification_permission_denied';

  static const search = 'search';
  static const searchResultTap = 'search_result_tap';

  static const favoriteAdded = 'favorite_added';
  static const favoriteRemoved = 'favorite_removed';
  static const historyViewed = 'history_viewed';
  static const journalEntrySaved = 'journal_entry_saved';

  static const deepLinkOpened = 'deep_link_opened';
  static const shareUsed = 'share_used';

  static const appReviewPrompted = 'app_review_prompted';
  static const appReviewCompleted = 'app_review_completed';
  static const appReviewDeclined = 'app_review_declined';

  static const forceUpdateShown = 'force_update_shown';
  static const forceUpdateAccepted = 'force_update_accepted';

  static const settingsOpened = 'settings_opened';
  static const resetHealTriggered = 'reset_heal_triggered';
  static const resetHealCompleted = 'reset_heal_completed';
  static const onboardingReplay = 'onboarding_replay';

  static const problemReported = 'problem_reported';
  static const contactSupport = 'contact_support';
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final svc = AnalyticsService();
  // Fire-and-forget init. Listen to auth state to keep the user ID in sync.
  ref.listen<AsyncValue<HealUser?>>(authStateProvider, (_, next) {
    final u = next.valueOrNull;
    unawaited(svc.setUser(u?.uid));
  });
  return svc;
});
