import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/debouncer.dart';

/// Circular arc dial controlling a fan's `percentage` (0–100). Dragging to 0
/// turns the fan off. Service calls are debounced at 200 ms.
class FanSpeedDial extends ConsumerStatefulWidget {
  final String entityId;
  final double size;
  const FanSpeedDial({super.key, required this.entityId, this.size = 160});

  @override
  ConsumerState<FanSpeedDial> createState() => _FanSpeedDialState();
}

class _FanSpeedDialState extends ConsumerState<FanSpeedDial> {
  // Arc spans 270°, from 135° sweeping clockwise to 45°.
  static const _startAngle = 135 * math.pi / 180;
  static const _sweep = 270 * math.pi / 180;

  final _debouncer = Debouncer();
  double? _dragValue;

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _handlePan(Offset local) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final v = local - center;
    final angle = math.atan2(v.dy, v.dx); // -pi..pi
    // Normalise into the arc's coordinate space.
    var rel = angle - _startAngle;
    while (rel < 0) {
      rel += 2 * math.pi;
    }
    if (rel > _sweep) {
      // Snap to nearer end when outside the arc gap.
      rel = (rel - _sweep) < (2 * math.pi - rel) ? _sweep : 0;
    }
    final pct = (rel / _sweep * 100).clamp(0, 100).toDouble();
    setState(() => _dragValue = pct);
    _debouncer.call(() => _apply(pct));
  }

  void _apply(double pct) {
    final service = ref.read(haServiceProvider);
    if (pct < 1) {
      service.turnOff(widget.entityId);
    } else {
      service.turnOn(widget.entityId, {'percentage': pct.round()});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(widget.entityId)).valueOrNull;
    final isOn = state?.isOn ?? false;
    final livePct =
        isOn ? (state?.attrInt('percentage') ?? 0).toDouble() : 0.0;
    final pct = _dragValue ?? livePct;

    return GestureDetector(
      onPanStart: (d) => _handlePan(d.localPosition),
      onPanUpdate: (d) => _handlePan(d.localPosition),
      onPanEnd: (_) {
        if (_dragValue != null) _apply(_dragValue!);
        setState(() => _dragValue = null);
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _DialPainter(
            fraction: pct / 100,
            active: tokens.onAccent,
            track: tokens.glassBorder,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${pct.round()}%', style: tokens.sensorStyle.copyWith(fontSize: 28)),
                Text('Fan', style: TextStyle(color: tokens.offMuted, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double fraction;
  final Color active;
  final Color track;
  _DialPainter({
    required this.fraction,
    required this.active,
    required this.track,
  });

  static const _startAngle = 135 * math.pi / 180;
  static const _sweep = 270 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(14);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(inset, _startAngle, _sweep, false, base);

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + _sweep,
        colors: [active.withValues(alpha: 0.6), active],
      ).createShader(inset);
    canvas.drawArc(inset, _startAngle, _sweep * fraction, false, fill);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.fraction != fraction || old.active != active;
}
