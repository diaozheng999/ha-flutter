// Builds RoomConfig objects dynamically from the HA area, device, and entity
// registries. Flutter-side overrides (alert rules, adaptive lighting, sensor
// assignments) are applied on top via room_overrides.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/room_config.dart';
import 'package:ha_flutter/config/room_overrides.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/registry_entry.dart';
import 'package:ha_flutter/ha/models/room_device.dart';

/// All rooms derived from the HA registries, sorted by [RoomOverride.sortOrder]
/// then alphabetically. Only areas that contain at least one controllable
/// device (climate, fan, purifier, light, media player) are included.
final roomConfigsProvider = FutureProvider<List<RoomConfig>>((ref) async {
  await ref.watch(dashboardInitProvider.future);
  final ws = ref.read(haWebSocketServiceProvider);

  final areas = await ws.fetchAreas();
  final entityList = await ws.fetchEntityRegistry();
  final deviceList = await ws.fetchDeviceRegistry();

  // ── Build lookup maps ──────────────────────────────────────────────────────

  final deviceById = {for (final d in deviceList) d.id: d};

  // Group enabled entities by device_id.
  final entitiesByDevice = <String, List<EntityRegistryEntry>>{};
  // Light helper entities assigned directly to an area (no device).
  final lightHelpersByArea = <String, List<EntityRegistryEntry>>{};

  for (final e in entityList) {
    if (e.disabledBy != null) continue;
    if (e.deviceId != null) {
      entitiesByDevice.putIfAbsent(e.deviceId!, () => []).add(e);
    } else if (e.domain == 'light' && e.areaId != null) {
      lightHelpersByArea.putIfAbsent(e.areaId!, () => []).add(e);
    }
  }

  // ── Build rooms ────────────────────────────────────────────────────────────

  final rooms = <RoomConfig>[];

  for (final area in areas) {
    final areaId = area.id;

    // Collect device ids in this area: either by device.area_id or by any of
    // the device's entities having entity.area_id pointing here.
    final areaDeviceIds = <String>{
      for (final d in deviceList)
        if (d.areaId == areaId) d.id,
      for (final e in entityList)
        if (e.areaId == areaId && e.deviceId != null) e.deviceId!,
    };

    final roomDevices = <RoomDevice>[];

    for (final deviceId in areaDeviceIds) {
      final deviceEntities = entitiesByDevice[deviceId] ?? [];
      if (deviceEntities.isEmpty) continue;
      final device = deviceById[deviceId];
      final role = _detectRole(deviceEntities);
      if (role == DeviceRole.unknown) continue;
      final entityMap = _extractEntities(role, deviceEntities);
      if (entityMap.isEmpty) continue;
      roomDevices.add(RoomDevice(
        deviceId: deviceId,
        name: device?.name.isNotEmpty == true ? device!.name : deviceId,
        role: role,
        entities: entityMap,
      ));
    }

    // Light helper groups (HA helpers assigned directly to area, no device).
    for (final e in lightHelpersByArea[areaId] ?? <EntityRegistryEntry>[]) {
      roomDevices.add(RoomDevice(
        deviceId: 'helper_${e.entityId}',
        name: e.entityId
            .replaceFirst('light.', '')
            .replaceAll('_', ' '),
        role: DeviceRole.light,
        entities: {'primary': e.entityId},
        isGroup: true,
      ));
    }

    if (roomDevices.isEmpty) continue;

    final override = roomOverrides[areaId];
    rooms.add(RoomConfig(
      id: areaId,
      name: area.name,
      icon: area.icon,
      devices: roomDevices,
      adaptiveLightingSwitch: override?.adaptiveLightingSwitch,
      alertRules: override?.alertRules ?? const [],
      temperatureSensor: override?.temperatureSensor,
      humiditySensor: override?.humiditySensor,
      illuminanceSensor: override?.illuminanceSensor,
      pm25Sensor: override?.pm25Sensor,
    ));
  }

  rooms.sort((a, b) {
    final ao = roomOverrides[a.id]?.sortOrder ?? 999;
    final bo = roomOverrides[b.id]?.sortOrder ?? 999;
    if (ao != bo) return ao.compareTo(bo);
    return a.name.compareTo(b.name);
  });

  // ── Extend WS subscription with all room entity ids ────────────────────────

  final allEntityIds = <String>[
    for (final r in rooms) ...[
      for (final d in r.devices) ...d.entities.values,
      ?r.temperatureSensor,
      ?r.humiditySensor,
      ?r.illuminanceSensor,
      ?r.pm25Sensor,
      ?r.adaptiveLightingSwitch,
    ],
  ];

  // Bootstrap room entity states via REST so the UI has data immediately.
  try {
    final states = await ref
        .read(haRestClientProvider)
        .fetchStates(allEntityIds.toSet());
    ref.read(entityRepositoryProvider).putAll(states);
  } catch (_) {}

  await ws.extendSubscription(allEntityIds);

  return rooms;
});

/// Single-room lookup; null while [roomConfigsProvider] is loading.
final roomConfigProvider = Provider.family<RoomConfig?, String>((ref, id) {
  return ref
      .watch(roomConfigsProvider)
      .valueOrNull
      ?.where((r) => r.id == id)
      .firstOrNull;
});

// ── Role detection ────────────────────────────────────────────────────────────

DeviceRole _detectRole(List<EntityRegistryEntry> entities) {
  final domains = {for (final e in entities) e.domain};
  if (domains.contains('climate')) return DeviceRole.climate;
  if (domains.contains('media_player')) return DeviceRole.mediaPlayer;
  if (domains.contains('fan')) return DeviceRole.fan;
  if (domains.contains('light')) return DeviceRole.light;
  // Air purifier: switch (power) + select (mode) + PM2.5 sensor
  if (domains.contains('switch') &&
      domains.contains('select') &&
      entities.any(
          (e) => e.domain == 'sensor' && e.entityId.contains('pm2_5'))) {
    return DeviceRole.airPurifier;
  }
  return DeviceRole.unknown;
}

Map<String, String> _extractEntities(
    DeviceRole role, List<EntityRegistryEntry> entities) {
  switch (role) {
    case DeviceRole.climate:
      final e =
          entities.where((e) => e.domain == 'climate').firstOrNull;
      return e == null ? {} : {'primary': e.entityId};

    case DeviceRole.fan:
      final e = entities.where((e) => e.domain == 'fan').firstOrNull;
      return e == null ? {} : {'primary': e.entityId};

    case DeviceRole.mediaPlayer:
      final e =
          entities.where((e) => e.domain == 'media_player').firstOrNull;
      return e == null ? {} : {'primary': e.entityId};

    case DeviceRole.light:
      final e =
          entities.where((e) => e.domain == 'light').firstOrNull;
      return e == null ? {} : {'primary': e.entityId};

    case DeviceRole.airPurifier:
      final result = <String, String>{};
      final power = entities
          .where((e) => e.domain == 'switch' && e.entityId.contains('_on_p_'))
          .firstOrNull;
      if (power != null) result['power'] = power.entityId;
      final mode = entities
          .where((e) =>
              e.domain == 'select' && e.entityId.contains('_mode_p_'))
          .firstOrNull;
      if (mode != null) result['mode'] = mode.entityId;
      final pm25 = entities
          .where((e) =>
              e.domain == 'sensor' && e.entityId.contains('pm2_5'))
          .firstOrNull;
      if (pm25 != null) result['pm25'] = pm25.entityId;
      final filter = entities
          .where((e) =>
              e.domain == 'sensor' &&
              e.entityId.contains('filter_life_level'))
          .firstOrNull;
      if (filter != null) result['filter'] = filter.entityId;
      return result;

    default:
      return {};
  }
}
