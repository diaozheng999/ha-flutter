/// Typed views over the HA entity and device registries, fetched via the
/// WebSocket `config/entity_registry/list` and `config/device_registry/list`
/// commands. Only the fields needed for area-based alert discovery are kept.
class EntityRegistryEntry {
  final String entityId;
  final String? deviceId;
  final String? areaId;
  final String? disabledBy;

  const EntityRegistryEntry({
    required this.entityId,
    this.deviceId,
    this.areaId,
    this.disabledBy,
  });

  String get domain => entityId.split('.').first;

  factory EntityRegistryEntry.fromJson(Map<String, dynamic> json) {
    return EntityRegistryEntry(
      entityId: json['entity_id'] as String,
      deviceId: json['device_id'] as String?,
      areaId: json['area_id'] as String?,
      disabledBy: json['disabled_by'] as String?,
    );
  }
}

class DeviceRegistryEntry {
  final String id;
  final String? areaId;

  const DeviceRegistryEntry({required this.id, this.areaId});

  factory DeviceRegistryEntry.fromJson(Map<String, dynamic> json) {
    return DeviceRegistryEntry(
      id: json['id'] as String,
      areaId: json['area_id'] as String?,
    );
  }
}
