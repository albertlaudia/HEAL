// HEAL — Favorites service.
// Stores song IDs the user has hearted, persists to SharedPreferences.
// Cheap to use: O(1) set lookup, ~1ms persistence per write.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesState {
  final Set<String> ids;       // praise song slugs
  final bool ready;

  const FavoritesState({required this.ids, required this.ready});

  bool contains(String id) => ids.contains(id);
  int get count => ids.length;

  FavoritesState copyWith({Set<String>? ids, bool? ready}) =>
      FavoritesState(ids: ids ?? this.ids, ready: ready ?? this.ready);
}

class FavoritesService extends StateNotifier<FavoritesState> {
  static const _key = 'heal.favorites.v1';

  FavoritesService() : super(const FavoritesState(ids: {}, ready: false)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const [];
    state = FavoritesState(ids: list.toSet(), ready: true);
  }

  Future<void> toggle(String id) async {
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
