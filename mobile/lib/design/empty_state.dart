// HEAL — Reusable empty-state widget
//
// Empty states are not errors. They are the *first* invitation the user
// sees in a new section. Tone: gentle, reverent, concrete. No "Oops!" or
// exclamation marks. No clip-art illustrations. One Lumen at the center
// or a single serif italic line.
//
// Layout:
//   [Lumen (emotion: weary or resting)]    ← small, centered
//   Title                                    ← 22pt, cream, no exclamation
//   Body                                     ← 14pt, creamDim
//   [CTA pill] (optional)                    ← outlined, brass border
//
// Used by: praise library (when no favorites), stickers (when 0 earned),
// sleep stories (when no profile), profile (when no sessions).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import 'lumen.dart';

class EmptyState extends StatelessWidget {
  final LumenEmotion lumenEmotion;
  final String title;
  final String body;
  final String? ctaLabel;
  final VoidCallback? ctaOnTap;
  final IconData? ctaIcon;

  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.lumenEmotion = LumenEmotion.resting,
    this.ctaLabel,
    this.ctaOnTap,
    this.ctaIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: HealTokens.s40, vertical: HealTokens.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            LumenSlot(
              emotion: lumenEmotion,
              size: 72,
              dimmed: true,
            ),
            const SizedBox(height: HealTokens.s24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: HealTokens.cream,
                fontSize: 22,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
                height: 1.3,
              ),
            ),
            const SizedBox(height: HealTokens.s12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HealTokens.creamDim.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (ctaLabel != null && ctaOnTap != null) ...[
              const SizedBox(height: HealTokens.s24),
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ctaOnTap!();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HealTokens.s24, vertical: HealTokens.s12,
                  ),
                  side: BorderSide(color: HealTokens.brass.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ctaIcon != null) ...[
                      Icon(ctaIcon, size: 16, color: HealTokens.brass),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      ctaLabel!,
                      style: const TextStyle(
                        color: HealTokens.brass,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
