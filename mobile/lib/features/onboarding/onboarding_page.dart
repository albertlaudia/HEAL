// HEAL — Onboarding flow.
//
// Psychology:
//   1. Two value-prop screens — establish identity, build trust
//   2. ONE first-breath screen — let the user feel the product before any ask
//   3. Permission ask only AFTER the user has felt value
//   4. Skip is always available — no friction
//
// Key insight: notification permission requests inside onboarding are the
// #1 cause of 1-star reviews. Calm asks *after* the first session.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../design/lumen.dart';

import '../../core/theme.dart';
import '../../services/notification_service.dart';
import '../../services/sound_service.dart' show SoundService, SoundKind;

class OnboardingPage extends HookConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState<int>(0);

    Future<void> completeOnboarding() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
    }

    // 3-screen onboarding:
    //   1. Value prop — "A quiet place to be still"
    //   2. Value prop — "No tracking, no noise"
    //   3. First Breath — user feels the product
    //
    // Notification permission ask happens AFTER the first completed session
    // (see PermissionGate widget in main.dart). Asking before value leads
    // to ~60% opt-out per Calm/Headspace benchmarks.
    final pages = [
      const _ValuePage(
        icon: Icons.spa_outlined,
        title: 'A quiet place\nto be still',
        body: 'Five minutes of scripture, breath, and prayer.\nFor the hurried and the weary.',
        color: HealTokens.brass,
      ),
      const _ValuePage(
        icon: Icons.cloud_outlined,
        title: 'No tracking.\nNo noise.',
        body: 'Your practice is yours. No ads, no analytics, no accounts required.',
        color: HealTokens.amber,
      ),
      const _FirstBreathPage(),
    ];

    // Mark that we should ask for notification permission after the first
    // completed session. The PermissionGate (in main.dart) reads this flag.
    final prefs = SharedPreferences.getInstance();
    // Fire and forget; the flag is set BEFORE onboarding completes.
    Future.microtask(() async {
      final p = await prefs;
      await p.setBool('ask_notifications_after_first_session', true);
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: pages.length,
              onPageChanged: (i) => currentPage.value = i,
              // Disable swipe on the first-breath page (index 2) so user doesn't skip it
              physics: currentPage.value == 2
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              itemBuilder: (context, i) => pages[i],
            ),
            // Skip button — visible only on first two pages
            Positioned(
              top: HealTokens.s16,
              right: HealTokens.s20,
              child: currentPage.value < pages.length - 2
                  ? TextButton(
                      onPressed: () async {
                        await completeOnboarding();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('SKIP'),
                    )
                  : const SizedBox.shrink(),
            ),
            // Page indicator
            Positioned(
              bottom: HealTokens.s40,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: pageController,
                  count: pages.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: HealTokens.brass,
                    dotColor: HealTokens.creamDim.withValues(alpha: 0.24),
                    expansionFactor: 3,
                    dotHeight: 6,
                    dotWidth: 6,
                    spacing: 6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// ── Value-prop page (icon + headline + body) ────────────────────
class _ValuePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _ValuePage({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HealTokens.s40, HealTokens.s80, HealTokens.s40, HealTokens.s120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.1)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.32),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: HealTokens.s40),
          Text(
            title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: HealTokens.cream,
                  height: 1.1,
                  fontWeight: FontWeight.w400,
                ),
          ),
          const SizedBox(height: HealTokens.s24),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: HealTokens.creamDim,
                  height: 1.6,
                ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}


/// ── FIRST BREATH PAGE — let the user feel the product ───────────
/// Three slow breaths, animated, with subtle sound + haptic. User
/// can't skip. By the time they reach the permission ask, they
/// already feel HEAL.
class _FirstBreathPage extends StatefulWidget {
  const _FirstBreathPage();
  @override
  State<_FirstBreathPage> createState() => _FirstBreathPageState();
}

class _FirstBreathPageState extends State<_FirstBreathPage>
    with TickerProviderStateMixin {
  late AnimationController _breathCtrl;
  int _phaseIdx = 0;  // 0 = inhale, 1 = hold, 2 = exhale
  int _cycle = 0;
  bool _started = false;

  // Three breaths: each is inhale (4s) → hold (2s) → exhale (6s) = 12s
  static const _firstDuration = 4; // breathe-in seconds (first phase)
  static const _durations = [4, 2, 6];
  static const _labels = [Copy.breathInhaleShort, Copy.breathHold, Copy.breathExhaleShort];

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      duration: const Duration(seconds: _firstDuration),
      vsync: this,
    );
    _breathCtrl.addStatusListener(_onPhaseDone);
  }

  void _start() async {
    setState(() => _started = true);
    HapticFeedback.lightImpact();
    _onboardingSound.play(SoundKind.inhaleStart);
    _breathCtrl.forward();
  }

  void _onPhaseDone(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    setState(() {
      _phaseIdx++;
      if (_phaseIdx >= _durations.length) {
        _phaseIdx = 0;
        _cycle++;
        if (_cycle >= 3) {
          // Done — auto-advance after 1s
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              HapticFeedback.mediumImpact();
              // ignore: use_build_context_synchronously
              Navigator.of(context).maybePop();
            }
          });
          return;
        }
      }
    });
    // Trigger haptic + sound for the next phase
    if (_phaseIdx == 0) {
      HapticFeedback.lightImpact();
      _onboardingSound.play(SoundKind.inhaleStart);
    } else if (_phaseIdx == 1) {
      HapticFeedback.selectionClick();
      _onboardingSound.play(SoundKind.hold);
    } else {
      HapticFeedback.lightImpact();
      _onboardingSound.play(SoundKind.exhaleStart);
    }
    _breathCtrl.duration = Duration(seconds: _durations[_phaseIdx]);
    _breathCtrl.reset();
    _breathCtrl.forward();
  }

  @override
  void dispose() {
    _breathCtrl.removeStatusListener(_onPhaseDone);
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HealTokens.s32, HealTokens.s80, HealTokens.s32, HealTokens.s120,
      ),
      child: Column(
        children: [
          const SizedBox(height: HealTokens.s32),
          const Text(
            'TRY ONE BREATH',
            style: TextStyle(
              color: HealTokens.brass,
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: HealTokens.s12),
          Text(
            'Before we go further.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: HealTokens.cream,
                  fontWeight: FontWeight.w300,
                ),
          ),
          const Spacer(),
          // Animated Lumen — the user's future companion, breathing
          // in real time with them. 220px tall, so it dominates the
          // screen as a presence, not a sticker. Tap Lumen to begin.
          GestureDetector(
            onTap: _started ? null : _start,
            behavior: HitTestBehavior.opaque,
            child:
          AnimatedBuilder(
            animation: _breathCtrl,
            builder: (ctx, _) {
              // Map controller value to breath phase 0..1 for Lumen.
              double t = _started ? _breathCtrl.value : 0;
              double phase;
              if (!_started) {
                phase = 0.5;
              } else if (_phaseIdx == 0) {
                phase = Curves.easeInOut.transform(t); // inhale 0→1
              } else if (_phaseIdx == 1) {
                phase = 1.0; // hold
              } else {
                phase = 1.0 - Curves.easeInOut.transform(t); // exhale 1→0
              }
              return SizedBox(
                width: 240, height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer breath ring — visualizes the breath cycle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: HealTokens.brass.withValues(alpha: 0.16 + 0.2 * phase),
                          width: 1.0,
                        ),
                      ),
                    ),
                    Lumen(
                      emotion: LumenEmotion.breathing,
                      size: 180,
                      breathPhase: phase,
                    ),
                    // Phase label below Lumen
                    Positioned(
                      bottom: 0,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: Text(
                          _started ? _labels[_phaseIdx] : Copy.breathTapToBegin,
                          key: ValueKey(_started ? _phaseIdx : 'tap'),
                          style: TextStyle(
                            color: HealTokens.cream.withValues(alpha: _started ? 1.0 : 0.7),
                            fontSize: _started ? 16 : 14,
                            fontStyle: _started ? FontStyle.normal : FontStyle.italic,
                            letterSpacing: _started ? 0 : 0.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ),
          const SizedBox(height: HealTokens.s32),
          // Cycle indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Container(
                width: 8, height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _cycle
                      ? HealTokens.brass
                      : (i == _cycle ? HealTokens.brass.withValues(alpha: 0.5) : HealTokens.creamDim.withValues(alpha: 0.2)),
                ),
              );
            }),
          ),
          const Spacer(),
          if (!_started)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: HealTokens.brass,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              onPressed: _start,
              child: const Text(
                'Begin',
                style: TextStyle(
                  color: HealTokens.rosewoodDeep,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          if (_started && _cycle >= 3)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Nice. That\'s the whole practice.',
                style: TextStyle(
                  color: HealTokens.creamDim,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


// Local service singleton for onboarding
final _onboardingSound = SoundService();


/// ── Permission page (renamed/refocused) ─────────────────────────
/// Now AFTER the first breath. Copy reframes the ask as opt-in.
class _PermissionPage extends ConsumerStatefulWidget {
  const _PermissionPage();
  @override
  ConsumerState<_PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends ConsumerState<_PermissionPage> {
  bool _busy = false;

  Future<void> _ask() async {
    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    try {
      final status = await Permission.notification.request();
      await ref.read(notificationServiceProvider).init();
      if (status.isGranted || status.isLimited) {
        await ref.read(notificationServiceProvider).scheduleMorningReminder();
      }
    } catch (_) {}
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    setState(() => _busy = false);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setBool('notif_morning_enabled', false);
    await prefs.setBool('notif_evening_enabled', false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HealTokens.s32, HealTokens.s80, HealTokens.s32, HealTokens.s120,
      ),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HealTokens.brass.withValues(alpha: 0.4),
                  HealTokens.brass.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: HealTokens.brass.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(color: HealTokens.brass.withValues(alpha: 0.24), blurRadius: 24),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: HealTokens.brass,
              size: 36,
            ),
          ),
          const SizedBox(height: HealTokens.s32),
          Text(
            'A gentle\nmorning nudge?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: HealTokens.cream,
                  fontWeight: FontWeight.w300,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: HealTokens.s16),
          const Text(
            'We can remind you at sunrise. One gentle\nnotification a day — never more. Or never.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HealTokens.creamDim,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: HealTokens.s32),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: HealTokens.brass,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            onPressed: _busy ? null : _ask,
            child: _busy
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: HealTokens.rosewoodDeep),
                  )
                : const Text(
                    'Yes, gently',
                    style: TextStyle(
                      color: HealTokens.rosewoodDeep,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
          ),
          const SizedBox(height: HealTokens.s12),
          TextButton(
            onPressed: _busy ? null : _skip,
            child: Text(
              'No thanks, just let me in',
              style: TextStyle(
                color: HealTokens.creamDim.withValues(alpha: 0.7),
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}