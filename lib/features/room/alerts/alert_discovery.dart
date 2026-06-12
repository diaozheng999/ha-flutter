// Area-based autodiscovery of alert sensors. The HA registries map entities
// to areas (room ids equal HA area ids); device classes come from a one-shot
// REST states snapshot because `config/entity_registry/list` does not include
// them. Discovered ids are appended to the WebSocket subscription so their
// states flow through entityStateProvider like any other entity.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/room_config.dart';
import 'package:ha_flutter/features/room/alerts/room_alert.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/registry_entry.dart';
import 'package:ha_flutter/ha/room_registry_provider.dart';

/// Binary-sensor device classes that map to safety alerts when `on`.
const safetyDeviceClasses = {
  'moisture',
  'gas',
  'smoke',
  'carbon_monoxide',
  'safety',
};

/// Pure classification of registry entries into per-room alert sensors.
/// Exposed for testing; [discoveredAlertSensorsProvider] feeds it live data.
Map<String, List<DiscoveredAlertSensor>> classifyAlertSensors({
  required List<EntityRegistryEntry> entities,
  required Map<String, String> deviceAreas,
  required Map<String, String> deviceClassByEntity,
  required Set<String> roomIds,
}) {
  final byRoom = <String, List<DiscoveredAlertSensor>>{};
  for (final e in entities) {
    if (e.disabledBy != null) continue;
    final area = e.areaId ?? (e.deviceId != null ? deviceAreas[e.deviceId] : null);
    if (area == null || !roomIds.contains(area)) continue;
    final deviceClass = deviceClassByEntity[e.entityId];
    if (deviceClass == null) continue;

    DiscoveredAlertKind? kind;
    if (e.domain == 'binary_sensor' && safetyDeviceClasses.contains(deviceClass)) {
      kind = DiscoveredAlertKind.safety;
    } else if (e.domain == 'binary_sensor' && deviceClass == 'problem') {
      kind = DiscoveredAlertKind.problem;
    } else if (e.domain == 'sensor' && deviceClass == 'battery') {
      kind = DiscoveredAlertKind.battery;
    }
    if (kind == null) continue;

    byRoom.putIfAbsent(area, () => []).add(DiscoveredAlertSensor(
          entityId: e.entityId,
          kind: kind,
          deviceClass: deviceClass,
        ));
  }
  return byRoom;
}

/// Room id → discovered alert sensors, fetched once per connection. Also
/// extends the WebSocket subscription with the discovered ids. Failures
/// degrade to no discovered sensors (offline detection and config rules
/// remain active).
final discoveredAlertSensorsProvider =
    FutureProvider<Map<String, List<DiscoveredAlertSensor>>>((ref) async {
  await ref.watch(dashboardInitProvider.future);
  final ws = ref.read(haWebSocketServiceProvider);
  try {
    final entities = await ws.fetchEntityRegistry();
    final devices = await ws.fetchDeviceRegistry();
    final snapshot = await ref
        .read(haRestClientProvider)
        .fetchDomainStates({'sensor', 'binary_sensor'});

    final byRoom = classifyAlertSensors(
      entities: entities,
      deviceAreas: {
        for (final d in devices)
          if (d.areaId != null) d.id: d.areaId!,
      },
      deviceClassByEntity: {
        for (final s in snapshot)
          if (s.attrString('device_class') != null)
            s.entityId: s.attrString('device_class')!,
      },
      roomIds: <String>{
        for (final r
            in ref.read(roomConfigsProvider).valueOrNull ?? <RoomConfig>[])
          r.id,
      },
    );

    await ws.extendSubscription([
      for (final sensors in byRoom.values)
        for (final s in sensors) s.entityId,
    ]);
    return byRoom;
  } catch (_) {
    return const {};
  }
});

/// Discovered alert sensors for one room (empty until discovery completes).
final roomAlertEntitiesProvider =
    Provider.family<List<DiscoveredAlertSensor>, String>((ref, roomId) {
  return ref.watch(discoveredAlertSensorsProvider).valueOrNull?[roomId] ??
      const [];
});
