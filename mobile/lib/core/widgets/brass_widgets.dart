// HEAL — Core reusable widgets.
// All widgets follow the brass/rosewood design system.

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Glassy dark card with subtle gradient + soft shadow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? glow;
  final double glowIntensity;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = HealTokens.r20,
    this.padding,
    this.onTap,
    this.glow,
    this.glowIntensity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A201C),
            Color(0xFF2A1815),
          ],
        ),
        border: Border.all(
          color: HealTokens.brass.withValues(alpha: 0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (glow ?? Colors.transparent).withValues(alpha: glowIntensity * 0.16),
            blurRadius: 32,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(HealTokens.s16),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Brass-bordered pill button with embossed feel.
class BrassPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;
  final bool compact;

  const BrassPill({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? HealTokens.brass : Colors.transparent;
    final fg = selected ? HealTokens.rosewoodDeep : HealTokens.cream;
    final border = selected
        ? Colors.transparent
        : HealTokens.brass.withValues(alpha: 0.32);

    return AnimatedContainer(
      duration: HealTokens.d200,
      curve: HealTokens.easeOutQuart,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 999 : 16),
        border: Border.all(color: border, width: 1),
        boxShadow: selected
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
          borderRadius: BorderRadius.circular(compact ? 999 : 16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? HealTokens.s12 : HealTokens.s16,
              vertical: compact ? HealTokens.s6 : HealTokens.s8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: fg),
                  const SizedBox(width: HealTokens.s6),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Big brass-bordered action button (primary CTA).
class BrassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool expanded;
  final bool loading;

  const BrassButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.expanded = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final btn = AnimatedContainer(
      duration: HealTokens.d200,
      curve: HealTokens.easeOutQuart,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HealTokens.brassLight,
            HealTokens.brass,
            HealTokens.brassDeep,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(HealTokens.r16),
        boxShadow: onTap != null
            ? [
                BoxShadow(
                  color: HealTokens.brass.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(HealTokens.r16),
          onTap: loading ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: HealTokens.s24,
              vertical: HealTokens.s16,
            ),
            child: Row(
              mainAxisAlignment: expanded ? MainAxisAlignment.center : MainAxisAlignment.start,
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(HealTokens.rosewoodDeep),
                    ),
                  )
                else if (icon != null) ...[
                  Icon(icon, color: HealTokens.rosewoodDeep, size: 18),
                  const SizedBox(width: HealTokens.s8),
                ],
                if (!loading)
                  Text(
                    label,
                    style:
                        Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: HealTokens.rosewoodDeep,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return btn;
  }
}

/// Section header — small caps + brass underline.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HealTokens.s20,
        HealTokens.s8,
        HealTokens.s20,
        HealTokens.s12,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: HealTokens.brass,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: HealTokens.s8),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                  color: HealTokens.brass,
                ),
          ),
          const Spacer(),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: HealTokens.s8),
              ),
              child: Text(
                action!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: HealTokens.brassLight,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Soft shimmer placeholder.
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.radius = HealTokens.r12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: [
                HealTokens.rosewoodLight,
                HealTokens.rosewood.withValues(alpha: 0.4),
                HealTokens.rosewoodLight,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Small fade-in wrapper used on scroll-into-view.
class FadeInOnMount extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const FadeInOnMount({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = HealTokens.d500,
    this.offsetY = 12,
  });

  @override
  State<FadeInOnMount> createState() => _FadeInOnMountState();
}

class _FadeInOnMountState extends State<FadeInOnMount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: HealTokens.easeOutQuart);
    _offset = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(_opacity);
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}