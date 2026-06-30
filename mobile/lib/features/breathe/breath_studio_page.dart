// HEAL — Breath studio.
//
// Production-quality breath pacer with:
//   - AnimationController driving the ring scale + glow + text fade
//   - easeInOutSine on inhale/exhale, hold phases static
//   - Haptic on each phase change (light impact on inhale/exhale)
//   - In-pocket mode: gentler haptic + dimmer screen for use without looking
//   - Voice-calibrated profile (if user has run voice calibration)
//   - 5 patterns: Gentle 4-4-6-2, 4·7·8, Box, Resonant, Coherent
//   - Cycle counter + total elapsed time + total breaths
//   - Background gradient that shifts with phase color
//   - Subtle pulse for "alive" feel

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/theme.dart';
import '../../core/time_palette.dart';
import '../../core/widgets/breath_ring.dart';
import '../../services/streak_service.dart';
import '../../services/voice_calibration_service.dart';

class BreathPattern {
  final String id;
  final String name;
  final String description;
  final int inhaleSeconds;
  final int holdInSeconds;
  final int exhaleSeconds;
  final int holdOutSeconds;

  const BreathPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.inhaleSeconds,
    required this.holdInSeconds,
    required this.exhaleSeconds,
    required this.holdOutSeconds,
  });

  int get totalSeconds =>
      inhaleSeconds + holdInSeconds + exhaleSeconds + holdOutSeconds;
}

const _defaultPatterns = <BreathPattern>[
  BreathPattern(
    id: '4-4-6-2',
    name: 'Gentle',
    description: 'A kind, easy breath. Begin where you are.',
    inhaleSeconds: 4,
    holdInSeconds: 4,
    exhaleSeconds: 6,
    holdOutSeconds: 2,
  ),
  BreathPattern(
    id: '4-7-8',
    name: '4·7·8',
    description: 'Dr. Weil\'s calming breath. Long exhale, deep rest.',
    inhaleSeconds: 4,
    holdInSeconds: 7,
    exhaleSeconds: 8,
    holdOutSeconds: 0,
  ),
  BreathPattern(
    id: 'box',
    name: 'Box',
    description: 'Equal counts in all four phases. Steady, grounding.',
    inhaleSeconds: 4,
    holdInSeconds: 4,
    exhaleSeconds: 4,
    holdOutSeconds: 4,
  ),
  BreathPattern(
    id: 'resonant',
    name: 'Resonant',
    description: '5.5 breaths per minute. The body\'s natural rhythm.',
    inhaleSeconds: 5,
    holdInSeconds: 0,
    exhaleSeconds: 5,
    holdOutSeconds: 0,
  ),
  BreathPattern(
    id: 'coherent',
    name: 'Coherent',
    description: 'Six per minute. Heart-brain coherence.',
    inhaleSeconds: 5,
    holdInSeconds: 2,
    exhaleSeconds: 5,
    holdOutSeconds: 0,
  ),
  BreathPattern(
    id: 'personal',
    name: 'Personal',
    description: 'Your breath, your rhythm. Run voice calibration to enable.',
    inhaleSeconds: 5,
    holdInSeconds: 0,
    exhaleSeconds: 6,
    holdOutSeconds: 0,
  ),
];

final breathPatternListProvider = Provider<List<BreathPattern>>(
  (_) => _defaultPatterns,
);

final _activePhaseProvider = StateProvider<BreathPhase>(
  (_) => BreathPhase.ready,
);

class BreathStudioPage extends HookConsumerWidget {
  const BreathStudioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPattern = useState<BreathPattern>(_defaultPatterns.first);
    final isRunning = useState<bool>(false);
    final isPocketMode = useState<bool>(false);
    final cycleCount = useState<int>(0);
    final elapsedSeconds = useState<int>(0);
    final sessionStart = useState<DateTime?>(null);
    final palette = ref.watch(timePaletteProvider);

    // Personal pattern uses voice calibration
    useEffect(() {
      if (selectedPattern.value.id == 'personal') {
        final cal = ref.read(voiceCalibrationServiceProvider);
        if (cal.hasProfile) {
          selectedPattern.value = BreathPattern(
            id: 'personal',
            name: 'Personal',
            description: 'Your breath, your rhythm.',
            inhaleSeconds: cal.savedInhaleSeconds!,
            holdInSeconds: 0,
            exhaleSeconds: cal.savedExhaleSeconds!,
            holdOutSeconds: 0,
          );
        }
      }
      return null;
    }, [selectedPattern.value.id]);

    Future<void> startSession() async {
      isRunning.value = true;
      sessionStart.value = DateTime.now();
      HapticFeedback.mediumImpact();
    }

    Future<void> stopSession() async {
      isRunning.value = false;
      // Record the session
      if (sessionStart.value != null) {
        final secs = DateTime.now().difference(sessionStart.value!).inSeconds;
        if (secs >= 30) {
          // ignore: discarded_futures
          ref.read(streakServiceProvider.notifier).recordSession(SessionRecord(
                timestamp: DateTime.now(),
                type: SessionType.breath,
                durationSeconds: secs,
              ));
        }
        sessionStart.value = null;
      }
      HapticFeedback.heavyImpact();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(selectedPattern.value.name,
            style: Theme.of(context).textTheme.titleLarge),
        actions: [
          // Pocket mode toggle
          IconButton(
            icon: Icon(
              isPocketMode.value
                  ? Icons.brightness_2_rounded
                  : Icons.brightness_5_rounded,
            ),
            tooltip: isPocketMode.value ? 'Exit pocket mode' : 'Pocket mode',
            onPressed: () {
              isPocketMode.value = !isPocketMode.value;
              HapticFeedback.selectionClick();
            },
          ),
          if (isRunning.value)
            Padding(
              padding: const EdgeInsets.only(right: HealTokens.s16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('cycle ${cycleCount.value}',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(_formatDuration(elapsedSeconds.value),
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Adaptive phase background
          Consumer(
            builder: (context, ref, _) {
              final phase = ref.watch(_activePhaseProvider);
              return AnimatedContainer(
                duration: HealTokens.d1200,
                curve: HealTokens.easeInOutSine,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      isPocketMode.value
                          ? palette.glow.withValues(alpha: 0.04)
                          : phase.glowColor.withValues(alpha: 0.16),
                      palette.background,
                    ],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _BreathRunner(
                    pattern: selectedPattern.value,
                    isRunning: isRunning,
                    isPocketMode: isPocketMode,
                    onCycle: () => cycleCount.value++,
                    onTick: () => elapsedSeconds.value++,
                  ),
                ),
                _PatternPicker(
                  selected: selectedPattern.value,
                  disabled: isRunning.value,
                  onSelect: (p) => selectedPattern.value = p,
                ),
                const SizedBox(height: HealTokens.s32),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HealTokens.s32,
                  ),
                  child: isRunning.value
                      ? OutlinedButton.icon(
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('END SESSION'),
                          onPressed: stopSession,
                        )
                      : FilledButton.icon(
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('BEGIN'),
                          onPressed: startSession,
                        ),
                ),
                const SizedBox(height: HealTokens.s48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _BreathRunner extends HookConsumerWidget {
  final BreathPattern pattern;
  final ValueNotifier<bool> isRunning;
  final ValueNotifier<bool> isPocketMode;
  final VoidCallback onCycle;
  final VoidCallback onTick;

  const _BreathRunner({
    required this.pattern,
    required this.isRunning,
    required this.isPocketMode,
    required this.onCycle,
    required this.onTick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phaseCtrl = useAnimationController(
      duration: const Duration(seconds: 1),
    );
    final pulseCtrl = useAnimationController(
      duration: const Duration(milliseconds: 4000),
    );

    final phase = useState<BreathPhase>(BreathPhase.ready);
    final tickInterval = useRef<Timer?>(null);
    final breathCount = useState<int>(0);
    final isMounted = useRef<bool>(true);
    useEffect(() {
      isMounted.value = true;
      return () => isMounted.value = false;
    }, const []);

    Future<void> runPhase(BreathPhase next, int seconds) async {
      if (!isRunning.value) return;
      phase.value = next;
      if (isMounted.value) ref.read(_activePhaseProvider.notifier).state = next;

      // In-pocket mode uses selectionClick (more subtle)
      // Standard mode uses lightImpact (more present)
      if (next == BreathPhase.inhale || next == BreathPhase.exhale) {
        if (isPocketMode.value) {
          await HapticFeedback.selectionClick();
        } else {
          await HapticFeedback.lightImpact();
        }
      }

      if (seconds == 0) return;
      phaseCtrl.duration = Duration(seconds: seconds);
      phaseCtrl.value = 0;
      phaseCtrl.forward();
    }

    useEffect(() {
      if (!isRunning.value) {
        phaseCtrl.stop();
        phase.value = BreathPhase.ready;
        if (isMounted.value) {
          ref.read(_activePhaseProvider.notifier).state = BreathPhase.ready;
        }
        tickInterval.value?.cancel();
        return null;
      }

      Future<void> chain() async {
        while (isRunning.value) {
          await runPhase(BreathPhase.inhale, pattern.inhaleSeconds);
          await Future.delayed(Duration(seconds: pattern.inhaleSeconds));
          if (!isRunning.value) break;
          if (pattern.holdInSeconds > 0) {
            await runPhase(BreathPhase.holdIn, pattern.holdInSeconds);
            await Future.delayed(Duration(seconds: pattern.holdInSeconds));
            if (!isRunning.value) break;
          }
          await runPhase(BreathPhase.exhale, pattern.exhaleSeconds);
          await Future.delayed(Duration(seconds: pattern.exhaleSeconds));
          if (!isRunning.value) break;
          if (pattern.holdOutSeconds > 0) {
            await runPhase(BreathPhase.holdOut, pattern.holdOutSeconds);
            await Future.delayed(Duration(seconds: pattern.holdOutSeconds));
            if (!isRunning.value) break;
          }
          if (!isMounted.value) break;
          onCycle();
          breathCount.value++;
          await runPhase(BreathPhase.inhale, pattern.inhaleSeconds);
        }
      }
      // ignore: discarded_futures
      chain();

      tickInterval.value?.cancel();
      tickInterval.value =
          Timer.periodic(const Duration(seconds: 1), (_) => onTick());

      return () {
        tickInterval.value?.cancel();
      };
    }, [isRunning.value, pattern.id]);

    useEffect(() {
      pulseCtrl.repeat();
      return null;
    }, []);

    double computeScale() {
      final v = phaseCtrl.value;
      switch (phase.value) {
        case BreathPhase.inhale:
          return 0.8 + 0.8 * Curves.easeInOutSine.transform(v);
        case BreathPhase.holdIn:
          return 1.6;
        case BreathPhase.exhale:
          return 1.6 - 0.8 * Curves.easeInOutSine.transform(v);
        case BreathPhase.holdOut:
          return 0.8;
        case BreathPhase.ready:
          return 1.0;
      }
    }

    final ringSize = isPocketMode.value ? 240.0 : 320.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([phaseCtrl, pulseCtrl]),
          builder: (context, _) {
            return CustomPaint(
              size: Size.square(ringSize),
              painter: BreathRingPainter(
                progress: phaseCtrl.value,
                phase: phase.value,
                phaseProgress: phaseCtrl.value,
                ringScale: computeScale(),
                pulse: pulseCtrl.value,
              ),
            );
          },
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: HealTokens.d400,
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                );
              },
              child: Text(
                phase.value.label,
                key: ValueKey(phase.value),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: HealTokens.cream,
                      fontWeight: FontWeight.w300,
                    ),
              ),
            ),
            const SizedBox(height: HealTokens.s8),
            AnimatedSwitcher(
              duration: HealTokens.d400,
              child: Text(
                phase.value.instruction,
                key: ValueKey('${phase.value}_instr'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HealTokens.creamDim,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
            if (isPocketMode.value && isRunning.value) ...[
              const SizedBox(height: HealTokens.s16),
              // In pocket mode, also show breath count as a haptic-friendly indicator
              Text(
                '${breathCount.value} breaths',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: HealTokens.brass,
                      letterSpacing: 2.0,
                    ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PatternPicker extends ConsumerWidget {
  final BreathPattern selected;
  final bool disabled;
  final ValueChanged<BreathPattern> onSelect;

  const _PatternPicker({
    required this.selected,
    required this.disabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPersonal = ref.watch(voiceCalibrationServiceProvider.select(
      (s) => s.hasProfile,
    ));
    final patterns = hasPersonal
        ? _defaultPatterns
        : _defaultPatterns.where((p) => p.id != 'personal').toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: HealTokens.s16),
      child: Row(
        children: patterns.map((p) {
          final isSelected = p.id == selected.id;
          final isDisabled = p.id == 'personal' && !hasPersonal;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: HealTokens.s4),
            child: AnimatedContainer(
              duration: HealTokens.d200,
              decoration: BoxDecoration(
                color: isSelected
                    ? HealTokens.brass
                    : HealTokens.rosewoodLight,
                borderRadius: BorderRadius.circular(HealTokens.r16),
                border: Border.all(
                  color: isSelected
                      ? HealTokens.brass
                      : HealTokens.brass.withValues(alpha: 0.24),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: HealTokens.brass.withValues(alpha: 0.32),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(HealTokens.r16),
                  onTap: (disabled || isDisabled) ? null : () => onSelect(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HealTokens.s16,
                      vertical: HealTokens.s12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.id == 'personal') ...[
                          Icon(
                            Icons.record_voice_over_rounded,
                            size: 14,
                            color: isSelected
                                ? HealTokens.rosewoodDeep
                                : HealTokens.brass,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          p.name,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: isSelected
                                    ? HealTokens.rosewoodDeep
                                    : HealTokens.cream,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}