// HEAL — PocketBase repositories.
// One repo per content type. All fetch from PB; cache for 5 minutes.
//
// IMPORTANT — PB sort quirks (learned the hard way):
//   PocketBase's getList() API validates sort fields against the schema.
//   System fields like `created` / `updated` are NOT exposed in
//   `?meta=schema` and so sorting by `-created` returns HTTP 400 from PB.
//   To get "newest first" we sort by `-id` instead — PB assigns id in
//   insertion order, so this is correct behaviour and far cheaper.
//   Use `safeSort()` below to keep the call sites readable.

import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pb_models.dart';

const _cacheTtl = Duration(minutes: 5);

/// PB-friendly sort strings.
/// `-id` = newest first (PB assigns id in insertion order)
/// `-sort_order` = user-defined order
/// Plain field name = ascending on that field
String _safeSort(String requested, {bool hasSortOrder = true}) {
  // Don't try to be clever — just keep what was asked if it's safe.
  // Insertion-order: anything ending in -created or containing -created maps to -id.
  if (requested.contains('-created') && !requested.contains('-sort')) {
    return hasSortOrder ? '-sort_order,-id' : '-id';
  }
  return requested;
}

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
    String sort = '-sort_order,-id',
  }) async {
    final safeSortStr = _safeSort(sort);
    final key = '${page}_${perPage}_${filter ?? ''}_$safeSortStr';
    final cached = _cache[key];
    if (cached != null && cached.fresh) return cached.data;

    final f = 'is_published=true${filter != null ? ' && ($filter)' : ''}';
    final records =
        await _pb.collection('HEAL_meditations').getList(page: page, perPage: perPage, filter: f, sort: safeSortStr);
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
    const sort = '-sort_order,-id';
    final key = 'all_${category ?? ''}_$limit';
    final cached = _cache[key];
    if (cached != null && cached.fresh) return cached.data;

    final filter = 'is_published=true${category != null ? ' && category="$category"' : ''}';
    final records = await _pb.collection('HEAL_praise').getList(
      page: 1,
      perPage: limit,
      filter: filter,
      sort: sort,
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
    const sort = '-sort_order,-id';
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
      sort: sort,
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
    // scriptures have NO sort_order field — sort by -day_of_year (newest first
    // in the calendar), tie-break by -id
    const sort = '-day_of_year,-id';
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
      sort: sort,
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
    const sort = '-day_of_year,-id';
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
      sort: sort,
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
    const sort = 'sort_order'; // ascending — patterns have explicit order
    const key = 'all';
    final cached = _cache[key];
    if (cached != null && cached.fresh) return cached.data;

    final records = await _pb.collection('HEAL_breathwork').getList(
      page: 1,
      perPage: 50,
      filter: 'is_published=true',
      sort: sort,
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
    // essays have no sort_order — sort by -id (newest first)
    const sort = '-id';
    const key = 'all';
    final cached = _cache[key];
    if (cached != null && cached.fresh) return cached.data;

    final records = await _pb.collection('HEAL_essays').getList(
      page: 1,
      perPage: limit,
      filter: 'is_published=true',
      sort: sort,
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

/// List all prayers (used by today shelf rotation).
final prayersProvider = FutureProvider<List<Prayer>>((ref) async {
  try {
    return await ref.watch(prayerRepoProvider).list(limit: 80);
  } catch (_) {
    return <Prayer>[];
  }
});

/// List all scriptures (used by today shelf rotation).
final allScripturesProvider = FutureProvider<List<Scripture>>((ref) async {
  try {
    return await ref.watch(scriptureRepoProvider).list(limit: 80);
  } catch (_) {
    return <Scripture>[];
  }
});
final quoteRepoProvider =
    Provider<QuoteRepository>((ref) => QuoteRepository(ref.watch(pocketbaseProvider)));
final breathRepoProvider =
    Provider<BreathRepository>((ref) => BreathRepository(ref.watch(pocketbaseProvider)));
final essayRepoProvider =
    Provider<EssayRepository>((ref) => EssayRepository(ref.watch(pocketbaseProvider)));
/// ── World (today's invitation) ────────────────────────────────────
class WorldRepository {
  final PocketBase _pb;
  WorldRepository(this._pb);

  Future<WorldDay?> today() async {
    try {
      // Australia-local date (UTC+8) to match the cron slug
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch + 8 * 3600 * 1000;
      final local = DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true);
      final slug = 'world-${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
      final r = await _pb.collection('HEAL_world').getFirstListItem('slug="$slug" && is_published=true');
      return WorldDay.fromJson(r.toJson());
    } catch (_) {
      return null;
    }
  }

  Future<WorldDay?> get(String id) async {
    try {
      final r = await _pb.collection('HEAL_world').getOne(id);
      return WorldDay.fromJson(r.toJson());
    } catch (_) {
      return null;
    }
  }

  Future<List<WorldDay>> recent({int limit = 30}) async {
    try {
      final records = await _pb.collection('HEAL_world').getList(
        page: 1, perPage: limit,
        filter: 'is_published=true',
        sort: '-published_at',
      );
      return records.items.map((r) => WorldDay.fromJson(r.toJson())).toList();
    } catch (_) {
      return [];
    }
  }
}

final worldRepoProvider = Provider<WorldRepository>((ref) => WorldRepository(ref.watch(pocketbaseProvider)));

final todayWorldProvider = FutureProvider<WorldDay?>((ref) async {
  return ref.watch(worldRepoProvider).today();
});

final recentWorldsProvider = FutureProvider<List<WorldDay>>((ref) async {
  return ref.watch(worldRepoProvider).recent();
});

// ── TODAY'S PICKS — light per-day determinism ───────────────────────
final todayMeditationsProvider = FutureProvider<Meditation?>((ref) async {
  final all = await ref.watch(meditationRepoProvider).list(perPage: 60);
  if (all.isEmpty) return null;
  final now = DateTime.now();
  final doy = int.parse('${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}');
  return all[doy % all.length];
});

final todayScriptureProvider = FutureProvider<Scripture?>((ref) async {
  try {
    final all = await ref.watch(scriptureRepoProvider).list(limit: 60);
    if (all.isEmpty) return null;
    final now = DateTime.now();
    final doy = int.parse('${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}');
    return all[doy % all.length];
  } catch (_) {
    return null;
  }
});

final todayPrayerProvider = FutureProvider<Prayer?>((ref) async {
  try {
    final all = await ref.watch(prayerRepoProvider).list(limit: 60);
    if (all.isEmpty) return null;
    final now = DateTime.now();
    final doy = int.parse('${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}');
    return all[doy % all.length];
  } catch (_) {
    return null;
  }
});

final praisesProvider = FutureProvider<List<PraiseSong>>((ref) async {
  try {
    return await ref.watch(praiseRepoProvider).list(limit: 100);
  } catch (_) {
    return [];
  }
});

final reflectionsProvider = FutureProvider<List<Essay>>((ref) async {
  try {
    return await ref.watch(essayRepoProvider).list(limit: 50);
  } catch (_) {
    return [];
  }
});


// ── Bible-in-a-Year ──────────────────────────────────────────────────────
class BibleRepository {
  final PocketBase _pb;
  BibleRepository(this._pb);

  Future<List<BibleReading>> listAll() async {
    try {
      final records = await _pb.collection('HEAL_bible_readings').getList(
        page: 1, perPage: 400, sort: 'day_number',
      );
      return records.items.map((r) => BibleReading.fromJson(r.toJson())).toList();
    } catch (_) {
      return <BibleReading>[];
    }
  }

  Future<BibleReading?> get(int dayNumber) async {
    try {
      final r = await _pb.collection('HEAL_bible_readings').getFirstListItem('day_number=$dayNumber');
      return BibleReading.fromJson(r.toJson());
    } catch (_) {
      return null;
    }
  }
}

class BibleProgressRepository {
  final PocketBase _pb;
  BibleProgressRepository(this._pb);

  Future<List<BibleProgress>> forUser(String userId) async {
    try {
      final records = await _pb.collection('HEAL_bible_progress').getList(
        page: 1, perPage: 400,
        filter: "user_id='$userId'",
        sort: '-completed_at',
      );
      return records.items.map((r) => BibleProgress.fromJson(r.toJson())).toList();
    } catch (_) {
      return <BibleProgress>[];
    }
  }

  Future<BibleProgress> markComplete({
    required String userId,
    required int dayNumber,
    String notes = '',
    int readingSeconds = 0,
  }) async {
    final record = await _pb.collection('HEAL_bible_progress').create(body: {
      'user_id': userId,
      'day_number': dayNumber,
      'completed_at': DateTime.now().toIso8601String(),
      'notes': notes,
      'reading_seconds': readingSeconds,
    });
    return BibleProgress.fromJson(record.toJson());
  }
}

final bibleRepoProvider = Provider<BibleRepository>((ref) => BibleRepository(ref.watch(pocketbaseProvider)));
final bibleProgressRepoProvider = Provider<BibleProgressRepository>((ref) => BibleProgressRepository(ref.watch(pocketbaseProvider)));

final allReadingsProvider = FutureProvider<List<BibleReading>>((ref) async {
  return ref.watch(bibleRepoProvider).listAll();
});

final userProgressProvider = FutureProvider.family<List<BibleProgress>, String>((ref, userId) async {
  return ref.watch(bibleProgressRepoProvider).forUser(userId);
});

class UserIdService {
  static const _key = 'heal.user_id.v1';
  String? _cached;

  Future<String> get() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null) {
      id = 'u-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';
      await prefs.setString(_key, id);
    }
    _cached = id;
    return id;
  }
}

final userIdProvider = FutureProvider<String>((ref) async => UserIdService().get());
