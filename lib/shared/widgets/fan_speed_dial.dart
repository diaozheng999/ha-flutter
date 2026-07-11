import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/debouncer.dart';
import 'package:ha_flutter/shared/widgets/arc_gauge.dart';
import 'package:ha_flutter/shared/widgets/control_card.dart';
import 'package:ha_flutter/shared/widgets/device_control_descriptor.dart';
import 'package:ha_flutter/shared/widgets/pending_overlay.dart';
import 'package:ha_flutter/shared/widgets/power_toggle.dart';
import 'package:ha_flutter/shared/widgets/selection_chips.dart';

/// Fan control rendered as a [ControlCard]: header icon, name, live status line
/// ("75%", "Off", "Unavailable") and a [PowerToggle]. The body is a circular
/// [ArcGauge] dial controlling `percentage` (drag to 0 turns the fan off), with
/// an oscillation [OptionChip] when the entity exposes `oscillating`. Service
/// calls are debounced at 200 ms.
class FanSpeedDial extends ConsumerStatefulWidget {
  final RoomDevice device;
  final double size;
  const FanSpeedDial({super.key, required this.device, this.size = 160});

  @override
  ConsumerState<FanSpeedDial> createState() => _FanSpeedDialState();
}

class _FanSpeedDialState extends ConsumerState<FanSpeedDial> {
  final _debouncer = Debouncer();
  double? _dragValue;

  String get _entityId => widget.device.entity('primary')!;

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _handlePan(Offset local) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final v = local - center;
    final angle = math.atan2(v.dy, v.dx); // -pi..pi
    var rel = angle - ArcGauge.startAngle;
    while (rel < 0) {
      rel += 2 * math.pi;
    }
    if (rel > ArcGauge.sweep) {
      // Snap to nearer end when outside the arc gap.
      rel = (rel - ArcGauge.sweep) < (2 * math.pi - rel) ? ArcGauge.sweep : 0;
    }
    final pct = (rel / ArcGauge.sweep * 100).clamp(0, 100).toDouble();
    setState(() => _dragValue = pct);
    _debouncer.call(() => _apply(pct));
  }

  void _apply(double pct) {
    final service = ref.read(haServiceProvider);
    if (pct < 1) {
      service.turnOff(_entityId);
    } else {
      service.turnOn(_entityId, {'percentage': pct.round()});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final service = ref.read(haServiceProvider);
    final state = ref.watch(entityStateProvider(_entityId)).valueOrNull;
    final d = DeviceControlDescriptor.describe(ref, widget.device);
    final isOn = d.isOn;
    final livePct = isOn ? (state?.attrInt('percentage') ?? 0).toDouble() : 0.0;
    final pct = _dragValue ?? livePct;

    final hasOscillation =
        state?.attributes.containsKey('oscillating') ?? false;
    final oscillating = state?.attributes['oscillating'] == true;

    return PendingOverlay(
      entityId: _entityId,
      child: ControlCard(
        icon: d.icon,
        name: d.name,
        status: d.statusLine,
        isOn: isOn,
        unavailable: !d.isAvailable,
        glowColor: d.glowColor,
        trailing: PowerToggle(isOn: isOn, onTap: d.togglePower),
        body: Column(
          children: [
            Center(
              child: GestureDetector(
                onPanStart: (e) => _handlePan(e.localPosition),
                onPanUpdate: (e) => _handlePan(e.localPosition),
                onPanEnd: (_) {
                  if (_dragValue != null) _apply(_dragValue!);
                  setState(() => _dragValue = null);
                },
                child: ArcGauge(
                  fraction: pct / 100,
                  fillColor: tokens.onAccent,
                  trackColor: tokens.glassBorder,
                  size: widget.size,
                  child: Text(
                    '${pct.round()}%',
                    style: tokens.sensorStyle.copyWith(fontSize: 28),
                  ),
                ),
              ),
            ),
            if (hasOscillation) ...[
              const SizedBox(height: 12),
              OptionChip(
                icon: Icons.sync,
                label: 'Oscillate',
                selected: oscillating,
                onToggle: isOn
                    ? (v) => service.call('fan', 'oscillate', data: {
                          'entity_id': _entityId,
                          'oscillating': v,
                        })
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
