import 'package:flutter/material.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';

/// Three-step severity level for any numeric reading.
enum Severity { nominal, warning, critical }

/// Resolves a numeric reading to a [Severity] level (or `null` for neutral).
/// The direction (rising-bad vs falling-bad) is encoded in the function itself.
typedef SeverityMapping = Severity Function(double value);

/// Resolves a [Severity] to its theme colour.
Color severityColor(Severity level, AppTokens tokens) => switch (level) {
      Severity.nominal => tokens.severityNominal,
      Severity.warning => tokens.severityWarning,
      Severity.critical => tokens.severityCritical,
    };

/// A single reading to render as a [ReadingPill]: an icon, a formatted value
/// string, and an optional severity mapping applied to [value].
class ReadingSpec {
  final IconData icon;
  final String text;

  /// The numeric value the [severity] mapping resolves. When null (or [severity]
  /// is null) the pill renders neutral.
  final double? value;
  final SeverityMapping? severity;

  const ReadingSpec({
    required this.icon,
    required this.text,
    this.value,
    this.severity,
  });

  /// The resolved severity level, or null when this reading has no mapping.
  Severity? get level =>
      (value != null && severity != null) ? severity!(value!) : null;

  /// A rising-bad mapping: higher is worse (e.g. PM2.5). `critical` when the
  /// value exceeds the critical threshold, `warning` at/above the warning
  /// threshold, else `nominal`.
  static SeverityMapping risingBad({
    required double warning,
    required double critical,
  }) =>
      (v) => v > critical
          ? Severity.critical
          : v >= warning
              ? Severity.warning
              : Severity.nominal;

  /// A falling-bad mapping: lower is worse (e.g. battery). `critical` at/below
  /// the critical threshold, `warning` at/below the warning threshold, else
  /// `nominal`.
  static SeverityMapping fallingBad({
    required double warning,
    required double critical,
  }) =>
      (v) => v <= critical
          ? Severity.critical
          : v <= warning
              ? Severity.warning
              : Severity.nominal;

  /// WHO 24-hour PM2.5 guideline mapping: nominal < 12, warning 12–35,
  /// critical > 35 µg/m³.
  static final SeverityMapping pm25 = risingBad(warning: 12, critical: 35);
}

/// A compact icon + value pill for a reading. Severity-mapped readings colour
/// their icon and text via the shared severity tokens; unmapped readings render
/// in the neutral muted foreground.
class ReadingPill extends StatelessWidget {
  final ReadingSpec spec;
  const ReadingPill({super.key, required this.spec});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final level = spec.level;
    final color = level != null ? severityColor(level, tokens) : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(spec.icon, size: 16, color: color ?? tokens.offMuted),
        const SizedBox(width: 4),
        Text(spec.text, style: tokens.sensorStyle.copyWith(color: color)),
      ],
    );
  }
}
