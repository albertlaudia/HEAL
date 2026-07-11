// HEAL — Milestone celebration overlay.
//
// Confetti is for birthdays. We don't do that here.
//
// What we do: a single brass-gold burst, Lumen radiating a star-glyph,
// the milestone text rising slowly, then settling into the page. Reverent.
// Like a candle catching the wind for a moment.
//
// Trigger: showMilestoneOverlay(context, title: ..., body: ..., icon: '🌱')

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import 'lumen.dart';
import 'motion.dart';

class MilestoneOverlay extends StatefulWidget {
  final String title;
  final String body;
  final String? subtitle;
  final IconData? icon;
  final Duration duration;
  const MilestoneOverlay({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.icon,
    this.duration = const Duration(milliseconds: 2200),
  });

  @override
  State<MilestoneOverlay> createState() => _MilestoneOverlayState();
}

class _MilestoneOverlayState extends State<MilestoneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _lumenIn;
  late final Animation<double> _textIn;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _controller, curve: HealMotion.standardEasing);
    _lumenIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: HealMotion.standardEasing),
    );
    _textIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.85, curve: HealMotion.decelerate),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(_textIn);
    HapticFeedback.heavyImpact();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: HealTokens.scrim,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1.0).animate(_lumenIn),
                child: const Lumen(
                  emotion: LumenEmotion.celebrating,
                  size: 96,
                  celebration: 1.0,
                ),
              ),
              const SizedBox(height: HealTokens.s24),
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textIn,
                  child: Column(
                    children: [
                      if (widget.subtitle != null) ...[
                        Text(
                          widget.subtitle!.toUpperCase(),
                          style: const TextStyle(
                            color: HealTokens.brass,
                            fontSize: 11,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: HealTokens.cream,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 280,
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          widget.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: HealTokens.creamDim.withValues(alpha: 0.9),
                            fontSize: 14,
                            height: 1.5,
                          ),
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
}

/// Show a milestone overlay. Returns when dismissed.
Future<void> showMilestoneOverlay(
  BuildContext context, {
  required String title,
  required String body,
  String? subtitle,
  IconData? icon,
  Duration duration = const Duration(milliseconds: 2200),
}) async {
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Milestone',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (ctx, anim, sec) => MilestoneOverlay(
      title: title, body: body, subtitle: subtitle, icon: icon, duration: duration,
    ),
    transitionBuilder: (ctx, anim, sec, child) => FadeTransition(opacity: anim, child: child),
  );
  await Future.delayed(duration);
  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  }
}
