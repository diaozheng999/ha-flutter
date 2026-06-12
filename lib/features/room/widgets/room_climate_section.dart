import 'package:flutter/material.dart';
import 'package:ha_flutter/config/room_config.dart';
import 'package:ha_flutter/features/room/widgets/trend_graph.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/shared/widgets/ac_thermostat_widget.dart';
import 'package:ha_flutter/shared/widgets/air_purifier_widget.dart';
import 'package:ha_flutter/shared/widgets/fan_speed_dial.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Climate & Air section: all climate-type devices (AC, fan, air purifier)
/// tiled equally in a horizontal row, with the 24 h trend graph below.
class RoomClimateSection extends StatelessWidget {
  final RoomConfig room;
  const RoomClimateSection({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final devices = room.climateDevices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (devices.isNotEmpty)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < devices.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Expanded(child: _deviceTile(devices[i])),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        TrendGraph(roomId: room.id),
      ],
    );
  }

  Widget _deviceTile(RoomDevice device) {
    return switch (device.role) {
      DeviceRole.climate => GlassCard(
          child: AcThermostatWidget(entityId: device.entity('primary')!),
        ),
      DeviceRole.fan => GlassCard(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: FanSpeedDial(entityId: device.entity('primary')!),
          ),
        ),
      DeviceRole.airPurifier => GlassCard(
          child: AirPurifierWidget(device: device),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
