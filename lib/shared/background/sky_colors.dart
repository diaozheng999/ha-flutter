import 'package:flutter/material.dart';

/// A two-stop vertical sky gradient (top of screen → horizon).
@immutable
class SkyGradient {
  final Color top;
  final Color bottom;
  const SkyGradient(this.top, this.bottom);

  static SkyGradient lerp(SkyGradient a, SkyGradient b, double t) => SkyGradient(
        Color.lerp(a.top, b.top, t)!,
        Color.lerp(a.bottom, b.bottom, t)!,
      );

  LinearGradient toLinearGradient({Color? mid}) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: mid != null ? [top, mid, bottom] : [top, bottom],
      );
}

/// Maps sun elevation (degrees) to a Singapore-equatorial sky gradient.
///
/// Anchors are defined at key elevations and lerped between. Elevation alone is
/// symmetric about noon, so a [rising] hint is used to make the descending
/// golden hour a touch warmer than the ascending one (Singapore's humid dusk).
class SkyColors {
  SkyColors._();

  // (elevation°, top, bottom) sorted ascending by elevation.
  static const List<(double, Color, Color)> _anchors = [
    (-90, Color(0xFF04040F), Color(0xFF0A0A20)), // deep night
    (-6, Color(0xFF04040F), Color(0xFF0A0A20)), // astronomical→civil edge
    (-3, Color(0xFF120828), Color(0xFF8B2FC9)), // civil twilight violet
    (0, Color(0xFF1A0A2E), Color(0xFFFF6B35)), // horizon ember
    (6, Color(0xFF1A0A2E), Color(0xFFFF7043)), // golden hour
    (12, Color(0xFF0D2137), Color(0xFFFF8A50)), // warm→blue transition
    (25, Color(0xFF0D2137), Color(0xFF2979C7)), // morning blue
    (45, Color(0xFF083260), Color(0xFF1565C0)), // bright sky
    (90, Color(0xFF083260), Color(0xFF1565C0)), // midday
  ];

  static SkyGradient forElevation(double elevation, {bool rising = true}) {
    final e = elevation.clamp(-90.0, 90.0);
    SkyGradient base;
    if (e <= _anchors.first.$1) {
      base = SkyGradient(_anchors.first.$2, _anchors.first.$3);
    } else if (e >= _anchors.last.$1) {
      base = SkyGradient(_anchors.last.$2, _anchors.last.$3);
    } else {
      base = SkyGradient(_anchors.last.$2, _anchors.last.$3);
      for (var i = 0; i < _anchors.length - 1; i++) {
        final lo = _anchors[i];
        final hi = _anchors[i + 1];
        if (e >= lo.$1 && e <= hi.$1) {
          final t = (e - lo.$1) / (hi.$1 - lo.$1);
          base = SkyGradient.lerp(
            SkyGradient(lo.$2, lo.$3),
            SkyGradient(hi.$2, hi.$3),
            t,
          );
          break;
        }
      }
    }

    // Warm the descending golden hour (sunset) relative to sunrise.
    if (!rising && e > -3 && e < 12) {
      base = SkyGradient(
        base.top,
        Color.lerp(base.bottom, const Color(0xFFFF5722), 0.25)!,
      );
    }
    return base;
  }

  /// Phase-based fallback when sun elevation is unavailable (low tier / no sun
  /// entity). Uses the local clock only.
  static SkyGradient forTimeOfDay(DateTime now) {
    final h = now.hour + now.minute / 60.0;
    if (h >= 5 && h < 7) {
      return const SkyGradient(Color(0xFF1A0A2E), Color(0xFFFF6B35)); // dawn
    } else if (h >= 7 && h < 17) {
      return const SkyGradient(Color(0xFF0A1628), Color(0xFF1E3A5F)); // day
    } else if (h >= 17 && h < 19.5) {
      return const SkyGradient(Color(0xFF1A0A1A), Color(0xFFFF4500)); // sunset
    }
    return const SkyGradient(Color(0xFF050510), Color(0xFF0D0D2B)); // night
  }

  /// Singapore haze tint colour, overlaid at 35% per design.
  static const Color hazeTint = Color(0xFFC8A96E);

  /// Applies a weather condition's colour treatment to a base sky.
  static SkyGradient applyWeather(SkyGradient base, String condition) {
    switch (condition) {
      case 'partlycloudy':
        return _desaturate(base, 0.10);
      case 'cloudy':
        return _darken(_desaturate(base, 0.30), 0.15);
      case 'rainy':
        return _darken(_shiftToBlueGrey(base, 0.3), 0.25);
      case 'pouring':
      case 'lightning-rainy':
        return _darken(_shiftToBlueGrey(base, 0.5), 0.30);
      case 'fog':
      case 'hazy':
      case 'haze':
        // Flatten contrast and overlay the warm haze tint.
        final flat = SkyGradient(
          Color.lerp(base.top, hazeTint, 0.35)!,
          Color.lerp(base.bottom, hazeTint, 0.35)!,
        );
        return flat;
      default:
        return base; // sunny / clear-night / unknown
    }
  }

  static SkyGradient _desaturate(SkyGradient g, double amount) => SkyGradient(
        _desatColor(g.top, amount),
        _desatColor(g.bottom, amount),
      );

  static Color _desatColor(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withSaturation((hsl.saturation - amount).clamp(0.0, 1.0))
        .toColor();
  }

  static SkyGradient _darken(SkyGradient g, double amount) => SkyGradient(
        Color.lerp(g.top, Colors.black, amount)!,
        Color.lerp(g.bottom, Colors.black, amount)!,
      );

  static SkyGradient _shiftToBlueGrey(SkyGradient g, double amount) =>
      SkyGradient(
        Color.lerp(g.top, const Color(0xFF37474F), amount)!,
        Color.lerp(g.bottom, const Color(0xFF455A64), amount)!,
      );
}
