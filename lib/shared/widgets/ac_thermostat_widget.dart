import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/arc_gauge.dart';
import 'package:ha_flutter/shared/widgets/control_card.dart';
import 'package:ha_flutter/shared/widgets/device_control_descriptor.dart';
import 'package:ha_flutter/shared/widgets/pending_overlay.dart';
import 'package:ha_flutter/shared/widgets/power_toggle.dart';
import 'package:ha_flutter/shared/widgets/selection_chips.dart';

/// AC thermostat rendered as a [ControlCard]: header icon, name, live status
/// line ("24.5° · Cool", "Off"), and a [PowerToggle]. The body is a temperature
/// ring ([ArcGauge]) showing the current temperature on the arc and the setpoint
/// in the centre, +/- 0.5 °C step buttons, and an HVAC mode [ModeSelector]. When
/// off, the ring dims and the step buttons disable while the mode selector stays
/// active. The card glows in a mode-derived hue (cool → cold, heat → warm).
class AcThermostatWidget extends ConsumerWidget {
  final RoomDevice device;
  const AcThermostatWidget({super.key, required this.device});

  static const _displayMin = 16.0;
  static const _displayMax = 30.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final id = device.entity('primary')!;
    final state = ref.watch(entityStateProvider(id)).valueOrNull;
    final d = DeviceControlDescriptor.describe(ref, device);

    final mode = state?.state ?? 'off';
    final isOff = !d.isOn;
    final current = state?.attrDouble('current_temperature');
    final setpoint = state?.attrDouble('temperature') ?? 24.0;
    final modes = state?.attrList<String>('hvac_modes') ?? const ['off', 'cool'];

    final service = ref.read(haServiceProvider);
    void setTemp(double t) => service.call(
          'climate',
          'set_temperature',
          data: {
            'entity_id': id,
            'temperature': double.parse(t.toStringAsFixed(1)),
          },
        );

    return PendingOverlay(
      entityId: id,
      child: ControlCard(
        icon: d.icon,
        name: d.name,
        status: d.statusLine,
        isOn: d.isOn,
        unavailable: !d.isAvailable,
        glowColor: d.glowColor,
        trailing: PowerToggle(isOn: d.isOn, onTap: d.togglePower),
        body: Column(
          children: [
            ArcGauge(
              fraction:
                  ((setpoint - _displayMin) / (_displayMax - _displayMin))
                      .clamp(0.0, 1.0),
              fillColor: tokens.onAccent,
              trackColor: tokens.glassBorder,
              dimmed: isOff,
              size: 200,
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
            ModeSelector<String>(
              options: modes,
              selected: mode,
              alignment: WrapAlignment.center,
              labelOf: hvacModeLabel,
              onSelect: (m) => service.call(
                'climate',
                'set_hvac_mode',
                data: {'entity_id': id, 'hvac_mode': m},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
