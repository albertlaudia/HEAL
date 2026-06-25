// HEAL — Now page.
// Today's daily content: one scripture, one quote, one prayer, one breath.
// Pulled deterministically by day-of-year. Swipeable page view.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets/brass_widgets.dart';
import '../../data/pb_repositories.dart';
import '../../data/pb_models.dart';

class NowPage extends HookConsumerWidget {
  const NowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays + 1;
    final pageController = usePageController(viewportFraction: 0.92);
    final currentIndex = useState<int>(0);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HealTokens.s20,
                HealTokens.s16,
                HealTokens.s20,
                HealTokens.s8,
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [HealTokens.brassLight, HealTokens.brass],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: HealTokens.s12),
                  Text(
                    'NOW',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HealTokens.s20,
                0,
                HealTokens.s20,
                HealTokens.s16,
              ),
              child: Text(
                _todayGreeting(dayOfYear),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: HealTokens.creamDim,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
            Expanded(
              child: FutureBuilder<_DailyContent>(
                future: _loadDaily(ref, dayOfYear),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(HealTokens.brass),
                      ),
                    );
                  }
                  final daily = snap.data!;
                  return Stack(
                    children: [
                      PageView.builder(
                        controller: pageController,
                        itemCount: daily.cards.length,
                        onPageChanged: (i) => currentIndex.value = i,
                        itemBuilder: (context, i) {
                          final card = daily.cards[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: HealTokens.s8,
                              vertical: HealTokens.s8,
                            ),
                            child: _DailyCard(card: card)
                                .animate(delay: Duration(milliseconds: 60 * i))
                                .fadeIn(duration: HealTokens.d500)
                                .slideY(begin: 0.06, end: 0),
                          );
                        },
                      ),
                      // Page indicator dots
                      Positioned(
                        bottom: HealTokens.s24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SmoothPageIndicatorDots(
                            count: daily.cards.length,
                            current: currentIndex.value,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: HealTokens.s64),
          ],
        ),
      ),
    );
  }

  String _todayGreeting(int day) {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'In the quiet hours · day $day of 365';
    if (hour < 12) return 'A gentle morning · day $day of 365';
    if (hour < 17) return 'Midday rest · day $day of 365';
    if (hour < 21) return 'Evening practice · day $day of 365';
    return 'A quiet night · day $day of 365';
  }
}

class SmoothPageIndicatorDots extends StatelessWidget {
  final int count;
  final int current;

  const SmoothPageIndicatorDots({
    super.key,
    required this.count,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: HealTokens.d300,
          curve: HealTokens.easeOutQuart,
          width: isActive ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive
                ? HealTokens.brass
                : HealTokens.creamDim.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

Future<_DailyContent> _loadDaily(WidgetRef ref, int dayOfYear) async {
  // Pull today's content in parallel.
  final scripture = await ref
      .read(scriptureRepoProvider)
      .list(dayOfYear: dayOfYear, limit: 1);
  final quote = await ref
      .read(quoteRepoProvider)
      .list(dayOfYear: dayOfYear, limit: 1);
  final prayers = await ref.read(prayerRepoProvider).list(limit: 50);
  // Pick a prayer deterministically by dayOfYear.
  final prayer = prayers.isEmpty
      ? null
      : prayers[dayOfYear % prayers.length];

  final cards = <_CardData>[];
  if (scripture.isNotEmpty) {
    cards.add(_CardData(
      type: 'Scripture',
      title: scripture.first.reference,
      body: scripture.first.text,
      subtitle: scripture.first.reflectionPrompt,
      theme: scripture.first.theme,
      accent: HealTokens.brass,
      onTap: '/sit-with-verse',
      extra: scripture.first,
    ));
  }
  if (quote.isNotEmpty) {
    cards.add(_CardData(
      type: 'A Word',
      title: quote.first.text,
      body: quote.first.attribution,
      subtitle: 'Sit with this for a moment.',
      accent: HealTokens.amber,
    ));
  }
  if (prayer != null) {
    cards.add(_CardData(
      type: 'Prayer',
      title: prayer.title,
      body: prayer.body,
      subtitle: 'Read slowly.',
      accent: HealTokens.bronzeLight,
      onTap: '/prayer/${prayer.id}',
    ));
  }
  cards.add(_CardData(
    type: 'Practice',
    title: 'Three minutes of breath',
    body: 'Begin where you are. The breath is already here.',
    subtitle: 'Tap to begin a gentle breath session.',
    accent: HealTokens.amber,
    onTap: '/breathe',
  ));

  return _DailyContent(cards: cards);
}

class _DailyContent {
  final List<_CardData> cards;
  _DailyContent({required this.cards});
}

class _CardData {
  final String type;
  final String title;
  final String body;
  final String? subtitle;
  final String? theme;
  final Color accent;
  final String? onTap;
  final Object? extra;

  _CardData({
    required this.type,
    required this.title,
    required this.body,
    this.subtitle,
    this.theme,
    required this.accent,
    this.onTap,
    this.extra,
  });
}

class _DailyCard extends StatelessWidget {
  final _CardData card;
  const _DailyCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(HealTokens.s32),
      onTap: card.onTap == null
          ? null
          : () {
              context.push(card.onTap!, extra: card.extra);
            },
      glow: card.accent,
      glowIntensity: 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type pill
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: HealTokens.s12,
              vertical: HealTokens.s4,
            ),
            decoration: BoxDecoration(
              color: card.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: card.accent.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              card.type.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: card.accent,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: HealTokens.s32),
          // Body text — large contemplative serif
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: HealTokens.cream,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: HealTokens.s16),
                  if (card.subtitle != null)
                    Text(
                      card.subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: HealTokens.creamDim,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: HealTokens.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (card.theme != null)
                Text(
                  card.theme!.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: card.accent,
                        letterSpacing: 1.5,
                      ),
                ),
              if (card.onTap != null)
                Icon(
                  Icons.arrow_forward_rounded,
                  color: card.accent,
                  size: 20,
                ),
            ],
          ),
        ],
      ),
    );
  }
}