import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';

/// Frosted-glass surface used by every control card. Applies a backdrop blur,
/// translucent fill, 1 px border, and an optional coloured glow when the
/// underlying device is "on".
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// When non-null, renders a radial glow in this colour (device is on).
  final Color? glowColor;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Dim the card (e.g. for unavailable entities).
  final bool dimmed;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glowColor,
    this.onTap,
    this.onLongPress,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(tokens.cardRadius);

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: radius,
        border: Border.all(color: tokens.glassBorder, width: 1),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.glassBlurSigma,
          sigmaY: tokens.glassBlurSigma,
        ),
        child: card,
      ),
    );

    if (onTap != null || onLongPress != null) {
      card = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          onLongPress: onLongPress,
          child: card,
        ),
      );
    }

    if (dimmed) {
      card = Opacity(opacity: 0.4, child: card);
    }

    return card;
  }
}
