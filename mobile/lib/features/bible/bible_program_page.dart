// HEAL — Bible-in-a-Year program.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/pb_models.dart';
import '../../data/bible_progress_cache.dart';
import '../../data/pb_repositories.dart';
import '../../services/streak_service.dart';
import '../../services/sound_service.dart';
import '../../services/sticker_book.dart';
import '../../services/activity_tracker.dart';

class BibleProgramPage extends HookConsumerWidget {
  const BibleProgramPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(allReadingsProvider);
    final userIdAsync   = ref.watch(userIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible in a Year'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(allReadingsProvider),
          ),
        ],
      ),
      body: readingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 1.2)),
        error: (e, _) => const Center(
          child: Text('Could not load.', style: TextStyle(color: HealTokens.creamDim)),
        ),
        data: (readings) {
          if (readings.isEmpty) {
            return const Center(
              child: Text('No readings yet.', style: TextStyle(color: HealTokens.creamDim)),
            );
          }
          return userIdAsync.when(
            loading: () => _buildBody(context, ref, readings, null),
            error: (_, __) => _buildBody(context, ref, readings, null),
            data: (userId) {
              final progressAsync = ref.watch(userProgressProvider(userId));
              return progressAsync.when(
                loading: () => _buildBody(context, ref, readings, null),
                data: (progress) => _buildBody(context, ref, readings, progress),
                error: (_, __) => _buildBody(context, ref, readings, null),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<BibleReading> readings, List<BibleProgress>? progress) {
    final completedDays = progress?.map((p) => p.dayNumber).toSet() ?? <int>{};
    final completedCount = completedDays.length;
    final today = DateTime.now();
    final startDate = DateTime(today.year, 1, 1);
    final daysSinceJan1 = today.difference(startDate).inDays + 1;
    final planDay = daysSinceJan1.clamp(1, 365);
    final currentReading = readings.firstWhere(
      (r) => r.dayNumber == planDay,
      orElse: () => readings.first,
    );
    final isTodayCompleted = completedDays.contains(planDay);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        HealTokens.s20,
        HealTokens.s16,
        HealTokens.s20,
        HealTokens.s80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BibleProgressHero(
            completedCount: completedCount,
            totalCount: readings.length,
            currentDay: planDay,
            currentTitle: currentReading.title,
            isTodayCompleted: isTodayCompleted,
          ),
          const SizedBox(height: HealTokens.s32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TODAY',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 2.5,
                      color: HealTokens.brass,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (isTodayCompleted)
                const Icon(Icons.check_circle_rounded, color: HealTokens.brass, size: 20),
            ],
          ),
          const SizedBox(height: HealTokens.s12),
          _TodayReadingCard(
            reading: currentReading,
            isCompleted: isTodayCompleted,
            onTap: () => _openDay(context, ref, currentReading),
            onMarkComplete: () => _markComplete(context, ref, currentReading),
          ),
          const SizedBox(height: HealTokens.s32),
          Text(
            'THE 365-DAY JOURNEY',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 2.5,
                  color: HealTokens.brass,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: HealTokens.s12),
          _DayStrip(
            readings: readings,
            currentDay: planDay,
            completedDays: completedDays,
            onTapDay: (d) => _openDay(context, ref, readings.firstWhere((r) => r.dayNumber == d)),
          ),
          const SizedBox(height: HealTokens.s32),
          Text(
            'THIS WEEK',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 2.5,
                  color: HealTokens.brass,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: HealTokens.s12),
          _WeekList(
            readings: readings,
            startDay: planDay,
            completedDays: completedDays,
            onTap: (r) => _openDay(context, ref, r),
          ),
        ],
      ),
    );
  }

  void _openDay(BuildContext context, WidgetRef ref, BibleReading reading) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BibleDayPage(reading: reading),
    ));
  }

  Future<void> _markComplete(BuildContext context, WidgetRef ref, BibleReading reading) async {
    final userId = await UserIdService().get();
    HapticFeedback.mediumImpact();
    await ref.read(bibleProgressRepoProvider).markComplete(
          userId: userId,
          dayNumber: reading.dayNumber,
        );
    await ref.read(streakServiceProvider.notifier).recordSession(
          SessionRecord(
            timestamp: DateTime.now(),
            type: SessionType.scripture,
            durationSeconds: 300,
          ),
        );
    // P0 #3: invalidate cached progress so the next sticker eval sees the new day.
    // (Previously this re-fetched from PB on every track end — see main.dart.)
    await ref.read(bibleProgressCacheProvider(userId).notifier).refresh();
    // Re-evaluate stickers — Bible completion may unlock "first-bible" + Bible moment stickers
    final track = ref.read(activityTrackerProvider);
    // P1 #4: Bible completion overlay — show "You finished [passage]. Day N of 365."
    // for 2 seconds with a brass-glow flash. Reverent, no confetti.
    if (context.mounted) {
      await showBibleCompletionOverlay(
        context,
        passage: '${reading.bookName} ${reading.chapter}',
        dayNumber: reading.dayNumber,
      );
    }
    final progress = await ref.read(bibleProgressCacheProvider(userId).notifier).ensure();
    final completedDays = progress.map((p) => p.dayNumber).toSet();
    final streak = ref.read(streakServiceProvider);
    final sticker = await ref.read(stickerBookProvider.notifier).evaluate(
      currentStreak: streak.currentStreak,
      totalSessions: streak.totalSessions,
      hasBreathed:     track.countFor('open_breath') > 0,
      hasMeditated:    track.countFor('open_meditation') > 0,
      hasPrayed:       track.countFor('today_play_prayer') > 0,
      hasPraised:      track.countFor('today_play_praise') > 0,
      hasReadBible:    true,  // just marked complete
      hasFavorited:    track.countFor('favorite_added') > 0,
      hasShared:       track.countFor('reflection_shared') > 0,
      completedBibleDays: completedDays,
    );
    if (sticker != null) {
      HapticFeedback.heavyImpact();
      ref.read(soundServiceProvider).play(
        sticker.family == 'moment' ? SoundKind.stickerBible
        : sticker.family == 'streak' ? SoundKind.stickerStreak
        : SoundKind.stickerPractice,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Text(sticker.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(child: Text('Sticker earned: ${sticker.name}')),
            ]),
            duration: const Duration(seconds: 3),
            backgroundColor: HealTokens.rosewood,
          ),
        );
      }
    }
    ref.invalidate(userProgressProvider(userId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Day ${reading.dayNumber} marked complete'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}


/// ── Progress hero ───────────────────────────────────────────────
class _BibleProgressHero extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final int currentDay;
  final String currentTitle;
  final bool isTodayCompleted;

  const _BibleProgressHero({
    required this.completedCount,
    required this.totalCount,
    required this.currentDay,
    required this.currentTitle,
    required this.isTodayCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(HealTokens.s24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HealTokens.rosewoodLight,
            HealTokens.rosewoodDeep,
          ],
        ),
        borderRadius: BorderRadius.circular(HealTokens.r20),
        border: Border.all(color: HealTokens.brass.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: HealTokens.brassLight, size: 18),
              const SizedBox(width: 8),
              Text(
                'YOUR JOURNEY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: HealTokens.brassLight,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: HealTokens.s16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$completedCount',
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
                  'of $totalCount days',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HealTokens.creamDim),
                ),
              ),
            ],
          ),
          const SizedBox(height: HealTokens.s16),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: HealTokens.rosewoodDeep.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
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
          const SizedBox(height: HealTokens.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$pct% complete',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HealTokens.creamDim)),
              if (isTodayCompleted)
                Text('Today ✓',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HealTokens.brass))
              else
                Text('Day $currentDay of 365',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HealTokens.creamDim)),
            ],
          ),
        ],
      ),
    );
  }
}


/// ── Today's reading card ────────────────────────────────────────
class _TodayReadingCard extends StatelessWidget {
  final BibleReading reading;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onMarkComplete;

  const _TodayReadingCard({
    required this.reading,
    required this.isCompleted,
    required this.onTap,
    required this.onMarkComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(HealTokens.r16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(HealTokens.s20),
          decoration: BoxDecoration(
            color: HealTokens.rosewood,
            borderRadius: BorderRadius.circular(HealTokens.r16),
            border: Border.all(
              color: isCompleted
                  ? HealTokens.brass.withValues(alpha: 0.6)
                  : HealTokens.brass.withValues(alpha: 0.16),
              width: isCompleted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [HealTokens.brassLight, HealTokens.brass],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${reading.dayNumber}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: HealTokens.rosewoodDeep,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${reading.dayNumber}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: HealTokens.brass,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reading.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: HealTokens.cream,
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reading.readings.map((r) => Chip(
                  label: Text(r.label, style: const TextStyle(color: HealTokens.cream, fontSize: 12)),
                  backgroundColor: HealTokens.rosewoodDeep.withValues(alpha: 0.6),
                  side: BorderSide(color: HealTokens.brass.withValues(alpha: 0.16)),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
              if (reading.reflectionPrompt.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HealTokens.rosewoodDeep.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(HealTokens.r12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, color: HealTokens.brass, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reading.reflectionPrompt,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: HealTokens.creamDim,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.menu_book_rounded, size: 16),
                      label: const Text('Read'),
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HealTokens.brass,
                        side: BorderSide(color: HealTokens.brass.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.check_rounded,
                        size: 16,
                      ),
                      label: Text(isCompleted ? 'Done' : 'Mark complete'),
                      onPressed: onMarkComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted
                            ? HealTokens.brass.withValues(alpha: 0.3)
                            : HealTokens.brass,
                        foregroundColor: HealTokens.rosewoodDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// ── Day strip ──────────────────────────────────────────────────
class _DayStrip extends StatelessWidget {
  final List<BibleReading> readings;
  final int currentDay;
  final Set<int> completedDays;
  final void Function(int dayNumber) onTapDay;

  const _DayStrip({
    required this.readings,
    required this.currentDay,
    required this.completedDays,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: readings.length,
        itemBuilder: (_, i) {
          final r = readings[i];
          final isCurrent = r.dayNumber == currentDay;
          final isDone = completedDays.contains(r.dayNumber);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onTapDay(r.dayNumber),
              child: Container(
                width: 36,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? HealTokens.brass
                      : isDone
                          ? HealTokens.brass.withValues(alpha: 0.18)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrent
                        ? HealTokens.brass
                        : isDone
                            ? HealTokens.brass.withValues(alpha: 0.3)
                            : HealTokens.creamDim.withValues(alpha: 0.12),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${r.dayNumber}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isCurrent
                              ? HealTokens.rosewoodDeep
                              : isDone
                                  ? HealTokens.brass
                                  : HealTokens.creamDim,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


/// ── Week list ──────────────────────────────────────────────────
class _WeekList extends StatelessWidget {
  final List<BibleReading> readings;
  final int startDay;
  final Set<int> completedDays;
  final void Function(BibleReading reading) onTap;

  const _WeekList({
    required this.readings,
    required this.startDay,
    required this.completedDays,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weekDays = <BibleReading>[];
    for (int i = 0; i < 7 && startDay + i <= 365; i++) {
      final r = readings.firstWhere((x) => x.dayNumber == startDay + i, orElse: () => readings.first);
      weekDays.add(r);
    }
    return Column(
      children: weekDays.map((r) {
        final isDone = completedDays.contains(r.dayNumber);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(HealTokens.r12),
              onTap: () => onTap(r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: HealTokens.rosewoodLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(HealTokens.r12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        'D${r.dayNumber}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: HealTokens.brass,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HealTokens.cream),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDone)
                      const Icon(Icons.check_circle_rounded, color: HealTokens.brass, size: 18)
                    else
                      const Icon(Icons.chevron_right_rounded, color: HealTokens.creamDim, size: 18),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}


/// ── Single day reading page ───────────────────────────────────
class BibleDayPage extends ConsumerStatefulWidget {
  final BibleReading reading;
  const BibleDayPage({super.key, required this.reading});

  @override
  ConsumerState<BibleDayPage> createState() => _BibleDayPageState();
}

class _BibleDayPageState extends ConsumerState<BibleDayPage> {
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reading;
    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${r.dayNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Mark complete',
            onPressed: () async {
              final userId = await UserIdService().get();
              await ref.read(bibleProgressRepoProvider).markComplete(
                userId: userId,
                dayNumber: r.dayNumber,
                notes: _notesCtrl.text,
              );
              ref.invalidate(userProgressProvider(userId));
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Day complete — well done')),
              );
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(HealTokens.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: HealTokens.cream)),
            const SizedBox(height: HealTokens.s16),
            for (final reading in r.readings) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HealTokens.rosewoodLight,
                  borderRadius: BorderRadius.circular(HealTokens.r12),
                  border: Border.all(color: HealTokens.brass.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: HealTokens.brass),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reading.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: HealTokens.cream),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, color: HealTokens.brass, size: 18),
                      onPressed: () => _openInBibleGateway(context, reading.bibleGatewayUrl),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (r.reflectionPrompt.isNotEmpty) ...[
              Text(
                'REFLECT',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: HealTokens.brass,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                r.reflectionPrompt,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: HealTokens.creamDim,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'NOTES',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: HealTokens.brass,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 6,
              style: const TextStyle(color: HealTokens.cream),
              decoration: InputDecoration(
                hintText: 'What is God saying to you today?',
                hintStyle: const TextStyle(color: HealTokens.creamDim),
                filled: true,
                fillColor: HealTokens.rosewoodLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HealTokens.r12),
                  borderSide: BorderSide(color: HealTokens.brass.withValues(alpha: 0.18)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HealTokens.r12),
                  borderSide: BorderSide(color: HealTokens.brass.withValues(alpha: 0.18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openInBibleGateway(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: HealTokens.rosewoodDeep,
        title: const Text('Open in Bible Gateway'),
        content: SelectableText(url, style: const TextStyle(color: HealTokens.creamDim, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}


/// ── Bible completion overlay (P1 #4) ────────────────────────────
/// Shown when a user marks a day's reading complete. Brass-glow flash,
/// passage name, day-of-365 progress. Dismissable by tap.
/// 1.8-second default duration. Reverent — no confetti.
Future<void> showBibleCompletionOverlay(
  BuildContext context, {
  required String passage,
  required int dayNumber,
  Duration duration = const Duration(milliseconds: 1800),
}) async {
  if (!context.mounted) return;
  // Dismiss anything currently up (so repeated marks don't pile up).
  Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Bible reading complete',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (ctx, anim, secAnim) {
      return Center(
        child: FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: HealTokens.s40),
              padding: const EdgeInsets.all(HealTokens.s24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [HealTokens.brass, HealTokens.bronze],
                ),
                borderRadius: BorderRadius.circular(HealTokens.r20),
                boxShadow: [
                  BoxShadow(
                    color: HealTokens.brass.withValues(alpha: 0.6),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    color: HealTokens.oxblood,
                    size: 36,
                  ),
                  const SizedBox(height: HealTokens.s12),
                  const Text(
                    'You finished',
                    style: TextStyle(
                      color: HealTokens.oxblood,
                      fontSize: 13,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    passage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: HealTokens.oxblood,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: HealTokens.s16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HealTokens.s12, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: HealTokens.oxblood.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(HealTokens.r20),
                    ),
                    child: Text(
                      'Day $dayNumber of 365',
                      style: const TextStyle(
                        color: HealTokens.oxblood,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, secAnim, child) => child,
  );

  await Future.delayed(duration);
  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  }
}
