// HEAL — Meditate list + detail.
// Pulls HEAL_meditations from PB. List shows cards; detail has full audio player.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets/brass_widgets.dart';
import '../../data/pb_repositories.dart';
import '../../data/pb_models.dart';
import '../../services/audio_service.dart';

class MeditateListPage extends HookConsumerWidget {
  const MeditateListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meditationsAsync = ref.watch(meditationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditate'),
      ),
      body: meditationsAsync.when(
        data: (meditations) {
          if (meditations.isEmpty) {
            return const Center(
              child: Text('No meditations yet.'),
            );
          }
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(HealTokens.s20),
            itemCount: meditations.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: HealTokens.s12),
            itemBuilder: (context, i) {
              final m = meditations[i];
              return _MeditationCard(meditation: m)
                  .animate(delay: Duration(milliseconds: 60 * i))
                  .fadeIn(duration: HealTokens.d400)
                  .slideY(begin: 0.04, end: 0);
            },
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

final meditationsProvider = FutureProvider<List<Meditation>>((ref) {
  return ref.read(meditationRepoProvider).list();
});

class _MeditationCard extends StatelessWidget {
  final Meditation meditation;
  const _MeditationCard({required this.meditation});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/meditate/${meditation.id}');
      },
      child: Row(
        children: [
          // Illustration
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(HealTokens.r20),
            ),
            child: CachedNetworkImage(
              imageUrl: meditation.cdnIllustration,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: HealTokens.rosewoodLight,
                child: const Icon(Icons.spa_outlined, color: HealTokens.brass),
              ),
              errorWidget: (_, __, ___) => Container(
                color: HealTokens.rosewoodLight,
                child: const Icon(Icons.spa_outlined, color: HealTokens.brass),
              ),
            ),
          ),
          // Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(HealTokens.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    meditation.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HealTokens.cream,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meditation.subtitle.isNotEmpty
                        ? meditation.subtitle
                        : '${(meditation.durationSeconds / 60).round()} min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HealTokens.creamDim,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Play icon
          Padding(
            padding: const EdgeInsets.only(right: HealTokens.s16),
            child: Icon(
              Icons.play_circle_filled_rounded,
              color: HealTokens.brass.withValues(alpha: 0.8),
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail page ───────────────────────────────────────────────────

class MeditateDetailPage extends HookConsumerWidget {
  final String id;
  const MeditateDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);

    return FutureBuilder<Meditation?>(
      future: ref.read(meditationRepoProvider).get(id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final m = snap.data!;
        final isThisTrack = audio.track?.id == m.id;
        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 320,
                backgroundColor: HealTokens.rosewoodDeep,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: m.cdnIllustration,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: HealTokens.rosewoodLight),
                        errorWidget: (_, __, ___) => Container(
                          color: HealTokens.rosewoodLight,
                          child: const Icon(Icons.spa_outlined, color: HealTokens.brass, size: 64),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              HealTokens.rosewoodDeep.withValues(alpha: 0.4),
                              HealTokens.rosewoodDeep,
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(HealTokens.s24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: HealTokens.cream,
                            ),
                      ),
                      const SizedBox(height: HealTokens.s8),
                      if (m.subtitle.isNotEmpty)
                        Text(
                          m.subtitle,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: HealTokens.creamDim,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      const SizedBox(height: HealTokens.s24),
                      if (m.body.isNotEmpty)
                        Text(
                          m.body,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: HealTokens.cream,
                                height: 1.7,
                              ),
                        ),
                      const SizedBox(height: HealTokens.s32),
                      _PlayerControls(
                        meditation: m,
                        audio: audio,
                        isThisTrack: isThisTrack,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerControls extends ConsumerWidget {
  final Meditation meditation;
  final AudioState audio;
  final bool isThisTrack;

  const _PlayerControls({
    required this.meditation,
    required this.audio,
    required this.isThisTrack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(audioServiceProvider.notifier);
    final pos = isThisTrack ? audio.position : Duration.zero;
    final dur = isThisTrack ? audio.duration : Duration.zero;
    final playing = isThisTrack && audio.playing;

    return Container(
      padding: const EdgeInsets.all(HealTokens.s20),
      decoration: BoxDecoration(
        color: HealTokens.rosewoodLight,
        borderRadius: BorderRadius.circular(HealTokens.r20),
        border: Border.all(
          color: HealTokens.brass.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          // Progress bar with seek
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: dur.inMilliseconds == 0
                  ? 0
                  : pos.inMilliseconds / dur.inMilliseconds,
              onChanged: dur.inMilliseconds == 0
                  ? null
                  : (v) {
                      service.seek(Duration(milliseconds: (v * dur.inMilliseconds).round()));
                    },
            ),
          ),
          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: HealTokens.s8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(pos), style: Theme.of(context).textTheme.bodySmall),
                Text(_fmt(dur), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: HealTokens.s16),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded),
                iconSize: 32,
                onPressed: isThisTrack
                    ? () => service.skipBack(const Duration(seconds: 10))
                    : null,
              ),
              const SizedBox(width: HealTokens.s16),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (isThisTrack) {
                    service.togglePlay();
                  } else {
                    service.play(AudioTrack(
                      id: meditation.id,
                      url: meditation.cdnAudio,
                      title: meditation.title,
                      subtitle: meditation.subtitle,
                      illustrationUrl: meditation.cdnIllustration,
                      source: AudioSource.meditation,
                    ));
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [HealTokens.brassLight, HealTokens.brass, HealTokens.brassDeep],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: HealTokens.brass.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(
                    playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 36,
                    color: HealTokens.rosewoodDeep,
                  ),
                ),
              ),
              const SizedBox(width: HealTokens.s16),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded),
                iconSize: 32,
                onPressed: isThisTrack
                    ? () => service.skipForward(const Duration(seconds: 10))
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}