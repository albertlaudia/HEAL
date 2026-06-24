// Breath studio — animated breathing core with phase progress ring.
// Mirrors /web's BreathStudio.tsx redesign.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BreathStudioPage extends HookConsumerWidget {
  const BreathStudioPage({required this.pattern, super.key});
  final String pattern;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Breath · $pattern')),
      body: const _BreathCore(),
    );
  }
}

class _BreathCore extends HookConsumerWidget {
  const _BreathCore();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = useState<String>('ready');
    final cycle = useState<int>(0);

    void start() {
      phase.value = 'inhale';
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (!context.mounted) return;
        phase.value = 'hold-in';
        Future<void>.delayed(const Duration(seconds: 4), () {
          if (!context.mounted) return;
          phase.value = 'exhale';
          Future<void>.delayed(const Duration(seconds: 6), () {
            if (!context.mounted) return;
            phase.value = 'hold-out';
            Future<void>.delayed(const Duration(seconds: 2), () {
              if (!context.mounted) return;
              cycle.value += 1;
              start();
            });
          });
        });
      });
    }

    final scale = switch (phase.value) {
      'inhale' => 1.6,
      'exhale' => 0.8,
      _ => 1.0,
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedScale(
            duration: const Duration(seconds: 4),
            scale: scale,
            curve: Curves.easeInOut,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: <Color>[Color(0xFFB08C4F), Color(0xFF7C4A4A)],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFFB08C4F).withValues(alpha: 0.4),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            switch (phase.value) {
              'inhale' => 'Fill the belly, not the chest',
              'hold-in' => 'Stillness at the top',
              'exhale' => 'Release what you are carrying',
              'hold-out' => 'A small holy pause',
              _ => 'When you are ready',
            },
            style: const TextStyle(fontSize: 16),
          ).animate(key: ValueKey(phase.value)).fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          Text('cycle ${cycle.value}'),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: phase.value == 'ready' ? start : null,
            child: const Text('Begin'),
          ),
        ],
      ),
    );
  }
}
