import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/features/home/widgets/active_devices_bar.dart';
import 'package:ha_flutter/features/home/widgets/appliances_row.dart';
import 'package:ha_flutter/features/home/widgets/config_selector.dart';
import 'package:ha_flutter/features/home/widgets/greeting_header.dart';
import 'package:ha_flutter/features/home/widgets/now_playing.dart';
import 'package:ha_flutter/features/home/widgets/room_grid.dart';
import 'package:ha_flutter/features/home/widgets/scene_launch_row.dart';
import 'package:ha_flutter/shared/widgets/connection_chip.dart';
import 'package:ha_flutter/shared/widgets/env_reading.dart';

/// The glanceable home dashboard. Background is supplied by the [AppShell].
class HomeOverviewScreen extends ConsumerWidget {
  const HomeOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        actions: const [ConnectionChip()],
      ),
      body: SafeArea(
        child: wide ? const _WideLayout() : const _NarrowLayout(),
      ),
    );
  }
}

/// Two-column layout for wide screens (≥900 px after the nav rail).
/// Left: summary panel (header, env, config, active devices, scenes, appliances,
/// now playing). Right: rooms grid — the content that benefits most from width.
class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left panel ──────────────────────────────────────────────────────
        SizedBox(
          width: 360,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 24),
            children: const [
              GreetingHeader(),
              SizedBox(height: 14),
              _EnvironmentSummary(),
              SizedBox(height: 16),
              ConfigSelector(),
              SizedBox(height: 16),
              ActiveDevicesBar(wrap: true),
              SizedBox(height: 20),
              _SectionLabel('Appliances'),
              SizedBox(height: 8),
              AppliancesRow(vertical: true),
              SizedBox(height: 20),
              NowPlaying(),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        // ── Right panel: rooms ───────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: const [
              _SectionLabel('Rooms'),
              SizedBox(height: 12),
              RoomGrid(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Single-column scroll layout for narrow screens (phone / small tablet).
class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: const [
        GreetingHeader(),
        SizedBox(height: 16),
        _EnvironmentSummary(),
        SizedBox(height: 16),
        ConfigSelector(),
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
        EnvReading(entityId: 'sensor.shellywalldisplay_00a90b9db957_humidity', kind: EnvKind.humidity),
        EnvReading(entityId: 'sensor.zhimi_sg_433492230_mb4_pm2_5_density_p_3_4', kind: EnvKind.pm25),
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
