// Standalone (non-room) entity ids and the allowlist seeded into the
// WebSocket subscription before room discovery runs.
// Room device entity ids are added dynamically by room_registry_provider.dart.

export 'package:ha_flutter/config/room_config.dart';

class HaEntities {
  HaEntities._();

  // ── Standalone entities ──────────────────────────────────────────────────
  static const weather = 'weather.forecast_home';
  static const sun = 'sun.sun';

  static const personSimon = 'person.simon';
  static const personYamin = 'person.yamin';
  static const persons = [personSimon, personYamin];

  static const vacuum = 'vacuum.roborock_qr_798';
  static const vacuumMap = 'image.shiny_map_0';

  static const washerStatus = 'sensor.mibx5_sg_2047340869_f35th_status_p_2_2';
  static const washerTimeLeft =
      'sensor.mibx5_sg_2047340869_f35th_left_time_p_2_10';
  static const waterHeater = 'climate.l10wfe';

  static const alarm = 'alarm_control_panel.doorbell_security_system';
  static const doorbellCamera = 'camera.doorbell_2';
  static const livingRoomCamera = 'camera.living_room';
  static const frigatePerson = 'image.doorbell_frigate_person';
  static const frigateBackpack = 'image.doorbell_frigate_backpack';

  static const camPanLeft = 'button.living_room_camera_pan_left';
  static const camPanRight = 'button.living_room_camera_pan_right';
  static const camTiltUp = 'button.living_room_camera_tilt_up';
  static const camTiltDown = 'button.living_room_camera_tilt_down';
  static const camPanDegrees = 'number.living_room_camera_pan_degrees';
  static const camTiltDegrees = 'number.living_room_camera_tilt_degrees';

  static const dbCabinetTemp = 'sensor.w02_001af7_temperature';
  static const dbCabinetFanSpeed = 'sensor.w02_001af7_fan_speed';
  static const dbCabinetFan = 'fan.w02_001af7';

  static const configSelect = 'input_select.configuration';

  // ── Power-cycling switches (label → entity) ──────────────────────────────
  static const powerCycleSwitches = <({String label, String entity})>[
    (label: 'Entry Light', entity: 'switch.entry_switch_l1'),
    (label: 'LR Hanging 1', entity: 'switch.0xa4c1388aecbb45dd_l1'),
    (label: 'LR Hanging 2', entity: 'switch.0xa4c1388aecbb45dd_l2'),
    (label: 'LR Spotlight', entity: 'switch.0xa4c1388aecbb45dd_l3'),
    (label: 'LR Fan', entity: 'switch.0xa4c1388aecbb45dd_l4'),
    (label: 'Walkway Spot', entity: 'switch.shellywalldisplay_00a90b9db957'),
    (label: 'Bedroom Light/Fan', entity: 'switch.bedroom_switch_l2'),
    (label: 'Bedroom Spotlight', entity: 'switch.bedroom_switch_l1'),
    (label: 'Study Light/Fan', entity: 'switch.study_switch_l1'),
  ];

  // ── Standalone allowlist seeded before room discovery ────────────────────
  static List<String> get standaloneAllowlist => [
        weather,
        sun,
        ...persons,
        vacuum,
        vacuumMap,
        washerStatus,
        washerTimeLeft,
        alarm,
        doorbellCamera,
        livingRoomCamera,
        frigatePerson,
        frigateBackpack,
        camPanDegrees,
        camTiltDegrees,
        dbCabinetTemp,
        dbCabinetFanSpeed,
        dbCabinetFan,
        configSelect,
        for (final s in powerCycleSwitches) s.entity,
      waterHeater,
      ];

  // Keep backward-compat alias used by existing callers.
  static List<String> get allowlist => standaloneAllowlist;
}
