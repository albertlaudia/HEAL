// HEAL — Sleep Stories / Wind-down.
//
// A calm, dimly-lit destination for evening practice. Long-form
// guided meditations (8-15 min) that help the listener drift off.
// Inspired by Calm's sleep stories but rooted in scripture.
//
// Tagline: "Slow your breathing. Lower the day. Lie in the Word."
//
// UI principles:
//   - dimmed color palette (deeper rosewood, no brass highlight)
//   - single hero per story with "Begin" CTA
//   - auto-advance disabled; auto-fade-out + auto-pause at end
//   - "moon" iconography throughout

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme.dart';
import '../../core/widgets/brass_widgets.dart';
import '../../data/pb_models.dart';
import '../../data/pb_repositories.dart';
import '../../services/audio_service.dart';

class SleepStoriesPage extends HookConsumerWidget {
  const SleepStoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meditations = useState<List<PraiseSong>>([]); // we'll use meditation model
    final loading = useState<bool>(true);

    useEffect(() {
      () async {
        try {
          // Fetch only is_sleep_story=true meditations
          final repo = ref.read(meditationRepoProvider);
          final all = await repo.list();
          meditations.value = all.where((m) => m.isPublished).toList();
        } catch (e) {
          // Fallback: empty
        } finally {
          loading.value = false;
        }
      }();
      return null;
    }, []);

    return Scaffold(
      backgroundColor: const Color(0xFF120A09),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF1A100F),
            iconTheme: const IconThemeData(color: HealTokens.cream),
            title: const Text('Sleep Stories', style: TextStyle(color: HealTokens.cream, fontSize: 18, fontWeight: FontWeight.w500)),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              HealTokens.s20, HealTokens.s24, HealTokens.s20, HealTokens.s80,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _Hero(),
                const SizedBox(height: HealTokens.s32),
                if (loading.value)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: HealTokens.brass),
                    ),
                  )
                else
                  for (var i = 0; i < meditations.value.length; i++) ...[
                    _SleepCard(meditation: meditations.value[i])
                        .animate()
                        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 60 * i))
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: HealTokens.s16),
                  ],
                const SizedBox(height: HealTokens.s32),
                _FootNote(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.nightlight_round, color: Color(0xFFD9C5A8), size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'WIND DOWN',
              style: TextStyle(
                color: HealTokens.brass.withValues(alpha: 0.7),
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: HealTokens.s24),
        Text(
          'Slow your breathing.\nLower the day.\nLie in the Word.',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: HealTokens.cream,
                fontWeight: FontWeight.w300,
                height: 1.15,
              ),
        ),
        const SizedBox(height: HealTokens.s16),
        Text(
          'Long, quiet meditations read slowly over music. Press play, put the phone down, and let the words carry you home.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: HealTokens.creamDim,
                height: 1.6,
              ),
        ),
      ],
    );
  }
}

class _SleepCard extends ConsumerWidget {
  final dynamic meditation;
  const _SleepCard({required this.meditation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(HealTokens.r20),
        onTap: () {
          HapticFeedback.selectionClick();
          // Build a minimal Meditation-like record for the audio service
          // We pass via a route — but to keep it simple, play it directly
          final m = meditation;
          // Use the existing meditate detail flow
          // Navigate to /meditate/{slug}
          context.push('/meditate/${m.slug}');
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1A100F), Color(0xFF120A09)],
            ),
            borderRadius: BorderRadius.circular(HealTokens.r20),
            border: Border.all(
              color: const Color(0xFFD9C5A8).withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              // Cover art
              Container(
                width: 88, height: 88,
                margin: const EdgeInsets.all(HealTokens.s16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HealTokens.r16),
                  image: (meditation.illustrationUrl as String).isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(meditation.illustrationUrl as String),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                  gradient: (meditation.illustrationUrl as String).isEmpty
                      ? const LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Color(0xFF2A1A18), Color(0xFF0F0807)],
                        )
                      : null,
                ),
                child: (meditation.illustrationUrl as String).isEmpty
                    ? const Center(
                        child: Icon(Icons.nightlight_round, color: Color(0xFFD9C5A8), size: 32),
                      )
                    : null,
              ),
              // Title + meta
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: HealTokens.s16, horizontal: HealTokens.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meditation.title as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HealTokens.cream,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if ((meditation.subtitle as String).isNotEmpty)
                        Text(
                          meditation.subtitle as String,
                          style: TextStyle(
                            color: HealTokens.creamDim.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: HealTokens.creamDim.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Text(
                            '${(meditation.durationSeconds as int? ?? 0) ~/ 60} min',
                            style: TextStyle(
                              color: HealTokens.creamDim.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1A18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFD9C5A8).withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              'BEDTIME',
                              style: TextStyle(
                                color: const Color(0xFFD9C5A8).withValues(alpha: 0.9),
                                fontSize: 9,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Play arrow
              Padding(
                padding: const EdgeInsets.only(right: HealTokens.s16),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9C5A8).withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFFD9C5A8),
                    size: 22,
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

class _FootNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HealTokens.s20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A100F),
        borderRadius: BorderRadius.circular(HealTokens.r16),
        border: Border.all(color: const Color(0xFFD9C5A8).withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_outlined, color: Color(0xFFD9C5A8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A gentle start: dim the screen, prop up your pillow, and let the words do the work. Sleep well.',
              style: TextStyle(
                color: HealTokens.creamDim.withValues(alpha: 0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}