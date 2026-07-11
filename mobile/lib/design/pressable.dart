// HEAL — Pressable
// ============================================================================
// Every primary action in HEAL goes through this. Spring-physics scale
// on press, soft haptic, and a subtle brightness shift. The feel of a
// real button — not a Material InkWell, but a *heavier*, more deliberate
// object. Like pressing a stone into a sand garden.
//
// Usage:
//   Pressable(
//     onTap: () => ...,
//     child: Container(...),
//   )
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion.dart';

class Pressable extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final double pressedScale;
  final Duration animationDuration;
  final bool hapticOnPress;
  final HitTestBehavior behavior;
  final BorderRadius? borderRadius;
  final Color? pressedOverlay;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.animationDuration = const Duration(milliseconds: 140),
    this.hapticOnPress = true,
    this.behavior = HitTestBehavior.opaque,
    this.borderRadius,
    this.pressedOverlay,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(20);
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap == null ? null : (_) {
        if (widget.hapticOnPress) HapticFeedback.selectionClick();
        setState(() => _pressed = true);
      },
      onTapUp: widget.onTap == null ? null : (_) {
        setState(() => _pressed = false);
      },
      onTapCancel: widget.onTap == null ? null : () {
        setState(() => _pressed = false);
      },
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.animationDuration,
        curve: HealMotion.standardEasing,
        child: AnimatedContainer(
          duration: widget.animationDuration,
          curve: HealMotion.standardEasing,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: _pressed
                ? (widget.pressedOverlay ?? Colors.white.withValues(alpha: 0.04))
                : Colors.transparent,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
