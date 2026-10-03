import 'package:ha_flutter/config/alert_rules.dart';

export 'package:ha_flutter/config/alert_rules.dart';

/// Flutter-side per-room overrides keyed by HA area_id. Contains only things
/// that cannot be auto-detected from the HA registries.
class RoomOverride {
  /// Controls sort order in the room grid (lower = earlier).
  final int sortOrder;

  /// Adaptive Lighting integration switch for this room.
  final String? adaptiveLightingSwitch;

  /// Declarative alert rules (activity / consumable thresholds). Standard
  /// safety / battery / problem sensors are auto-discovered from HA.
  final List<AlertRule> alertRules;

  /// Ordered lighting-role layers for this room. Null uses the default role
  /// order from `lighting_config.dart`; roles found on labels but absent from
  /// the list are appended after it.
  final List<String>? lightingRoles;

  /// Environment sensor entity ids shown in the sidebar / header.
  /// Used until auto-detection from device classes is implemented.
  final String? temperatureSensor;
  final String? humiditySensor;
  final String? illuminanceSensor;
  final String? pm25Sensor;

  const RoomOverride({
    this.sortOrder = 999,
    this.adaptiveLightingSwitch,
    this.alertRules = const [],
    this.lightingRoles,
    this.temperatureSensor,
    this.humiditySensor,
    this.illuminanceSensor,
    this.pm25Sensor,
  });
}

const roomOverrides = <String, RoomOverride>{
  'living_room': RoomOverride(
    sortOrder: 1,
    adaptiveLightingSwitch:
        'switch.living_room_kitchen_adaptive_lighting_main',
    temperatureSensor:
        'sensor.shellywalldisplay_00a90b9db957_temperature',
    humiditySensor:
        'sensor.shellywalldisplay_00a90b9db957_humidity',
    illuminanceSensor:
        'sensor.shellywalldisplay_00a90b9db957_illuminance',
  ),
  'kitchen': RoomOverride(
    sortOrder: 2,
    adaptiveLightingSwitch: 'switch.adaptive_lighting_kitchen_lights',
    alertRules: [
      AlertRule.stateIn(
        entity: 'sensor.mibx5_sg_2047340869_f35th_status_p_2_2',
        states: ['end', 'finish', 'finished', 'complete', 'completed', 'done'],
        severity: RoomAlertSeverity.activity,
        label: 'Laundry done',
      ),
    ],
  ),
  'bedroom': RoomOverride(
    sortOrder: 3,
    adaptiveLightingSwitch: 'switch.bedrooms_adaptive_lighting_bedrooms',
    pm25Sensor: 'sensor.zhimi_sg_433492230_mb4_pm2_5_density_p_3_4',
  ),
  'study': RoomOverride(
    sortOrder: 4,
    adaptiveLightingSwitch:
        'switch.study_lights_adaptive_lighting_study_lights',
  ),
  'entrance': RoomOverride(sortOrder: 5),
  'pantry': RoomOverride(sortOrder: 6),
};
