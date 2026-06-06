import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/features/home/widgets/active_devices_bar.dart';
import 'package:ha_flutter/features/home/widgets/appliances_row.dart';
import 'package:ha_flutter/features/home/widgets/greeting_header.dart';
import 'package:ha_flutter/features/home/widgets/now_playing.dart';
import 'package:ha_flutter/features/home/widgets/presence_strip.dart';
import 'package:ha_flutter/features/home/widgets/room_grid.dart';
import 'package:ha_flutter/features/home/widgets/scene_launch_row.dart';
import 'package:ha_flutter/shared/widgets/connection_chip.dart';
import 'package:ha_flutter/shared/widgets/env_reading.dart';

/// The glanceable home dashboard. Background is supplied by the [AppShell].
class HomeOverviewScreen extends ConsumerWidget {
  const HomeOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        actions: const [ConnectionChip()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: const [
            GreetingHeader(),
            SizedBox(height: 16),
            PresenceStrip(),
            SizedBox(height: 12),
            _EnvironmentSummary(),
            SizedBox(height: 16),
            ActiveDevicesBar(),
            SizedBox(height: 20),
            _SectionLabel('Scenes'),
            SizedBox(height: 8),
            SceneLaunchRow(),
            SizedBox(height: 20),
            _SectionLabel('Rooms'),
            SizedBox(height: 8),
            RoomGrid(),
            SizedBox(height: 20),
            _SectionLabel('Appliances'),
            SizedBox(height: 8),
            AppliancesRow(),
            SizedBox(height: 20),
            NowPlaying(),
          ],
        ),
      ),
    );
  }
}

/// Compact environment readings: LR temperature + humidity, Bedroom PM2.5.
class _EnvironmentSummary extends StatelessWidget {
  const _EnvironmentSummary();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        EnvReading(
          entityId: 'climate.living_room_ac',
          kind: EnvKind.temperature,
          attribute: 'current_temperature',
        ),
        EnvReading(entityId: HaEntities.lrHumiditySensor, kind: EnvKind.humidity),
        EnvReading(entityId: HaEntities.bedroomPm25Sensor, kind: EnvKind.pm25),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}
