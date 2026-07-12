import 'package:flutter/material.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';

/// The single power affordance in detailed control-card headers: a circular
/// glass icon button with a power glyph. When off it renders the glyph in the
/// muted foreground on the glass fill; when on it renders with the accent fill.
/// Deliberately not a Material `Switch` (D11). Hit target is at least 48 dp.
class PowerToggle extends StatelessWidget {
  final bool isOn;

  /// Invoked on tap. When null the control renders disabled (non-interactive).
  final VoidCallback? onTap;

  const PowerToggle({super.key, required this.isOn, this.onTap});

  static const double _hitTarget = 48;
  static const double _diameter = 40;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = onTap != null;

    final glyphColor = isOn
        ? const Color(0xFF1A1A1A)
        : tokens.offMuted;

    final Widget button = Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOn ? tokens.onAccent : tokens.glassFill,
        border: Border.all(color: tokens.glassBorder, width: 1),
      ),
      child: Icon(Icons.power_settings_new, size: 20, color: glyphColor),
    );

    return Semantics(
      button: true,
      toggled: isOn,
      label: 'Power',
      child: SizedBox(
        width: _hitTarget,
        height: _hitTarget,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Opacity(opacity: enabled ? 1 : 0.4, child: button),
            ),
          ),
        ),
      ),
    );
  }
}
