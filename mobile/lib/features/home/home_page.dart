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
import '../../design/copy.dart';
import '../../design/edge_glow.dart';
import '../../design/emotion_palette.dart';
import '../../design/lumen.dart';
import '../../design/lumen_state.dart';
import '../../design/pressable.dart';
import '../../services/streak_service.dart';
import '../../services/voice_calibration_service.dart';
import '../../data/pb_models.dart';
import '../../data/pb_repositories.dart';
import '../../services/audio_service.dart';
import '../../services/activity_tracker.dart';
import '../../services/sticker_book.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeOfDay = useState<String>(_timeOfDay());
    final palette = ref.watch(timePaletteProvider);
    final emotionPalette = ref.watch(emotionPaletteProvider);
    final streak = ref.watch(streakServiceProvider);
    final hasVoiceProfile = ref.watch(voiceCalibrationServiceProvider.select(
      (s) => s.hasProfile,
    ));
    final lumenState = ref.watch(lumenProvider);
    // Lumen's emotion follows streak state and time of day.
    // Welcome-back users get weary; deep evenings get resting-but-dim.
    final lumenEmotion = streak.shouldShowWelcomeBack
        ? LumenEmotion.weary
        : lumenState.emotion;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          SafeArea(
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
              // ── Greeting + Lumen (the daily companion) ─────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Lumen — global companion. Emotion follows the lumen
                    // state machine (which other screens also write to).
                    LumenSlot(
                      emotion: lumenEmotion,
                      size: 56,
                      celebration: lumenState.celebration,
                    ),
                    const SizedBox(width: HealTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Copy.greetingForHour(DateTime.now().hour),
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: HealTokens.cream,
                                  fontWeight: FontWeight.w300,
                                  height: 1.05,
                                ),
                          ),
                          const SizedBox(height: 6),
                          // Lumen's voice — first-person, no streak-shame.
                          Text(
                            Copy.lumenGreeting(streak.currentStreak),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: HealTokens.creamDim,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Streak chip (compact, never proud/shameful) ────
              const SizedBox(height: HealTokens.s8),
              if (streak.currentStreak > 0)
                _StreakChip(currentStreak: streak.currentStreak,
                            longestStreak: streak.longestStreak),
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
              const FadeInOnMount(
                delay: Duration(milliseconds: 500),
                child: _TodayShelf(),
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
              const SizedBox(height: HealTokens.s40),

              // ── Bible-in-a-Year hero ───────────────────────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 650),
                child: _BibleYearHero(palette: palette),
              ),
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
      // EdgeGlow — sits on top of everything, follows emotion state
      Positioned(
        top: 0, left: 0, right: 0,
        child: EdgeGlow(palette: emotionPalette),
      ),
    ],
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
class _StreakChip extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  const _StreakChip({required this.currentStreak, required this.longestStreak});

  @override
  Widget build(BuildContext context) {
    final isLit = currentStreak > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HealTokens.s4),
      child: Row(
        children: [
          // Small ember dot — never a flame emoji (cluttery)
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: isLit ? HealTokens.ember : HealTokens.creamDim.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              boxShadow: isLit ? [
                BoxShadow(color: HealTokens.ember.withValues(alpha: 0.6),
                         blurRadius: 6, spreadRadius: 0)
              ] : null,
            ),
          ),
          const SizedBox(width: HealTokens.s8),
          Text(
            isLit
                ? '$currentStreak day${currentStreak == 1 ? '' : 's'} together'
                : 'Start a streak today',
            style: const TextStyle(
              color: HealTokens.creamDim,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
            label: Copy.statLongestStreak,
            value: '${streak.longestStreak} days',
          ),
          const SizedBox(height: HealTokens.s12),
          _StreakStat(
            label: Copy.statTotalSessions,
            value: '${streak.totalSessions}',
          ),
          const SizedBox(height: HealTokens.s12),
          _StreakStat(
            label: Copy.statTotalMinutes,
            value: '${streak.totalMinutes}',
          ),
          if (streak.lastSession != null) ...[
            const SizedBox(height: HealTokens.s12),
            _StreakStat(
              label: Copy.statLastSession,
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

String _heroTitle() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'A morning\nritual';
  if (hour >= 21) return 'Wind down\nfor the night';
  return 'A quiet\npractice';
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
    return Pressable(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      pressedScale: 0.97,
      pressedOverlay: HealTokens.white05,
      borderRadius: BorderRadius.circular(HealTokens.r24),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
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
                    _heroTitle(),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: HealTokens.cream,
                          height: 1.1,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  const SizedBox(height: HealTokens.s12),
                  Text(
                    Copy.heroPreviewLine,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HealTokens.creamDim,
                          letterSpacing: 0.3,
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
      )),
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

class _PracticeGrid extends ConsumerWidget {
  final TimePalette palette;
  const _PracticeGrid({required this.palette});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stage grid by session count to reduce paradox of choice on day 1.
    // - Sessions 0:   1 tile (Breathe)
    // - Sessions 1-3: 3 tiles (Breathe + Meditate + Pray)
    // - Sessions 4-7: 5 tiles (+ Praise + Reflections)
    // - Sessions 8+:  full 6-tile grid (+ Sleep + Stickers)
    final total = ref.watch(streakServiceProvider).totalSessions;
    final tiles = <Widget>[
      _PracticeTile(
        title: 'Breathe',
        subtitle: '~1 min · Start here',
        icon: Icons.air_rounded,
        gradient: const [HealTokens.brass, HealTokens.bronze],
        onTap: () => context.push('/breathe'),
      ),
    ];
    if (total >= 1) {
      tiles.addAll([
        _PracticeTile(
          title: 'Meditate',
          subtitle: '~5 min · Guided stillness',
          icon: Icons.self_improvement_rounded,
          gradient: const [HealTokens.brass, HealTokens.bronze],
          onTap: () => context.push('/meditate'),
        ),
        _PracticeTile(
          title: 'Pray',
          subtitle: '~3 min · Words for the hour',
          icon: Icons.favorite_outline_rounded,
          gradient: const [HealTokens.bronzeLight, HealTokens.bronze],
          onTap: () => context.push('/prayer'),
        ),
      ]);
    }
    if (total >= 4) {
      tiles.addAll([
        _PracticeTile(
          title: 'Praise',
          subtitle: '~4 min · Songs & hymns',
          icon: Icons.music_note_rounded,
          gradient: const [HealTokens.amber, HealTokens.brassDeep],
          onTap: () => context.push('/praise'),
        ),
        _PracticeTile(
          title: 'Reflections',
          subtitle: '~7 min · Slow reading',
          icon: Icons.menu_book_rounded,
          gradient: const [HealTokens.bronze, HealTokens.rosewood],
          onTap: () => context.push('/essays'),
        ),
      ]);
    }
    if (total >= 8) {
      tiles.addAll([
        _PracticeTile(
          title: 'Sleep',
          subtitle: '~10 min · Wind down',
          icon: Icons.nightlight_round,
          gradient: const [HealTokens.practiceSleepFrom, HealTokens.practiceSleepTo],
          onTap: () => context.push('/sleep'),
        ),
        _StickerBookTile(),
      ]);
    }

    if (tiles.length == 6) {
      // Full grid path (>=8 sessions): preserve original layout.
      return _PracticeGridLayout(tiles: tiles);
    }

    // Staged path: show tiles in a wrapping row.
    return Wrap(
      spacing: HealTokens.s12,
      runSpacing: HealTokens.s12,
      children: [
        for (final t in tiles)
          SizedBox(
            width: (MediaQuery.of(context).size.width - HealTokens.s20 * 2 - HealTokens.s12 * 2) / 3,
            child: t,
          ),
      ],
    );
  }
}

class _PracticeGridLayout extends StatelessWidget {
  final List<Widget> tiles;
  const _PracticeGridLayout({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: HealTokens.s12,
        crossAxisSpacing: HealTokens.s12,
        childAspectRatio: 0.85,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) => tiles[i],
    );
  }
}




/// ── Sticker Book tile (5th practice card) ─────────────────────
class _StickerBookTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(stickerBookProvider);
    final earned = book.unlockedCount;
    final total = book.totalCount;
    final pct = total == 0 ? 0.0 : earned / total;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/stickers');
      },
      child: Container(
        padding: const EdgeInsets.all(HealTokens.s20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [HealTokens.rosewood, HealTokens.rosewoodDeep],
          ),
          borderRadius: BorderRadius.circular(HealTokens.r20),
          border: Border.all(color: HealTokens.brass.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: HealTokens.brass.withValues(alpha: 0.2),
              blurRadius: 12, spreadRadius: -2,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HealTokens.brass.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.collections_bookmark_rounded,
                    color: HealTokens.brass, size: 20),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                '$earned / $total',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: HealTokens.brass,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Stickers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HealTokens.cream,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pct == 1.0
                        ? 'All earned'
                        : pct == 0
                            ? 'Begin the journey'
                            : '$earned more to go',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HealTokens.creamDim,
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: HealTokens.creamDim.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pct,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [HealTokens.brassLight, HealTokens.brass],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
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
    final audio            = ref.watch(audioServiceProvider);
    final activity         = ref.watch(activityTrackerProvider);

    Future<void> playMeditation(Meditation m) async {
      HapticFeedback.mediumImpact();
      ref.read(activityTrackerProvider.notifier).log('today_play', target: 'meditation:${m.slug}');
      ref.read(activityTrackerProvider.notifier).log('play_start', target: m.slug);
      ref.read(audioServiceProvider.notifier).play(AudioTrack(
            id: m.id,
            url: m.cdnAudio,
            title: m.title,
            subtitle: m.subtitle,
            illustrationUrl: m.cdnIllustration,
            source: AudioSource.meditation,
          ));
    }

    Future<void> playPraise(PraiseSong s) async {
      HapticFeedback.mediumImpact();
      ref.read(activityTrackerProvider.notifier).log('today_play', target: 'praise:${s.slug}');
      ref.read(activityTrackerProvider.notifier).log('play_start', target: s.slug);
      ref.read(audioServiceProvider.notifier).play(AudioTrack(
            id: s.id,
            url: s.cdnAudio,
            title: s.title,
            subtitle: s.subtitle,
            illustrationUrl: s.cdnIllustration,
            source: AudioSource.praise,
            lyrics: s.lyrics.isNotEmpty ? s.lyrics : null,
          ));
    }

    // Pick WHICH meditation / praise / prayer / reflection to surface today.
    // Deterministic by day-of-year so it doesn't feel random or repeat within a day,
    // but rotates every day.
    final now = DateTime.now();
    final todayKey = now.year * 1000 + now.month * 31 + now.day;

    final praiseList = praiseAsync.maybeWhen(data: (x) => x, orElse: () => <PraiseSong>[]);
    final reflectionList = reflectionsAsync.maybeWhen(data: (x) => x, orElse: () => <Essay>[]);
    final prayerList = ref.watch(prayersProvider).maybeWhen(data: (x) => x, orElse: () => <Prayer>[]);
    final scriptureList = ref.watch(allScripturesProvider).maybeWhen(data: (x) => x, orElse: () => <Scripture>[]);

    final todayMed = meditationsAsync.maybeWhen(data: (m) => m, orElse: () => null);
    final todayScripture = scriptureAsync.maybeWhen(data: (s) => s, orElse: () => null);
    final todayPrayer = prayerAsync.maybeWhen(data: (p) => p, orElse: () => null);
    final todayPraise = praiseList.isNotEmpty ? praiseList[todayKey % praiseList.length] : null;
    final todayReflection = reflectionList.isNotEmpty ? reflectionList[todayKey % reflectionList.length] : null;
    final todayWorld = worldAsync.maybeWhen(data: (w) => w, orElse: () => null);

    // Activity-aware recommendation: sort shelf by what user engages with most.
    final kindBoost = <String, int>{
      'today_play_meditation': activity.countFor('today_play_meditation'),
      'today_play_praise':     activity.countFor('today_play_praise'),
      'today_play_prayer':     activity.countFor('today_play_prayer'),
      'today_play_reflection': activity.countFor('today_play_reflection'),
      'today_play_scripture':  activity.countFor('today_play_scripture'),
    };

    Future<void> openScripture(Scripture s) async {
      HapticFeedback.selectionClick();
      ref.read(activityTrackerProvider.notifier).log('today_play', target: 'scripture:${s.reference}');
      context.push('/sit-with-verse', extra: s);
    }

    Future<void> openPrayer(Prayer p) async {
      HapticFeedback.selectionClick();
      ref.read(activityTrackerProvider.notifier).log('today_play', target: 'prayer:${p.slug}');
      context.push('/prayer/${p.id}');
    }

    Future<void> openReflection(Essay e) async {
      HapticFeedback.selectionClick();
      ref.read(activityTrackerProvider.notifier).log('today_play', target: 'reflection:${e.slug}');
      context.push('/essays/${e.slug}');
    }

    Future<void> openWorld(WorldDay w) async {
      HapticFeedback.selectionClick();
      ref.read(activityTrackerProvider.notifier).log('today_play', target: 'world:${w.slug}');
      context.push('/world/${w.slug}');
    }

    // Are we already playing this track? Show a "Playing" badge instead of eyebrow.
    String? nowPlayingEyebrow;
    if (audio.track != null && audio.playing) {
      switch (audio.track!.source) {
        case AudioSource.meditation: nowPlayingEyebrow = 'NOW PLAYING'; break;
        case AudioSource.praise:     nowPlayingEyebrow = 'NOW PLAYING'; break;
        case AudioSource.reference:  nowPlayingEyebrow = 'NOW READING'; break;
        case AudioSource.custom:     nowPlayingEyebrow = 'NOW PLAYING'; break;
      }
    }

    return SizedBox(
      height: 168,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Meditation — tap to play directly, NOT just go to a list ──
          _TodayCard(
            icon: Icons.self_improvement_rounded,
            eyebrow: nowPlayingEyebrow ?? 'MEDITATION',
            title: todayMed?.title ?? 'A small practice',
            subtitle: todayMed?.subtitle.isNotEmpty == true
                ? (todayMed!.subtitle.length > 60
                    ? '${todayMed.subtitle.substring(0, 60)}…'
                    : todayMed.subtitle)
                : 'A quiet practice',
            palette: const [HealTokens.practiceMeditateFrom, HealTokens.practiceMeditateTo],
            onTap: todayMed == null
                ? () => context.push('/meditate')
                : () => playMeditation(todayMed),
            onLongPress: todayMed == null
                ? null
                : () => context.push('/meditate/${todayMed.id}'),
          ),
          const SizedBox(width: HealTokens.s12),
          // ── Scripture — opens /sit-with-verse directly with today's verse ──
          _TodayCard(
            icon: Icons.menu_book_rounded,
            eyebrow: nowPlayingEyebrow ?? 'SCRIPTURE',
            title: todayScripture?.text ?? 'Be still and know',
            subtitle: todayScripture?.reference ?? 'A verse for the day',
            palette: const [HealTokens.practiceScriptureFrom, HealTokens.practiceScriptureTo],
            onTap: todayScripture == null
                ? () => context.push('/scripture')
                : () => openScripture(todayScripture),
          ),
          const SizedBox(width: HealTokens.s12),
          // ── Prayer — tap to open today's prayer detail (not generic list) ──
          _TodayCard(
            icon: Icons.favorite_rounded,
            eyebrow: nowPlayingEyebrow ?? 'PRAYER',
            title: todayPrayer?.title ?? 'A prayer',
            subtitle: todayPrayer?.body.split('\n').first ?? 'Bring it to God',
            palette: const [HealTokens.practicePrayerFrom, HealTokens.practicePrayerTo],
            onTap: todayPrayer == null
                ? () => context.push('/prayer')
                : () => openPrayer(todayPrayer),
          ),
          const SizedBox(width: HealTokens.s12),
          // ── Reflection — rotates daily via todayKey (not always first) ──
          _TodayCard(
            icon: Icons.menu_book_rounded,
            eyebrow: 'REFLECTION',
            title: todayReflection?.title ?? 'A long read',
            subtitle: todayReflection?.subtitle ?? 'A reflection',
            palette: const [HealTokens.practiceReflectionFrom, HealTokens.practiceReflectionTo],
            onTap: todayReflection == null
                ? () => context.push('/essays')
                : () => openReflection(todayReflection),
          ),
          const SizedBox(width: HealTokens.s12),
          // ── Praise — tap to play today's song directly (no detail page) ──
          _TodayCard(
            icon: Icons.music_note_rounded,
            eyebrow: nowPlayingEyebrow ?? 'PRAISE',
            title: todayPraise?.title ?? 'A hymn',
            subtitle: todayPraise?.subtitle ?? 'A song for today',
            palette: const [HealTokens.practicePraiseFrom, HealTokens.practicePraiseTo],
            onTap: todayPraise == null
                ? () => context.push('/praise')
                : () => playPraise(todayPraise),
            onLongPress: todayPraise == null
                ? null
                : () => context.push('/praise'),
          ),
          const SizedBox(width: HealTokens.s12),
          // ── World — opens today-in-the-world directly, not /world route ──
          _TodayCard(
            icon: Icons.public_rounded,
            eyebrow: 'THE WORLD',
            title: todayWorld?.title ?? 'Today in the world',
            subtitle: todayWorld?.scriptureRef ?? 'A prayer, a verse, an expectation',
            palette: const [HealTokens.practiceWorldFrom, HealTokens.practiceWorldTo],
            onTap: todayWorld == null
                ? () => context.push('/world/world-${_todaySlug()}')
                : () => openWorld(todayWorld),
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
  final VoidCallback? onLongPress;
  const _TodayCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      onLongPress: onLongPress == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onLongPress!();
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
                    color: HealTokens.white18,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: HealTokens.s8),
                Expanded(
                  child: Text(
                    eyebrow.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: HealTokens.white80,
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
                    color: HealTokens.white70,
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


/// ─────────────────────────────────────────────────────────────────────
/// BIBLE YEAR HERO — converts the Bible-in-a-Year idea into a CTA card on
/// the home page so users who don't open the Bible tab see it daily.
/// ─────────────────────────────────────────────────────────────────────
class _BibleYearHero extends HookConsumerWidget {
  final TimePalette palette;
  const _BibleYearHero({required this.palette});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync  = ref.watch(allReadingsProvider);
    final userIdAsync    = ref.watch(userIdProvider);
    return userIdAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (userId) {
        final progressAsync = ref.watch(userProgressProvider(userId));
        final completedDays = progressAsync.maybeWhen(
          data: (p) => p.map((x) => x.dayNumber).toSet(),
          orElse: () => <int>{},
        );
        final today = DateTime.now();
        final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays + 1;
        final planDay = dayOfYear.clamp(1, 365);
        final completedCount = completedDays.length;
        final isTodayDone = completedDays.contains(planDay);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(HealTokens.r24),
            onTap: () => context.push('/bible'),
            child: Container(
              padding: const EdgeInsets.all(HealTokens.s24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [HealTokens.practiceStickerFrom, HealTokens.practiceStickerTo],
                ),
                borderRadius: BorderRadius.circular(HealTokens.r24),
                border: Border.all(color: HealTokens.brass.withValues(alpha: 0.32)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: HealTokens.black32,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: HealTokens.brassLight, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'BIBLE IN A YEAR',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: HealTokens.brassLight,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: HealTokens.creamDim.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: HealTokens.s12),
                  Text(
                    isTodayDone
                      ? "Today's reading is complete"
                      : 'Day $planDay awaits',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: HealTokens.cream,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  readingsAsync.maybeWhen(
                    data: (readings) {
                      if (readings.isEmpty) {
                        return Text(
                          '365 days through the Bible, one chapter at a time',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HealTokens.creamDim),
                        );
                      }
                      final r = readings.firstWhere(
                        (x) => x.dayNumber == planDay,
                        orElse: () => readings.first,
                      );
                      return Text(
                        r.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: HealTokens.creamDim,
                              fontStyle: FontStyle.italic,
                            ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: HealTokens.s16),
                  SizedBox(
                    height: 6,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 365,
                      itemBuilder: (_, i) {
                        final day = i + 1;
                        return Container(
                          width: 1,
                          margin: EdgeInsets.only(right: i % 60 == 59 ? 6 : 0),
                          color: completedDays.contains(day)
                              ? HealTokens.brass
                              : HealTokens.brass.withValues(alpha: 0.1),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedCount / 365 days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HealTokens.creamDim),
                      ),
                      Text(
                        isTodayDone ? 'Day $planDay done' : 'Tap to read',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: HealTokens.brass,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


/// Australia's local 'today' for the daily world piece (matches the cron slug).
String _todaySlug() {
  // UTC + 8h = WST. Cron runs at 21:00 UTC = 06:00 WST.
  final ms = DateTime.now().toUtc().millisecondsSinceEpoch + 8 * 3600 * 1000;
  final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return 'world-$y-$m-$day';
}
