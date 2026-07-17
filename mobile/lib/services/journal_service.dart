// HEAL — Journal service.
//
// A private reflection journal. Each entry is short-form text the user
// writes in response to a meditation, prayer, or scripture reading.
//
// Persistence: SharedPreferences (no Firestore yet — kept local-only so
// the journal feels private). When Firebase auth is wired up, the
// optional sync layer can be added behind the same interface.
//
// Encryption: NOT YET. Future work: encrypt entries with a per-user
// key derived from a passphrase. For now entries are plaintext JSON
// in SharedPreferences. We document this gap clearly in the README.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalEntry {
  final String id;            // ULID-ish timestamp + random suffix
  final String? contextKind;  // 'meditation' | 'praise' | etc. (what prompted the entry)
  final String? contextSlug;
  final String? contextTitle;
  final String body;          // markdown-lite
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? mood;            // 1-5, optional user-tagged

  const JournalEntry({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.contextKind,
    this.contextSlug,
    this.contextTitle,
    this.mood,
  });

  JournalEntry copyWith({
    String? body,
    DateTime? updatedAt,
    int? mood,
  }) {
    return JournalEntry(
      id: id,
      contextKind: contextKind,
      contextSlug: contextSlug,
      contextTitle: contextTitle,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      mood: mood ?? this.mood,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'contextKind': contextKind,
        'contextSlug': contextSlug,
        'contextTitle': contextTitle,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'mood': mood,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String? ?? '',
        contextKind: json['contextKind'] as String?,
        contextSlug: json['contextSlug'] as String?,
        contextTitle: json['contextTitle'] as String?,
        body: json['body'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        mood: json['mood'] as int?,
      );
}

class JournalState {
  final List<JournalEntry> entries;
  final bool ready;

  const JournalState({required this.entries, required this.ready});

  /// Entries tied to a specific practice item, if any.
  List<JournalEntry> forContext(String kind, String slug) =>
      entries.where((e) => e.contextKind == kind && e.contextSlug == slug).toList();

  int get count => entries.length;
}

class JournalService extends StateNotifier<JournalState> {
  static const _key = 'heal.journal.v1';

  JournalService() : super(const JournalState(entries: [], ready: false)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    final list = raw
        .map((s) {
          try {
            return JournalEntry.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<JournalEntry>()
        .toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = JournalState(entries: list, ready: true);
  }

  /// Create a new journal entry. Returns the new id.
  Future<String> create({
    required String body,
    String? contextKind,
    String? contextSlug,
    String? contextTitle,
    int? mood,
  }) async {
    final now = DateTime.now();
    final entry = JournalEntry(
      id: _mintId(now),
      body: body,
      createdAt: now,
      updatedAt: now,
      contextKind: contextKind,
      contextSlug: contextSlug,
      contextTitle: contextTitle,
      mood: mood,
    );
    final next = [entry, ...state.entries];
    state = JournalState(entries: next, ready: true);
    await _persist();
    return entry.id;
  }

  /// Update an existing entry.
  Future<void> update(String id, {String? body, int? mood}) async {
    final next = state.entries.map((e) {
      if (e.id == id) {
        return e.copyWith(body: body, mood: mood, updatedAt: DateTime.now());
      }
      return e;
    }).toList();
    state = JournalState(entries: next, ready: true);
    await _persist();
  }

  /// Delete an entry.
  Future<void> delete(String id) async {
    final next = state.entries.where((e) => e.id != id).toList();
    state = JournalState(entries: next, ready: true);
    await _persist();
  }

  Future<void> clear() async {
    state = const JournalState(entries: [], ready: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }

  /// Time-ordered + 4 random base36 chars. Good enough for a
  /// per-device journal; not a security primitive.
  String _mintId(DateTime now) {
    final ms = now.microsecondsSinceEpoch.toRadixString(36);
    final r = (now.millisecondsSinceEpoch ^ now.hashCode)
        .toRadixString(36)
        .padLeft(6, '0');
    return '$ms-$r';
  }
}

final journalServiceProvider =
    StateNotifierProvider<JournalService, JournalState>(
  (ref) => JournalService(),
);
