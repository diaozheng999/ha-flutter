import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/room_config.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/shared/widgets/device_control_descriptor.dart';

/// Concept sections of the room detail screen. Declaration order is the
/// display and default-selection order.
enum RoomSection {
  climate('Climate & Air', Icons.thermostat_outlined),
  lights('Lights & Ambiance', Icons.lightbulb_outline),
  media('Media', Icons.play_circle_outline);

  final String label;
  final IconData icon;
  const RoomSection(this.label, this.icon);
}

/// True when a media player state counts as active for the Media section.
bool isMediaActiveState(String? state) =>
    state == 'playing' || state == 'paused' || state == 'idle';

/// Sections available for [room], in display order. [mediaActive] is the
/// live activity of the room's media player (always false without one).
List<RoomSection> availableSections(RoomConfig room,
    {required bool mediaActive}) {
  return [
    if (room.climateDevices.isNotEmpty) RoomSection.climate,
    // Resolved lighting covers fixtures the device scan misses — area-less
    // group helpers and role-labelled wall switches.
    if (!room.lighting.isEmpty || room.allLights.isNotEmpty)
      RoomSection.lights,
    if (room.mediaPlayer != null && mediaActive) RoomSection.media,
  ];
}

/// The section a device's quick-control tile opens into.
RoomSection sectionForDevice(RoomDevice device) => switch (device.role) {
      DeviceRole.light => RoomSection.lights,
      DeviceRole.mediaPlayer => RoomSection.media,
      _ => RoomSection.climate,
    };

RoomDevice? _deviceOfRole(RoomConfig room, DeviceRole role, {bool? group}) =>
    room.devices
        .where((d) => d.role == role && (group == null || d.isGroup == group))
        .firstOrNull;

/// Live one-line status for a section's nav item / selector chip, sourced from
/// the shared [DeviceControlDescriptor] so nav items and quick tiles render the
/// same string, e.g. "2 on", "24.5° · Cool", "Playing".
String sectionStatusLine(WidgetRef ref, RoomConfig room, RoomSection section) {
  switch (section) {
    case RoomSection.lights:
      // Counted over resolved lighting so the nav status matches what the
      // section renders, including switch fixtures and rescued groups.
      final fixtures = room.lighting.isEmpty
          ? room.allLights
          : room.lighting.allFixtureIds;
      if (fixtures.isEmpty) return 'Off';
      final onCount = fixtures
          .where((id) =>
              ref.watch(entityStateProvider(id)).valueOrNull?.isOn ?? false)
          .length;
      return onCount > 0 ? '$onCount on' : 'Off';

    case RoomSection.climate:
      final climate = _deviceOfRole(room, DeviceRole.climate) ??
          _deviceOfRole(room, DeviceRole.fan);
      if (climate == null) return 'Off';
      return DeviceControlDescriptor.describe(ref, climate).statusLine;

    case RoomSection.media:
      final s =
          ref.watch(entityStateProvider(room.mediaPlayer!)).valueOrNull?.state ??
              'idle';
      return s[0].toUpperCase() + s.substring(1);
  }
}
