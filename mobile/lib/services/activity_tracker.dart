// HEAL — local activity tracker.
// Records user actions to SharedPreferences so we can:
//   - Adapt the UI to user behavior (don't show Meditate card if they always
//     tap Praise)
//   - Generate the "PRACTICE STRIP" recommended order based on real use
//   - Surface accurate streaks (sessions, completions, milestones)
//   - Power local notifications tuned to actual usage patterns
//
// Privacy: 100% local. No remote sink. No PII leaves the device.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single logged action.
@immutable
class ActivityEvent {
  final String kind;         // 'open', 'play', 'complete', 'tap_meditate', etc.
  final String? target;      // meditation slug, prayer id, etc.
  final DateTime at;
  final Duration? durationMs;
  final Map<String, Object?> meta;

  const ActivityEvent({
    required this.kind,
    this.target,
    required this.at,
    this.durationMs,
    this.meta = const {},
  });

  Map<String, Object?> toJson() => {
        'k': kind,
        't': target,
        'a': at.toIso8601String(),
        if (durationMs != null) 'd': durationMs!.inMilliseconds,
        'm': meta,
      };

  factory ActivityEvent.fromJson(Map<String, dynamic> j) => ActivityEvent(
        kind: (j['k'] ?? '') as String,
        target: j['t'] as String?,
        at: DateTime.tryParse((j['a'] ?? '') as String) ?? DateTime.now(),
        durationMs: j['d'] != null ? Duration(milliseconds: (j['d'] as num).toInt()) : null,
        meta: (j['m'] as Map?)?.cast<String, Object?>() ?? const {},
      );
}

class ActivityTrackerState {
  final List<ActivityEvent> recent;
  final int totalSessions;
  final int totalPlays;
  final int totalCompletions;
  final DateTime? lastActiveAt;
  final Map<String, int> byKind;
  final Map<String, int> byTarget;

  const ActivityTrackerState({
    this.recent = const [],
    this.totalSessions = 0,
    this.totalPlays = 0,
    this.totalCompletions = 0,
    this.lastActiveAt,
    this.byKind = const {},
    this.byTarget = const {},
  });

  ActivityTrackerState copyWith({
    List<ActivityEvent>? recent,
    int? totalSessions,
    int? totalPlays,
    int? totalCompletions,
    DateTime? lastActiveAt,
    Map<String, int>? byKind,
    Map<String, int>? byTarget,
  }) => ActivityTrackerState(
        recent: recent ?? this.recent,
        totalSessions: totalSessions ?? this.totalSessions,
        totalPlays: totalPlays ?? this.totalPlays,
        totalCompletions: totalCompletions ?? this.totalCompletions,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
        byKind: byKind ?? this.byKind,
        byTarget: byTarget ?? this.byTarget,
      );

  /// How many times `target` was used (slug, id, or kind).
  int countFor(String target) => byTarget[target] ?? 0;

  /// Total events across all kinds.
  int totalCount() => recent.length;

  /// Count of events that happened on the same calendar day as `day`.
  int countOnDay(DateTime day) {
    final ymd = DateTime(day.year, day.month, day.day);
    int c = 0;
    for (final e in recent) {
      final ey = DateTime(e.at.year, e.at.month, e.at.day);
      if (ey == ymd) c++;
    }
    return c;
  }

  /// Top-N most-engaged target kinds (e.g. 'meditate', 'praise', 'pray').
  List<MapEntry<String, int>> topKinds({int n = 6}) {
    final entries = byKind.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(n).toList();
  }

  /// Whether the user engaged in the last `window` (default 14 days).
  bool get isActive {
    if (lastActiveAt == null) return false;
    return DateTime.now().difference(lastActiveAt!).inDays <= 14;
  }
}

class ActivityTracker extends StateNotifier<ActivityTrackerState> {
  ActivityTracker() : super(const ActivityTrackerState());

  static const _stateKey = 'heal.activity.v1';

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final events = (j['recent'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ActivityEvent.fromJson)
          .toList();
      state = state.copyWith(
        recent: events,
        totalSessions: (j['totalSessions'] ?? 0) as int,
        totalPlays: (j['totalPlays'] ?? 0) as int,
        totalCompletions: (j['totalCompletions'] ?? 0) as int,
        lastActiveAt: j['lastActiveAt'] != null
            ? DateTime.tryParse(j['lastActiveAt'] as String)
            : null,
        byKind: ((j['byKind'] as Map?) ?? {}).cast<String, int>(),
        byTarget: ((j['byTarget'] as Map?) ?? {}).cast<String, int>(),
      );
    } catch (_) {
      // Corrupted state — start fresh.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final j = {
      'recent': state.recent.take(200).map((e) => e.toJson()).toList(),
      'totalSessions': state.totalSessions,
      'totalPlays': state.totalPlays,
      'totalCompletions': state.totalCompletions,
      'lastActiveAt': state.lastActiveAt?.toIso8601String(),
      'byKind': state.byKind,
      'byTarget': state.byTarget,
    };
    await prefs.setString(_stateKey, jsonEncode(j));
  }

  /// Log a generic event.
  Future<void> log(
    String kind, {
    String? target,
    Duration? duration,
    Map<String, Object?>? meta,
  }) async {
    final event = ActivityEvent(
      kind: kind,
      target: target,
      at: DateTime.now(),
      durationMs: duration,
      meta: meta ?? const {},
    );
    final newRecent = [event, ...state.recent].take(200).toList();
    final byKind = Map<String, int>.from(state.byKind)
      ..[kind] = (state.byKind[kind] ?? 0) + 1;
    final byTarget = target == null
        ? state.byTarget
        : (Map<String, int>.from(state.byTarget)
          ..[target] = (state.byTarget[target] ?? 0) + 1);
    final totalSessions = kind == 'session' || kind == 'open'
        ? state.totalSessions + 1
        : state.totalSessions;
    final totalPlays = kind == 'play_start'
        ? state.totalPlays + 1
        : state.totalPlays;
    final totalCompletions = kind == 'play_complete' || kind == 'reading_complete'
        ? state.totalCompletions + 1
        : state.totalCompletions;
    state = state.copyWith(
      recent: newRecent,
      byKind: byKind,
      byTarget: byTarget,
      totalSessions: totalSessions,
      totalPlays: totalPlays,
      totalCompletions: totalCompletions,
      lastActiveAt: event.at,
    );
    await _persist();
  }

  /// Days since last "session" event.
  int daysSinceLastSession() {
    final last = state.recent
        .firstWhere(
          (e) => e.kind == 'session' || e.kind == 'open',
          orElse: () => ActivityEvent(kind: 'never', at: DateTime(2000)),
        );
    if (state.recent.isEmpty || last.kind == 'never') return 999;
    return DateTime.now().difference(last.at).inDays;
  }

  /// How many times the user engaged with `target` (slug, id, kind).
  int countFor(String target) => state.byTarget[target] ?? 0;

  /// Top-N most-engaged target kinds (e.g. 'meditate', 'praise', 'pray').
  List<MapEntry<String, int>> topKinds({int n = 6}) {
    final entries = state.byKind.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(n).toList();
  }
}

final activityTrackerProvider =
    StateNotifierProvider<ActivityTracker, ActivityTrackerState>((ref) {
  return ActivityTracker();
});
