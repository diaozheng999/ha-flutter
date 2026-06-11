import 'package:flutter/material.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/features/room/widgets/trend_graph.dart';
import 'package:ha_flutter/shared/widgets/ac_thermostat_widget.dart';
import 'package:ha_flutter/shared/widgets/fan_speed_dial.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Climate & Air section: thermostat and fan side by side when the width
/// allows (Wrap reflows them into a stack on compact layouts), with the 24 h
/// environment trend graph below. The graph loads progressively and never
/// blocks the controls.
class RoomClimateSection extends StatelessWidget {
  final RoomConfig room;
  const RoomClimateSection({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            if (room.climate != null)
              GlassCard(child: AcThermostatWidget(entityId: room.climate!)),
            if (room.fan != null)
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  child: FanSpeedDial(entityId: room.fan!),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TrendGraph(roomId: room.id),
      ],
    );
  }
}
