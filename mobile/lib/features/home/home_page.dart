// HEAL — Home page (revamped).
//
// What's new in this build:
//   - Streak flame + day counter (top-right)
//   - Adaptive palette: background shifts color with the time of day
//   - "Welcome back" card (no shame) when user returns after 4+ days
//   - "Today's practice" — single-tap to scripture + breath + prayer sequence
//   - Voice calibration entry surfaced when no profile exists

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/time_palette.dart';
import '../../core/widgets/brass_widgets.dart';
import '../../services/streak_service.dart';
import '../../services/voice_calibration_service.dart';
import '../../data/pb_models.dart';
import '../../data/pb_repositories.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeOfDay = useState<String>(_timeOfDay());
    final palette = ref.watch(timePaletteProvider);
    final streak = ref.watch(streakServiceProvider);
    final hasVoiceProfile = ref.watch(voiceCalibrationServiceProvider.select(
      (s) => s.hasProfile,
    ));

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            HealTokens.s20,
            HealTokens.s24,
            HealTokens.s20,
            HealTokens.s32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting + Streak ─────────────────────────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeOfDay.value,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: HealTokens.cream,
                                  fontWeight: FontWeight.w300,
                                ),
                          ),
                          const SizedBox(height: HealTokens.s4),
                          Text(
                            'A quiet practice awaits.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: HealTokens.creamDim,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _StreakFlame(streak: streak),
                  ],
                ),
              ),
              const SizedBox(height: HealTokens.s24),

              // ── Streak message ──────────────────────────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HealTokens.s16,
                    vertical: HealTokens.s12,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(HealTokens.r12),
                    border: Border.all(
                      color: palette.primary.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: palette.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: palette.primary.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: HealTokens.s12),
                      Expanded(
                        child: Text(
                          streak.streakMessage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: HealTokens.cream,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Welcome Back card (gentle, only after 4+ days) ─
              if (streak.shouldShowWelcomeBack && !streak.showedWelcomeBack) ...[
                const SizedBox(height: HealTokens.s16),
                _WelcomeBackCard(
                  daysAway: streak.daysSinceLastSession ?? 0,
                  onDismiss: () {
                    ref.read(streakServiceProvider.notifier).markWelcomeBackShown();
                  },
                ),
              ],

              const SizedBox(height: HealTokens.s32),

              // ── Today's practice — single-tap entry ─────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 300),
                child: _HeroPracticeCard(
                  onTap: () => context.push('/now'),
                  palette: palette,
                ),
              ),
              const SizedBox(height: HealTokens.s24),

              // ── Voice calibration banner (if no profile yet) ─
              if (!hasVoiceProfile) ...[
                FadeInOnMount(
                  delay: const Duration(milliseconds: 350),
                  child: _VoiceCalibrationBanner(
                    onTap: () => context.push('/breathe/calibrate'),
                    palette: palette,
                  ),
                ),
                const SizedBox(height: HealTokens.s24),
              ],

              // ── Quick actions ────────────────────────────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 400),
                child: _QuickActions(palette: palette),
              ),
              const SizedBox(height: HealTokens.s32),

              // ── TODAY'S CONTENT ──────────────────────────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 450),
                child: Text(
                  'TODAY',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 2.5,
                        color: palette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: HealTokens.s8),
              FadeInOnMount(
                delay: const Duration(milliseconds: 480),
                child: Text(
                  'A small shelf of the day\'s practice.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HealTokens.creamDim,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
              const SizedBox(height: HealTokens.s16),
              FadeInOnMount(
                delay: const Duration(milliseconds: 500),
                child: const _TodayShelf(),
              ),
              const SizedBox(height: HealTokens.s40),

              // ── Practice tiles ───────────────────────────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 600),
                child: Text(
                  'PRACTICE',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 2.5,
                        color: palette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: HealTokens.s16),

              _PracticeGrid(palette: palette),
              const SizedBox(height: HealTokens.s48),

              // ── Footer mark ─────────────────────────────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 700),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              palette.primary.withValues(alpha: 0),
                              palette.primary.withValues(alpha: 0.6),
                              palette.primary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: HealTokens.s16),
                      Text(
                        'HEAL',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              letterSpacing: 6,
                              color: HealTokens.creamDim,
                            ),
                      ),
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

  String _timeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Still awake?';
    if (hour < 12) return 'Good morning.';
    if (hour < 17) return 'Good afternoon.';
    if (hour < 21) return 'Good evening.';
    return 'Good night.';
  }
}

// ── Streak flame ─────────────────────────────────────────────────
class _StreakFlame extends StatelessWidget {
  final StreakState streak;
  const _StreakFlame({required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak.currentStreak == 0 && streak.totalSessions == 0) {
      return const SizedBox.shrink();
    }
    final isLit = streak.currentStreak > 0;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet(
          context: context,
          backgroundColor: HealTokens.rosewood,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(HealTokens.r24)),
          ),
          builder: (_) => _StreakDetailsSheet(streak: streak),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HealTokens.s12,
          vertical: HealTokens.s8,
        ),
        decoration: BoxDecoration(
          color: HealTokens.rosewoodLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isLit
                ? HealTokens.brass.withValues(alpha: 0.5)
                : HealTokens.creamDim.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLit ? Icons.local_fire_department_rounded : Icons.fireplace_outlined,
              color: isLit ? HealTokens.brass : HealTokens.creamDim,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              streak.currentStreak > 0
                  ? '${streak.currentStreak}'
                  : 'start',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isLit ? HealTokens.cream : HealTokens.creamDim,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakDetailsSheet extends StatelessWidget {
  final StreakState streak;
  const _StreakDetailsSheet({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(HealTokens.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: HealTokens.s24),
            decoration: BoxDecoration(
              color: HealTokens.creamDim.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: HealTokens.brass, size: 32),
              const SizedBox(width: HealTokens.s12),
              Text(
                '${streak.currentStreak}-day practice',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: HealTokens.s24),
          _StreakStat(
            label: 'Longest streak',
            value: '${streak.longestStreak} days',
          ),
          const SizedBox(height: HealTokens.s12),
          _StreakStat(
            label: 'Total sessions',
            value: '${streak.totalSessions}',
          ),
          const SizedBox(height: HealTokens.s12),
          _StreakStat(
            label: 'Total minutes',
            value: '${streak.totalMinutes}',
          ),
          if (streak.lastSession != null) ...[
            const SizedBox(height: HealTokens.s12),
            _StreakStat(
              label: 'Last session',
              value: _relativeTime(streak.lastSession!),
            ),
          ],
          const SizedBox(height: HealTokens.s32),
          Text(
            'A practice is a kind of prayer. Even three minutes counts.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HealTokens.creamDim,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _StreakStat extends StatelessWidget {
  final String label;
  final String value;
  const _StreakStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HealTokens.creamDim,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HealTokens.cream,
              ),
        ),
      ],
    );
  }
}

// ── Welcome back card (warm, no guilt) ──────────────────────────
class _WelcomeBackCard extends StatelessWidget {
  final int daysAway;
  final VoidCallback onDismiss;

  const _WelcomeBackCard({required this.daysAway, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: HealTokens.d800,
      curve: HealTokens.easeOutQuart,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(HealTokens.s20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              HealTokens.bronze.withValues(alpha: 0.32),
              HealTokens.rosewood,
            ],
          ),
          borderRadius: BorderRadius.circular(HealTokens.r20),
          border: Border.all(
            color: HealTokens.bronzeLight.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.coffee_outlined,
                    color: HealTokens.bronzeLight, size: 18),
                const SizedBox(width: HealTokens.s8),
                Expanded(
                  child: Text(
                    'You were away $daysAway days.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HealTokens.cream,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: HealTokens.creamDim, size: 18),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: HealTokens.s8),
            Text(
              'The room is still here. There is no catching up to do. Just begin again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HealTokens.creamDim,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Voice calibration banner ─────────────────────────────────────
class _VoiceCalibrationBanner extends StatelessWidget {
  final VoidCallback onTap;
  final TimePalette palette;
  const _VoiceCalibrationBanner({required this.onTap, required this.palette});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(HealTokens.s16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.primary.withValues(alpha: 0.16),
              palette.accent.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(HealTokens.r16),
          border: Border.all(
            color: palette.primary.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.32),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.record_voice_over_rounded,
                color: palette.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: HealTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn your breath',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: HealTokens.cream,
                        ),
                  ),
                  Text(
                    '30 seconds · HEAL will pace to you',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HealTokens.creamDim,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded,
                color: palette.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Hero practice card ──────────────────────────────────────────
class _HeroPracticeCard extends StatelessWidget {
  final VoidCallback onTap;
  final TimePalette palette;
  const _HeroPracticeCard({required this.onTap, required this.palette});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(HealTokens.s32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HealTokens.r24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.primary.withValues(alpha: 0.32),
              palette.surface,
            ],
          ),
          border: Border.all(
            color: palette.primary.withValues(alpha: 0.32),
          ),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.16),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HealTokens.s12,
                      vertical: HealTokens.s4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: palette.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'TODAY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: palette.primary,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: HealTokens.s16),
                  Text(
                    'A daily\npractice',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: HealTokens.cream,
                          height: 1.1,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  const SizedBox(height: HealTokens.s12),
                  Text(
                    'Scripture · breath · prayer. Five minutes.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HealTokens.creamDim,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: HealTokens.s16),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [palette.primary, palette.accent],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: HealTokens.rosewoodDeep,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final TimePalette palette;
  const _QuickActions({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.air_rounded,
            label: 'Breathe',
            onTap: () => context.push('/breathe'),
          ),
        ),
        const SizedBox(width: HealTokens.s12),
        Expanded(
          child: _QuickAction(
            icon: Icons.self_improvement_rounded,
            label: 'Meditate',
            onTap: () => context.push('/meditate'),
          ),
        ),
        const SizedBox(width: HealTokens.s12),
        Expanded(
          child: _QuickAction(
            icon: Icons.favorite_rounded,
            label: 'Pray',
            onTap: () => context.push('/prayer'),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(HealTokens.r16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: HealTokens.s20),
          decoration: BoxDecoration(
            color: HealTokens.rosewoodLight,
            borderRadius: BorderRadius.circular(HealTokens.r16),
            border: Border.all(
              color: HealTokens.brass.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: HealTokens.brass, size: 24),
              const SizedBox(height: HealTokens.s8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: HealTokens.cream,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeGrid extends StatelessWidget {
  final TimePalette palette;
  const _PracticeGrid({required this.palette});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _PracticeTile(
        title: 'Meditate',
        subtitle: 'Guided stillness',
        icon: Icons.self_improvement_rounded,
        gradient: const [HealTokens.brass, HealTokens.bronze],
        onTap: () => context.push('/meditate'),
      ),
      _PracticeTile(
        title: 'Praise',
        subtitle: 'Songs & hymns',
        icon: Icons.music_note_rounded,
        gradient: const [HealTokens.amber, HealTokens.brassDeep],
        onTap: () => context.push('/praise'),
      ),
      _PracticeTile(
        title: 'Pray',
        subtitle: 'Words for the hour',
        icon: Icons.favorite_outline_rounded,
        gradient: const [HealTokens.bronzeLight, HealTokens.bronze],
        onTap: () => context.push('/prayer'),
      ),
      _PracticeTile(
        title: 'Reflections',
        subtitle: 'Slow reading',
        icon: Icons.menu_book_rounded,
        gradient: const [HealTokens.bronze, HealTokens.rosewood],
        onTap: () => context.push('/essays'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: HealTokens.s12,
        crossAxisSpacing: HealTokens.s12,
        childAspectRatio: 1.05,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) => tiles[i],
    );
  }
}

class _PracticeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _PracticeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(HealTokens.s20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
            stops: const [0.0, 1.0],
          ).scale(0.5),
          borderRadius: BorderRadius.circular(HealTokens.r20),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.32),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                icon,
                color: HealTokens.rosewoodDeep.withValues(alpha: 0.4),
                size: 48,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: HealTokens.rosewoodDeep,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HealTokens.rosewoodDeep.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// ─────────────────────────────────────────────────────────────────────
/// TODAY SHELF — a swipeable rail of the day's content.
/// Each card pulls the day's pick from its provider and routes the user
/// straight into that piece. Fetches all six in parallel for snappy paint.
/// ─────────────────────────────────────────────────────────────────────

class _TodayShelf extends HookConsumerWidget {
  const _TodayShelf();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meditationsAsync = ref.watch(todayMeditationsProvider);
    final scriptureAsync   = ref.watch(todayScriptureProvider);
    final prayerAsync       = ref.watch(todayPrayerProvider);
    final reflectionsAsync  = ref.watch(reflectionsProvider);
    final praiseAsync       = ref.watch(praisesProvider);
    final worldAsync        = ref.watch(todayWorldProvider);

    return SizedBox(
      height: 168,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        physics: const BouncingScrollPhysics(),
        children: [
          _TodayCard(
            icon: Icons.self_improvement_rounded,
            eyebrow: 'Meditation',
            title: meditationsAsync.maybeWhen(
              data: (m) => m?.title ?? 'A small practice',
              orElse: () => 'A small practice',
            ),
            subtitle: meditationsAsync.maybeWhen(
              data: (m) {
                if (m == null) return 'Five minutes';
                final s = m.subtitle.isNotEmpty ? m.subtitle : 'A quiet practice';
                return s.length > 60 ? '${s.substring(0, 60)}…' : s;
              },
              orElse: () => 'Five minutes',
            ),
            palette: const [Color(0xFF4A6B5E), Color(0xFF2C3E36)],
            onTap: () => context.push('/meditate'),
          ),
          const SizedBox(width: HealTokens.s12),
          _TodayCard(
            icon: Icons.menu_book_rounded,
            eyebrow: 'Scripture',
            title: scriptureAsync.maybeWhen(
              data: (s) => s?.text ?? 'Be still',
              orElse: () => 'Be still',
            ),
            subtitle: scriptureAsync.maybeWhen(
              data: (s) => s?.reference ?? 'A verse for the day',
              orElse: () => 'A verse for the day',
            ),
            palette: const [Color(0xFF8E6F47), Color(0xFF5B4530)],
            onTap: () => context.push('/scripture'),
          ),
          const SizedBox(width: HealTokens.s12),
          _TodayCard(
            icon: Icons.favorite_rounded,
            eyebrow: 'Prayer',
            title: prayerAsync.maybeWhen(
              data: (p) => p.title ?? 'A prayer',
              orElse: () => 'A prayer',
            ),
            subtitle: prayerAsync.maybeWhen(
              data: (p) => p.body?.split('\n').first ?? 'Bring it to God',
              orElse: () => 'Bring it to God',
            ),
            palette: const [Color(0xFFA66B5C), Color(0xFF6F4538)],
            onTap: () => context.push('/prayer'),
          ),
          const SizedBox(width: HealTokens.s12),
          _TodayCard(
            icon: Icons.menu_book_rounded,
            eyebrow: 'Reflection',
            title: reflectionsAsync.maybeWhen(
              data: (r) => r.isNotEmpty ? r.first.title : 'A long read',
              orElse: () => 'A long read',
            ),
            subtitle: reflectionsAsync.maybeWhen(
              data: (r) => r.isNotEmpty ? (r.first.subtitle ?? 'A reflection') : 'A reflection',
              orElse: () => 'A reflection',
            ),
            palette: const [Color(0xFF5B6E8E), Color(0xFF394861)],
            onTap: () => context.push('/essays'),
          ),
          const SizedBox(width: HealTokens.s12),
          _TodayCard(
            icon: Icons.music_note_rounded,
            eyebrow: 'Praise',
            title: praiseAsync.maybeWhen(
              data: (p) => p.isNotEmpty ? p.first.title : 'A hymn',
              orElse: () => 'A hymn',
            ),
            subtitle: praiseAsync.maybeWhen(
              data: (p) => p.isNotEmpty ? (p.first.subtitle ?? 'A song for today') : 'A song for today',
              orElse: () => 'A song for today',
            ),
            palette: const [Color(0xFF6E5BA6), Color(0xFF44386F)],
            onTap: () => context.push('/praise'),
          ),
          const SizedBox(width: HealTokens.s12),
          _TodayCard(
            icon: Icons.public_rounded,
            eyebrow: worldAsync.maybeWhen(
              data: (w) {
                if (w == null) return 'The world';
                switch (w.promptKind) {
                  case 'challenge': return 'A weight to pray into';
                  case 'grace':     return 'Good, already happening';
                  case 'gratitude': return 'Worth pausing for';
                  default:          return 'The world, today';
                }
              },
              orElse: () => 'The world, today',
            ),
            title: worldAsync.maybeWhen(
              data: (w) => w?.title ?? 'Today in the world',
              orElse: () => 'Today in the world',
            ),
            subtitle: worldAsync.maybeWhen(
              data: (w) => w?.scriptureRef ?? 'A prayer, a verse, an expectation',
              orElse: () => 'A prayer, a verse, an expectation',
            ),
            palette: const [Color(0xFF4A8E8E), Color(0xFF2E6363)],
            onTap: () {
              final slug = worldAsync.maybeWhen(
                data: (w) => w?.slug,
                orElse: () => null,
              );
              if (slug != null) context.push('/world/$slug');
            },
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Color> palette;
  final VoidCallback onTap;
  const _TodayCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(HealTokens.s16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HealTokens.r20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette[0],
              palette[1],
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: palette[0].withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: HealTokens.s8),
                Expanded(
                  child: Text(
                    eyebrow.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
