import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';

/// Thermostat control: a temperature ring (current on the arc, setpoint in the
/// centre), +/- step buttons (0.5 °C), and an HVAC mode chip row built from the
/// entity's `hvac_modes`. When off, the ring dims and step buttons disable.
class AcThermostatWidget extends ConsumerWidget {
  final String entityId;
  const AcThermostatWidget({super.key, required this.entityId});

  static const _displayMin = 16.0;
  static const _displayMax = 30.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(entityId)).valueOrNull;
    if (state == null) {
      return const SizedBox(height: 200);
    }

    final mode = state.state;
    final isOff = mode == 'off' || mode == 'unknown' || mode == 'unavailable';
    final current = state.attrDouble('current_temperature');
    final setpoint = state.attrDouble('temperature') ?? 24.0;
    final modes = state.attrList<String>('hvac_modes') ?? const ['off', 'cool'];

    final service = ref.read(haServiceProvider);
    void setTemp(double t) => service.call(
          'climate',
          'set_temperature',
          data: {
            'entity_id': entityId,
            'temperature': double.parse(t.toStringAsFixed(1)),
          },
        );

    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _RingPainter(
              fraction: ((setpoint - _displayMin) / (_displayMax - _displayMin))
                  .clamp(0.0, 1.0),
              dimmed: isOff,
              active: tokens.onAccent,
              track: tokens.glassBorder,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${setpoint.toStringAsFixed(1)}°',
                    style: tokens.sensorStyle.copyWith(fontSize: 40),
                  ),
                  if (current != null)
                    Text(
                      'now ${current.toStringAsFixed(1)}°',
                      style: TextStyle(color: tokens.offMuted, fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: isOff ? null : () => setTemp(setpoint - 0.5),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 24),
            IconButton.filledTonal(
              onPressed: isOff ? null : () => setTemp(setpoint + 0.5),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final m in modes)
              ChoiceChip(
                label: Text(_modeLabel(m)),
                selected: m == mode,
                onSelected: (_) => service.call(
                  'climate',
                  'set_hvac_mode',
                  data: {'entity_id': entityId, 'hvac_mode': m},
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _modeLabel(String m) => switch (m) {
        'off' => 'Off',
        'cool' => 'Cool',
        'heat' => 'Heat',
        'fan_only' => 'Fan',
        'dry' => 'Dry',
        'auto' => 'Auto',
        'heat_cool' => 'Auto',
        _ => m,
      };
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final bool dimmed;
  final Color active;
  final Color track;
  _RingPainter({
    required this.fraction,
    required this.dimmed,
    required this.active,
    required this.track,
  });

  static const _start = 135 * math.pi / 180;
  static const _sweep = 270 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = (Offset.zero & size).deflate(16);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(inset, _start, _sweep, false, base);

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = dimmed ? active.withValues(alpha: 0.25) : active;
    canvas.drawArc(inset, _start, _sweep * fraction, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.dimmed != dimmed;
}
