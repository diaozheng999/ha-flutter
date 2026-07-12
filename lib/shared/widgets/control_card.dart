import 'package:flutter/material.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// The single card anatomy every detailed device control is built from. Composes
/// [GlassCard] with a fixed, compact header — leading icon, name, an optional
/// live status line, and a trailing slot (the power toggle by default) — above
/// an optional [body] holding the detailed controls.
///
/// Renders state layers 1–4: availability dims (40%) and disables the card;
/// the on/off treatment tints the icon and, when [glowColor] is supplied,
/// applies the rationed radial glow (D10); the body holds the control surface.
class ControlCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String? status;
  final Widget? trailing;
  final Widget? body;

  /// Whether the device is on (accent icon tint).
  final bool isOn;

  /// Whether the device is unavailable (dim + disable everything).
  final bool unavailable;

  /// Rationed glow colour (D10). Null for devices that signal "on" through the
  /// accent treatment only (fan, purifier) or that are off/unavailable.
  final Color? glowColor;

  final EdgeInsetsGeometry padding;

  const ControlCard({
    super.key,
    required this.icon,
    required this.name,
    this.status,
    this.trailing,
    this.body,
    this.isOn = false,
    this.unavailable = false,
    this.glowColor,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final header = Row(
      children: [
        Icon(icon, size: 22, color: isOn ? tokens.onAccent : tokens.offMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (status != null)
                Text(
                  status!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: tokens.offMuted),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );

    return GlassCard(
      padding: padding,
      glowColor: unavailable ? null : glowColor,
      dimmed: unavailable,
      child: IgnorePointer(
        ignoring: unavailable,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (body != null) ...[
              const SizedBox(height: 12),
              body!,
            ],
          ],
        ),
      ),
    );
  }
}
