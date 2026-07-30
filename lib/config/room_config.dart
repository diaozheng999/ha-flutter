import 'package:ha_flutter/config/alert_rules.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/ha/models/room_lighting.dart';

export 'package:ha_flutter/config/alert_rules.dart';

/// Runtime description of a room, built dynamically from the HA area +
/// device + entity registries. Flutter-side overrides (alert rules, adaptive
/// lighting) are applied on top in [room_overrides.dart].
class RoomConfig {
  final String id; // HA area_id
  final String name;
  final String? icon; // MDI icon string from HA area registry
  final List<RoomDevice> devices;
  final String? adaptiveLightingSwitch;
  final List<AlertRule> alertRules;

  /// Lighting resolved into role layers + an ungrouped bucket. Empty for rooms
  /// with no lighting fixtures.
  final RoomLighting lighting;

  /// Environment sensor entity ids — supplied via [RoomOverride] until
  /// auto-detection from device classes is implemented.
  final String? temperatureSensor;
  final String? humiditySensor;
  final String? illuminanceSensor;
  final String? pm25Sensor;

  const RoomConfig({
    required this.id,
    required this.name,
    this.icon,
    required this.devices,
    this.adaptiveLightingSwitch,
    this.alertRules = const [],
    this.lighting = const RoomLighting(),
    this.temperatureSensor,
    this.humiditySensor,
    this.illuminanceSensor,
    this.pm25Sensor,
  });

  // ── Derived convenience getters ───────────────────────────────────────────

  List<RoomDevice> get climateDevices =>
      devices.where((d) => d.isClimateType).toList();

  String? get climate => devices
      .where((d) => d.role == DeviceRole.climate)
      .firstOrNull
      ?.entity('primary');

  String? get fan => devices
      .where((d) => d.role == DeviceRole.fan)
      .firstOrNull
      ?.entity('primary');

  String? get mediaPlayer => devices
      .where((d) => d.role == DeviceRole.mediaPlayer)
      .firstOrNull
      ?.entity('primary');

  /// Primary light group (HA helper entity, no backing device).
  String? get lightGroup => devices
      .where((d) => d.role == DeviceRole.light && d.isGroup)
      .firstOrNull
      ?.entity('primary');

  /// Individual addressable lights (backed by real devices).
  List<String> get individualLights => [
        for (final d in devices)
          if (d.role == DeviceRole.light && !d.isGroup)
            d.entity('primary')!,
      ];

  /// All light entity ids (group + individuals) for aggregate state / glow.
  List<String> get allLights => [
        ?lightGroup,
        ...individualLights,
      ];

  /// On/off-capable devices for the quick-controls layer: climate, fan, air
  /// purifier, and the light group (one tile each). Media is excluded.
  List<RoomDevice> get quickControlDevices => [
        for (final d in devices)
          if (d.role == DeviceRole.climate ||
              d.role == DeviceRole.fan ||
              d.role == DeviceRole.airPurifier ||
              (d.role == DeviceRole.light && d.isGroup))
            d,
      ];

  /// All controllable device entity ids (for offline detection).
  List<String> get deviceEntities => [
        ...allLights,
        ?climate,
        ?fan,
        ?mediaPlayer,
        for (final d in climateDevices)
          if (d.role == DeviceRole.airPurifier) ...d.entities.values,
      ];
}
