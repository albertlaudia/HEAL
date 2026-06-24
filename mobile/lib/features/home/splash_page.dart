// HEAL — Splash page.
// Brass "R" logomark fades up over rosewood, then transitions to home.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: HealTokens.rosewoodDeep,
      body: Stack(
        children: [
          // Soft brass radial behind logo
          Positioned.fill(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      HealTokens.brass.withValues(alpha: 0.16),
                      HealTokens.brass.withValues(alpha: 0),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [HealTokens.brassLight, HealTokens.brass, HealTokens.brassDeep],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: HealTokens.brass.withValues(alpha: 0.4),
                        blurRadius: 32,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'H',
                    style: TextStyle(
                      fontFamily: 'Cormorant Garamond',
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      color: HealTokens.rosewoodDeep,
                    ),
                  ),
                ).animate().scale(
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
                const SizedBox(height: HealTokens.s24),
                Text(
                  'HEAL',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: HealTokens.cream,
                        letterSpacing: 12,
                        fontWeight: FontWeight.w300,
                      ),
                ).animate(delay: 200.ms).fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: HealTokens.s8),
                Text(
                  'a quiet practice',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HealTokens.creamDim,
                        letterSpacing: 2,
                        fontStyle: FontStyle.italic,
                      ),
                ).animate(delay: 600.ms).fadeIn(duration: 800.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}