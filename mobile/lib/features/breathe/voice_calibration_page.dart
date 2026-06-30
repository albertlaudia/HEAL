// HEAL — Voice calibration page.
//
// UI for the breath-voice calibration flow. Shows:
//   - Big amber waveform (live mic amplitude)
//   - Phase indicator (Get ready → Breathe in → Breathe out → Done)
//   - Detected durations
//   - Skip / Cancel options

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/time_palette.dart';
import '../../services/voice_calibration_service.dart';

class VoiceCalibrationPage extends HookConsumerWidget {
  const VoiceCalibrationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cal = ref.watch(voiceCalibrationServiceProvider);
    final controller = ref.read(voiceCalibrationServiceProvider.notifier);
    final palette = ref.watch(timePaletteProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Voice Calibration'),
        actions: [
          if (cal.phase != CalibrationPhase.idle)
            TextButton(
              onPressed: () => controller.cancel(),
              child: const Text('CANCEL',
                  style: TextStyle(color: HealTokens.creamDim)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HealTokens.s24),
          child: cal.phase == CalibrationPhase.idle
              ? _IdleView(hasProfile: cal.hasProfile)
              : _ActiveCalibrationView(state: cal, palette: palette),
        ),
      ),
    );
  }
}

class _IdleView extends ConsumerWidget {
  final bool hasProfile;
  const _IdleView({required this.hasProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(timePaletteProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        // Icon
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.primary.withValues(alpha: 0.4), palette.primary.withValues(alpha: 0.1)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: palette.primary.withValues(alpha: 0.4)),
          ),
          child: Icon(
            Icons.air_rounded,
            color: palette.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: HealTokens.s32),
        Text(
          'Learn your breath',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: HealTokens.cream,
                fontWeight: FontWeight.w300,
              ),
        ),
        const SizedBox(height: HealTokens.s16),
        Text(
          'HEAL can pace itself to YOUR natural rhythm. Take a slow breath in, then out. We\'ll measure the time.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: HealTokens.creamDim,
                height: 1.6,
              ),
        ),
        if (hasProfile) ...[
          const SizedBox(height: HealTokens.s24),
          Container(
            padding: const EdgeInsets.all(HealTokens.s16),
            decoration: BoxDecoration(
              color: HealTokens.rosewoodLight,
              borderRadius: BorderRadius.circular(HealTokens.r16),
              border: Border.all(color: HealTokens.brass.withValues(alpha: 0.24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: HealTokens.brass, size: 20),
                const SizedBox(width: HealTokens.s12),
                Expanded(
                  child: Text(
                    'Current profile saved',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HealTokens.cream,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: HealTokens.s48),
        const Spacer(),
        // CTA
        FilledButton.icon(
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(hasProfile ? 'RECALIBRATE' : 'BEGIN'),
          onPressed: () {
            HapticFeedback.mediumImpact();
            ref.read(voiceCalibrationServiceProvider.notifier).start();
          },
        ),
        if (hasProfile) ...[
          const SizedBox(height: HealTokens.s12),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('CLEAR PROFILE'),
            onPressed: () async {
              await ref.read(voiceCalibrationServiceProvider.notifier).clearProfile();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile cleared.')),
                );
              }
            },
          ),
        ],
        const SizedBox(height: HealTokens.s16),
        Text(
          'No audio is recorded or uploaded. Only the length of your breath is stored locally on this device.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HealTokens.creamDim,
                fontStyle: FontStyle.italic,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: HealTokens.s24),
      ],
    );
  }
}

class _ActiveCalibrationView extends StatelessWidget {
  final CalibrationState state;
  final TimePalette palette;
  const _ActiveCalibrationView({required this.state, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        // Phase label
        Text(
          _phaseLabel(state.phase),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: HealTokens.cream,
                fontWeight: FontWeight.w300,
              ),
        ),
        const SizedBox(height: HealTokens.s16),
        Text(
          state.message ?? '',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: HealTokens.creamDim,
                fontStyle: FontStyle.italic,
              ),
        ),
        const SizedBox(height: HealTokens.s48),

        // Big amplitude meter
        AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 280 * (state.amplitude ?? 0.05).clamp(0.05, 1.0),
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.primary, palette.accent],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        const SizedBox(height: HealTokens.s8),
        Text(
          state.amplitude != null && state.amplitude! > 0.2
              ? 'I can hear you'
              : 'Stay close to the mic',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HealTokens.creamDim,
              ),
        ),

        const SizedBox(height: HealTokens.s48),

        // Count-in countdown
        if (state.phase == CalibrationPhase.countIn)
          Text(
            '${state.countInSecondsLeft}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: palette.primary,
                  fontWeight: FontWeight.w200,
                ),
          ),

        // Detected durations
        if (state.inhaleSeconds > 0 || state.exhaleSeconds > 0) ...[
          const SizedBox(height: HealTokens.s32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DurationBadge(
                label: 'IN',
                seconds: state.inhaleSeconds,
                palette: palette,
              ),
              const SizedBox(width: HealTokens.s24),
              _DurationBadge(
                label: 'OUT',
                seconds: state.exhaleSeconds,
                palette: palette,
              ),
            ],
          ),
        ],

        if (state.error != null) ...[
          const SizedBox(height: HealTokens.s24),
          Container(
            padding: const EdgeInsets.all(HealTokens.s16),
            decoration: BoxDecoration(
              color: HealTokens.rosewoodLight,
              borderRadius: BorderRadius.circular(HealTokens.r12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: HealTokens.ember, size: 20),
                const SizedBox(width: HealTokens.s12),
                Expanded(
                  child: Text(
                    state.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HealTokens.cream,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        // Done button
        if (state.phase == CalibrationPhase.done)
          FilledButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: const Text('USE THIS RHYTHM'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),

        // Skip manual control
        if (state.phase == CalibrationPhase.inhale ||
            state.phase == CalibrationPhase.exhale)
          _StopPhaseButton(palette: palette, phase: state.phase),
      ],
    );
  }

  String _phaseLabel(CalibrationPhase p) {
    switch (p) {
      case CalibrationPhase.requestingPermission:
        return '…';
      case CalibrationPhase.countIn:
        return 'Get ready';
      case CalibrationPhase.inhale:
        return 'Breathe in';
      case CalibrationPhase.exhale:
        return 'Breathe out';
      case CalibrationPhase.done:
        return 'Your rhythm';
      case CalibrationPhase.idle:
        return '';
    }
  }
}

class _StopPhaseButton extends ConsumerWidget {
  final TimePalette palette;
  final CalibrationPhase phase;
  const _StopPhaseButton({required this.palette, required this.phase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => ref.read(voiceCalibrationServiceProvider.notifier).stopCurrentPhase(),
      child: Text(
        phase == CalibrationPhase.inhale
            ? 'I FINISHED INHALING'
            : 'I FINISHED EXHALING',
        style: TextStyle(color: palette.primary, letterSpacing: 2),
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  final String label;
  final int seconds;
  final TimePalette palette;

  const _DurationBadge({
    required this.label,
    required this.seconds,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: HealTokens.s16,
            vertical: HealTokens.s8,
          ),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(HealTokens.r12),
            border: Border.all(color: palette.primary.withValues(alpha: 0.32)),
          ),
          child: Text(
            '${seconds}s',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: palette.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: HealTokens.creamDim,
                letterSpacing: 2,
              ),
        ),
      ],
    );
  }
}