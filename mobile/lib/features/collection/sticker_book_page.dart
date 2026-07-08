// HEAL — Sticker book page.
//
// Displays the user's earned + locked stickers in 3 sections:
//   1. Streak milestones  (1, 3, 7, 14, 30, 100, 365 day)
//   2. First-times       (first breath, first meditation, etc.)
//   3. Bible iconic moments (Red Sea, David, Daniel, Empty Tomb, etc.)
//
// Each sticker shows:
//   - icon (emoji)
//   - name + description
//   - "Locked" overlay if not yet earned
//   - "New!" badge if earned in the last 24h
//
// Tapping a sticker plays a small chime + haptic.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme.dart';
import '../../services/sticker_book.dart';
import '../../services/sound_service.dart';

class StickerBookPage extends HookConsumerWidget {
  const StickerBookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(stickerBookProvider);
    final earned = book.earned;
    final total = book.totalCount;
    final pct = (earned.length / total * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticker Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              // Re-evaluate using current data sources. Stub: just hydrate.
              HapticFeedback.lightImpact();
              await ref.read(stickerBookProvider.notifier).hydrate();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          HealTokens.s20, HealTokens.s16, HealTokens.s20, HealTokens.s80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Progress hero ──
            _ProgressHero(earned: earned.length, total: total, pct: pct)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: HealTokens.s12),

                // ── Next milestones (anticipatory motivation) ──
                if (earned.length < book.totalCount)
                  _NextMilestones(book: book)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms)
                      .slideY(begin: 0.05, end: 0),

                const SizedBox(height: HealTokens.s24),

                // ── Streak family ──
            _SectionHeader(label: 'Streaks', count: book.byFamily('streak').length),
            const SizedBox(height: HealTokens.s12),
            _StickerGrid(stickers: book.byFamily('streak'), book: book),
            const SizedBox(height: HealTokens.s24),

            // ── Practice family ──
            _SectionHeader(label: 'First Times', count: book.byFamily('practice').length),
            const SizedBox(height: HealTokens.s12),
            _StickerGrid(stickers: book.byFamily('practice'), book: book),
            const SizedBox(height: HealTokens.s24),

            // ── Bible moments family ──
            _SectionHeader(label: 'Bible Iconic Moments', count: book.byFamily('moment').length),
            const SizedBox(height: HealTokens.s12),
            _StickerGrid(stickers: book.byFamily('moment'), book: book),
            const SizedBox(height: HealTokens.s24),

            // ── Motivational footer ──
            _MotivationalFooter(earned: earned.length, total: total),
          ],
        ),
      ),
    );
  }
}


/// ── Progress hero ───────────────────────────────────────────────
class _ProgressHero extends StatelessWidget {
  final int earned;
  final int total;
  final int pct;
  const _ProgressHero({required this.earned, required this.total, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HealTokens.s24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [HealTokens.rosewood, HealTokens.rosewoodDeep],
        ),
        borderRadius: BorderRadius.circular(HealTokens.r20),
        border: Border.all(color: HealTokens.brass.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.collections_bookmark_rounded,
                  color: HealTokens.brassLight, size: 22),
              const SizedBox(width: 8),
              Text(
                'YOUR COLLECTION',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: HealTokens.brassLight,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: HealTokens.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$earned',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: HealTokens.cream,
                      fontWeight: FontWeight.w300,
                      height: 1,
                    ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'of $total stickers',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HealTokens.creamDim),
                ),
              ),
            ],
          ),
          const SizedBox(height: HealTokens.s12),
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: HealTokens.rosewoodDeep.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: earned / (total == 0 ? 1 : total),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [HealTokens.brassLight, HealTokens.brass],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$pct% of the journey walked',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HealTokens.creamDim),
          ),
        ],
      ),
    );
  }
}


/// ── Section header ──────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 2.5,
                color: HealTokens.brass,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          '· $count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: HealTokens.creamDim,
              ),
        ),
      ],
    );
  }
}


/// ── Sticker grid ────────────────────────────────────────────────
class _StickerGrid extends ConsumerWidget {
  final List<Sticker> stickers;
  final StickerBookState book;
  const _StickerGrid({required this.stickers, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: HealTokens.s12,
        mainAxisSpacing: HealTokens.s12,
        childAspectRatio: 0.85,
      ),
      itemCount: stickers.length,
      itemBuilder: (_, i) {
        final s = stickers[i];
        final isEarned = book.has(s.id);
        final isNew = isEarned && book.lastUnlockedId == s.id;
        return _StickerCard(
          sticker: s,
          isEarned: isEarned,
          isNew: isNew,
          onTap: isEarned ? () => _onEarnedTap(context, ref, s) : null,
        );
      },
    );
  }

  void _onEarnedTap(BuildContext context, WidgetRef ref, Sticker s) {
    HapticFeedback.mediumImpact();
    // Play appropriate chime
    final sound = s.family == 'moment'
        ? SoundKind.stickerBible
        : s.family == 'streak'
            ? SoundKind.stickerStreak
            : SoundKind.stickerPractice;
    ref.read(soundServiceProvider).play(sound);
    showModalBottomSheet(
      context: context,
      backgroundColor: HealTokens.rosewoodDeep,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HealTokens.r24)),
      ),
      builder: (_) => _StickerDetailSheet(sticker: s),
    );
  }
}


/// ── Sticker card ───────────────────────────────────────────────
class _StickerCard extends StatelessWidget {
  final Sticker sticker;
  final bool isEarned;
  final bool isNew;
  final VoidCallback? onTap;
  const _StickerCard({
    required this.sticker,
    required this.isEarned,
    required this.isNew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Color(int.parse('FF${sticker.accent}', radix: 16));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(HealTokens.r16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(HealTokens.s12),
          decoration: BoxDecoration(
            color: isEarned ? HealTokens.rosewoodLight : HealTokens.rosewood,
            borderRadius: BorderRadius.circular(HealTokens.r16),
            border: Border.all(
              color: isNew
                  ? accent
                  : (isEarned
                      ? accent.withValues(alpha: 0.32)
                      : HealTokens.creamDim.withValues(alpha: 0.08)),
              width: isNew ? 2 : 1,
            ),
            boxShadow: isNew
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon — large emoji
              Center(
                child: Opacity(
                  opacity: isEarned ? 1.0 : 0.3,
                  child: Text(
                    sticker.icon,
                    style: const TextStyle(fontSize: 40, height: 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Name
              Text(
                sticker.name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isEarned ? HealTokens.cream : HealTokens.creamDim,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Description
              Expanded(
                child: Text(
                  sticker.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isEarned ? HealTokens.creamDim : HealTokens.creamDim.withValues(alpha: 0.6),
                        fontSize: 10,
                        height: 1.25,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: HealTokens.rosewoodDeep,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  else if (isEarned)
                    Icon(Icons.check_rounded, color: accent, size: 14)
                  else
                    const Icon(Icons.lock_outline_rounded, color: HealTokens.creamDim, size: 12),
                  if (sticker.milestone > 0)
                    Text(
                      '${sticker.milestone}d',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isEarned ? accent : HealTokens.creamDim.withValues(alpha: 0.4),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(target: isNew ? 1 : 0).shimmer(
          duration: const Duration(seconds: 2),
          color: accent.withValues(alpha: 0.4),
        );
  }
}


/// ── Sticker detail sheet ────────────────────────────────────────
class _StickerDetailSheet extends StatelessWidget {
  final Sticker sticker;
  const _StickerDetailSheet({required this.sticker});

  @override
  Widget build(BuildContext context) {
    final accent = Color(int.parse('FF${sticker.accent}', radix: 16));
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HealTokens.s32, HealTokens.s24, HealTokens.s32, HealTokens.s48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: HealTokens.creamDim.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: HealTokens.s32),
          // Big icon
          Text(sticker.icon, style: const TextStyle(fontSize: 96, height: 1.0)),
          const SizedBox(height: HealTokens.s24),
          Text(
            sticker.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w400,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            sticker.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: HealTokens.cream,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: HealTokens.s16),
          Text(
            sticker.criteria,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HealTokens.creamDim,
                  letterSpacing: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}


/// ── Motivational footer ─────────────────────────────────────────
class _MotivationalFooter extends StatelessWidget {
  final int earned;
  final int total;
  const _MotivationalFooter({required this.earned, required this.total});

  @override
  Widget build(BuildContext context) {
    final remaining = total - earned;
    String line;
    if (remaining == 0) {
      line = 'You hold the full collection. The story is yours.';
    } else if (earned == 0) {
      line = 'Begin anywhere. The first sticker is the loudest.';
    } else if (earned < 5) {
      line = '$remaining stickers still hidden. One more practice reveals more.';
    } else if (earned < 15) {
      line = 'You\'re building a real collection. The next chapter awaits.';
    } else {
      line = 'A real collection forming. The story is writing itself.';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HealTokens.s20),
      decoration: BoxDecoration(
        color: HealTokens.rosewoodLight,
        borderRadius: BorderRadius.circular(HealTokens.r16),
        border: Border.all(color: HealTokens.brass.withValues(alpha: 0.16)),
      ),
      child: Text(
        line,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HealTokens.creamDim,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}



/// ── Next milestones panel ──────────────────────────────────────
/// Shows the next 2-3 stickers the user is closest to earning.
/// Creates anticipatory motivation — a known retention driver.
class _NextMilestones extends StatelessWidget {
  final StickerBookState book;
  const _NextMilestones({required this.book});

  @override
  Widget build(BuildContext context) {
    // Find the next 3 locked stickers (closest in milestone terms)
    final locked = book.locked;
    final byMilestone = <String, List<Sticker>>{
      'next session': [],
      'this week': [],
      'longer arc': [],
    };
    for (final s in locked) {
      if (s.family == 'practice') {
        byMilestone['next session']!.add(s);
      } else if (s.family == 'streak' && s.milestone <= 7) {
        byMilestone['this week']!.add(s);
      } else {
        byMilestone['longer arc']!.add(s);
      }
    }
    // Show the next 3
    final next = <Sticker>[
      ...byMilestone['next session']!.take(1),
      ...byMilestone['this week']!.take(2),
    ].take(3).toList();
    if (next.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(HealTokens.s16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            HealTokens.rosewoodLight.withValues(alpha: 0.6),
            HealTokens.rosewood.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(HealTokens.r16),
        border: Border.all(color: HealTokens.brass.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 14, color: HealTokens.brass.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Text(
                'NEXT MILESTONES',
                style: TextStyle(
                  color: HealTokens.brass.withValues(alpha: 0.9),
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final s in next)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Opacity(
                    opacity: 0.7,
                    child: Text(s.icon, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            color: HealTokens.cream,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          s.criteria,
                          style: TextStyle(
                            color: HealTokens.creamDim.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.lock_outline_rounded, size: 14, color: HealTokens.creamDim.withValues(alpha: 0.4)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
