// HEAL — Bible progress cache.
//
// Why this exists:
//   Track-completion side effects (lib/main.dart audio.onTrackComplete)
//   used to hit PocketBase /HEAL_bible_progress on every play. A user
//   skipping through a praise playlist would fire 20+ network calls in
//   seconds. This cache:
//     - Fetches lazily on first read of the session
//     - Caches in-memory until invalidate() is called
//     - Has a 5-minute TTL as belt-and-suspenders
//     - Is invalidated by bibleProgressRepoProvider.markComplete() (TODO:
//       wiremarkComplete through this notifier, not the raw repo)
//
// Usage:
//   final progress = await ref.read(bibleProgressCacheProvider(userId).future);
//   // local mutation:
//   ref.read(bibleProgressCacheProvider(userId).notifier).addLocal(day);
//   // force refetch:
//   ref.invalidate(bibleProgressCacheProvider(userId));

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pb_models.dart';
import 'pb_repositories.dart';

class BibleProgressCacheState {
  final List<BibleProgress> progress;
  final DateTime fetchedAt;
  const BibleProgressCacheState({
    this.progress = const [],
    required this.fetchedAt,
  });

  Set<int> get completedDayNumbers =>
      progress.map((p) => p.dayNumber).toSet();
  bool get isStale =>
      DateTime.now().difference(fetchedAt) > const Duration(minutes: 5);
}

class BibleProgressCacheNotifier extends StateNotifier<BibleProgressCacheState> {
  final Ref ref;
  final String userId;
  bool _inflight = false;

  BibleProgressCacheNotifier(this.ref, this.userId)
      : super(BibleProgressCacheState(
          progress: const [],
          fetchedAt: DateTime.fromMillisecondsSinceEpoch(0),
        ));

  /// Trigger an initial fetch if cache is empty or stale.
  /// Returns the in-memory list (refetching only when needed).
  Future<List<BibleProgress>> ensure() async {
    if (state.isStale && !_inflight) {
      await refresh();
    }
    return state.progress;
  }

  /// Force a refetch from the network.
  Future<List<BibleProgress>> refresh() async {
    if (_inflight) return state.progress;
    _inflight = true;
    try {
      final repo = ref.read(bibleProgressRepoProvider);
      final list = await repo.forUser(userId);
      state = BibleProgressCacheState(
        progress: list,
        fetchedAt: DateTime.now(),
      );
      return list;
    } finally {
      _inflight = false;
    }
  }

  /// Optimistic local insert (used by mark-complete flow before refetch).
  void addLocal(BibleProgress p) {
    if (state.progress.any((e) => e.dayNumber == p.dayNumber)) return;
    state = BibleProgressCacheState(
      progress: [p, ...state.progress],
      fetchedAt: DateTime.now(),
    );
  }

  /// Wipe the cache (used by Reset HEAL).
  void clear() {
    state = BibleProgressCacheState(
      progress: const [],
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

final bibleProgressCacheProvider = StateNotifierProvider.family<
    BibleProgressCacheNotifier, BibleProgressCacheState, String>(
  (ref, userId) => BibleProgressCacheNotifier(ref, userId),
);

/// Debouncer — debounce sticker evaluation across rapid track completions.
/// A user skipping through 10 praise songs shouldn't trigger 10 sticker
/// evaluations + 10 sticker chimes. Coalesce to one eval at 2 seconds idle.
class StickerEvaluationDebouncer {
  final int debounceMs;
  DateTime? _lastRunAt;
  bool _inflight = false;

  StickerEvaluationDebouncer({this.debounceMs = 2000});

  /// Returns true if the caller should run an evaluation now.
  /// Catches up to one deferred execution per debounceMs window.
  bool tick() {
    final now = DateTime.now();
    final last = _lastRunAt;
    if (_inflight) return false;
    if (last == null || now.difference(last) >= Duration(milliseconds: debounceMs)) {
      _lastRunAt = now;
      return true;
    }
    return false;
  }

  void markInflight(bool v) => _inflight = v;
}

final stickerEvalDebouncerProvider = Provider<StickerEvaluationDebouncer>(
  (_) => StickerEvaluationDebouncer(),
);
