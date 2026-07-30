/// Typed views over the HA entity and device registries, fetched via the
/// WebSocket `config/entity_registry/list` and `config/device_registry/list`
/// commands. Only the fields needed for area-based alert discovery and
/// lighting-role resolution are kept.
class EntityRegistryEntry {
  final String entityId;
  final String? deviceId;
  final String? areaId;
  final String? disabledBy;

  /// Label ids assigned to the entity in the HA label registry. Used to read
  /// lighting-role labels (`role:<name>`); an entity may carry unrelated labels
  /// (e.g. `matterbridge`) alongside them. Empty when the registry response
  /// omits labels.
  final List<String> labels;

  /// Integration that provides the entity, e.g. `group` for a light-group
  /// helper or `template` for a template light.
  final String? platform;

  const EntityRegistryEntry({
    required this.entityId,
    this.deviceId,
    this.areaId,
    this.disabledBy,
    this.labels = const [],
    this.platform,
  });

  String get domain => entityId.split('.').first;

  /// True for HA group helpers, whose members are readable from the entity's
  /// `entity_id` **state** attribute (not the registry).
  bool get isGroupPlatform => platform == 'group';

  /// True for template entities, which are opaque: their backing entities live
  /// in Jinja and are not enumerable from the registry.
  bool get isTemplatePlatform => platform == 'template';

  factory EntityRegistryEntry.fromJson(Map<String, dynamic> json) {
    return EntityRegistryEntry(
      entityId: json['entity_id'] as String,
      deviceId: json['device_id'] as String?,
      areaId: json['area_id'] as String?,
      disabledBy: json['disabled_by'] as String?,
      labels: [
        for (final l in (json['labels'] as List?) ?? const [])
          if (l is String) l,
      ],
      platform: json['platform'] as String?,
    );
  }
}

class DeviceRegistryEntry {
  final String id;
  final String? areaId;
  final String name;
  final String? model;

  const DeviceRegistryEntry({
    required this.id,
    required this.name,
    this.areaId,
    this.model,
  });

  factory DeviceRegistryEntry.fromJson(Map<String, dynamic> json) {
    return DeviceRegistryEntry(
      id: json['id'] as String,
      name: (json['name_by_user'] ?? json['name'] ?? '') as String,
      areaId: json['area_id'] as String?,
      model: json['model'] as String?,
    );
  }
}
