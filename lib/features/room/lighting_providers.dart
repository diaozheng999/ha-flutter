// Providers for the room lighting L0 surface: per-room scene association and
// the smart master action.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/room_config.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/ha/room_registry_provider.dart';

/// A scene offered for a room, with the name shown on its chip.
class RoomScene {
  final String entityId;
  final String name;

  const RoomScene({required this.entityId, required this.name});
}

/// All `scene.*` entities with their member lists. Fetched once via REST — scenes
/// have no meaningful state to watch (they are fire-and-forget), so they are not
/// worth a permanent WebSocket subscription.
final allScenesProvider = FutureProvider<List<EntityState>>((ref) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    return await ref.read(haRestClientProvider).fetchByDomain('scene');
  } catch (_) {
    return const [];
  }
});

/// Member entity ids a scene sets.
List<String> sceneMemberIds(EntityState scene) =>
    scene.attrList<String>('entity_id') ?? const [];

/// Scenes associated with a room, by overlap between the scene's members and the
/// room's lighting fixtures.
///
/// Scenes carry no area assignment, so overlap is the available signal. A scene
/// only counts as a *lighting* scene when at least one member is one of this
/// room's lighting fixtures — which is what excludes the fan-speed scenes that
/// otherwise look like room scenes.
final roomLightingScenesProvider =
    Provider.family<List<RoomScene>, String>((ref, areaId) {
  final room = ref.watch(roomConfigProvider(areaId));
  if (room == null) return const [];
  final scenes = ref.watch(allScenesProvider).valueOrNull ?? const [];
  return lightingScenesFor(room, scenes);
});

/// Pure association used by [roomLightingScenesProvider]; separated so it can be
/// tested without providers.
List<RoomScene> lightingScenesFor(
  RoomConfig room,
  List<EntityState> scenes,
) {
  final fixtures = room.lighting.allFixtureIds.toSet();
  if (fixtures.isEmpty) return const [];

  final result = <RoomScene>[];
  for (final scene in scenes) {
    final members = sceneMemberIds(scene);
    if (members.isEmpty) continue;
    if (!members.any(fixtures.contains)) continue;
    result.add(RoomScene(
      entityId: scene.entityId,
      name: scene.friendlyName,
    ));
  }
  result.sort((a, b) => a.name.compareTo(b.name));
  return result;
}

/// The room's comfort scene, recalled by the master "on" action.
///
/// Comfort scenes are authored by hand per room (the final phase of this
/// change), so this resolves to null for rooms that do not have one yet and the
/// master falls back to a plain turn-on.
final comfortSceneProvider =
    Provider.family<String?, String>((ref, areaId) {
  final scenes = ref.watch(allScenesProvider).valueOrNull ?? const [];
  final expected = 'scene.${areaId}_comfort';
  for (final s in scenes) {
    if (s.entityId == expected) return s.entityId;
  }
  return null;
});
