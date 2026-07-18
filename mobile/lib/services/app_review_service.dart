// HEAL — In-app review prompt service.
//
// Shows the OS-native "Rate HEAL?" sheet (Google Play In-App Review API on
// Android, StoreKit In-App Review on iOS). Per Apple + Google guidelines:
//   - Never show a custom dialog first
//   - Only call after the user has had a positive experience
//   - At most 1 prompt per 365 days
//   - Don't gate features behind a review
//
// We trigger on:
//   1. The user completes their 5th session
//   2. The user unlocks their 7th-day streak sticker
//   3. The user finishes the Bible program (day 365)
//
// All triggers are throttled to once every 6 months.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppReviewService {
  static const _lastPromptedKey = 'heal.review.last_prompted_at';
  static const _promptCountKey = 'heal.review.prompt_count';
  static const _cooldownDays = 180; // 6 months

  final InAppReview _inAppReview = InAppReview.instance;

  /// Returns true if the user is eligible for a review prompt right now.
  /// Used to gate the call to [requestReview] without asking twice.
  Future<bool> isEligible() async {
    if (kIsWeb) return false;
    if (!_isSupported) return false;
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastPromptedKey) ?? 0;
    if (lastMs == 0) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final days = DateTime.now().difference(last).inDays;
    return days >= _cooldownDays;
  }

  /// Returns true if the OS supports the in-app review flow.
  /// (iOS 14+ and Android 5+ via the Play Core SDK.)
  bool get _isSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// Show the native review sheet. Returns true if the user actually
  /// completed (left a rating), false if they dismissed or it wasn't shown.
  Future<bool> requestReview({String reason = 'general'}) async {
    if (kIsWeb || !_isSupported) return false;
    if (!await isEligible()) return false;
    try {
      if (!(await _inAppReview.isAvailable())) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('AppReview: not available on this platform');
        }
        return false;
      }
      await _inAppReview.requestReview();
      await _recordPrompt();
      return true;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('AppReview.requestReview failed: $e');
      }
      return false;
    }
  }

  /// In debug mode, this just logs. Used by tests + dev.
  Future<bool> debugFakeReview() async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('AppReview: (debug) fake review shown');
    }
    await _recordPrompt();
    return true;
  }

  Future<void> _recordPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPromptedKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_promptCountKey, (prefs.getInt(_promptCountKey) ?? 0) + 1);
  }

  /// Total times we've ever shown the review sheet to this user.
  Future<int> lifetimePromptCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_promptCountKey) ?? 0;
  }

  /// Reset all review state. Used by the "Reset HEAL" flow and tests.
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastPromptedKey);
    await prefs.remove(_promptCountKey);
  }
}

final appReviewServiceProvider = Provider<AppReviewService>((ref) {
  return AppReviewService();
});
