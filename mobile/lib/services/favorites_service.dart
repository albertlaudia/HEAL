// HEAL — Favorites service (extended).
//
// Stores content IDs the user has hearted, across ALL content types:
//   - praise song slugs ('praise:slug')
//   - meditation slugs ('meditation:slug')
//   - prayer slugs ('prayer:slug')
//   - scripture slugs ('scripture:slug')
//   - essay slugs ('essay:slug')
//   - world slugs ('world:slug')
//
// We prefix the IDs with the kind so a meditation and a praise can have
// the same slug ("amen") without colliding.
//
// Cheap to use: O(1) set lookup, ~1ms persistence per write.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesState {
  final Set<String> ids;
  final bool ready;

  const FavoritesState({required this.ids, required this.ready});

  bool contains(String kind, String slug) => ids.contains(_key(kind, slug));
  bool containsAny(String id) => ids.contains(id);

  int get count => ids.length;

  /// All favorites of a given kind.
  Set<String> ofKind(String kind) =>
      ids.where((id) => id.startsWith('$kind:')).map((id) => id.substring(kind.length + 1)).toSet();

  FavoritesState copyWith({Set<String>? ids, bool? ready}) =>
      FavoritesState(ids: ids ?? this.ids, ready: ready ?? this.ids.isNotEmpty || (ready ?? this.ready));
}

class FavoritesService extends StateNotifier<FavoritesState> {
  static const _key = 'heal.favorites.v2';

  FavoritesService() : super(const FavoritesState(ids: {}, ready: false)) {
    _load();
  }

  static String _key(String kind, String slug) => '$kind:$slug';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const [];
    state = FavoritesState(ids: list.toSet(), ready: true);
  }

  Future<void> toggle(String kind, String slug) async {
    final id = _key(kind, slug);
    final next = Set<String>.from(state.ids);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(ids: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  Future<void> add(String kind, String slug) async {
    final id = _key(kind, slug);
    if (state.ids.contains(id)) return;
    final next = Set<String>.from(state.ids)..add(id);
    state = state.copyWith(ids: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  Future<void> remove(String kind, String slug) async {
    final id = _key(kind, slug);
    if (!state.ids.contains(id)) return;
    final next = Set<String>.from(state.ids)..remove(id);
    state = state.copyWith(ids: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  Future<void> clear() async {
    state = const FavoritesState(ids: {}, ready: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final favoritesServiceProvider =
    StateNotifierProvider<FavoritesService, FavoritesState>(
  (ref) => FavoritesService(),
);
