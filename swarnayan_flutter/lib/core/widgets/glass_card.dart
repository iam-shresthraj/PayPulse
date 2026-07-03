import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_spacing.dart';
import 'glass_container.dart';

/// A pre-configured glass card with padding, margins, tap effect, and entrance animation.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool animate;
  final int animationIndex;
  final Color? backgroundColor;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = AppSpacing.radiusXl,
    this.animate = true,
    this.animationIndex = 0,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = GlassContainer(
      padding: padding ?? AppSpacing.paddingCard,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: child,
    );

    if (animate) {
      card = card
          .animate()
          .fadeIn(
            duration: 400.ms,
            delay: (100 * animationIndex).ms,
          )
          .slideY(
            begin: 0.05,
            end: 0,
            duration: 400.ms,
            delay: (100 * animationIndex).ms,
            curve: Curves.easeOutCubic,
          );
    }

    return card;
  }
}
