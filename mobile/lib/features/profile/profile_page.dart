// HEAL — Profile screen.
//
// Single place for everything about the user's practice:
//   1. Identity (first name + avatar) — optional, edit in place
//   2. Streak summary (current, longest, total sessions)
//   3. Activity calendar (GitHub-style heatmap, last 90 days)
//   4. Time spent (totals + by category chart)
//   5. Practice highlights (recent sticker unlocks, longest streak day)
//
// Mirrors the calm/premium feel of Calm's "Stats" and Headspace's
// "Today" tab — but with a deeper history view.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../core/widgets/brass_widgets.dart';
import '../../services/streak_service.dart';
import '../../services/sticker_book.dart';
import '../../services/activity_tracker.dart';
import '../../services/audio_service.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakServiceProvider);
    final book = ref.watch(stickerBookProvider);
    final track = ref.watch(activityTrackerProvider);
    final name = useState<String>('');
    final hydrated = useState<bool>(false);

    useEffect(() {
      () async {
        final prefs = await SharedPreferences.getInstance();
        name.value = prefs.getString('heal.profile.name') ?? '';
        hydrated.value = true;
      }();
      return null;
    }, []);

    Future<void> editName() async {
      final controller = TextEditingController(text: name.value);
      final newName = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: HealTokens.rosewoodDeep,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(HealTokens.r24)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(
            HealTokens.s24, HealTokens.s24, HealTokens.s24,
            HealTokens.s24 + MediaQuery.of(ctx).viewInsets.bottom,
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
              const SizedBox(height: HealTokens.s24),
              const Text(
                'What should we call you?',
                style: TextStyle(color: HealTokens.cream, fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: HealTokens.s16),
              TextField(
                controller: controller,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(color: HealTokens.cream, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Your name',
                  hintStyle: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(HealTokens.r12),
                    borderSide: BorderSide(color: HealTokens.brass.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(HealTokens.r12),
                    borderSide: const BorderSide(color: HealTokens.brass),
                  ),
                ),
              ),
              const SizedBox(height: HealTokens.s16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: HealTokens.brass,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                child: const Text('Save', style: TextStyle(color: HealTokens.rosewoodDeep)),
              ),
            ],
          ),
        ),
      );
      if (newName != null && newName.isNotEmpty) {
        name.value = newName;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('heal.profile.name', newName);
        HapticFeedback.selectionClick();
      }
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: HealTokens.rosewoodDeep,
            title: const Text('Your practice'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              HealTokens.s20, HealTokens.s12, HealTokens.s20, HealTokens.s80,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Identity card
                _IdentityCard(
                  name: name.value,
                  onTap: editName,
                  streak: streak,
                  book: book,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: HealTokens.s24),

                // Quick action tiles
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.collections_bookmark_rounded,
                        label: 'Stickers',
                        count: '${book.unlockedCount}/${book.totalCount}',
                        onTap: () => context.push('/stickers'),
                      ),
                    ),
                    const SizedBox(width: HealTokens.s12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.book_rounded,
                        label: 'Bible',
                        count: 'Year',
                        onTap: () => context.push('/bible'),
                      ),
                    ),
                    const SizedBox(width: HealTokens.s12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.favorite_outline_rounded,
                        label: 'Favorites',
                        count: '',
                        onTap: () => context.push('/favorites'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: HealTokens.s24),

                // Streak stats card
                _StatsCard(streak: streak, track: track)
                    .animate().fadeIn(duration: 400.ms, delay: 100.ms)
                    .slideY(begin: 0.05, end: 0),

                const SizedBox(height: HealTokens.s24),

                // Activity heatmap
                const _SectionLabel(label: 'Last 90 days'),
                const SizedBox(height: HealTokens.s12),
                _ActivityHeatmap(activity: track)
                    .animate().fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: 0.05, end: 0),

                const SizedBox(height: HealTokens.s24),

                // Time spent
                const _SectionLabel(label: 'Time in practice'),
                const SizedBox(height: HealTokens.s12),
                _TimeChart(activity: track)
                    .animate().fadeIn(duration: 400.ms, delay: 300.ms)
                    .slideY(begin: 0.05, end: 0),

                const SizedBox(height: HealTokens.s24),

                // Recent stickers
                const _SectionLabel(label: 'Recently earned'),
                const SizedBox(height: HealTokens.s12),
                _RecentStickers(book: book),

                const SizedBox(height: HealTokens.s32),

                // Motivational footer
                _MotivationalQuote(streak: streak),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}


// ── Identity card ───────────────────────────────────────────────
class _IdentityCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final StreakState streak;
  final StickerBookState book;
  const _IdentityCard({
    required this.name,
    required this.onTap,
    required this.streak,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.isEmpty ? 'Friend' : name;
    final initial = name.isEmpty ? '✦' : name[0].toUpperCase();
    final greeting = _greetingForHour(DateTime.now().hour);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(HealTokens.s24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [HealTokens.rosewood, HealTokens.rosewoodDeep],
          ),
          borderRadius: BorderRadius.circular(HealTokens.r24),
          border: Border.all(color: HealTokens.brass.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [HealTokens.brassLight, HealTokens.brass],
                ),
                boxShadow: [
                  BoxShadow(
                    color: HealTokens.brass.withValues(alpha: 0.4),
                    blurRadius: 16, spreadRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: HealTokens.rosewoodDeep,
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(width: HealTokens.s20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: TextStyle(
                      color: HealTokens.creamDim.withValues(alpha: 0.8),
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: HealTokens.cream,
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MiniStat(
                        icon: Icons.local_fire_department_rounded,
                        value: '${streak.currentStreak}',
                        label: streak.currentStreak == 1 ? 'day' : 'days',
                      ),
                      const SizedBox(width: 16),
                      _MiniStat(
                        icon: Icons.collections_bookmark_outlined,
                        value: '${book.unlockedCount}',
                        label: 'stickers',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              color: HealTokens.creamDim.withValues(alpha: 0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  String _greetingForHour(int hour) {
    if (hour < 5) return 'Still up';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Resting well';
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _MiniStat({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: HealTokens.brass, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(color: HealTokens.cream, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.7), fontSize: 11),
        ),
      ],
    );
  }
}


// ── Quick action tile ────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(HealTokens.r16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(HealTokens.s16),
          decoration: BoxDecoration(
            color: HealTokens.rosewood,
            borderRadius: BorderRadius.circular(HealTokens.r16),
            border: Border.all(color: HealTokens.brass.withValues(alpha: 0.16)),
          ),
          child: Column(
            children: [
              Icon(icon, color: HealTokens.brass, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: HealTokens.cream, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (count.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  count,
                  style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.7), fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


// ── Stats card ───────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final StreakState streak;
  final ActivityTrackerState track;
  const _StatsCard({required this.streak, required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HealTokens.s20),
      decoration: BoxDecoration(
        color: HealTokens.rosewoodLight,
        borderRadius: BorderRadius.circular(HealTokens.r20),
        border: Border.all(color: HealTokens.brass.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: HealTokens.brass, size: 20),
              SizedBox(width: 8),
              const Text(
                'STREAK',
                style: TextStyle(
                  color: HealTokens.brass,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: HealTokens.s16),
          Row(
            children: [
              _StatTile(label: 'Current', value: '${streak.currentStreak}', unit: streak.currentStreak == 1 ? 'day' : 'days'),
              _StatTile(label: 'Longest', value: '${streak.longestStreak}', unit: 'days'),
              _StatTile(label: 'Sessions', value: '${streak.totalSessions}', unit: 'total'),
            ],
          ),
          if (streak.recentSessions.isNotEmpty) ...[
            const SizedBox(height: HealTokens.s16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    HealTokens.creamDim.withValues(alpha: 0.0),
                    HealTokens.creamDim.withValues(alpha: 0.16),
                    HealTokens.creamDim.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: HealTokens.s12),
            Row(
              children: [
                Text(
                  'Last session',
                  style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.6), fontSize: 11),
                ),
                const Spacer(),
                Text(
                  _formatRelative(streak.recentSessions.last.timestamp),
                  style: const TextStyle(color: HealTokens.cream, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _StatTile({required this.label, required this.value, required this.unit});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.6), fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(color: HealTokens.cream, fontSize: 28, fontWeight: FontWeight.w300),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: unit,
                  style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.7), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ── Activity heatmap ────────────────────────────────────────────
class _ActivityHeatmap extends StatelessWidget {
  final ActivityTrackerState activity;
  const _ActivityHeatmap({required this.activity});

  @override
  Widget build(BuildContext context) {
    // Build a 90-day grid: 13 weeks × 7 days
    final today = DateTime.now();
    final days = <DateTime>[];
    for (int i = 89; i >= 0; i--) {
      days.add(DateTime(today.year, today.month, today.day).subtract(Duration(days: i)));
    }
    // Group by week column (Mon-Sun)
    final weekly = <List<DateTime>>[];
    // Start from the Monday of (today - 89 days)
    final first = days.first;
    final firstMonday = first.subtract(Duration(days: (first.weekday - 1) % 7));
    var weekStart = firstMonday;
    var idx = 0;
    while (idx < days.length) {
      final wk = <DateTime>[];
      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        if (idx < days.length && days[idx].difference(day).inDays == 0) {
          wk.add(days[idx]);
          idx++;
        } else if (day.isBefore(days.first)) {
          wk.add(day);
        } else if (day.isAfter(days.last)) {
          wk.add(day);
        } else {
          wk.add(day);
        }
      }
      weekly.add(wk);
      weekStart = weekStart.add(const Duration(days: 7));
    }

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final monthLabels = <String>[];
    int? lastMonth;
    for (final wk in weekly) {
      final monday = wk.first;
      if (lastMonth != monday.month) {
        const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        monthLabels.add(m[monday.month - 1]);
        lastMonth = monday.month;
      } else {
        monthLabels.add('');
      }
    }

    return Container(
      padding: const EdgeInsets.all(HealTokens.s20),
      decoration: BoxDecoration(
        color: HealTokens.rosewoodLight,
        borderRadius: BorderRadius.circular(HealTokens.r20),
        border: Border.all(color: HealTokens.brass.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${activity.totalCount()} sessions',
                  style: const TextStyle(color: HealTokens.cream, fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'Less',
                style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.5), fontSize: 10),
              ),
              const SizedBox(width: 6),
              for (final c in const [0.06, 0.20, 0.40, 0.65, 1.0])
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: HealTokens.brass.withValues(alpha: c),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                'More',
                style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.5), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: HealTokens.s16),
          // Month labels
          Row(
            children: [
              const SizedBox(width: 18),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: monthLabels.take(13).map((m) => SizedBox(
                    width: 14,
                    child: Text(
                      m,
                      style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.6), fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
              Column(
                children: [
                  for (int i = 0; i < 7; i++)
                    Container(
                      width: 14, height: 14,
                      alignment: Alignment.center,
                      child: Text(
                        i.isEven ? dayLabels[i ~/ 2 * 2] : '',
                        style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.4), fontSize: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              // Grid
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: weekly.map((wk) => Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Column(
                        children: wk.map((day) {
                          final count = activity.countOnDay(day);
                          final intensity = count == 0 ? 0.06 : (count > 5 ? 1.0 : count / 5.0);
                          final isFuture = day.isAfter(DateTime.now());
                          return Container(
                            width: 12, height: 12,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: isFuture
                                  ? HealTokens.creamDim.withValues(alpha: 0.04)
                                  : (count == 0
                                      ? HealTokens.brass.withValues(alpha: 0.06)
                                      : HealTokens.brass.withValues(alpha: 0.15 + intensity * 0.85)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }).toList(),
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ── Time chart ───────────────────────────────────────────────────
class _TimeChart extends StatelessWidget {
  final ActivityTrackerState activity;
  const _TimeChart({required this.activity});

  @override
  Widget build(BuildContext context) {
    // Bucket totals by kind
    final byKind = <String, int>{};
    for (final kind in ['breath', 'meditation', 'prayer', 'praise', 'scripture', 'reflection']) {
      byKind[kind] = activity.countFor(kind);
    }
    final total = byKind.values.fold<int>(0, (a, b) => a + b);
    final maxV = byKind.values.fold<int>(1, (a, b) => a > b ? a : b);

    final kindMeta = {
      'breath':      ('Breathwork',  Icons.air_rounded),
      'meditation':  ('Meditate',    Icons.self_improvement_rounded),
      'prayer':      ('Prayer',      Icons.favorite_outline_rounded),
      'praise':      ('Praise',      Icons.music_note_rounded),
      'scripture':   ('Scripture',   Icons.menu_book_rounded),
      'reflection':  ('Reflections', Icons.edit_note_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(HealTokens.s20),
      decoration: BoxDecoration(
        color: HealTokens.rosewoodLight,
        borderRadius: BorderRadius.circular(HealTokens.r20),
        border: Border.all(color: HealTokens.brass.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: HealTokens.brass, size: 20),
              const SizedBox(width: 8),
              const Text(
                'BY PRACTICE',
                style: TextStyle(
                  color: HealTokens.brass,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$total sessions total',
                style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.7), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: HealTokens.s16),
          for (final entry in byKind.entries) ...[
            _Bar(
              label: kindMeta[entry.key]?.$1 ?? entry.key,
              icon: kindMeta[entry.key]?.$2 ?? Icons.circle,
              value: entry.value,
              maxValue: maxV,
              color: _kindColor(entry.key),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Color _kindColor(String kind) {
    switch (kind) {
      case 'breath':     return const Color(0xFF5B8FA8); // cyan
      case 'meditation': return HealTokens.brass;
      case 'prayer':     return const Color(0xFFD08E8E); // rose
      case 'praise':     return const Color(0xFFA56B6B); // warm brown
      case 'scripture':  return HealTokens.brassLight;
      case 'reflection': return const Color(0xFF8B6A36); // bronze
      default:           return HealTokens.brass;
    }
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final int maxValue;
  final Color color;
  const _Bar({required this.label, required this.icon, required this.value, required this.maxValue, required this.color});
  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : value / maxValue;
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: HealTokens.cream, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: HealTokens.creamDim.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}


// ── Recent stickers ──────────────────────────────────────────────
class _RecentStickers extends StatelessWidget {
  final StickerBookState book;
  const _RecentStickers({required this.book});

  @override
  Widget build(BuildContext context) {
    final earned = book.earned;
    final recent = earned.reversed.take(6).toList();
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(HealTokens.s20),
        decoration: BoxDecoration(
          color: HealTokens.rosewoodLight,
          borderRadius: BorderRadius.circular(HealTokens.r16),
          border: Border.all(color: HealTokens.brass.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Start a practice to earn your first sticker.',
                style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.8), fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: recent.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = recent[i];
          final accent = Color(int.parse('FF${s.accent}', radix: 16));
          return Container(
            width: 88,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HealTokens.rosewoodLight,
              borderRadius: BorderRadius.circular(HealTokens.r16),
              border: Border.all(color: accent.withValues(alpha: 0.32)),
            ),
            child: Column(
              children: [
                Text(s.icon, style: const TextStyle(fontSize: 28, height: 1.0)),
                const SizedBox(height: 4),
                Text(
                  s.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700, height: 1.1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


// ── Motivational footer ──────────────────────────────────────────
class _MotivationalQuote extends StatelessWidget {
  final StreakState streak;
  const _MotivationalQuote({required this.streak});

  @override
  Widget build(BuildContext context) {
    final lines = <String, int>{
      '“The Lord is my shepherd; I shall not want.”': 1,
      '“Be still, and know that I am God.”': 1,
      '“Come to me, all you who are weary.”': 1,
    };
    final entry = lines.entries.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HealTokens.s24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [HealTokens.rosewood, HealTokens.rosewoodDeep],
        ),
        borderRadius: BorderRadius.circular(HealTokens.r20),
        border: Border.all(color: HealTokens.brass.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Text(
            entry.key,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HealTokens.cream,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '— A line to carry you',
            style: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }
}


// ── Section label ────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: HealTokens.brass,
        fontSize: 11,
        letterSpacing: 2.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}