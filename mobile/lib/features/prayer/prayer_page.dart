// HEAL — Prayer library + emotion-tinted reader.
// Filter by emotion + category. Reader has warm tint based on emotion.

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

class PrayerPage extends HookConsumerWidget {
  const PrayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emotionFilter = useState<String?>(null);
    final prayersAsync = ref.watch(prayersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pray')),
      body: prayersAsync.when(
        data: (prayers) {
          return Column(
            children: [
              // Emotion filter chips
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: HealTokens.s20),
                  children: [
                    BrassPill(
                      label: 'All',
                      icon: Icons.all_inclusive_rounded,
                      selected: emotionFilter.value == null,
                      onTap: () => emotionFilter.value = null,
                    ),
                    const SizedBox(width: HealTokens.s8),
                    ...HealTokens.emotionGlow.keys.map((e) => Padding(
                          padding: const EdgeInsets.only(right: HealTokens.s8),
                          child: BrassPill(
                            label: e,
                            selected: emotionFilter.value == e,
                            onTap: () => emotionFilter.value = e,
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
                  itemCount: prayers.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: HealTokens.s12),
                  itemBuilder: (context, i) {
                    final p = prayers[i];
                    if (emotionFilter.value != null &&
                        p.emotion != emotionFilter.value) {
                      return const SizedBox.shrink();
                    }
                    return _PrayerCard(prayer: p)
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

final prayersProvider = FutureProvider<List<Prayer>>((ref) {
  return ref.read(prayerRepoProvider).list();
});

class _PrayerCard extends StatelessWidget {
  final Prayer prayer;
  const _PrayerCard({required this.prayer});

  @override
  Widget build(BuildContext context) {
    final tint = HealTokens.emotionGlow[prayer.emotion ?? 'comfort'] ??
        HealTokens.bronzeLight;
    return GlassCard(
      padding: const EdgeInsets.all(HealTokens.s20),
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/prayer/${prayer.id}');
      },
      glow: tint,
      glowIntensity: 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: HealTokens.s12,
                  vertical: HealTokens.s4,
                ),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tint.withValues(alpha: 0.4)),
                ),
                child: Text(
                  (prayer.emotion ?? 'comfort').toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tint,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const Spacer(),
              if (prayer.isEventPrayer)
                Tooltip(
                  message: prayer.sourceEvent ?? 'Daily prayer for current events',
                  child: Icon(
                    Icons.public_rounded,
                    size: 16,
                    color: tint.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: HealTokens.s12),
          Text(
            prayer.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: HealTokens.cream,
                ),
          ),
          const SizedBox(height: HealTokens.s8),
          Text(
            prayer.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HealTokens.creamDim,
                  height: 1.5,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Detail (reader) ────────────────────────────────────────────────

class PrayerDetailPage extends HookConsumerWidget {
  final String id;
  const PrayerDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayersAsync = ref.watch(prayersProvider);
    return prayersAsync.when(
      data: (prayers) {
        final prayer = prayers.firstWhere((p) => p.id == id, orElse: () => prayers.first);
        final tint = HealTokens.emotionGlow[prayer.emotion ?? 'comfort'] ??
            HealTokens.bronzeLight;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.5,
                    colors: [
                      tint.withValues(alpha: 0.16),
                      HealTokens.rosewoodDeep,
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(HealTokens.s32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: HealTokens.s32),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: HealTokens.s16,
                          vertical: HealTokens.s6,
                        ),
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: tint.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          (prayer.emotion ?? 'comfort').toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: tint,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (prayer.isEventPrayer) ...[
                        const SizedBox(height: HealTokens.s8),
                        Row(
                          children: [
                            Icon(Icons.public_rounded, color: tint, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'For: ${prayer.sourceEvent ?? 'current events'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tint,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: HealTokens.s24),
                      Text(
                        prayer.title,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: HealTokens.cream,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                      ),
                      const SizedBox(height: HealTokens.s32),
                      // Body — generous line-height for contemplative reading
                      Text(
                        prayer.body,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: HealTokens.cream,
                              fontWeight: FontWeight.w300,
                              height: 1.7,
                            ),
                      ),
                      const SizedBox(height: HealTokens.s48),
                      Center(
                        child: Container(
                          width: 64,
                          height: 1,
                          decoration: BoxDecoration(
                            color: tint.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: HealTokens.s48),
                      if (prayer.attribution != null)
                        Text(
                          '— ${prayer.attribution!}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: HealTokens.creamDim,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
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