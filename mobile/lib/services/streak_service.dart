// HEAL — Streak + session tracking service.
//
// Tracks every completed practice session and computes:
//   - current streak (consecutive days with at least 1 session)
//   - longest streak ever
//   - total sessions, total minutes
//   - last session timestamp
//   - "broken days" rule: a day without practice doesn't break the streak
//     if you return within 3 days. After 3 days, the streak resets —
//     warmly. No red badges, no shame.
//
// Storage: SharedPreferences (single-device for v1; Firebase sync later).

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SessionType { breath, meditate, prayer, scripture, praise, essay }

extension SessionTypeLabel on SessionType {
  String get label {
    switch (this) {
      case SessionType.breath:
        return 'Breath';
      case SessionType.meditate:
        return 'Meditation';
      case SessionType.prayer:
        return 'Prayer';
      case SessionType.scripture:
        return 'Scripture';
      case SessionType.praise:
        return 'Praise';
      case SessionType.essay:
        return 'Essay';
    }
  }
}

class SessionRecord {
  final DateTime timestamp;
  final SessionType type;
  final int durationSeconds;

  const SessionRecord({
    required this.timestamp,
    required this.type,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'type': type.name,
        'dur': durationSeconds,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        timestamp: DateTime.parse(json['ts'] as String),
        type: SessionType.values
            .firstWhere((t) => t.name == json['type'], orElse: () => SessionType.meditate),
        durationSeconds: (json['dur'] as int?) ?? 0,
      );
}

class StreakState {
  final int currentStreak;
  final int longestStreak;
  final int totalSessions;
  final int totalMinutes;
  final DateTime? lastSession;
  final List<SessionRecord> recentSessions;
  final bool showedWelcomeBack; // local flag — don't show again this session

  const StreakState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.lastSession,
    this.recentSessions = const [],
    this.showedWelcomeBack = false,
  });

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalSessions,
    int? totalMinutes,
    DateTime? lastSession,
    List<SessionRecord>? recentSessions,
    bool? showedWelcomeBack,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalSessions: totalSessions ?? this.totalSessions,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      lastSession: lastSession ?? this.lastSession,
      recentSessions: recentSessions ?? this.recentSessions,
      showedWelcomeBack: showedWelcomeBack ?? this.showedWelcomeBack,
    );
  }

  /// Days since last session, clamped to >= 0. Null if never.
  int? get daysSinceLastSession {
    if (lastSession == null) return null;
    final now = DateTime.now();
    final last = DateTime(lastSession!.year, lastSession!.month, lastSession!.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(last).inDays;
  }

  /// True if the user has been away long enough to warrant a welcome-back card.
  /// Threshold: 4+ days. Within 4 days, just show normal streak.
  bool get shouldShowWelcomeBack {
    final d = daysSinceLastSession;
    return d != null && d >= 4;
  }

  /// A short phrase for the streak state. Warm, never guilt-laden.
  String get streakMessage {
    if (currentStreak == 0 && totalSessions == 0) {
      return 'Begin where you are.';
    }
    if (currentStreak == 0 && totalSessions > 0) {
      return 'A quiet return.';
    }
    if (currentStreak == 1) {
      return 'Day one of a new rhythm.';
    }
    if (currentStreak < 7) {
      return 'Day $currentStreak of a quiet practice.';
    }
    if (currentStreak < 30) {
      return '$currentStreak days. The room is becoming familiar.';
    }
    if (currentStreak < 100) {
      return '$currentStreak days. You are not the same as when you began.';
    }
    return '$currentStreak days. A long quiet.';
  }
}

class StreakService extends StateNotifier<StreakState> {
  StreakService() : super(const StreakState());

  static const _sessionsKey = 'heal_sessions_v1';
  static const _streakGraceDays = 4; // days absent before streak resets

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final List<dynamic> arr = jsonDecode(raw);
      final sessions = arr
          .map((j) => SessionRecord.fromJson(j as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      _recompute(sessions);
    } catch (e) {
      if (kDebugMode) print('StreakService.load error: $e');
    }
  }

  /// Record a completed practice session. Updates streak in place.
  Future<void> recordSession(SessionRecord session) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = state.recentSessions;
    final updated = [...existing, session]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Trim to last 90 days to keep storage small.
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final trimmed = updated.where((s) => s.timestamp.isAfter(cutoff)).toList();

    await prefs.setString(
      _sessionsKey,
      jsonEncode(trimmed.map((s) => s.toJson()).toList()),
    );

    _recompute(trimmed);
    state = state.copyWith(showedWelcomeBack: false);
  }

  void markWelcomeBackShown() {
    state = state.copyWith(showedWelcomeBack: true);
  }

  void _recompute(List<SessionRecord> sessions) {
    if (sessions.isEmpty) {
      state = const StreakState();
      return;
    }

    // Day-buckets of sessions.
    final dayKeys = <String>{};
    final byDay = <String, List<SessionRecord>>{};
    for (final s in sessions) {
      final k = _dayKey(s.timestamp);
      dayKeys.add(k);
      byDay.putIfAbsent(k, () => []).add(s);
    }

    // Total sessions + minutes
    final totalSessions = sessions.length;
    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + (s.durationSeconds / 60).round());

    // Compute current streak: walk back from today, allowing up to 3-day grace.
    final today = DateTime.now();
    final todayKey = _dayKey(today);

    int currentStreak = 0;
    int? longestStreak;

    if (dayKeys.contains(todayKey)) {
      // Active streak
      currentStreak = 1;
      var cursor = today.subtract(const Duration(days: 1));
      while (dayKeys.contains(_dayKey(cursor))) {
        currentStreak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    } else {
      // Check if last session was within grace period
      final lastSession = sessions.last;
      final daysAway = today.difference(lastSession.timestamp).inDays;
      if (daysAway <= _streakGraceDays) {
        // The streak is still "alive" even if today has no session yet
        currentStreak = 0; // today counts as a fresh day
        var cursor = lastSession.timestamp;
        var count = 1;
        cursor = cursor.subtract(const Duration(days: 1));
        while (dayKeys.contains(_dayKey(cursor))) {
          count++;
          cursor = cursor.subtract(const Duration(days: 1));
        }
        currentStreak = count;
      } else {
        // Streak broken — start fresh at 0
        currentStreak = 0;
      }
    }

    // Longest streak ever (compute from all sessions, sorted by day)
    final sortedDays = dayKeys.toList()..sort();
    int longest = 0;
    int run = 0;
    String? prevDay;
    for (final d in sortedDays) {
      if (prevDay == null) {
        run = 1;
      } else {
        final prev = DateTime.parse(prevDay);
        final cur = DateTime.parse(d);
        if (cur.difference(prev).inDays == 1) {
          run++;
        } else {
          run = 1;
        }
      }
      if (run > longest) longest = run;
      prevDay = d;
    }
    longestStreak = longest;

    state = state.copyWith(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalSessions: totalSessions,
      totalMinutes: totalMinutes,
      lastSession: sessions.last.timestamp,
      recentSessions: sessions,
    );
  }

  String _dayKey(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return d.toIso8601String();
  }
}

final streakServiceProvider =
    StateNotifierProvider<StreakService, StreakState>((ref) {
  final svc = StreakService();
  // ignore: discarded_futures
  svc.load();
  return svc;
});