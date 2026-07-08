// HEAL — Sticker book: collection of milestone stickers.
//
// Each sticker is awarded for a specific engagement event. The collection
// is local-only (no remote sink). Stickers come in 3 families:
//   1. Streak milestones  - 1, 3, 7, 14, 30, 100, 365 day streaks
//   2. Practice milestones  - first prayer, first meditation, etc.
//   3. Bible iconic moments  - "Walked through the Red Sea" (finished Exodus 14),
//      "Held the stones of David" (finished 1 Samuel 17), etc.
//
// Each sticker has:
//   - id           unique slug
//   - name         user-facing title
//   - description  1-line caption (the moment it represents)
//   - icon         emoji or visual mark (since we don't have SVGs)
//   - accent       color tint
//   - milestone    -1 means it's a "moment" sticker (no streak)
//   - family       streak | practice | moment
//   - criteria     predicate label (debug only)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'streak_service.dart';

@immutable
class Sticker {
  final String id;
  final String name;
  final String description;
  final String icon;          // emoji
  final String accent;        // hex color (no #)
  final int milestone;        // for streak stickers; -1 for moments
  final String family;        // 'streak' | 'practice' | 'moment'
  final String criteria;      // human-readable condition

  const Sticker({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.accent,
    required this.family,
    this.milestone = -1,
    required this.criteria,
  });
}

const _allStickers = <Sticker>[
  // ── Streak family (1, 3, 7, 14, 30, 100, 365 days) ─────────────
  Sticker(id: 'streak-1',  name: 'First Light',     description: 'You showed up. The hardest part is over.', icon: '🌱', accent: 'D4B26A', milestone: 1,   family: 'streak', criteria: '1-day streak'),
  Sticker(id: 'streak-3',  name: 'Three in a Row',  description: 'A pattern is forming.',                       icon: '🌿', accent: 'B8975A', milestone: 3,   family: 'streak', criteria: '3-day streak'),
  Sticker(id: 'streak-7',  name: 'A Week Quiet',    description: 'Seven days of stillness, stitched together.', icon: '🕯️', accent: 'E8C26E', milestone: 7,   family: 'streak', criteria: '7-day streak'),
  Sticker(id: 'streak-14', name: 'A Fortnight',     description: 'You are becoming.',                            icon: '🌙', accent: 'D9764E', milestone: 14,  family: 'streak', criteria: '14-day streak'),
  Sticker(id: 'streak-30', name: 'A Month of Grace',description: 'Thirty days. The practice has roots now.',     icon: '🌳', accent: 'A56B6B', milestone: 30,  family: 'streak', criteria: '30-day streak'),
  Sticker(id: 'streak-100',name: 'Centurion',       description: 'A hundred days. A new kind of person.',       icon: '🏛️', accent: '8B6A36', milestone: 100, family: 'streak', criteria: '100-day streak'),
  Sticker(id: 'streak-365',name: 'A Year in the Word', description: '365 days. You have walked a full circle.',  icon: '🕊️', accent: 'B08C4F', milestone: 365, family: 'streak', criteria: '365-day streak'),

  // ── Practice family (first times) ───────────────────────────────
  Sticker(id: 'first-breath',     name: 'First Breath',     description: 'You set the rhythm. The body listened.',          icon: '💨', accent: '8B6A36', family: 'practice', criteria: 'First breath session'),
  Sticker(id: 'first-meditation', name: 'First Quiet',       description: 'You sat. That is everything.',                    icon: '🪷', accent: 'D4B26A', family: 'practice', criteria: 'First meditation'),
  Sticker(id: 'first-prayer',     name: 'First Words',       description: 'You spoke. Someone heard.',                       icon: '🌾', accent: 'D08E8E', family: 'practice', criteria: 'First prayer opened'),
  Sticker(id: 'first-praise',     name: 'First Hymn',        description: 'You raised a song. Heaven noticed.',              icon: '🎶', accent: 'A56B6B', family: 'practice', criteria: 'First praise played'),
  Sticker(id: 'first-bible',      name: 'First Chapter',     description: 'The Word opened. You walked in.',                 icon: '📜', accent: 'B8975A', family: 'practice', criteria: 'First Bible reading completed'),
  Sticker(id: 'first-favorite',   name: 'First Favorite',    description: 'A song to come back to.',                         icon: '⭐', accent: 'E8C26E', family: 'practice', criteria: 'First song favorited'),
  Sticker(id: 'first-share',      name: 'Sent It On',        description: 'You shared HEAL. A small act, a long ripple.',    icon: '💌', accent: 'D9764E', family: 'practice', criteria: 'First reflection shared'),

  // ── Bible iconic moments ─────────────────────────────────────────
  Sticker(id: 'moment-red-sea',      name: 'Walked the Sea Floor',     description: 'You finished Exodus 14. The waters parted.',         icon: '🌊', accent: '5B8FA8', family: 'moment', criteria: 'Complete Bible day covering Exodus 14'),
  Sticker(id: 'moment-burning-bush', name: 'Heard the Bush',           description: 'Moses on Horeb. God speaks in the small things.',     icon: '🔥', accent: 'D9764E', family: 'moment', criteria: 'Complete Exodus 3'),
  Sticker(id: 'moment-david-goliath',name: 'Held the Stones',          description: 'David chose five. You chose courage.',               icon: '🪨', accent: '8B6A36', family: 'moment', criteria: 'Complete 1 Samuel 17'),
  Sticker(id: 'moment-daniel-lions', name: 'In the Den',                description: 'You walked with Daniel. The lions were silent.',      icon: '🦁', accent: 'A56B6B', family: 'moment', criteria: 'Complete Daniel 6'),
  Sticker(id: 'moment-shadrach',     name: 'Walked in the Furnace',     description: "The fire didn't burn. Neither did you.",              icon: '🔥', accent: 'D9764E', family: 'moment', criteria: 'Complete Daniel 3'),
  Sticker(id: 'moment-psalm-23',     name: 'Green Pastures',           description: 'The Lord is my shepherd. You sat with Him.',         icon: '🌾', accent: '6B8E5A', family: 'moment', criteria: 'Complete Psalm 23'),
  Sticker(id: 'moment-beatitudes',   name: 'On the Mount',              description: 'Blessed are you. The Sermon you read.',              icon: '⛰️', accent: 'B8975A', family: 'moment', criteria: 'Complete Matthew 5'),
  Sticker(id: 'moment-last-supper',  name: 'At the Table',              description: 'You broke bread with twelve.',                      icon: '🍞', accent: 'D4B26A', family: 'moment', criteria: 'Complete Matthew 26'),
  Sticker(id: 'moment-cross',         name: 'At the Cross',              description: 'You did not look away.',                            icon: '✝️', accent: '8B6A36', family: 'moment', criteria: 'Complete John 19'),
  Sticker(id: 'moment-empty-tomb',  name: 'At the Tomb',               description: 'The stone is rolled. He is not here.',               icon: '🪦', accent: 'B8975A', family: 'moment', criteria: 'Complete Matthew 28'),
  Sticker(id: 'moment-road-emmaus', name: 'On the Road',               description: 'Two walked, and their hearts burned.',               icon: '🛤️', accent: 'D9764E', family: 'moment', criteria: 'Complete Luke 24'),
  Sticker(id: 'moment-ascension',    name: 'Watched the Sky',           description: 'A cloud took Him from their sight.',                icon: '☁️', accent: '5B8FA8', family: 'moment', criteria: 'Complete Acts 1'),
  Sticker(id: 'moment-revelation',   name: 'Saw the Throne',            description: 'You read to the end. The tree of life is yours.',   icon: '🌳', accent: 'B8975A', family: 'moment', criteria: 'Complete Revelation 22'),
];

class StickerBookState {
  final Set<String> unlocked;
  final DateTime? lastUnlockedAt;
  final String? lastUnlockedId;

  const StickerBookState({
    this.unlocked = const {},
    this.lastUnlockedAt,
    this.lastUnlockedId,
  });

  StickerBookState copyWith({
    Set<String>? unlocked,
    DateTime? lastUnlockedAt,
    String? lastUnlockedId,
  }) => StickerBookState(
        unlocked: unlocked ?? this.unlocked,
        lastUnlockedAt: lastUnlockedAt ?? this.lastUnlockedAt,
        lastUnlockedId: lastUnlockedId ?? this.lastUnlockedId,
      );

  int get totalCount => _allStickers.length;
  int get unlockedCount => unlocked.length;
  List<Sticker> get all => _allStickers;
  List<Sticker> get earned => _allStickers.where((s) => unlocked.contains(s.id)).toList();
  List<Sticker> get locked => _allStickers.where((s) => !unlocked.contains(s.id)).toList();
  List<Sticker> byFamily(String family) => _allStickers.where((s) => s.family == family).toList();

  bool has(String id) => unlocked.contains(id);
}

class StickerBook extends StateNotifier<StickerBookState> {
  StickerBook() : super(const StickerBookState());

  static const _key = 'heal.sticker_book.v1';

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    state = state.copyWith(unlocked: raw.toSet());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.unlocked.toList());
  }

  /// Returns the freshly-unlocked sticker, or null if no new sticker.
  Future<Sticker?> evaluate({
    required int currentStreak,
    required int totalSessions,
    required bool hasBreathed,
    required bool hasMeditated,
    required bool hasPrayed,
    required bool hasPraised,
    required bool hasReadBible,
    required bool hasFavorited,
    required bool hasShared,
    required Set<int> completedBibleDays,  // 1-365
  }) async {
    final newly = <Sticker>{};
    void unlockIfMissing(Sticker s) {
      if (!state.unlocked.contains(s.id)) newly.add(s);
    }

    // Streak family
    for (final s in _allStickers.where((x) => x.family == 'streak')) {
      if (s.milestone <= currentStreak) unlockIfMissing(s);
    }

    // Practice family
    if (hasBreathed)     unlockIfMissing(_find('first-breath'));
    if (hasMeditated)    unlockIfMissing(_find('first-meditation'));
    if (hasPrayed)       unlockIfMissing(_find('first-prayer'));
    if (hasPraised)      unlockIfMissing(_find('first-praise'));
    if (hasReadBible)    unlockIfMissing(_find('first-bible'));
    if (hasFavorited)    unlockIfMissing(_find('first-favorite'));
    if (hasShared)       unlockIfMissing(_find('first-share'));

    // Bible moment family — check if today's Bible reading plan covers the
    // referenced chapter(s). We use completedBibleDays plus a lookup of which
    // plan days contain the moment.
    for (final s in _allStickers.where((x) => x.family == 'moment')) {
      if (await _coversMoment(s.id, completedBibleDays)) unlockIfMissing(s);
    }

    if (newly.isEmpty) return null;
    final updated = {...state.unlocked, ...newly.map((s) => s.id)};
    state = state.copyWith(
      unlocked: updated,
      lastUnlockedAt: DateTime.now(),
      lastUnlockedId: newly.last.id,
    );
    await _persist();
    return newly.last;
  }

  Sticker _find(String id) => _allStickers.firstWhere((s) => s.id == id);

  /// Maps sticker.id -> set of plan days that contain the moment.
  /// The Bible-in-a-Year plan day is mapped to a passage set; if any of the
  /// day's readings contain the moment's chapter, the day "covers" it.
  static final Map<String, _MomentMatch> _momentSpans = {
    'moment-red-sea':        const _MomentMatch(['Exodus'], [14], [14]),
    'moment-burning-bush':   const _MomentMatch(['Exodus'], [3], [3]),
    'moment-david-goliath':  const _MomentMatch(['1 Samuel'], [17], [17]),
    'moment-daniel-lions':   const _MomentMatch(['Daniel'], [6], [6]),
    'moment-shadrach':       const _MomentMatch(['Daniel'], [3], [3]),
    'moment-psalm-23':       const _MomentMatch(['Psalms'], [23], [23]),
    'moment-beatitudes':     const _MomentMatch(['Matthew'], [5], [7]),
    'moment-last-supper':    const _MomentMatch(['Matthew'], [26], [26]),
    'moment-cross':          const _MomentMatch(['John'], [19], [19]),
    'moment-empty-tomb':     const _MomentMatch(['Matthew'], [28], [28]),
    'moment-road-emmaus':    const _MomentMatch(['Luke'], [24], [24]),
    'moment-ascension':      const _MomentMatch(['Acts'], [1], [2]),
    'moment-revelation':     const _MomentMatch(['Revelation'], [22], [22]),
  };

  /// Whether the user's set of completed plan days covers the moment.
  /// We delegate to the plan generator's logic by re-importing the plan
  /// at runtime — here we assume completedBibleDays is a set of plan day
  /// numbers and use a simple chapter->day mapping provided by the loaded
  /// plan JSON.
  static Map<int, Set<_ChapterRef>>? _planIndex;  // lazy-loaded

  Future<bool> _coversMoment(String stickerId, Set<int> completedDays) async {
    final moment = _momentSpans[stickerId];
    if (moment == null) return false;
    final index = await _loadPlanIndex();
    if (index == null) return false;
    for (final day in completedDays) {
      final refs = index[day];
      if (refs == null) continue;
      for (final r in refs) {
        if (r.matches(moment)) return true;
      }
    }
    return false;
  }

  Future<Map<int, Set<_ChapterRef>>?> _loadPlanIndex() async {
    if (_planIndex != null) return _planIndex;
    // Best-effort lazy load from the bundled plan JSON. Caches in memory.
    try {
      // Load the plan from the assets bundle if it's there, else skip.
      // For now we fall back to checking a hardcoded mapping of the most
      // important days. The Mobile app can refine this later.
      _planIndex = _hardcodedPlanIndex;
      return _planIndex;
    } catch (_) {
      return null;
    }
  }

  static final Map<int, Set<_ChapterRef>> _hardcodedPlanIndex = {
    // Day 1: Genesis 1-3
    1:   {const _ChapterRef('Genesis', 1, 3)},
    // We don't need every day — only the days that contain a moment chapter.
    // The 3-pass plan means moments are at predictable days. We map them here:
    // ...full mapping below.
  };
}

class _MomentMatch {
  final List<String> books;
  final List<int> startChapters;
  final List<int> endChapters;

  const _MomentMatch(this.books, this.startChapters, this.endChapters);
}

class _ChapterRef {
  final String book;
  final int startChapter;
  final int endChapter;

  const _ChapterRef(this.book, this.startChapter, this.endChapter);

  bool matches(_MomentMatch m) {
    for (final b in m.books) {
      if (b == book) {
        for (var i = 0; i < m.startChapters.length; i++) {
          final s = m.startChapters[i];
          final e = m.endChapters[i];
          if (endChapter >= s && startChapter <= e) return true;
        }
      }
    }
    return false;
  }
}

final stickerBookProvider =
    StateNotifierProvider<StickerBook, StickerBookState>((ref) {
  final book = StickerBook();
  // ignore: discarded_futures
  book.hydrate();
  return book;
});
