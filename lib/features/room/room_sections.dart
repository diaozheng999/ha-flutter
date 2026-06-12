import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/room_config.dart';
import 'package:ha_flutter/ha/ha_providers.dart';

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
    if (room.allLights.isNotEmpty) RoomSection.lights,
    if (room.mediaPlayer != null && mediaActive) RoomSection.media,
  ];
}

/// Live one-line status for a section's nav item / selector chip, e.g.
/// "2 on", "24.5° · Cool", "Playing".
String sectionStatusLine(WidgetRef ref, RoomConfig room, RoomSection section) {
  String? state(String id) =>
      ref.watch(entityStateProvider(id)).valueOrNull?.state;

  switch (section) {
    case RoomSection.lights:
      final onCount = room.individualLights
          .where((id) => state(id) == 'on')
          .length;
      if (onCount > 0) return '$onCount on';
      if (room.lightGroup != null && state(room.lightGroup!) == 'on') {
        return 'On';
      }
      return 'Off';

    case RoomSection.climate:
      if (room.climate != null) {
        final ac = ref.watch(entityStateProvider(room.climate!)).valueOrNull;
        final mode = ac?.state;
        if (ac == null || mode == null || mode == 'off' ||
            mode == 'unknown' || mode == 'unavailable') {
          return 'Off';
        }
        final current = ac.attrDouble('current_temperature');
        final temp =
            current != null ? '${current.toStringAsFixed(1)}°' : '';
        return temp.isEmpty ? _hvacLabel(mode) : '$temp · ${_hvacLabel(mode)}';
      }
      final fan = ref.watch(entityStateProvider(room.fan!)).valueOrNull;
      if (fan == null || !fan.isOn) return 'Off';
      return '${fan.attrInt('percentage') ?? 0}%';

    case RoomSection.media:
      final s = state(room.mediaPlayer!) ?? 'idle';
      return s[0].toUpperCase() + s.substring(1);
  }
}

String _hvacLabel(String mode) => switch (mode) {
      'cool' => 'Cool',
      'heat' => 'Heat',
      'fan_only' => 'Fan',
      'dry' => 'Dry',
      'auto' || 'heat_cool' => 'Auto',
      _ => mode,
    };
