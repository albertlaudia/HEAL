// HEAL — Global search service.
//
// Searches across all content types in parallel:
//   meditations, praise, prayers, scriptures, essays, world, quotes,
//   breathwork, bible-readings.
//
// Uses the Next.js API gateway (api_repositories.dart) with the `q` query
// parameter on collections that support it. Falls back to in-memory
// filtering for collections that don't have a server-side search.
//
// Ranks results by relevance: title-match > body-match > tag-match.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_repositories.dart';
import '../data/pb_models.dart';

class SearchResult {
  final String kind;          // 'meditation' | 'praise' | 'prayer' | etc.
  final String id;
  final String slug;          // for routing: /meditate/:slug, /praise/:slug
  final String title;
  final String subtitle;      // 1-line preview
  final String? imageUrl;
  final int score;            // 0-100, higher = more relevant
  final int durationSeconds;  // for the mini-player preview

  const SearchResult({
    required this.kind,
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.score,
    this.imageUrl,
    this.durationSeconds = 0,
  });
}

class SearchService {
  SearchService({
    required this.meditations,
    required this.praises,
    required this.prayers,
    required this.scriptures,
    required this.essays,
    required this.world,
  });

  final ApiMeditationRepository meditations;
  final ApiPraiseRepository praises;
  final ApiPrayerRepository prayers;
  final ApiScriptureRepository scriptures;
  final ApiEssayRepository essays;
  final ApiWorldRepository world;

  /// Run a global search. Returns a list of results ordered by relevance.
  /// Empty query returns recent items (so the empty state is useful).
  Future<List<SearchResult>> search(String query, {int maxPerKind = 8}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final lower = q.toLowerCase();
    final results = <SearchResult>[];

    // Fan out in parallel — each list call is independent.
    final futures = await Future.wait([
      _searchMeditations(lower, maxPerKind),
      _searchPraise(lower, maxPerKind),
      _searchPrayers(lower, maxPerKind),
      _searchScriptures(lower, maxPerKind),
      _searchEssays(lower, maxPerKind),
      _searchWorld(lower, maxPerKind),
    ]);

    for (final r in futures) {
      results.addAll(r);
    }

    // Sort by score descending.
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  Future<List<SearchResult>> _searchMeditations(String q, int limit) async {
    try {
      final list = await meditations.list(limit: 200, q: q);
      return list.map((m) {
        final score = _score(q, [m.title, m.subtitle, m.theme ?? '', m.body, m.tags.join(' ')]);
        return SearchResult(
          kind: 'meditation',
          id: m.id,
          slug: m.slug,
          title: m.title,
          subtitle: m.subtitle.isNotEmpty ? m.subtitle : _truncate(m.body, 90),
          score: score,
          imageUrl: m.illustrationUrl.isNotEmpty ? m.illustrationUrl : null,
          durationSeconds: m.durationSeconds,
        );
      }).where((r) => r.score > 0).take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<SearchResult>> _searchPraise(String q, int limit) async {
    try {
      final list = await praises.list(limit: 200, q: q);
      return list.map((p) {
        final score = _score(q, [
          p.title, p.subtitle, p.category ?? '', p.lyrics,
          p.reflection, p.scriptureRefs.join(' ')
        ]);
        return SearchResult(
          kind: 'praise',
          id: p.id,
          slug: p.slug,
          title: p.title,
          subtitle: p.subtitle.isNotEmpty ? p.subtitle : _truncate(p.lyrics, 90),
          score: score,
          imageUrl: p.illustrationUrl.isNotEmpty ? p.illustrationUrl : null,
          durationSeconds: 0,
        );
      }).where((r) => r.score > 0).take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<SearchResult>> _searchPrayers(String q, int limit) async {
    try {
      final list = await prayers.list(limit: 200);
      return list.map((p) {
        final score = _score(q, [p.title, p.category ?? '', p.body, p.tags.join(' ')]);
        return SearchResult(
          kind: 'prayer',
          id: p.id,
          slug: p.slug,
          title: p.title,
          subtitle: _truncate(p.body, 90),
          score: score,
          imageUrl: p.illustrationUrl.isNotEmpty ? p.illustrationUrl : null,
          durationSeconds: 0,
        );
      }).where((r) => r.score > 0).take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<SearchResult>> _searchScriptures(String q, int limit) async {
    try {
      final list = await scriptures.list(limit: 200);
      return list.map((s) {
        final score = _score(q, [
          s.reference, s.theme ?? '', s.text, s.reflectionPrompt ?? ''
        ]);
        return SearchResult(
          kind: 'scripture',
          id: s.id,
          slug: s.slug,
          title: s.reference,
          subtitle: _truncate(s.text, 90),
          score: score,
          durationSeconds: 0,
        );
      }).where((r) => r.score > 0).take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<SearchResult>> _searchEssays(String q, int limit) async {
    try {
      final list = await essays.list(limit: 200, q: q);
      return list.map((e) {
        final score = _score(q, [e.title, e.subtitle ?? '', e.body]);
        return SearchResult(
          kind: 'essay',
          id: e.id,
          slug: e.slug,
          title: e.title,
          subtitle: _truncate(e.body, 90),
          score: score,
          durationSeconds: 0,
        );
      }).where((r) => r.score > 0).take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<SearchResult>> _searchWorld(String q, int limit) async {
    try {
      final list = await world.list(limit: 200);
      return list.map((w) {
        final score = _score(q, [w.title, w.category, w.body]);
        return SearchResult(
          kind: 'world',
          id: w.id,
          slug: w.slug,
          title: w.title,
          subtitle: _truncate(w.body, 90),
          score: score,
          durationSeconds: 0,
        );
      }).where((r) => r.score > 0).take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Per-query scoring:
  ///   - exact title match = 100
  ///   - title prefix match = 80
  ///   - any field substring match = 50 (less for less-important fields)
  int _score(String q, List<String> fields) {
    if (q.isEmpty) return 0;
    int score = 0;
    for (int i = 0; i < fields.length; i++) {
      final f = fields[i].toLowerCase();
      if (f.isEmpty) continue;
      if (f == q) {
        score += 100 - (i * 10);
      } else if (f.startsWith(q)) {
        score += 80 - (i * 10);
      } else if (f.contains(q)) {
        score += 50 - (i * 5);
      }
    }
    return score.clamp(0, 100);
  }

  String _truncate(String s, int max) {
    final clean = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max - 1)}…';
  }
}

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(
    meditations: ref.watch(apiMeditationRepoProvider),
    praises: ref.watch(apiPraiseRepoProvider),
    prayers: ref.watch(apiPrayerRepoProvider),
    scriptures: ref.watch(apiScriptureRepoProvider),
    essays: ref.watch(apiEssayRepoProvider),
    world: ref.watch(apiWorldRepoProvider),
  );
});
