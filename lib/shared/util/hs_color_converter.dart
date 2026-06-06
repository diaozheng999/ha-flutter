import 'package:flutter/material.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';

/// Converts Home Assistant `hs_color` values into Flutter [Color]s for the
/// glassmorphic glow effect described in the design.
class HsColorConverter {
  HsColorConverter._();

  /// Default glow tuning per design: saturation clamped to 0.6, lightness 0.45.
  static const double glowSatClamp = 0.6;
  static const double glowLightness = 0.45;

  /// Warm white fallback for devices without colour (fans, ACs, CCT lights).
  static const Color warmWhite = Color(0xFFFFF4E0);

  /// Converts an HA hue (0–360) and saturation (0–100) to an sRGB colour with a
  /// clamped saturation and fixed lightness.
  static Color fromHs(
    double hue,
    double saturation, {
    double satClamp = glowSatClamp,
    double lightness = glowLightness,
  }) {
    final s = (saturation / 100.0).clamp(0.0, satClamp);
    return HSLColor.fromAHSL(1.0, hue % 360, s, lightness).toColor();
  }

  /// Glow colour for a single light entity. Falls back to [warmWhite] when the
  /// light reports no `hs_color` (e.g. a CCT-only or on/off bulb).
  static Color glowFor(EntityState light) {
    final hs = light.hsColor;
    if (hs == null) return warmWhite;
    return fromHs(hs.hue, hs.saturation);
  }

  /// Averages the `hs_color` of every on light, returning an ambient tint at the
  /// given [lightness]. Returns null when no light is on or none report colour.
  static Color? ambientTint(
    Iterable<EntityState> lights, {
    double lightness = 0.15,
  }) {
    double sumHue = 0;
    double sumSat = 0;
    var count = 0;
    for (final l in lights) {
      if (!l.isOn) continue;
      final hs = l.hsColor;
      if (hs == null) continue;
      sumHue += hs.hue;
      sumSat += hs.saturation;
      count++;
    }
    if (count == 0) return null;
    return fromHs(
      sumHue / count,
      sumSat / count,
      satClamp: 0.6,
      lightness: lightness,
    );
  }
}
