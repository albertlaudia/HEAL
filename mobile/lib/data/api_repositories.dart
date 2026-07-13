// HEAL — API repositories (Postgres-backed reads via Next.js gateway).
// ============================================================================
// Parallel implementation of pb_repositories.dart that hits the Next.js
// /api/heal/* routes instead of PocketBase. Same JSON shape on the
// wire, so Meditation.fromJson / PraiseSong.fromJson etc. are unchanged.
//
// Migration path:
//   1. The mobile app reads `nextApiUrl` from env.dart.
//   2. If set, all read paths route through Next.js → Postgres.
//   3. If null, fall back to PB (legacy path stays in the codebase
//      for rollback).
//   4. The PB write paths (bible progress, sticker evaluation) stay
//      where they are until Firebase auth lands.
//
// Reference: docs/POSTGRES_MIGRATION_PLAN.md
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../core/env.dart';
import 'pb_models.dart';

/// Light wrapper around the Next.js API.
class HealApi {
  final String baseUrl;
  final http.Client _client = http.Client();

  HealApi({String? baseUrl}) : baseUrl = baseUrl ?? HealEnv.nextApiUrl;

  Uri _u(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: '${base.path.replaceAll(RegExp(r'/+$'), '')}/api/heal$path',
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<List<JsonMap>> _list(String collection, [Map<String, dynamic>? query]) async {
    final uri = _u('/$collection', query);
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('GET $uri → ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['items'] as List).cast<JsonMap>();
  }

  Future<JsonMap?> _get(String collection, String id) async {
    final uri = _u('/$collection/$id');
    final res = await _client.get(uri);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception('GET $uri → ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as JsonMap;
  }

  void dispose() => _client.close();
}

typedef JsonMap = Map<String, dynamic>;

final healApiProvider = Provider<HealApi>((ref) {
  final api = HealApi();
  ref.onDispose(api.dispose);
  return api;
});


// ── Meditation ─────────────────────────────────────────────────────
class ApiMeditationRepository {
  final HealApi _api;
  ApiMeditationRepository(this._api);

  Future<List<Meditation>> list({
    int limit = 100,
    int offset = 0,
    String? dayOfYear,
    String? theme,
    String? isSleepStory,
    String? q,
  }) async {
    final items = await _api._list('meditations', {
      'limit': limit,
      'offset': offset,
      if (dayOfYear != null) 'day_of_year': dayOfYear,
      if (theme != null) 'theme': theme,
      if (isSleepStory != null) 'is_sleep_story': isSleepStory,
      if (q != null) 'q': q,
      'is_published': 'true',
    });
    return items.map(Meditation.fromJson).toList();
  }

  Future<Meditation?> get(String id) async {
    final json = await _api._get('meditations', id);
    return json == null ? null : Meditation.fromJson(json);
  }

  Future<Meditation?> byDayOfYear(int day) async {
    final items = await list(dayOfYear: '$day', limit: 1);
    return items.isEmpty ? null : items.first;
  }
}


// ── Praise ─────────────────────────────────────────────────────────
class ApiPraiseRepository {
  final HealApi _api;
  ApiPraiseRepository(this._api);

  Future<List<PraiseSong>> list({int limit = 200, String? category, String? q}) async {
    final items = await _api._list('praise', {
      'limit': limit,
      'is_published': 'true',
      if (category != null) 'category': category,
      if (q != null) 'q': q,
    });
    return items.map(PraiseSong.fromJson).toList();
  }

  Future<PraiseSong?> get(String id) async {
    final json = await _api._get('praise', id);
    return json == null ? null : PraiseSong.fromJson(json);
  }

  Future<PraiseSong?> byDayOfYear(int day) async {
    final items = await list(limit: 1, q: 'day_of_year:$day');
    return items.isEmpty ? null : items.first;
  }
}


// ── Prayer ─────────────────────────────────────────────────────────
class ApiPrayerRepository {
  final HealApi _api;
  ApiPrayerRepository(this._api);

  Future<List<Prayer>> list({int limit = 100, String? category, String? emotion}) async {
    final items = await _api._list('prayers', {
      'limit': limit,
      'is_published': 'true',
      if (category != null) 'category': category,
      if (emotion != null) 'emotion': emotion,
    });
    return items.map(Prayer.fromJson).toList();
  }

  Future<Prayer?> get(String id) async {
    final json = await _api._get('prayers', id);
    return json == null ? null : Prayer.fromJson(json);
  }
}


// ── Scripture ──────────────────────────────────────────────────────
class ApiScriptureRepository {
  final HealApi _api;
  ApiScriptureRepository(this._api);

  Future<List<Scripture>> list({int limit = 50, String? theme, String? dayOfYear}) async {
    final items = await _api._list('scriptures', {
      'limit': limit,
      'is_published': 'true',
      if (theme != null) 'theme': theme,
      if (dayOfYear != null) 'day_of_year': dayOfYear,
    });
    return items.map(Scripture.fromJson).toList();
  }

  Future<Scripture?> byDayOfYear(int day) async {
    final items = await list(dayOfYear: '$day', limit: 1);
    return items.isEmpty ? null : items.first;
  }
}


// ── Quote ──────────────────────────────────────────────────────────
class ApiQuoteRepository {
  final HealApi _api;
  ApiQuoteRepository(this._api);

  Future<List<Quote>> list({int limit = 80, String? category, String? isMotivation, String? dayOfYear}) async {
    final items = await _api._list('quotes', {
      'limit': limit,
      'is_published': 'true',
      if (category != null) 'category': category,
      if (isMotivation != null) 'is_motivation': isMotivation,
      if (dayOfYear != null) 'day_of_year': dayOfYear,
    });
    return items.map(Quote.fromJson).toList();
  }

  Future<Quote?> byDayOfYear(int day) async {
    final items = await list(dayOfYear: '$day', limit: 1);
    return items.isEmpty ? null : items.first;
  }
}


// ── Breathwork ─────────────────────────────────────────────────────
class ApiBreathRepository {
  final HealApi _api;
  ApiBreathRepository(this._api);

  Future<List<BreathPattern>> list({int limit = 20}) async {
    final items = await _api._list('breathwork', {'limit': limit});
    return items.map(BreathPattern.fromJson).toList();
  }
}


// ── Essay ──────────────────────────────────────────────────────────
class ApiEssayRepository {
  final HealApi _api;
  ApiEssayRepository(this._api);

  Future<List<Essay>> list({int limit = 20, String? q}) async {
    final items = await _api._list('essays', {
      'limit': limit,
      'is_published': 'true',
      if (q != null) 'q': q,
    });
    return items.map(Essay.fromJson).toList();
  }

  Future<Essay?> get(String id) async {
    final json = await _api._get('essays', id);
    return json == null ? null : Essay.fromJson(json);
  }
}


// ── Bible readings ─────────────────────────────────────────────────
class ApiBibleRepository {
  final HealApi _api;
  ApiBibleRepository(this._api);

  Future<List<BibleReading>> listAll() async {
    final items = await _api._list('bible-readings', {'limit': 500});
    return items.map(BibleReading.fromJson).toList();
  }
}


// ── World ──────────────────────────────────────────────────────────
class ApiWorldRepository {
  final HealApi _api;
  ApiWorldRepository(this._api);

  Future<List<WorldDay>> list({int limit = 30, String? category, String? dayOfYear}) async {
    final items = await _api._list('world', {
      'limit': limit,
      'is_published': 'true',
      if (category != null) 'category': category,
      if (dayOfYear != null) 'day_of_year': dayOfYear,
    });
    return items.map(WorldDay.fromJson).toList();
  }

  Future<WorldDay?> bySlug(String slug) async {
    final items = await list(limit: 500);
    for (final w in items) {
      if (w.slug == slug) return w;
    }
    return null;
  }
}


/// Provider aliases. These mirror the *RepoProvider names from
/// pb_repositories.dart so the rest of the app can be migrated by
/// simply renaming imports.
final apiMeditationRepoProvider = Provider<ApiMeditationRepository>(
  (ref) => ApiMeditationRepository(ref.watch(healApiProvider)),
);
final apiPraiseRepoProvider = Provider<ApiPraiseRepository>(
  (ref) => ApiPraiseRepository(ref.watch(healApiProvider)),
);
final apiPrayerRepoProvider = Provider<ApiPrayerRepository>(
  (ref) => ApiPrayerRepository(ref.watch(healApiProvider)),
);
final apiScriptureRepoProvider = Provider<ApiScriptureRepository>(
  (ref) => ApiScriptureRepository(ref.watch(healApiProvider)),
);
final apiQuoteRepoProvider = Provider<ApiQuoteRepository>(
  (ref) => ApiQuoteRepository(ref.watch(healApiProvider)),
);
final apiBreathRepoProvider = Provider<ApiBreathRepository>(
  (ref) => ApiBreathRepository(ref.watch(healApiProvider)),
);
final apiEssayRepoProvider = Provider<ApiEssayRepository>(
  (ref) => ApiEssayRepository(ref.watch(healApiProvider)),
);
final apiBibleRepoProvider = Provider<ApiBibleRepository>(
  (ref) => ApiBibleRepository(ref.watch(healApiProvider)),
);
final apiWorldRepoProvider = Provider<ApiWorldRepository>(
  (ref) => ApiWorldRepository(ref.watch(healApiProvider)),
);
