// HEAL — Listening history service.
//
// Records every track the user has played (or read) so they can revisit
// it. Capped to 100 entries to keep SharedPreferences lean.
//
// Differs from ActivityTracker:
//   - ActivityTracker is for analytics (count plays, fuel the streak)
//   - HistoryService is for the user-facing "Recently played" list
//
// Each entry is denormalized so the list can render without a network
// round-trip when the user opens it offline.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  final String kind;          // 'meditation' | 'praise' | 'prayer' | 'scripture' | ...
  final String slug;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final int durationSeconds;
  final DateTime playedAt;
  final double completionRatio;  // 0.0-1.0; 1.0 = finished

  const HistoryEntry({
    required this.kind,
    required this.slug,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.durationSeconds,
    required this.playedAt,
    this.completionRatio = 0.0,
  });

  Map<String, Object?> toJson() => {
        'kind': kind,
        'slug': slug,
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'durationSeconds': durationSeconds,
        'playedAt': playedAt.toIso8601String(),
        'completionRatio': completionRatio,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        kind: json['kind'] as String? ?? 'unknown',
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        imageUrl: json['imageUrl'] as String?,
        durationSeconds: (json['durationSeconds'] as int?) ?? 0,
        playedAt: json['playedAt'] != null
            ? DateTime.tryParse(json['playedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        completionRatio: (json['completionRatio'] as num?)?.toDouble() ?? 0.0,
      );

  String get compositeId => '$kind:$slug';
}

class HistoryState {
  final List<HistoryEntry> entries;
  final bool ready;

  const HistoryState({required this.entries, required this.ready});

  /// Most-recent N entries.
  List<HistoryEntry> recent({int n = 30}) =>
      entries.take(n).toList(growable: false);

  /// All entries of a given kind.
  List<HistoryEntry> ofKind(String kind) =>
      entries.where((e) => e.kind == kind).toList(growable: false);

  /// Already played this kind+slug?
  bool contains(String kind, String slug) =>
      entries.any((e) => e.kind == kind && e.slug == slug);
}

class HistoryService extends StateNotifier<HistoryState> {
  static const _key = 'heal.history.v1';
  static const _max = 100;

  HistoryService() : super(const HistoryState(entries: [], ready: false)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    final list = raw
        .map((s) {
          try {
            final m = jsonDecode(s) as Map<String, dynamic>;
            return HistoryEntry.fromJson(m);
          } catch (_) {
            return null;
          }
        })
        .whereType<HistoryEntry>()
        .toList();
    state = HistoryState(entries: list, ready: true);
  }

  /// Record a play. Most recent first. Deduplicates consecutive plays
  /// of the same item within 5 seconds.
  Future<void> record(HistoryEntry entry) async {
    final filtered = state.entries.where((e) {
      // Drop if same composite ID and played within the last 5 seconds.
      if (e.compositeId == entry.compositeId &&
          entry.playedAt.difference(e.playedAt).inSeconds.abs() < 5) {
        return false;
      }
      return true;
    }).toList();
    filtered.insert(0, entry);
    if (filtered.length > _max) filtered.removeRange(_max, filtered.length);
    state = HistoryState(entries: filtered, ready: true);
    await _persist();
  }

  Future<void> remove(String kind, String slug) async {
    final next = state.entries
        .where((e) => !(e.kind == kind && e.slug == slug))
        .toList();
    state = HistoryState(entries: next, ready: true);
    await _persist();
  }

  Future<void> clear() async {
    state = const HistoryState(entries: [], ready: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }
}

final historyServiceProvider =
    StateNotifierProvider<HistoryService, HistoryState>(
  (ref) => HistoryService(),
);
