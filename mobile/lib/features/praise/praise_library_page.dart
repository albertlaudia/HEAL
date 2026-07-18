// HEAL — Praise library (redesigned 2026-07-18).
//
// User-friendly navigation:
//   1. Sticky search bar in the app bar
//   2. Hero "Today's Praise" card with full-bleed illustration
//   3. Mood/season chips (morning / evening / anxious / grateful / alone)
//      — these are the moments when people actually want a song
//   4. Category visual grid (large, tappable, illustrated)
//   5. Recently sung horizontal carousel
//   6. Three main tabs: All / Favorites / Saved
//   7. Songs list: illustrated cards with scripture refs + reflection snippet
//
// The previous version was a flat list with 4 small tabs and category
// pills. This version leads with the *moments* (mood + season) before
// the *content* (categories) — and shows just one featured song first
// to reduce the paradox of choice.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/time_palette.dart';
import '../../core/widgets/brass_widgets.dart';
import '../../data/pb_repositories.dart';
import '../../data/pb_models.dart';
import '../../services/audio_service.dart';
import '../../services/favorites_service.dart';
import '../../services/offline_cache_service.dart';
import '../../services/activity_tracker.dart';
import 'song_script_page.dart';

// ── Library ────────────────────────────────────────────────────────

enum _Tab { all, favorites, saved }

enum _Moment {
  morning('Morning', 'For the first moment of the day', Icons.wb_twilight_rounded, ['morning', 'waking']),
  evening('Evening', 'For the end of the day', Icons.nights_stay_rounded, ['evening', 'come-home']),
  anxious('Anxious', 'For the worried mind', Icons.spa_rounded, ['anxiety', 'anxious-but-hoping', 'in-between']),
  grateful('Grateful', 'For the small mercies', Icons.eco_rounded, ['gratitude', 'small-things']),
  alone('Alone', 'For the unseen hours', Icons.cabin_rounded, ['invisible', 'lonely', 'unseen']),
  weary('Weary', 'For the long road', Icons.hourglass_bottom_rounded, ['weary-but-faithful', 'weary', 'perseverance']),
  grieved('Grieving', 'For the empty chair', Icons.local_fire_department_rounded, ['grieving', 'grief', 'lament']),
  celebrating('Celebrating', 'For the good news', Icons.celebration_rounded, ['joyful', 'open-hearted', 'celebration']);

  final String label;
  final String subtitle;
  final IconData icon;
  final List<String> matchedEmotions;
  const _Moment(this.label, this.subtitle, this.icon, this.matchedEmotions);
}

class PraiseLibraryPage extends HookConsumerWidget {
  const PraiseLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(praisesProvider);
    final favorites  = ref.watch(favoritesServiceProvider);
    final cache      = ref.watch(offlineCacheProvider);
    final tab        = useState<_Tab>(_Tab.all);
    final search     = useState<String>('');
    final searchCtrl = useTextEditingController();
    final activeMoment = useState<_Moment?>(null);

    return Scaffold(
      body: songsAsync.when(
        loading: () => const _LoadingState(),
        error: (e, _) => const _ErrorState(),
        data: (songs) {
          // Apply tab + moment + search filter
          var visible = songs;
          switch (tab.value) {
            case _Tab.favorites:
              visible = visible.where((s) => favorites.contains('praise', s.slug)).toList();
              break;
            case _Tab.saved:
              visible = visible.where((s) => cache.isCached(s.slug)).toList();
              break;
            case _Tab.all:
              break;
          }
          if (activeMoment.value != null) {
            final m = activeMoment.value!;
            visible = visible.where((s) =>
              s.emotion != null && m.matchedEmotions.contains(s.emotion)
            ).toList();
          }
          if (search.value.trim().isNotEmpty) {
            final q = search.value.toLowerCase().trim();
            visible = visible.where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.subtitle.toLowerCase().contains(q) ||
              s.lyrics.toLowerCase().contains(q) ||
              s.reflection.toLowerCase().contains(q) ||
              (s.category?.toLowerCase().contains(q) ?? false)
            ).toList();
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Sticky header: app bar + search + tabs ───
              SliverToBoxAdapter(
                child: _Header(
                  tab: tab.value,
                  onTabChange: (t) {
                    HapticFeedback.selectionClick();
                    tab.value = t;
                  },
                  favoritesCount: favorites.count,
                  savedCount: cache.cachedSlugs.length,
                  searchCtrl: searchCtrl,
                  onSearchChanged: (s) => search.value = s,
                  onClearSearch: () {
                    searchCtrl.clear();
                    search.value = '';
                  },
                ),
              ),
              // ── "Today's Praise" hero ─────────────────
              if (tab.value == _Tab.all && activeMoment.value == null && search.value.isEmpty)
                SliverToBoxAdapter(
                  child: _TodaysPraiseHero(
                    songs: songs,
                    onTap: (song) {
                      HapticFeedback.mediumImpact();
                      _openScript(context, song: song);
                    },
                  ),
                ),
              // ── Mood/season chips ─────────────────────
              if (tab.value == _Tab.all)
                SliverToBoxAdapter(
                  child: _MomentsRow(
                    active: activeMoment.value,
                    onTap: (m) {
                      HapticFeedback.selectionClick();
                      if (activeMoment.value == m) {
                        activeMoment.value = null;
                      } else {
                        activeMoment.value = m;
                      }
                    },
                  ),
                ),
              // ── Active filter chip + count ────────────
              if (activeMoment.value != null || search.value.isNotEmpty)
                SliverToBoxAdapter(
                  child: _FilterIndicator(
                    count: visible.length,
                    onClear: () {
                      activeMoment.value = null;
                      searchCtrl.clear();
                      search.value = '';
                    },
                  ),
                ),
              // ── Recently sung carousel ────────────────
              if (tab.value == _Tab.all && activeMoment.value == null && search.value.isEmpty)
                SliverToBoxAdapter(
                  child: _RecentlySungCarousel(
                    songs: songs,
                    favorites: favorites,
                    onTap: (song) {
                      HapticFeedback.selectionClick();
                      _openScript(context, song: song);
                    },
                  ),
                ),
              // ── Section header for the main list ──────
              SliverToBoxAdapter(
                child: _ListHeader(
                  tab: tab.value,
                  moment: activeMoment.value,
                  count: visible.length,
                ),
              ),
              // ── Main grid/list of songs ────────────────
              if (visible.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyState(tab: tab.value, hasFilters: activeMoment.value != null || search.value.isNotEmpty),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    HealTokens.s20, HealTokens.s8, HealTokens.s20, HealTokens.s80,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: HealTokens.s12),
                        child: _SongCard(
                          song: visible[i],
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _openScript(context, song: visible[i]);
                          },
                        ),
                      ),
                      childCount: visible.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Open a song's "script" view (lyrics-first, no audio).
  /// Auto-favorites and auto-caches on first open.
  static void _openScript(BuildContext context, {required PraiseSong song}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SongScriptPage(song: song),
    ));
  }
}

// ── Header (app bar + search + tabs) ──────────────────────────────
class _Header extends StatelessWidget {
  const _Header({
    required this.tab,
    required this.onTabChange,
    required this.favoritesCount,
    required this.savedCount,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onClearSearch,
  });
  final _Tab tab;
  final ValueChanged<_Tab> onTabChange;
  final int favoritesCount;
  final int savedCount;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HealTokens.rosewood,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            HealTokens.s20, HealTokens.s8, HealTokens.s20, HealTokens.s12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Praise',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: HealTokens.cream,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: HealTokens.brass),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      FocusScope.of(context).requestFocus(FocusNode());
                    },
                    tooltip: 'Search',
                  ),
                ],
              ),
              const SizedBox(height: HealTokens.s8),
              // Search bar
              _SearchField(
                controller: searchCtrl,
                onChanged: onSearchChanged,
                onClear: onClearSearch,
              ),
              const SizedBox(height: HealTokens.s12),
              // Tabs
              _TabBar(
                current: tab,
                onChange: onTabChange,
                favoritesCount: favoritesCount,
                savedCount: savedCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged, required this.onClear});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: HealTokens.oxblood.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(HealTokens.r12),
        border: Border.all(color: HealTokens.brass.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: HealTokens.s12),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: HealTokens.creamDim, size: 18),
          const SizedBox(width: HealTokens.s8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: HealTokens.cream, fontSize: 15),
              cursorColor: HealTokens.brass,
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Search by title, lyric, or scripture…',
                hintStyle: TextStyle(
                  color: HealTokens.creamDim.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded, color: HealTokens.creamDim, size: 18),
            ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.current,
    required this.onChange,
    required this.favoritesCount,
    required this.savedCount,
  });
  final _Tab current;
  final ValueChanged<_Tab> onChange;
  final int favoritesCount;
  final int savedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: HealTokens.oxblood.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(HealTokens.r16),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'All',
            count: null,
            active: current == _Tab.all,
            onTap: () => onChange(_Tab.all),
          ),
          _TabItem(
            label: 'Favorites',
            count: favoritesCount,
            active: current == _Tab.favorites,
            onTap: () => onChange(_Tab.favorites),
          ),
          _TabItem(
            label: 'Saved',
            count: savedCount,
            active: current == _Tab.saved,
            onTap: () => onChange(_Tab.saved),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });
  final String label;
  final int? count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? HealTokens.brass : Colors.transparent,
            borderRadius: BorderRadius.circular(HealTokens.r12),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: active ? HealTokens.oxblood : HealTokens.cream,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                if (count != null && count! > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: active
                          ? HealTokens.oxblood.withValues(alpha: 0.15)
                          : HealTokens.creamDim.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: active ? HealTokens.oxblood : HealTokens.creamDim,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mood/season chips row ────────────────────────────────────────
class _MomentsRow extends StatelessWidget {
  const _MomentsRow({required this.active, required this.onTap});
  final _Moment? active;
  final ValueChanged<_Moment?> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(HealTokens.s20, HealTokens.s16, HealTokens.s20, HealTokens.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: HealTokens.s12),
            child: Text(
              'What moment are you in?',
              style: TextStyle(
                color: HealTokens.cream,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                for (final m in _Moment.values) ...[
                  _MomentCard(
                    moment: m,
                    active: active == m,
                    onTap: () => onTap(m),
                  ),
                  const SizedBox(width: HealTokens.s8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.moment,
    required this.active,
    required this.onTap,
  });
  final _Moment moment;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? HealTokens.brass
              : HealTokens.oxblood.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(HealTokens.r16),
          border: Border.all(
            color: active
                ? HealTokens.brass
                : HealTokens.brass.withValues(alpha: 0.15),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              moment.icon,
              color: active ? HealTokens.oxblood : HealTokens.brass,
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              moment.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? HealTokens.oxblood : HealTokens.cream,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter indicator (active moment + count) ─────────────────────
class _FilterIndicator extends StatelessWidget {
  const _FilterIndicator({required this.count, required this.onClear});
  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(HealTokens.s20, HealTokens.s12, HealTokens.s20, 0),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'song' : 'songs'}',
            style: const TextStyle(
              color: HealTokens.creamDim,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, color: HealTokens.brass, size: 16),
            label: const Text('Clear filter', style: TextStyle(color: HealTokens.brass)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ── "Today's Praise" hero card ─────────────────────────────────────
class _TodaysPraiseHero extends StatelessWidget {
  const _TodaysPraiseHero({required this.songs, required this.onTap});
  final List<PraiseSong> songs;
  final ValueChanged<PraiseSong> onTap;

  @override
  Widget build(BuildContext context) {
    final today = _praiseOfTheDay(songs);
    if (today == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(HealTokens.s20, HealTokens.s8, HealTokens.s20, HealTokens.s16),
      child: GestureDetector(
        onTap: () => onTap(today),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HealTokens.r24),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: today.cdnIllustration,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: HealTokens.oxblood,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [HealTokens.rosewood, HealTokens.oxblood],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.music_note_rounded, color: HealTokens.brass, size: 48),
                    ),
                  ),
                ),
                // Gradient overlay for text legibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        HealTokens.oxblood.withValues(alpha: 0.95),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(HealTokens.s20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: HealTokens.brass,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "TODAY'S PRAISE",
                          style: TextStyle(
                            color: HealTokens.oxblood,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: HealTokens.s8),
                      Text(
                        today.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HealTokens.cream,
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (today.subtitle.isNotEmpty)
                        Text(
                          today.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HealTokens.creamDim,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0),
    );
  }
}

class _RecentlySungCarousel extends StatelessWidget {
  const _RecentlySungCarousel({
    required this.songs,
    required this.favorites,
    required this.onTap,
  });
  final List<PraiseSong> songs;
  final FavoritesState favorites;
  final ValueChanged<PraiseSong> onTap;

  @override
  Widget build(BuildContext context) {
    // Show the user's most-recently-favorited songs (the ones they've
    // actually opened) — this is the "warm" subset.
    final recent = songs
        .where((s) => favorites.contains('praise', s.slug))
        .take(8)
        .toList();
    if (recent.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(HealTokens.s20, HealTokens.s16, HealTokens.s20, HealTokens.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: HealTokens.s12),
            child: Row(
              children: [
                const Text(
                  'Your songs',
                  style: TextStyle(
                    color: HealTokens.cream,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${recent.length}',
                  style: const TextStyle(
                    color: HealTokens.creamDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: HealTokens.s12),
              itemBuilder: (_, i) => _RecentSongCard(
                song: recent[i],
                onTap: () => onTap(recent[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSongCard extends StatelessWidget {
  const _RecentSongCard({required this.song, required this.onTap});
  final PraiseSong song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HealTokens.r16),
          color: HealTokens.oxblood,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HealTokens.r16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: song.cdnIllustration,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: HealTokens.oxblood),
                errorWidget: (_, __, ___) => Container(
                  color: HealTokens.rosewood,
                  child: const Icon(Icons.music_note_rounded, color: HealTokens.brass),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      HealTokens.oxblood.withValues(alpha: 0.92),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      song.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HealTokens.cream,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.tab, required this.moment, required this.count});
  final _Tab tab;
  final _Moment? moment;
  final int count;

  @override
  Widget build(BuildContext context) {
    String title;
    switch (tab) {
      case _Tab.favorites: title = 'Favorites'; break;
      case _Tab.saved:     title = 'Saved for offline'; break;
      case _Tab.all:       title = moment != null ? moment!.label : 'All praise'; break;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(HealTokens.s20, HealTokens.s20, HealTokens.s20, HealTokens.s12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: HealTokens.cream,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          if (tab == _Tab.all && moment == null)
            Text(
              '$count',
              style: const TextStyle(
                color: HealTokens.creamDim,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Song card (the main list item) ────────────────────────────────
class _SongCard extends ConsumerWidget {
  const _SongCard({required this.song, required this.onTap});
  final PraiseSong song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesServiceProvider);
    final cached = ref.watch(offlineCacheProvider);
    final isFav = favs.contains('praise', song.slug);
    final isCached = cached.isCached(song.slug);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: HealTokens.oxblood.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(HealTokens.r16),
          border: Border.all(
            color: HealTokens.brass.withValues(alpha: 0.10),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(HealTokens.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Illustration
              ClipRRect(
                borderRadius: BorderRadius.circular(HealTokens.r12),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: CachedNetworkImage(
                    imageUrl: song.cdnIllustration,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: HealTokens.rosewood),
                    errorWidget: (_, __, ___) => Container(
                      color: HealTokens.rosewood,
                      child: const Icon(Icons.music_note_rounded, color: HealTokens.brass),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: HealTokens.s12),
              // Title + meta + reflection snippet
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: HealTokens.cream,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isFav)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.favorite_rounded, color: HealTokens.brass, size: 14),
                          ),
                        if (isCached)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.download_done_rounded, color: HealTokens.creamDim, size: 14),
                          ),
                      ],
                    ),
                    if (song.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        song.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HealTokens.creamDim,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (song.reflection.isNotEmpty)
                      Text(
                        _reflectionSnippet(song.reflection),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: HealTokens.creamDim.withValues(alpha: 0.8),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Meta: category + key signature + scripture
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (song.category != null && song.category!.isNotEmpty)
                          _MetaChip(label: _capitalize(song.category!)),
                        if (song.scriptureRefs.isNotEmpty)
                          _MetaChip(
                            label: song.scriptureRefs.first,
                            color: HealTokens.ember,
                          ),
                        if (song.keySignature.isNotEmpty)
                          _MetaChip(
                            label: 'Key ${song.keySignature}',
                            color: HealTokens.creamDim.withValues(alpha: 0.5),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _reflectionSnippet(String s) {
    // First sentence or first 90 chars
    final first = s.split(RegExp(r'(?<=[.!?])\s+')).first;
    return first.length <= 110 ? first : '${first.substring(0, 110)}…';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? HealTokens.brass;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tab, required this.hasFilters});
  final _Tab tab;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = switch (tab) {
      _Tab.favorites => (
        Icons.favorite_border_rounded,
        'No favorites yet',
        'Tap the heart on any song and it lands here.',
      ),
      _Tab.saved => (
        Icons.download_outlined,
        'Nothing saved for offline',
        'Download a song and it stays with you, even off the grid.',
      ),
      _Tab.all when hasFilters => (
        Icons.tune_rounded,
        'Nothing here',
        'Try a different moment, or clear the filter to see everything.',
      ),
      _Tab.all => (
        Icons.music_note_outlined,
        'No songs',
        'Check back soon — we are adding more.',
      ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(HealTokens.s32, HealTokens.s40, HealTokens.s32, HealTokens.s40),
      child: Column(
        children: [
          Icon(icon, size: 56, color: HealTokens.creamDim),
          const SizedBox(height: HealTokens.s16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HealTokens.cream,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: HealTokens.s8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HealTokens.creamDim,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading / error ───────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 1.2, color: HealTokens.brass),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(HealTokens.s32),
      child: Center(
        child: Text(
          'Could not load praise songs.',
          style: TextStyle(color: HealTokens.creamDim),
        ),
      ),
    );
  }
}

// ── Deterministic "today's praise" pick ──────────────────────────
PraiseSong? _praiseOfTheDay(List<PraiseSong> songs) {
  if (songs.isEmpty) return null;
  final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
  // 1. Prefer a song that has a day_of_year matching today
  for (final s in songs) {
    if (s.dayOfYear == dayOfYear) return s;
  }
  // 2. Fall back to a deterministic pick
  return songs[dayOfYear % songs.length];
}
