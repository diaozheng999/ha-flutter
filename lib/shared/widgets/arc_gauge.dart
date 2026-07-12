import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A single 270° arc gauge shared by the AC thermostat ring and the fan speed
/// dial. The arc starts at 135° and sweeps clockwise to 45°, leaving a gap at
/// the bottom. Callers supply the fill [fraction] (0–1) and optional centre
/// [child]; every gauge draws with the same sweep, caps, and stroke treatment.
class ArcGauge extends StatelessWidget {
  final double fraction;

  /// The active ("fill") colour. The fill is a subtle sweep gradient from
  /// [fillColor] at 60% opacity to full [fillColor].
  final Color fillColor;

  /// The unfilled track colour.
  final Color trackColor;

  /// Dim the fill (e.g. a powered-off climate ring).
  final bool dimmed;

  final double size;
  final Widget? child;

  const ArcGauge({
    super.key,
    required this.fraction,
    required this.fillColor,
    required this.trackColor,
    this.dimmed = false,
    this.size = 200,
    this.child,
  });

  /// Arc geometry shared by every gauge.
  static const double startAngle = 135 * math.pi / 180;
  static const double sweep = 270 * math.pi / 180;
  static const double strokeWidth = 14;
  static const double inset = 16;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcGaugePainter(
          fraction: fraction.clamp(0.0, 1.0),
          fillColor: fillColor,
          trackColor: trackColor,
          dimmed: dimmed,
        ),
        child: child != null ? Center(child: child) : null,
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double fraction;
  final Color fillColor;
  final Color trackColor;
  final bool dimmed;

  _ArcGaugePainter({
    required this.fraction,
    required this.fillColor,
    required this.trackColor,
    required this.dimmed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(ArcGauge.inset);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ArcGauge.strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(rect, ArcGauge.startAngle, ArcGauge.sweep, false, track);

    if (fraction <= 0) return;

    final active = dimmed ? fillColor.withValues(alpha: 0.25) : fillColor;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ArcGauge.strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: ArcGauge.startAngle,
        endAngle: ArcGauge.startAngle + ArcGauge.sweep,
        colors: [active.withValues(alpha: 0.6), active],
      ).createShader(rect);
    canvas.drawArc(
        rect, ArcGauge.startAngle, ArcGauge.sweep * fraction, false, fill);
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.fraction != fraction ||
      old.fillColor != fillColor ||
      old.trackColor != trackColor ||
      old.dimmed != dimmed;
}
