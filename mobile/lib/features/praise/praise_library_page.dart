// HEAL — Praise library + immersive detail page.
// Features:
//   - Top tabs: All / Favorites / Downloaded
//   - Heart + download icons on each card
//   - Tap a song → immersive player with karaoke-style lyrics
//   - Tap "Play all" on a tab → plays the queue, auto-advances
//   - Auto-resolves local file path for offline-cached songs

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
import 'karaoke_lyrics.dart';
import 'song_script_page.dart';
import 'timed_lyrics.dart';

// ── Library ────────────────────────────────────────────────────────

enum _Tab { all, opened, favorites, downloaded }

class PraiseLibraryPage extends HookConsumerWidget {
  const PraiseLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(praisesProvider);
    final favorites  = ref.watch(favoritesServiceProvider);
    final cache      = ref.watch(offlineCacheProvider);
    final filter     = useState<String?>(null);
    final tab        = useState<_Tab>(_Tab.all);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Praise'),
      ),
      body: songsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 1.2)),
        error: (e, _) => const Center(
          child: Text('Could not load.', style: TextStyle(color: HealTokens.creamDim)),
        ),
        data: (songs) {
          // Build category filter from songs
          final categories = <String>{for (final s in songs) s.category ?? ''}
              .where((c) => c.isNotEmpty)
              .toList()
            ..sort();

          // Apply tab + category filter
          var visible = songs;
          switch (tab.value) {
            case _Tab.favorites:
              visible = visible.where((s) => favorites.contains(s.slug)).toList();
              break;
            case _Tab.opened:
              // Auto-populated: any song the user has ever opened
              // is added to favorites, so this == favorites
              // but it's surfaced as "Your list" to make the
              // automatic action feel intentional.
              visible = visible.where((s) => favorites.contains(s.slug)).toList();
              break;
            case _Tab.downloaded:
              visible = visible.where((s) => cache.isCached(s.slug)).toList();
              break;
            case _Tab.all:
              break;
          }
          if (filter.value != null) {
            visible = visible.where((s) => s.category == filter.value).toList();
          }

          return Column(
            children: [
              // Tab bar
              _PraiseTabs(
                current: tab.value,
                onChange: (t) => tab.value = t,
                favoritesCount: favorites.count,
                downloadedCount: cache.cachedSlugs.length,
              ),
              // Category filter (only in All)
              if (tab.value == _Tab.all)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: HealTokens.s20),
                    children: [
                      BrassPill(
                        label: 'All',
                        selected: filter.value == null,
                        onTap: () => filter.value = null,
                      ),
                      ...categories.map((c) => Padding(
                            padding: const EdgeInsets.only(left: HealTokens.s8),
                            child: BrassPill(
                              label: c,
                              selected: filter.value == c,
                              onTap: () => filter.value = c,
                            ),
                          )),
                    ],
                  ),
                ),
              // Empty state
              if (visible.isEmpty)
                Expanded(child: _PraiseEmpty(tab: tab.value)),
              // List
              if (visible.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      HealTokens.s20,
                      HealTokens.s12,
                      HealTokens.s20,
                      HealTokens.s80,
                    ),
                    itemCount: visible.length + 3, // +3 for today's-praise + divider + 'Library' header
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        // "Today's praise" — deterministic pick by day-of-year.
                        // Reduces paradox of choice on a 112-song library.
                        // Only show on the All tab.
                        if (tab.value != _Tab.all && tab.value != _Tab.opened) {
                          return const SizedBox.shrink();
                        }
                        final today = _praiseOfTheDay(songs, favorites);
                        if (today == null) return const SizedBox.shrink();
                        return _TodaysPraiseHero(song: today, onTap: () {
          HapticFeedback.selectionClick();
          _openScript(context, song: today);
        });
                      }
                      if (i == 1) {
                        // Section divider — "MORE PRAISE"
                        return Padding(
                          padding: const EdgeInsets.only(top: HealTokens.s24, bottom: HealTokens.s12),
                          child: Row(
                            children: [
                              Text(
                                'MORE PRAISE',
                                style: TextStyle(
                                  color: HealTokens.creamDim.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: HealTokens.s12),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: HealTokens.creamDim.withValues(alpha: 0.18),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      if (i == 2) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: HealTokens.s12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${visible.length} song${visible.length == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: HealTokens.creamDim,
                                    ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.menu_book_rounded,
                                    color: HealTokens.brass, size: 18),
                                label: const Text('Read all',
                                    style: TextStyle(color: HealTokens.brass)),
                                onPressed: () => _openScript(context, song: visible[0]),
                              ),
                            ],
                          ),
                        );
                      }
                      final s = visible[i - 1];
                      return _PraiseTile(
                        song: s,
                        onTap: () => _openScript(context, song: visible[i - 1]),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Play a list of songs as a queue. Resolves local file paths for any
  /// that are downloaded so they play offline.
  static Future<void> _playPlaylist(WidgetRef ref, List<PraiseSong> songs, int index) async {
    final cache = ref.read(offlineCacheProvider.notifier);
    final localPaths = <String>[];
    for (final s in songs) {
      final p = await cache.localPath(s.slug);
      localPaths.add(p ?? '');
    }
    final queue = songs.map((s) => AudioTrack(
          id: s.id,
          url: s.cdnAudio,
          title: s.title,
          subtitle: s.subtitle,
          illustrationUrl: s.cdnIllustration,
          lyrics: s.lyrics,
          source: AudioSource.praise,
          kind: 'praise',
          durationSeconds: 0, // filled by audio_service if available
        )).toList();
    await ref
        .read(audioServiceProvider.notifier)
        .playPlaylist(queue, index, localPaths: localPaths);
  }

  /// Open a song's "script" view (lyrics-first, no audio).
  /// Auto-favorites and auto-caches on first open.
  /// Replaces the old _openPlayer since the hymn audio was removed.
  static void _openScript(BuildContext context, {required PraiseSong song}) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SongScriptPage(song: song),
    ));
  }

  static void _openPlayer(BuildContext context, WidgetRef ref, List<PraiseSong> songs, int index) async {
    // Legacy method - kept for backward compat with KaraokeLyrics widget.
    final cache = ref.read(offlineCacheProvider.notifier);
    final localPaths = <String>[];
    for (final s in songs) {
      final p = await cache.localPath(s.slug);
      localPaths.add(p ?? '');
    }
    final queue = songs.map((s) => AudioTrack(
          id: s.id,
          url: s.cdnAudio,
          title: s.title,
          subtitle: s.subtitle,
          illustrationUrl: s.cdnIllustration,
          lyrics: s.lyrics,
          source: AudioSource.praise,
          kind: 'praise',
          durationSeconds: 0, // filled by audio_service if available
        )).toList();
    await ref
        .read(audioServiceProvider.notifier)
        .playPlaylist(queue, index, localPaths: localPaths);
    if (!context.mounted) return;
    // Praise audio was removed (REMOVE_PRAISE_AUDIO_PLAN.md 2026-07-17).
    // This method now just navigates to the lyrics view for the first song.
    _openScript(context, song: songs[index]);
  }
}

// ── Tabs ───────────────────────────────────────────────────────────

class _PraiseTabs extends StatelessWidget {
  final _Tab current;
  final void Function(_Tab) onChange;
  final int favoritesCount;
  final int downloadedCount;
  const _PraiseTabs({
    required this.current,
    required this.onChange,
    required this.favoritesCount,
    required this.downloadedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HealTokens.s20, HealTokens.s12, HealTokens.s20, HealTokens.s8,
      ),
      child: Row(
        children: [
          _TabButton(label: 'All',          count: null,          active: current == _Tab.all,          onTap: () => onChange(_Tab.all)),
          const SizedBox(width: HealTokens.s8),
          _TabButton(label: 'Your list',    count: favoritesCount, active: current == _Tab.opened,       onTap: () => onChange(_Tab.opened)),
          _TabButton(label: 'Favorites',    count: favoritesCount, active: current == _Tab.favorites,    onTap: () => onChange(_Tab.favorites)),
          const SizedBox(width: HealTokens.s8),
          _TabButton(label: 'Downloaded',   count: downloadedCount, active: current == _Tab.downloaded, onTap: () => onChange(_Tab.downloaded)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int? count;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.count, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: HealTokens.s16, vertical: HealTokens.s8),
        decoration: BoxDecoration(
          color: active ? HealTokens.brass.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? HealTokens.brass : HealTokens.creamDim.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: active ? HealTokens.brass : HealTokens.creamDim,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: HealTokens.brass,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────

class _PraiseEmpty extends StatelessWidget {
  final _Tab tab;
  const _PraiseEmpty({required this.tab});

  @override
  Widget build(BuildContext context) {
    String title; String body; IconData icon;
    switch (tab) {
      case _Tab.opened:
        title = 'Your list is empty';
        body = 'Songs you open will appear here automatically — no need to bookmark anything.';
        icon = Icons.auto_awesome_rounded;
        break;
      case _Tab.favorites:
        title = 'No favorites yet';
        body = 'Tap the heart on any song to add it here.';
        icon = Icons.favorite_border_rounded;
        break;
      case _Tab.downloaded:
        title = 'No downloads yet';
        body = 'Tap the download icon to save a song for offline listening.';
        icon = Icons.cloud_download_outlined;
        break;
      case _Tab.all:
        title = 'No songs in this category';
        body = 'Try a different category above.';
        icon = Icons.music_off_outlined;
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HealTokens.s40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: HealTokens.creamDim),
            const SizedBox(height: HealTokens.s16),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: HealTokens.cream)),
            const SizedBox(height: HealTokens.s8),
            Text(body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HealTokens.creamDim)),
          ],
        ),
      ),
    );
  }
}

// ── Tile ───────────────────────────────────────────────────────────

class _PraiseTile extends ConsumerWidget {
  final PraiseSong song;
  final VoidCallback onTap;
  const _PraiseTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesServiceProvider);
    final cache     = ref.watch(offlineCacheProvider);
    final isFav = favorites.contains(song.slug);
    final isCached = cache.isCached(song.slug);
    final isDownloading = cache.isDownloading(song.slug);

    return Padding(
      padding: const EdgeInsets.only(bottom: HealTokens.s12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(HealTokens.r16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(HealTokens.s12),
            decoration: BoxDecoration(
              color: HealTokens.rosewoodLight,
              borderRadius: BorderRadius.circular(HealTokens.r16),
              border: Border.all(color: HealTokens.brass.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(HealTokens.r12),
                  child: Container(
                    width: 56, height: 56,
                    color: HealTokens.rosewood,
                    child: CachedNetworkImage(
                      imageUrl: song.cdnIllustration,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Icon(Icons.music_note_rounded, color: HealTokens.brass),
                      errorWidget: (_, __, ___) => const Icon(Icons.music_note_rounded, color: HealTokens.brass),
                    ),
                  ),
                ),
                const SizedBox(width: HealTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: HealTokens.cream,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (song.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(song.subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: HealTokens.creamDim,
                                  fontStyle: FontStyle.italic,
                                ),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      // Lyrics preview (2 lines)
                      if (song.lyrics.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _lyricsPreview(song.lyrics),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: HealTokens.creamDim.withValues(alpha: 0.7),
                                fontSize: 11,
                                height: 1.3,
                              ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (isCached) ...[
                            const Icon(Icons.download_done_rounded, size: 12, color: HealTokens.brass),
                            const SizedBox(width: 4),
                          ],
                          if (song.category != null && song.category!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: HealTokens.brass.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                song.category!,
                                style: const TextStyle(
                                  color: HealTokens.brass,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          if (song.tempoBpm != null && song.tempoBpm! > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${song.tempoBpm} bpm',
                              style: const TextStyle(
                                color: HealTokens.creamDim,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _HeartButton(isFav: isFav, slug: song.slug),
                const SizedBox(width: 4),
                _DownloadButton(
                  slug: song.slug,
                  url: song.cdnAudio,
                  isCached: isCached,
                  isDownloading: isDownloading,
                  progress: cache.progressFor(song.slug),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Heart ──────────────────────────────────────────────────────────

class _HeartButton extends ConsumerWidget {
  final bool isFav;
  final String slug;
  const _HeartButton({required this.isFav, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFav ? HealTokens.brass : HealTokens.creamDim,
        size: 20,
      ),
      onPressed: () {
        HapticFeedback.selectionClick();
        ref.read(favoritesServiceProvider.notifier).toggle(slug);
      },
      tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
    );
  }
}

// ── Download ───────────────────────────────────────────────────────

class _DownloadButton extends ConsumerWidget {
  final String slug;
  final String url;
  final bool isCached;
  final bool isDownloading;
  final CacheDownloadProgress? progress;
  const _DownloadButton({
    required this.slug,
    required this.url,
    required this.isCached,
    required this.isDownloading,
    required this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isDownloading) {
      return SizedBox(
        width: 36, height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                value: progress?.progress,
                strokeWidth: 2.0,
                color: HealTokens.brass,
                backgroundColor: HealTokens.creamDim.withValues(alpha: 0.16),
              ),
            ),
            const Icon(Icons.close_rounded, size: 12, color: HealTokens.creamDim),
          ],
        ),
      );
    }
    return IconButton(
      icon: Icon(
        isCached ? Icons.download_done_rounded : Icons.download_for_offline_outlined,
        color: isCached ? HealTokens.brass : HealTokens.creamDim,
        size: 22,
      ),
      onPressed: () async {
        if (isCached) {
          // Already cached — tap to remove
          await ref.read(offlineCacheProvider.notifier).remove(slug);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Removed from offline storage'), duration: Duration(seconds: 2)),
            );
          }
          return;
        }
        HapticFeedback.lightImpact();
        final ok = await ref.read(offlineCacheProvider.notifier).download(slug, url);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok ? 'Saved for offline listening' : 'Download failed'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      tooltip: isCached ? 'Remove download' : 'Download for offline',
    );
  }
}

// ── Immersive Player ───────────────────────────────────────────────

class PraisePlayerPage extends HookConsumerWidget {
  final List<PraiseSong> songs;
  final List<AudioTrack> queue;
  final int index;
  const PraisePlayerPage({
    super.key,
    required this.songs,
    required this.queue,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    final palette = ref.watch(timePaletteProvider);

    // The "current" song/audio might differ from `index` if the user manually
    // changed tracks. Prefer the audio state's current track id; fall back to index.
    final currentIdx = audio.inPlaylist && audio.queueIndex >= 0
        ? audio.queueIndex
        : index;
    final song = songs[currentIdx];
    final track = queue[currentIdx];
    final isThisTrack = audio.track?.id == track.id;

    final pos = audio.position;
    final dur = audio.duration;

    // Build timed lyrics once
    final timed = useMemoized(
      () => TimedLyricsParser.parse(song.lyrics),
      [song.lyrics],
    );

    return Scaffold(
      backgroundColor: HealTokens.rosewoodDeep,
      body: Stack(
        children: [
          // Background art (blurred)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: song.cdnIllustration,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: HealTokens.rosewoodDeep),
              errorWidget: (_, __, ___) => Container(color: HealTokens.rosewoodDeep),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HealTokens.rosewoodDeep.withValues(alpha: 0.6),
                  HealTokens.rosewoodDeep.withValues(alpha: 0.4),
                  HealTokens.rosewoodDeep.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    HealTokens.s12, HealTokens.s8, HealTokens.s12, 0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                        color: HealTokens.cream,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'NOW PLAYING',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: HealTokens.brassLight,
                                    letterSpacing: 2.0,
                                  ),
                            ),
                            Text(
                              '${currentIdx + 1} of ${songs.length}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: HealTokens.creamDim,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _HeartButton(isFav: ref.watch(favoritesServiceProvider).contains(song.slug), slug: song.slug),
                      _DownloadButton(
                        slug: song.slug,
                        url: song.cdnAudio,
                        isCached: ref.watch(offlineCacheProvider).isCached(song.slug),
                        isDownloading: ref.watch(offlineCacheProvider).isDownloading(song.slug),
                        progress: ref.watch(offlineCacheProvider).progressFor(song.slug),
                      ),
                    ],
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    HealTokens.s24, HealTokens.s16, HealTokens.s24, HealTokens.s8,
                  ),
                  child: Column(
                    children: [
                      Text(
                        song.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: HealTokens.cream,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      if (song.subtitle.isNotEmpty)
                        Text(
                          song.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: HealTokens.creamDim,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      // Music metadata chips
                      if (song.keySignature.isNotEmpty || song.tempoBpm != null) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (song.keySignature.isNotEmpty)
                              _MusicChip(icon: Icons.music_note_rounded, label: song.keySignature),
                            if (song.tempoBpm != null && song.tempoBpm! > 0)
                              _MusicChip(icon: Icons.speed_rounded, label: '${song.tempoBpm} bpm'),
                            if (song.meter.isNotEmpty)
                              _MusicChip(icon: Icons.straighten_rounded, label: song.meter),
                            if (song.mood != null && song.mood!.isNotEmpty)
                              _MusicChip(icon: Icons.face_retouching_natural_rounded, label: song.mood!),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Reflection on the song (the writer's note)
                if (song.reflection.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      HealTokens.s24, 0, HealTokens.s24, HealTokens.s16,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(HealTokens.s16),
                      decoration: BoxDecoration(
                        color: HealTokens.rosewoodLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(HealTokens.r16),
                        border: Border.all(
                          color: HealTokens.brass.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: HealTokens.brass.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: HealTokens.brass,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REFLECTION',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: HealTokens.brass,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song.reflection,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: HealTokens.cream,
                                        fontStyle: FontStyle.italic,
                                        height: 1.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Scripture refs (small chips below reflection)
                if (song.scriptureRefs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      HealTokens.s24, 0, HealTokens.s24, HealTokens.s16,
                    ),
                    child: Wrap(
                      spacing: 6, runSpacing: 6,
                      children: [
                        for (final ref in song.scriptureRefs)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: HealTokens.rosewood,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: HealTokens.brass.withValues(alpha: 0.16)),
                            ),
                            child: Text(
                              ref,
                              style: const TextStyle(
                                color: HealTokens.cream,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Karaoke lyrics
                Expanded(
                  child: KaraokeLyrics(
                    timed: timed,
                    position: pos,
                    onSeek: (s) {
                      ref.read(audioServiceProvider.notifier)
                          .seek(Duration(milliseconds: (s * 1000).round()));
                    },
                  ),
                ),

                // Progress
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    HealTokens.s24, 0, HealTokens.s24, HealTokens.s8,
                  ),
                  child: _ProgressBar(pos: pos, dur: dur),
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    HealTokens.s24, HealTokens.s8, HealTokens.s24, HealTokens.s32,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 30,
                        color: audio.hasPrev ? HealTokens.cream : HealTokens.creamDim.withValues(alpha: 0.3),
                        onPressed: audio.hasPrev
                            ? () => ref.read(audioServiceProvider.notifier).prev()
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded),
                        iconSize: 30,
                        color: HealTokens.cream,
                        onPressed: isThisTrack
                            ? () => ref.read(audioServiceProvider.notifier).skipBack(const Duration(seconds: 10))
                            : null,
                      ),
                      _PlayPauseButton(
                        playing: audio.playing,
                        loading: audio.loading,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          if (isThisTrack) {
                            ref.read(audioServiceProvider.notifier).togglePlay();
                          } else {
                            // Re-issue play with the right track (e.g. tapped after seek)
                            // Use the audio state's queueLocalPaths (resolved at queue build time)
                            final localPaths = ref.read(audioServiceProvider).queueLocalPaths;
                            ref
                                .read(audioServiceProvider.notifier)
                                .playPlaylist(queue, currentIdx, localPaths: localPaths);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10_rounded),
                        iconSize: 30,
                        color: HealTokens.cream,
                        onPressed: isThisTrack
                            ? () => ref.read(audioServiceProvider.notifier).skipForward(const Duration(seconds: 10))
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 30,
                        color: audio.hasNext ? HealTokens.cream : HealTokens.creamDim.withValues(alpha: 0.3),
                        onPressed: audio.hasNext
                            ? () => ref.read(audioServiceProvider.notifier).next()
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool playing;
  final bool loading;
  final VoidCallback onTap;
  const _PlayPauseButton({required this.playing, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [HealTokens.brassLight, HealTokens.brass, HealTokens.brassDeep],
          ),
          shape: BoxShape.circle,
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2.5, color: HealTokens.rosewoodDeep),
              )
            : Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: HealTokens.rosewoodDeep,
                size: 36,
              ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Duration pos;
  final Duration dur;
  const _ProgressBar({required this.pos, required this.dur});

  @override
  Widget build(BuildContext context) {
    final progress = dur.inMilliseconds == 0
        ? 0.0
        : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
    return Row(
      children: [
        Text(_fmt(pos),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HealTokens.creamDim)),
        const SizedBox(width: HealTokens.s8),
        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: HealTokens.creamDim.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [HealTokens.brassLight, HealTokens.brass],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: HealTokens.s8),
        Text(_fmt(dur),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HealTokens.creamDim)),
      ],
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}


/// Extract a 2-line preview from raw lyrics text.
String _lyricsPreview(String lyrics) {
  final lines = lyrics.split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('['))
      .take(2);
  return lines.join('  ·  ');
}


class _MusicChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MusicChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: HealTokens.rosewood,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HealTokens.brass.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: HealTokens.brass, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: HealTokens.cream,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


/// ── Today's Praise (deterministic daily pick) ───────────────────
/// Stable per day across devices — same song for everyone on the same day.
/// Skips songs the user has favorited in favor of discovery rotation.
PraiseSong? _praiseOfTheDay(List<PraiseSong> all, FavoritesState favorites) {
  if (all.isEmpty) return null;
  // Day-of-year — Jan 1 = 0, Dec 31 = 364
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  // Prefer songs the user has NOT favorited yet (drive discovery),
  // but always bias by recent listens so favorites aren't starved.
  final unfavorited = all.where((s) => !favorites.contains(s.slug)).toList();
  final pool = unfavorited.isNotEmpty ? unfavorited : all;
  return pool[dayOfYear % pool.length];
}


/// Big-tile hero showing today's praise. Tap to play.
class _TodaysPraiseHero extends StatelessWidget {
  final PraiseSong song;
  final VoidCallback onTap;
  const _TodaysPraiseHero({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: HealTokens.s12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HealTokens.r20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [HealTokens.rosewood, HealTokens.rosewoodDeep],
        ),
        border: Border.all(color: HealTokens.brass.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: HealTokens.brass.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(HealTokens.r20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(HealTokens.s20),
            child: Row(
              children: [
                // Illustration thumb
                ClipRRect(
                  borderRadius: BorderRadius.circular(HealTokens.r12),
                  child: SizedBox(
                    width: 72, height: 72,
                    child: song.cdnIllustration.isEmpty
                        ? Container(color: HealTokens.rosewoodDeep)
                        : CachedNetworkImage(
                            imageUrl: song.cdnIllustration,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Container(color: HealTokens.rosewoodDeep),
                          ),
                  ),
                ),
                const SizedBox(width: HealTokens.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 12, color: HealTokens.brass,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "TODAY'S PRAISE",
                            style: TextStyle(
                              color: HealTokens.brass,
                              fontSize: 10,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HealTokens.cream,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.subtitle.isNotEmpty ? song.subtitle : song.category ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: HealTokens.creamDim.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: HealTokens.brass,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: HealTokens.brass.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: HealTokens.oxblood,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
