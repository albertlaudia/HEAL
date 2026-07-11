// HEAL — EdgeGlow
// ============================================================================
// A 2-pixel-tall band along the top of the screen whose color is the
// user's current emotion. Like a soft mood-light running across the
// device. Adds a quiet "the app knows what I'm doing" feeling without
// being intrusive.
// ============================================================================

import 'package:flutter/material.dart';

import 'emotion_palette.dart';
import 'lumen.dart';
import 'motion.dart';

class EdgeGlow extends StatelessWidget {
  final EmotionPalette palette;
  final bool top;
  final double intensity;
  const EdgeGlow({
    super.key,
    required this.palette,
    this.top = true,
    this.intensity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: HealMotion.slideMedium,
          curve: HealMotion.standardEasing,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                palette.primary.withValues(alpha: 0),
                palette.primary.withValues(alpha: intensity),
                palette.primary.withValues(alpha: 0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: intensity * 0.5),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
