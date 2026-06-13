/// A physical device in a room, detected from the HA device registry.
/// One device = one tile in the room detail screen.
enum DeviceRole {
  climate,      // HA `climate` entity (AC, heat pump)
  fan,          // HA `fan` entity (ceiling fan, desk fan)
  airPurifier,  // Xiaomi-style: switch + select (mode) + PM2.5 sensor
  light,        // HA `light` entity (individual bulb or helper group)
  mediaPlayer,  // HA `media_player` entity
  unknown,
}

class RoomDevice {
  final String deviceId;
  final String name;
  final DeviceRole role;

  /// Semantic key → entity_id. Keys vary by role:
  /// - climate / fan / mediaPlayer / light: `primary`
  /// - airPurifier: `power`, `mode`, `pm25`, `filter` (any may be absent)
  final Map<String, String> entities;

  /// True for light helper groups (no backing HA device, area-assigned entity).
  final bool isGroup;

  const RoomDevice({
    required this.deviceId,
    required this.name,
    required this.role,
    required this.entities,
    this.isGroup = false,
  });

  String? entity(String key) => entities[key];

  bool get isClimateType =>
      role == DeviceRole.climate ||
      role == DeviceRole.fan ||
      role == DeviceRole.airPurifier;
}
