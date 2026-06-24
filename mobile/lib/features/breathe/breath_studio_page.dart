// HEAL — Breath studio.
//
// Production-quality breath pacer with:
//   - AnimationController driving the ring scale + glow + text fade
//   - Phase transitions: easeInOutSine on inhale/exhale, hold uses no curve
//   - Haptic on each phase change (light impact on inhale/exhale)
//   - Customizable pattern (4-7-8, box, resonant, coherent)
//   - Cycle counter + total elapsed time
//   - Background gradient that shifts with phase
//   - Subtle pulse for "alive" feel

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../core/theme.dart';
import '../../core/widgets/breath_ring.dart';

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
    final cycleCount = useState<int>(0);
    final elapsedSeconds = useState<int>(0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(selectedPattern.value.name,
            style: Theme.of(context).textTheme.titleLarge),
        actions: [
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
          // Phase background
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
                      phase.glowColor.withValues(alpha: 0.16),
                      HealTokens.rosewoodDeep,
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
                          onPressed: () => isRunning.value = false,
                        )
                      : FilledButton.icon(
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('BEGIN'),
                          onPressed: () => isRunning.value = true,
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
  final VoidCallback onCycle;
  final VoidCallback onTick;

  const _BreathRunner({
    required this.pattern,
    required this.isRunning,
    required this.onCycle,
    required this.onTick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Master phase controller — drives the ring scale.
    final phaseCtrl = useAnimationController(
      duration: const Duration(seconds: 1),
    );
    final pulseCtrl = useAnimationController(
      duration: const Duration(milliseconds: 4000),
    );

    final phase = useState<BreathPhase>(BreathPhase.ready);
    final phaseProgress = useState<double>(0);
    final tickInterval = useRef<Timer?>(null);

    // Step through phases sequentially.
    Future<void> runPhase(BreathPhase next, int seconds) async {
      if (!isRunning.value) return;
      phase.value = next;
      ref.read(_activePhaseProvider.notifier).state = next;

      // Haptic on phase change (skip ready and silent holds for less noise).
      if (next == BreathPhase.inhale || next == BreathPhase.exhale) {
        await HapticFeedback.lightImpact();
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
        ref.read(_activePhaseProvider.notifier).state = BreathPhase.ready;
        phaseProgress.value = 0;
        tickInterval.value?.cancel();
        return;
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
          onCycle();
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

    // Compute ring scale as a function of phase + phaseCtrl value.
    double computeScale() {
      final v = phaseCtrl.value;
      switch (phase.value) {
        case BreathPhase.inhale:
          phaseProgress.value = v;
          return 0.8 + 0.8 * Curves.easeInOutSine.transform(v);
        case BreathPhase.holdIn:
          phaseProgress.value = v;
          return 1.6;
        case BreathPhase.exhale:
          phaseProgress.value = v;
          return 1.6 - 0.8 * Curves.easeInOutSine.transform(v);
        case BreathPhase.holdOut:
          phaseProgress.value = v;
          return 0.8;
        case BreathPhase.ready:
          return 1.0;
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([phaseCtrl, pulseCtrl]),
          builder: (context, _) {
            return CustomPaint(
              size: const Size.square(320),
              painter: BreathRingPainter(
                progress: phaseCtrl.value,
                phase: phase.value,
                phaseProgress: phaseProgress.value,
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
          ],
        ),
      ],
    );
  }
}

class _PatternPicker extends StatelessWidget {
  final BreathPattern selected;
  final bool disabled;
  final ValueChanged<BreathPattern> onSelect;

  const _PatternPicker({
    required this.selected,
    required this.disabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: HealTokens.s16),
      child: Row(
        children: _defaultPatterns.map((p) {
          final isSelected = p.id == selected.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: HealTokens.s4),
            child: AnimatedContainer(
              duration: HealTokens.d200,
              decoration: BoxDecoration(
                color:
                    isSelected ? HealTokens.brass : HealTokens.rosewoodLight,
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
                  onTap: disabled ? null : () => onSelect(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HealTokens.s16,
                      vertical: HealTokens.s12,
                    ),
                    child: Text(
                      p.name,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isSelected
                                ? HealTokens.rosewoodDeep
                                : HealTokens.cream,
                          ),
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