import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/features/room/widgets/room_lights_section.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/shared/background/background_engine.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/hs_color_converter.dart';
import 'package:ha_flutter/shared/util/mdi_resolver.dart';
import 'package:ha_flutter/shared/widgets/ac_thermostat_widget.dart';
import 'package:ha_flutter/shared/widgets/connection_chip.dart';
import 'package:ha_flutter/shared/widgets/env_reading.dart';
import 'package:ha_flutter/shared/widgets/fan_speed_dial.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';
import 'package:ha_flutter/shared/widgets/media_mini_player.dart';

/// Per-room detail with its own background, ambient light tinting, and all of
/// the room's device controls. Pushed from the room grid.
class RoomDetailScreen extends ConsumerWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = HaEntities.roomById(roomId);

    // Ambient tint from on lights → animated middle-gradient overlay (600 ms).
    final lights = [
      for (final id in room.allLights)
        ref.watch(entityStateProvider(id)).valueOrNull ??
            EntityState.unknown(id),
    ];
    final tint = HsColorConverter.ambientTint(lights, lightness: 0.15);

    final mediaActive = _mediaActive(ref, room);

    return Stack(
      children: [
        const Positioned.fill(child: AppBackground()),
        // Ambient room tint overlay.
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: tint ?? Colors.transparent),
              duration: const Duration(milliseconds: 600),
              builder: (context, color, _) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      color ?? Colors.transparent,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Scaffold(
          appBar: AppBar(
            title: Text(room.name),
            actions: const [ConnectionChip()],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _RoomHeader(room: room),
                const SizedBox(height: 16),
                if (room.lightGroup != null) ...[
                  RoomLightsSection(room: room),
                  const SizedBox(height: 16),
                ],
                if (room.fan != null) ...[
                  _SectionLabel('Fan'),
                  const SizedBox(height: 8),
                  Center(child: FanSpeedDial(entityId: room.fan!)),
                  const SizedBox(height: 16),
                ],
                if (room.climate != null) ...[
                  _SectionLabel('Climate'),
                  const SizedBox(height: 8),
                  AcThermostatWidget(entityId: room.climate!),
                  const SizedBox(height: 16),
                ],
                if (mediaActive) ...[
                  _SectionLabel('Media'),
                  const SizedBox(height: 8),
                  MediaMiniPlayer(entityId: room.mediaPlayer!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _mediaActive(WidgetRef ref, RoomConfig room) {
    if (room.mediaPlayer == null) return false;
    final s = ref.watch(entityStateProvider(room.mediaPlayer!)).valueOrNull?.state;
    return s == 'playing' || s == 'paused' || s == 'idle';
  }
}

class _RoomHeader extends ConsumerWidget {
  final RoomConfig room;
  const _RoomHeader({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final readings = <Widget>[
      if (room.climate != null)
        EnvReading(
          entityId: room.climate!,
          kind: EnvKind.temperature,
          attribute: 'current_temperature',
        ),
      if (room.humiditySensor != null)
        EnvReading(entityId: room.humiditySensor!, kind: EnvKind.humidity),
      if (room.illuminanceSensor != null)
        EnvReading(entityId: room.illuminanceSensor!, kind: EnvKind.illuminance),
      if (room.pm25Sensor != null)
        EnvReading(entityId: room.pm25Sensor!, kind: EnvKind.pm25),
    ];

    final areaIcons = ref.watch(areaIconsProvider).valueOrNull ?? {};
    final roomIcon = mdiIcon(areaIcons[room.id], fallback: MdiIcons.homeOutline);

    return GlassCard(
      child: Row(
        children: [
          Icon(roomIcon, size: 32, color: tokens.onAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                if (readings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(runSpacing: 4, children: readings),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      );
}
