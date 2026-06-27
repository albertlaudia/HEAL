// HEAL — Praise library + immersive detail page.
// Full-screen player with lyrics that highlight in time with audio.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets/brass_widgets.dart';
import '../../data/pb_repositories.dart';
import '../../data/pb_models.dart';
import '../../services/audio_service.dart';

// ── Library ────────────────────────────────────────────────────────

class PraiseLibraryPage extends HookConsumerWidget {
  const PraiseLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(praiseProvider);
    final filter = useState<String?>(null);
    final tags = useState<Set<String>>({'All', 'Adoration', 'Gratitude', 'Hope', 'Comfort', 'Celebration'});

    return Scaffold(
      appBar: AppBar(title: const Text('Praise')),
      body: songsAsync.when(
        data: (songs) {
          // Build category filter from songs
          final categories = <String>{for (final s in songs) s.category ?? ''}
              .where((c) => c.isNotEmpty)
              .toList()
            ..sort();

          return Column(
            children: [
              // Category filter
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
                    const SizedBox(width: HealTokens.s8),
                    ...categories.map((c) => Padding(
                          padding: const EdgeInsets.only(right: HealTokens.s8),
                          child: BrassPill(
                            label: c,
                            selected: filter.value == c,
                            onTap: () => filter.value = c,
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: HealTokens.s8),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(HealTokens.s20),
                  itemCount: songs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: HealTokens.s12),
                  itemBuilder: (context, i) {
                    final s = songs[i];
                    if (filter.value != null && s.category != filter.value) {
                      return const SizedBox.shrink();
                    }
                    return _SongCard(song: s)
                        .animate(delay: Duration(milliseconds: 50 * i))
                        .fadeIn(duration: HealTokens.d400)
                        .slideY(begin: 0.04, end: 0);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(HealTokens.brass),
          ),
        ),
        error: (e, _) => Center(child: Text('Could not load: $e')),
      ),
    );
  }
}

final praiseProvider = FutureProvider<List<PraiseSong>>((ref) {
  return ref.read(praiseRepoProvider).list();
});

class _SongCard extends StatelessWidget {
  final PraiseSong song;
  const _SongCard({required this.song});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(HealTokens.s12),
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/praise/${song.id}');
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(HealTokens.r12),
            child: CachedNetworkImage(
              imageUrl: song.cdnIllustration,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: HealTokens.rosewoodLight,
                child: const Icon(Icons.music_note_outlined,
                    color: HealTokens.brass),
              ),
              errorWidget: (_, __, ___) => Container(
                color: HealTokens.rosewoodLight,
                child: const Icon(Icons.music_note_outlined,
                    color: HealTokens.brass),
              ),
            ),
          ),
          const SizedBox(width: HealTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HealTokens.cream,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  song.subtitle.isNotEmpty
                      ? song.subtitle
                      : (song.category ?? 'Praise'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HealTokens.creamDim,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.play_circle_fill_rounded,
            color: HealTokens.brass.withValues(alpha: 0.8),
            size: 32,
          ),
        ],
      ),
    );
  }
}

// ── Detail (full-screen immersive player) ──────────────────────────

class PraiseDetailPage extends HookConsumerWidget {
  final String id;
  const PraiseDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    final songsAsync = ref.watch(praiseProvider);

    return songsAsync.when(
      data: (songs) {
        final song = songs.firstWhere((s) => s.id == id, orElse: () => songs.first);
        final isThisTrack = audio.track?.id == song.id;
        final pos = isThisTrack ? audio.position : Duration.zero;
        final dur = isThisTrack ? audio.duration : Duration.zero;
        final playing = isThisTrack && audio.playing;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: () {},
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Background art
              CachedNetworkImage(
                imageUrl: song.cdnIllustration,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: HealTokens.rosewoodDeep),
                errorWidget: (_, __, ___) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        HealTokens.rosewood,
                        HealTokens.rosewoodDeep,
                      ],
                    ),
                  ),
                ),
              ),
              // Gradient overlay
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
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(HealTokens.s24),
                  child: Column(
                    children: [
                      const Spacer(),
                      // Title block
                      Text(
                        song.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: HealTokens.brassLight,
                              letterSpacing: 3,
                            ),
                      ),
                      const SizedBox(height: HealTokens.s12),
                      if (song.subtitle.isNotEmpty)
                        Text(
                          song.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: HealTokens.creamDim,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      const SizedBox(height: HealTokens.s32),
                      // Lyrics
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            song.lyrics,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: HealTokens.cream,
                                  height: 1.5,
                                  fontWeight: FontWeight.w300,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: HealTokens.s24),
                      // Progress bar
                      _ProgressBar(pos: pos, dur: dur),
                      const SizedBox(height: HealTokens.s16),
                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded),
                            iconSize: 32,
                            onPressed: isThisTrack
                                ? () => ref
                                    .read(audioServiceProvider.notifier)
                                    .skipBack(const Duration(seconds: 10))
                                : null,
                          ),
                          const SizedBox(width: HealTokens.s24),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              final service =
                                  ref.read(audioServiceProvider.notifier);
                              if (isThisTrack) {
                                service.togglePlay();
                              } else {
                                service.play(AudioTrack(
                                  id: song.id,
                                  url: song.cdnAudio,
                                  title: song.title,
                                  subtitle: song.subtitle,
                                  illustrationUrl: song.cdnIllustration,
                                  source: AudioSource.praise,
                                ));
                              }
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    HealTokens.brassLight,
                                    HealTokens.brass,
                                    HealTokens.brassDeep
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: HealTokens.brass
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 40,
                                color: HealTokens.rosewoodDeep,
                              ),
                            ),
                          ),
                          const SizedBox(width: HealTokens.s24),
                          IconButton(
                            icon: const Icon(Icons.forward_10_rounded),
                            iconSize: 32,
                            onPressed: isThisTrack
                                ? () => ref
                                    .read(audioServiceProvider.notifier)
                                    .skipForward(const Duration(seconds: 10))
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: HealTokens.s32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Could not load: $e')),
      ),
    );
  }
}

class _ProgressBar extends ConsumerWidget {
  final Duration pos;
  final Duration dur;

  const _ProgressBar({required this.pos, required this.dur});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 3),
          child: Slider(
            value: dur.inMilliseconds == 0
                ? 0
                : pos.inMilliseconds / dur.inMilliseconds,
            onChanged: dur.inMilliseconds == 0
                ? null
                : (v) {
                    ref
                        .read(audioServiceProvider.notifier)
                        .seek(Duration(milliseconds: (v * dur.inMilliseconds).round()));
                  },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HealTokens.s8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(pos),
                  style: Theme.of(context).textTheme.bodySmall),
              Text(_fmt(dur),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}