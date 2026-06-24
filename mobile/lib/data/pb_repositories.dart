// HEAL — PocketBase repositories.
// One repo per content type. All fetch from PB; cache for 5 minutes.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'pb_models.dart';

const _cacheTtl = Duration(minutes: 5);

class _CachedList<T> {
  final List<T> data;
  final DateTime fetchedAt;
  _CachedList(this.data) : fetchedAt = DateTime.now();
  bool get fresh => DateTime.now().difference(fetchedAt) < _cacheTtl;
}

/// ── Meditations ──────────────────────────────────────────────────
class MeditationRepository {
  final PocketBase _pb;
  final Map<String, _CachedList<Meditation>> _cache = {};

  MeditationRepository(this._pb);

  Future<List<Meditation>> list({
    int page = 1,
    int perPage = 50,
    String? filter,
    String? sort = '-sort_order,-created',
  }) async {
    final key = '${page}_${perPage}_${filter ?? ''}_$sort';
    final cached = _cache[key];
    if (cached != null && cached.fresh) return cached.data;

    final params = {
      'page': page,
      'perPage': perPage,
      'filter': 'is_published=true${filter != null ? ' && ($filter)' : ''}',
      'sort': sort,
    };
    final records =
        await _pb.collection('HEAL_meditations').getList(page: page, perPage: perPage, filter: params['filter'], sort: sort);
    final list = records.items.map((r) => Meditation.fromJson(r.toJson())).toList();
    _cache[key] = _CachedList(list);
    return list;
  }

  Future<Meditation?> get(String id) async {
    try {
      final r = await _pb.collection('HEAL_meditations').getOne(id);
      return Meditation.fromJson(r.toJson());
    } catch (_) {
      return null;
    }
  }
}

/// ── Praise ───────────────────────────────────────────────────────
class PraiseRepository {
  final PocketBase _pb;
  final Map<String, _CachedList<PraiseSong>> _cache = {};

  PraiseRepository(this._pb);

  Future<List<PraiseSong>> list({String? category, int limit = 100}) async {
    final key = 'all_${category ?? ''}_$limit';
    final cached = _cache[key];
    if (cached != null && cached.fresh) return cached.data;

    final filter = 'is_published=true${category != null ? ' && category="$category"' : ''}';
    final records = await _pb.collection('HEAL_praise').getList(
      page: 1,
      perPage: limit,
      filter: filter,
      sort: '-sort_order,-created',
    );
    final list = records.items.map((r) => PraiseSong.fromJson(r.toJson())).toList();
    _cache[key] = _CachedList(list);
    return list;
  }
}

/// ── Prayers ──────────────────────────────────────────────────────
class PrayerRepository {
  final PocketBase _pb;
  final Map<String, _CachedList<Prayer>> _cache = {};

  PrayerRepository(this._pb);

  Future<List<Prayer>> list({String? emotion, String? category, int limit = 200}) async {
    final key = '${emotion ?? ''}_${category ?? ''}_$limit';
    final cached = _cache[key];
    if (cached != null && cached.fresh) return cached.data;

    final filters = <String>['is_published=true'];
    if (emotion != null) filters.add('emotion="$emotion"');
    if (category != null) filters.add('category="$category"');
    final filter = filters.join(' && ');

    final records = await _pb.collection('HEAL_prayers').getList(
      page: 1,
      perPage: limit,
      filter: filter,
      sort: '-created',
    );
    final list = records.items.map((r) => Prayer.fromJson(r.toJson())).toList();
    _cache[key] = _CachedList(list);
    return list;
  }
}

/// ── Scriptures ───────────────────────────────────────────────────
class ScriptureRepository {
  final PocketBase _pb;
  final Map<String, _CachedList<Scripture>> _cache = {};

  ScriptureRepository(this._pb);

  Future<List<Scripture>> list({int limit = 100, int? dayOfYear, String? theme}) async {
    final key = '${dayOfYear ?? ''}_${theme ?? ''}_$limit';
    final cached = _cache[key];
    if (cached != null && cached.fresh) return cached.data;

    final filters = <String>['is_published=true'];
    if (dayOfYear != null) filters.add('day_of_year=$dayOfYear');
    if (theme != null) filters.add('theme="$theme"');
    final filter = filters.join(' && ');

    final records = await _pb.collection('HEAL_scriptures').getList(
      page: 1,
      perPage: limit,
      filter: filter,
      sort: '-day_of_year,-created',
    );
    final list = records.items.map((r) => Scripture.fromJson(r.toJson())).toList();
    _cache[key] = _CachedList(list);
    return list;
  }
}

/// ── Quotes ───────────────────────────────────────────────────────
class QuoteRepository {
  final PocketBase _pb;
  final Map<String, _CachedList<Quote>> _cache = {};

  QuoteRepository(this._pb);

  Future<List<Quote>> list({int? dayOfYear, String? emotion, int limit = 200}) async {
    final key = '${dayOfYear ?? ''}_${emotion ?? ''}_$limit';
    final cached = _cache[key];
    if (cached != null && cached.fresh) return cached.data;

    final filters = <String>['is_published=true'];
    if (dayOfYear != null) filters.add('day_of_year=$dayOfYear');
    if (emotion != null) filters.add('emotion="$emotion"');
    final filter = filters.join(' && ');

    final records = await _pb.collection('HEAL_quotes').getList(
      page: 1,
      perPage: limit,
      filter: filter,
      sort: '-created',
    );
    final list = records.items.map((r) => Quote.fromJson(r.toJson())).toList();
    _cache[key] = _CachedList(list);
    return list;
  }
}

/// ── Breath patterns ──────────────────────────────────────────────
class BreathRepository {
  final PocketBase _pb;
  final Map<String, _CachedList<BreathPattern>> _cache = {};

  BreathRepository(this._pb);

  Future<List<BreathPattern>> list() async {
    const key = 'all';
    final cached = _cache[key];
    if (cached != null && cached.fresh) return cached.data;

    final records = await _pb.collection('HEAL_breathwork').getList(
      page: 1,
      perPage: 50,
      filter: 'is_published=true',
      sort: 'sort_order',
    );
    final list = records.items.map((r) => BreathPattern.fromJson(r.toJson())).toList();
    _cache[key] = _CachedList(list);
    return list;
  }
}

/// ── Essays ───────────────────────────────────────────────────────
class EssayRepository {
  final PocketBase _pb;
  final Map<String, _CachedList<Essay>> _cache = {};

  EssayRepository(this._pb);

  Future<List<Essay>> list({int limit = 50}) async {
    const key = 'all';
    final cached = _cache[key];
    if (cached != null && cached.fresh) return cached.data;

    final records = await _pb.collection('HEAL_essays').getList(
      page: 1,
      perPage: limit,
      filter: 'is_published=true',
      sort: '-created',
    );
    final list = records.items.map((r) => Essay.fromJson(r.toJson())).toList();
    _cache[key] = _CachedList(list);
    return list;
  }
}

/// ── Providers ────────────────────────────────────────────────────
final pocketbaseProvider = Provider<PocketBase>((ref) {
  throw UnimplementedError('Override in main()');
});

final meditationRepoProvider =
    Provider<MeditationRepository>((ref) => MeditationRepository(ref.watch(pocketbaseProvider)));
final praiseRepoProvider =
    Provider<PraiseRepository>((ref) => PraiseRepository(ref.watch(pocketbaseProvider)));
final prayerRepoProvider =
    Provider<PrayerRepository>((ref) => PrayerRepository(ref.watch(pocketbaseProvider)));
final scriptureRepoProvider =
    Provider<ScriptureRepository>((ref) => ScriptureRepository(ref.watch(pocketbaseProvider)));
final quoteRepoProvider =
    Provider<QuoteRepository>((ref) => QuoteRepository(ref.watch(pocketbaseProvider)));
final breathRepoProvider =
    Provider<BreathRepository>((ref) => BreathRepository(ref.watch(pocketbaseProvider)));
final essayRepoProvider =
    Provider<EssayRepository>((ref) => EssayRepository(ref.watch(pocketbaseProvider)));