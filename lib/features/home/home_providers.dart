import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/room_registry_provider.dart';

/// Count of lights currently on across all rooms.
final lightsOnCountProvider = Provider<int>((ref) {
  final rooms = ref.watch(roomConfigsProvider).valueOrNull ?? [];
  var count = 0;
  for (final room in rooms) {
    for (final id in room.allLights) {
      if (ref.watch(entityStateProvider(id)).valueOrNull?.isOn ?? false) {
        count++;
      }
    }
  }
  return count;
});

/// Count of fans currently on.
final fansOnCountProvider = Provider<int>((ref) {
  final rooms = ref.watch(roomConfigsProvider).valueOrNull ?? [];
  var count = 0;
  for (final room in rooms) {
    final fan = room.fan;
    if (fan == null) continue;
    if (ref.watch(entityStateProvider(fan)).valueOrNull?.isOn ?? false) {
      count++;
    }
  }
  return count;
});

/// Count of climate entities not off/unknown.
final acsActiveCountProvider = Provider<int>((ref) {
  final rooms = ref.watch(roomConfigsProvider).valueOrNull ?? [];
  var count = 0;
  for (final room in rooms) {
    final ac = room.climate;
    if (ac == null) continue;
    final s = ref.watch(entityStateProvider(ac)).valueOrNull?.state;
    if (s != null && s != 'off' && s != 'unknown' && s != 'unavailable') {
      count++;
    }
  }
  return count;
});

/// Whether the vacuum is doing something other than sitting on its dock.
final vacuumActiveProvider = Provider<bool>((ref) {
  final s =
      ref.watch(entityStateProvider(HaEntities.vacuum)).valueOrNull?.state;
  return s != null && s != 'docked' && s != 'unavailable';
});

/// The media players currently `playing`.
final playingMediaProvider = Provider<List<String>>((ref) {
  final rooms = ref.watch(roomConfigsProvider).valueOrNull ?? [];
  return [
    for (final room in rooms)
      if (room.mediaPlayer != null)
        if (ref
                .watch(entityStateProvider(room.mediaPlayer!))
                .valueOrNull
                ?.state ==
            'playing')
          room.mediaPlayer!,
  ];
});
