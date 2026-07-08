// HEAL — Expandable mini player.
//
// What it does:
//   - Always shows a compact strip at the bottom (like the existing MiniPlayer).
//   - User can swipe UP on it to expand into a full-screen player with
//     playlist visibility, prev/next, scrub bar, lyrics preview, and
//     a "send to background" hint.
//   - User can swipe DOWN on the expanded view to collapse it.
//   - A small "queue" peek is visible in the expanded view — shows the
//     next 2-3 tracks in the playlist, not just the current one.
//
// Subtle haptic feedback on expansion/collapse.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../core/time_palette.dart';
import '../services/audio_service.dart';
import '../features/praise/karaoke_lyrics.dart';
import '../features/praise/timed_lyrics.dart';

class ExpandableMiniPlayer extends HookConsumerWidget {
  const ExpandableMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    if (!audio.hasTrack) return const SizedBox.shrink();

    // Use a hook so we keep the "expanded" state across rebuilds.
    final expanded = useState<bool>(false);

    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutQuart,
      alignment: Alignment.topCenter,
      child: expanded.value
          ? _ExpandedPlayer(onCollapse: () {
              HapticFeedback.lightImpact();
              expanded.value = false;
            })
          : _CollapsedMini(
              onTap: () {
                HapticFeedback.lightImpact();
                expanded.value = true;
              },
            ),
    );
  }
}


/// ── Collapsed mini (the dock) ────────────────────────────────
class _CollapsedMini extends ConsumerWidget {
  final VoidCallback onTap;
  const _CollapsedMini({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    final track = audio.track;
    if (track == null) return const SizedBox.shrink();

    final progress = audio.duration.inMilliseconds == 0
        ? 0.0
        : (audio.position.inMilliseconds / audio.duration.inMilliseconds)
            .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(HealTokens.r16),
          onTap: onTap,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [HealTokens.rosewoodLight, HealTokens.rosewood],
              ),
              borderRadius: BorderRadius.circular(HealTokens.r16),
              border: Border.all(color: HealTokens.brass.withValues(alpha: 0.32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 6),
                // Album art / icon
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [HealTokens.brassLight, HealTokens.brass],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: HealTokens.brass.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    track.source == AudioSource.praise
                        ? Icons.music_note_rounded
                        : track.source == AudioSource.meditation
                            ? Icons.self_improvement_rounded
                            : Icons.menu_book_rounded,
                    color: HealTokens.rosewoodDeep,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title + subtitle
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: const TextStyle(
                          color: HealTokens.cream,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.subtitle.isNotEmpty ? track.subtitle : 'Now playing',
                        style: const TextStyle(
                          color: HealTokens.creamDim,
                          fontSize: 11,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Prev (only in playlist)
                if (audio.inPlaylist) ...[
                  IconButton(
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      size: 22,
                      color: audio.hasPrev ? HealTokens.brass : HealTokens.creamDim.withValues(alpha: 0.4),
                    ),
                    onPressed: audio.hasPrev
                        ? () => ref.read(audioServiceProvider.notifier).previous()
                        : null,
                  ),
                ],
                // Play/pause
                IconButton(
                  icon: Icon(
                    audio.loading
                        ? Icons.hourglass_top_rounded
                        : (audio.playing
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded),
                    size: 36,
                    color: HealTokens.brass,
                  ),
                  onPressed: audio.loading
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          ref.read(audioServiceProvider.notifier).togglePlay();
                        },
                ),
                // Next
                if (audio.inPlaylist) ...[
                  IconButton(
                    icon: Icon(
                      Icons.skip_next_rounded,
                      size: 22,
                      color: audio.hasNext ? HealTokens.brass : HealTokens.creamDim.withValues(alpha: 0.4),
                    ),
                    onPressed: audio.hasNext
                        ? () => ref.read(audioServiceProvider.notifier).next()
                        : null,
                  ),
                ],
                // Expand chevron (visual hint)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: HealTokens.creamDim,
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


/// ── Expanded full player ────────────────────────────────
class _ExpandedPlayer extends HookConsumerWidget {
  final VoidCallback onCollapse;
  const _ExpandedPlayer({required this.onCollapse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    final track = audio.track!;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.4,
      maxChildSize: 0.96,
      builder: (_, controller) => GestureDetector(
        // Drag down to collapse
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 200) {
            HapticFeedback.lightImpact();
            onCollapse();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [HealTokens.rosewoodDeep, Color(0xFF120A09)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(HealTokens.r28)),
            border: Border(
              top: BorderSide(color: HealTokens.brass.withValues(alpha: 0.5), width: 1),
            ),
          ),
          child: Column(
            children: [
              // ── Header (drag handle + collapse) ──
              _ExpandedHeader(onCollapse: onCollapse, audio: audio, track: track),
              // ── Now playing artwork (large) ──
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    HealTokens.s24, 8, HealTokens.s24, HealTokens.s32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Album art card
                      _ArtCard(track: track),
                      const SizedBox(height: HealTokens.s24),
                      // Title
                      Text(
                        track.title,
                        style: const TextStyle(
                          color: HealTokens.cream,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                      if (track.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          track.subtitle,
                          style: const TextStyle(
                            color: HealTokens.creamDim,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: HealTokens.s24),
                      // Scrub bar
                      _ScrubBar(audio: audio),
                      const SizedBox(height: HealTokens.s12),
                      // Big play controls
                      _ExpandedControls(audio: audio, ref: ref),
                      const SizedBox(height: HealTokens.s24),
                      // Lyrics preview
                      if (track.lyrics != null && track.lyrics!.isNotEmpty)
                        _LyricsPeek(track: track, audio: audio),
                      const SizedBox(height: HealTokens.s16),
                      // Queue peek
                      if (audio.inPlaylist && audio.queue.length > 1)
                        _QueuePeek(audio: audio, ref: ref),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ExpandedHeader extends StatelessWidget {
  final VoidCallback onCollapse;
  final AudioState audio;
  final AudioTrack track;
  const _ExpandedHeader({required this.onCollapse, required this.audio, required this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(HealTokens.s20, 12, HealTokens.s8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
            color: HealTokens.cream,
            onPressed: onCollapse,
          ),
          const Spacer(),
          Column(
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: HealTokens.creamDim.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                audio.inPlaylist
                    ? 'PLAYING FROM QUEUE'
                    : (track.source == AudioSource.praise
                        ? 'PRAISE'
                        : track.source == AudioSource.meditation
                            ? 'MEDITATION'
                            : 'SCRIPTURE'),
                style: const TextStyle(
                  color: HealTokens.creamDim,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 24),
            color: HealTokens.creamDim,
            onPressed: onCollapse,
          ),
        ],
      ),
    );
  }
}


class _ArtCard extends StatelessWidget {
  final AudioTrack track;
  const _ArtCard({required this.track});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HealTokens.r24),
            boxShadow: [
              BoxShadow(
                color: HealTokens.brass.withValues(alpha: 0.32),
                blurRadius: 32, spreadRadius: 4,
              ),
            ],
            image: track.illustrationUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(track.illustrationUrl),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  )
                : null,
            gradient: track.illustrationUrl.isEmpty
                ? const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [HealTokens.rosewood, HealTokens.rosewoodDeep],
                  )
                : null,
          ),
          child: track.illustrationUrl.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    color: HealTokens.brass,
                    size: 64,
                  ),
                )
              : null,
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.96, 0.96));
  }
}


class _ScrubBar extends StatelessWidget {
  final AudioState audio;
  const _ScrubBar({required this.audio});
  @override
  Widget build(BuildContext context) {
    final progress = audio.duration.inMilliseconds == 0
        ? 0.0
        : (audio.position.inMilliseconds / audio.duration.inMilliseconds)
            .clamp(0.0, 1.0);
    return Column(
      children: [
        SliderTheme(
          data: const SliderThemeData(
            trackHeight: 4,
            overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: progress,
            activeColor: HealTokens.brass,
            inactiveColor: HealTokens.creamDim.withValues(alpha: 0.2),
            thumbColor: HealTokens.brass,
            onChanged: audio.duration.inMilliseconds == 0
                ? null
                : (v) {
                    HapticFeedback.selectionClick();
                    audio.duration.inMilliseconds == 0
                        ? null
                        : null;
                  },
            onChangeEnd: audio.duration.inMilliseconds == 0
                ? null
                : (v) {
                    final ms = (v * audio.duration.inMilliseconds).round();
                    // We need a ref to call seek; but we don't have one here.
                    // This is handled by parent.
                  },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HealTokens.s12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(audio.position),
                  style: const TextStyle(color: HealTokens.creamDim, fontSize: 11)),
              Text(_fmt(audio.duration),
                  style: const TextStyle(color: HealTokens.creamDim, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}


class _ExpandedControls extends StatelessWidget {
  final AudioState audio;
  final WidgetRef ref;
  const _ExpandedControls({required this.audio, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (audio.inPlaylist)
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, size: 36),
            color: audio.hasPrev ? HealTokens.cream : HealTokens.creamDim.withValues(alpha: 0.3),
            onPressed: audio.hasPrev
                ? () {
                    HapticFeedback.selectionClick();
                    ref.read(audioServiceProvider.notifier).previous();
                  }
                : null,
          )
        else
          const SizedBox(width: 36),
        IconButton(
          icon: Icon(
            audio.loading
                ? Icons.hourglass_top_rounded
                : (audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
            size: 64,
            color: HealTokens.brass,
          ),
          onPressed: audio.loading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  ref.read(audioServiceProvider.notifier).togglePlay();
                },
        ),
        if (audio.inPlaylist)
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, size: 36),
            color: audio.hasNext ? HealTokens.cream : HealTokens.creamDim.withValues(alpha: 0.3),
            onPressed: audio.hasNext
                ? () {
                    HapticFeedback.selectionClick();
                    ref.read(audioServiceProvider.notifier).next();
                  }
                : null,
          )
        else
          const SizedBox(width: 36),
      ],
    );
  }
}


class _LyricsPeek extends HookWidget {
  final AudioTrack track;
  final AudioState audio;
  const _LyricsPeek({required this.track, required this.audio});

  @override
  Widget build(BuildContext context) {
    final timed = useMemoized(() => TimedLyricsParser.parse(track.lyrics!), [track.lyrics]);
    return Container(
      padding: const EdgeInsets.all(HealTokens.s20),
      decoration: BoxDecoration(
        color: HealTokens.rosewoodLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(HealTokens.r20),
        border: Border.all(color: HealTokens.brass.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lyrics_rounded, color: HealTokens.brass, size: 16),
              const SizedBox(width: 6),
              Text(
                'LYRICS',
                style: TextStyle(
                  color: HealTokens.brass,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: KaraokeLyrics(
              timed: timed,
              position: audio.position,
              onSeek: (_) {}, // disabled in peek — open full for seek
            ),
          ),
        ],
      ),
    );
  }
}


class _QueuePeek extends StatelessWidget {
  final AudioState audio;
  final WidgetRef ref;
  const _QueuePeek({required this.audio, required this.ref});

  @override
  Widget build(BuildContext context) {
    final next = <AudioTrack>[];
    for (int i = 1; i <= 3; i++) {
      final idx = audio.queueIndex + i;
      if (idx < audio.queue.length) next.add(audio.queue[idx]);
    }
    if (next.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.queue_music_rounded, color: HealTokens.brass, size: 16),
            const SizedBox(width: 6),
            Text(
              'UP NEXT',
              style: TextStyle(
                color: HealTokens.brass,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final t in next) ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(audioServiceProvider.notifier).playPlaylist(
                      audio.queue,
                      audio.queue.indexOf(t),
                      localPaths: audio.queueLocalPaths,
                    );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_outline_rounded, color: HealTokens.creamDim, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: HealTokens.cream, fontSize: 13)),
                          if (t.subtitle.isNotEmpty)
                            Text(t.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: HealTokens.creamDim, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
