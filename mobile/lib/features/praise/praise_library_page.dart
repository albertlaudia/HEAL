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
import 'timed_lyrics.dart';

// ── Library ────────────────────────────────────────────────────────

enum _Tab { all, favorites, downloaded }

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
                    itemCount: visible.length + 1, // +1 for the header / "play all"
                    itemBuilder: (_, i) {
                      if (i == 0) {
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
                                icon: const Icon(Icons.play_circle_filled_rounded,
                                    color: HealTokens.brass, size: 18),
                                label: const Text('Play all',
                                    style: TextStyle(color: HealTokens.brass)),
                                onPressed: () => _playPlaylist(ref, visible, 0),
                              ),
                            ],
                          ),
                        );
                      }
                      final s = visible[i - 1];
                      return _PraiseTile(
                        song: s,
                        onTap: () => _openPlayer(context, ref, visible, i - 1),
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
        )).toList();
    await ref
        .read(audioServiceProvider.notifier)
        .playPlaylist(queue, index, localPaths: localPaths);
  }

  static void _openPlayer(BuildContext context, WidgetRef ref, List<PraiseSong> songs, int index) async {
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
        )).toList();
    await ref
        .read(audioServiceProvider.notifier)
        .playPlaylist(queue, index, localPaths: localPaths);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PraisePlayerPage(songs: songs, queue: queue, index: index),
    ));
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
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: HealTokens.cream),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (song.subtitle.isNotEmpty)
                        Text(song.subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: HealTokens.creamDim,
                                  fontStyle: FontStyle.italic,
                                ),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isCached)
                            const Icon(Icons.download_done_rounded, size: 14, color: HealTokens.brass),
                          if (isCached) const SizedBox(width: 4),
                          if (song.category != null && song.category!.isNotEmpty)
                            Text(song.category!,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: HealTokens.creamDim.withValues(alpha: 0.7),
                                      letterSpacing: 0.5,
                                    )),
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
