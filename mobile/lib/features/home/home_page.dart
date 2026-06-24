// HEAL — Home page.
// Hero entry tiles for: Meditate, Praise, Prayer, Breath, Essays.
// Day-of-year greeting + brass accent.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets/brass_widgets.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeOfDay = useState<String>(_timeOfDay());
    final scale = useState<double>(1.0);

    return Scaffold(
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
              // ── Greeting ────────────────────────────────────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 100),
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
                    const SizedBox(height: HealTokens.s8),
                    Text(
                      'A quiet practice awaits.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: HealTokens.creamDim,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HealTokens.s40),

              // ── Today's practice — hero tile ──────────────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 200),
                child: _HeroPracticeCard(
                  onTap: () => context.push('/now'),
                ),
              ),
              const SizedBox(height: HealTokens.s32),

              // ── Quick actions ─────────────────────────────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 300),
                child: _QuickActions(),
              ),
              const SizedBox(height: HealTokens.s40),

              // ── Practice tiles ────────────────────────────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'PRACTICE',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 2.5,
                        color: HealTokens.brass,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: HealTokens.s16),

              _PracticeGrid(),
              const SizedBox(height: HealTokens.s48),

              // ── Footer mark ───────────────────────────────────
              FadeInOnMount(
                delay: const Duration(milliseconds: 600),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              HealTokens.brass.withValues(alpha: 0),
                              HealTokens.brass.withValues(alpha: 0.6),
                              HealTokens.brass.withValues(alpha: 0),
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

class _HeroPracticeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroPracticeCard({required this.onTap});

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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A2C26),
              Color(0xFF2A1815),
            ],
          ),
          border: Border.all(
            color: HealTokens.brass.withValues(alpha: 0.32),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: HealTokens.brass.withValues(alpha: 0.16),
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
                      color: HealTokens.brass.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: HealTokens.brass.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'TODAY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: HealTokens.brassLight,
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
                    'Five minutes of scripture, breath, and prayer.',
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
                gradient: const LinearGradient(
                  colors: [HealTokens.brassLight, HealTokens.brass],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: HealTokens.brass.withValues(alpha: 0.4),
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
          padding: const EdgeInsets.symmetric(
            vertical: HealTokens.s20,
          ),
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
  @override
  Widget build(BuildContext context) {
    final tiles = [
      _PracticeTile(
        title: 'Meditate',
        subtitle: 'Guided stillness',
        icon: Icons.self_improvement_rounded,
        gradient: [HealTokens.brass, HealTokens.bronze],
        onTap: () => context.push('/meditate'),
      ),
      _PracticeTile(
        title: 'Praise',
        subtitle: 'Songs & hymns',
        icon: Icons.music_note_rounded,
        gradient: [HealTokens.amber, HealTokens.brassDeep],
        onTap: () => context.push('/praise'),
      ),
      _PracticeTile(
        title: 'Pray',
        subtitle: 'Words for the hour',
        icon: Icons.favorite_outline_rounded,
        gradient: [HealTokens.bronzeLight, HealTokens.bronze],
        onTap: () => context.push('/prayer'),
      ),
      _PracticeTile(
        title: 'Essays',
        subtitle: 'Slow reading',
        icon: Icons.menu_book_rounded,
        gradient: [HealTokens.bronze, HealTokens.rosewood],
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
            // Icon (large, top-right)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                icon,
                color: HealTokens.rosewoodDeep.withValues(alpha: 0.4),
                size: 48,
              ),
            ),
            // Title block (bottom-left)
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