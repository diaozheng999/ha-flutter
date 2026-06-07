import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// Single source of truth for the entity ids this dashboard controls, the
/// room-to-entity mapping, and the WebSocket subscription allowlist.
///
/// Room order and entity assignment are hardcoded for v1 (see design Open
/// Questions). A follow-on change can make this data-driven.

/// Per-room device inventory.
class RoomConfig {
  final String id;
  final String name;
  final IconData icon;

  /// Primary light *group* entity for the room (controls all lights at once).
  final String? lightGroup;

  /// Individually addressable lights within the room.
  final List<String> individualLights;

  final String? fan;
  final String? climate;
  final String? mediaPlayer;

  /// Adaptive lighting switch governing this room, if any.
  final String? adaptiveLightingSwitch;

  /// Environment sensors surfaced in this room's header.
  final String? humiditySensor;
  final String? illuminanceSensor;
  final String? pm25Sensor;

  const RoomConfig({
    required this.id,
    required this.name,
    required this.icon,
    this.lightGroup,
    this.individualLights = const [],
    this.fan,
    this.climate,
    this.mediaPlayer,
    this.adaptiveLightingSwitch,
    this.humiditySensor,
    this.illuminanceSensor,
    this.pm25Sensor,
  });

  /// All light entities (group + individuals) for aggregate state/glow.
  List<String> get allLights => [
        ?lightGroup,
        ...individualLights,
      ];
}

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

  // Living Room camera PTZ
  static const camPanLeft = 'button.living_room_camera_pan_left';
  static const camPanRight = 'button.living_room_camera_pan_right';
  static const camTiltUp = 'button.living_room_camera_tilt_up';
  static const camTiltDown = 'button.living_room_camera_tilt_down';
  static const camPanDegrees = 'number.living_room_camera_pan_degrees';
  static const camTiltDegrees = 'number.living_room_camera_tilt_degrees';

  // Living Room environment (ShellyWallDisplay)
  static const lrTemperatureSensor =
      'sensor.shellywalldisplay_00a90b9db957_temperature';
  static const lrHumiditySensor =
      'sensor.shellywalldisplay_00a90b9db957_humidity';
  static const lrIlluminanceSensor =
      'sensor.shellywalldisplay_00a90b9db957_illuminance';
  // Bedroom air quality (Xiaomi air purifier)
  static const bedroomPm25Sensor =
      'sensor.zhimi_sg_433492230_mb4_pm2_5_density_p_3_4';

  // DB cabinet
  static const dbCabinetTemp = 'sensor.w02_001af7_temperature';
  static const dbCabinetFanSpeed = 'sensor.w02_001af7_fan_speed';
  static const dbCabinetFan = 'fan.w02_001af7';

  static const configSelect = 'input_select.configuration';

  // ── Adaptive lighting switches (by room) ─────────────────────────────────
  static const alLivingRoom = 'switch.living_room_kitchen_adaptive_lighting_main';
  static const alKitchen = 'switch.adaptive_lighting_kitchen_lights';
  static const alBedroom = 'switch.bedrooms_adaptive_lighting_bedrooms';
  static const alStudy = 'switch.study_lights_adaptive_lighting_study_lights';

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

  // ── Rooms ─────────────────────────────────────────────────────────────────
  static final rooms = <RoomConfig>[
    RoomConfig(
      id: 'living_room',
      name: 'Living Room',
      icon: MdiIcons.sofa,
      lightGroup: 'light.living_room_lights',
      individualLights: [
        'light.0x001788010d9450aa', // hue window
        'light.0x001788010d945872', // hue entrance
        'light.shellywalldisplay_00a90b9db957_walkway_spotlight',
      ],
      fan: 'fan.living_room_fan',
      climate: 'climate.living_room_ac',
      mediaPlayer: 'media_player.lg_webos_tv_qned82asa_3',
      adaptiveLightingSwitch: alLivingRoom,
      humiditySensor: lrHumiditySensor,
      illuminanceSensor: lrIlluminanceSensor,
    ),
    RoomConfig(
      id: 'kitchen',
      name: 'Kitchen',
      icon: MdiIcons.stove,
      lightGroup: 'light.kitchen_lights',
      individualLights: [
        'light.kitchen_spotlights',
        'light.kitchen_ceiling_light',
        'light.0xa4c138d640ca3df3',
        'light.0xa4c138d1bf23fbfe',
        'light.0xa4c138467b2c9455',
        'light.0xa4c138f0bf4d2de3',
        'light.0xa4c1380314577806',
        'light.pantry_lights',
        'light.dining_table_lights',
      ],
      adaptiveLightingSwitch: alKitchen,
    ),
    RoomConfig(
      id: 'bedroom',
      name: 'Bedroom',
      icon: MdiIcons.bed,
      lightGroup: 'light.bedroom_light',
      individualLights: ['light.bedroom_spotlight'],
      fan: 'fan.bedroom_fan',
      climate: 'climate.bedroom_ac',
      mediaPlayer: 'media_player.bedroom_speaker_2',
      adaptiveLightingSwitch: alBedroom,
      pm25Sensor: bedroomPm25Sensor,
    ),
    RoomConfig(
      id: 'study',
      name: 'Study',
      icon: MdiIcons.bookOpenPageVariant,
      lightGroup: 'light.study_light',
      fan: 'fan.study_fan',
      climate: 'climate.study_ac',
      mediaPlayer: 'media_player.study_speaker_2',
      adaptiveLightingSwitch: alStudy,
    ),
    RoomConfig(
      id: 'entrance',
      name: 'Entrance',
      icon: MdiIcons.doorOpen,
      lightGroup: 'light.entry_lights',
      individualLights: ['light.dining_table_lights'],
    ),
    RoomConfig(
      id: 'pantry',
      name: 'Pantry',
      icon: MdiIcons.cupboardOutline,
      lightGroup: 'light.pantry_lights',
      individualLights: [
        'light.walkway_spotlight_inner',
        'light.walkway_spotlight_outer',
      ],
      mediaPlayer: 'media_player.pantry_display_2',
    ),
  ];

  static RoomConfig roomById(String id) =>
      rooms.firstWhere((r) => r.id == id);

  /// Rooms that have adaptive lighting control (for the scenes screen).
  static List<RoomConfig> get roomsWithAdaptiveLighting =>
      rooms.where((r) => r.adaptiveLightingSwitch != null).toList();

  /// All media player entities referenced across rooms (de-duplicated).
  static List<String> get mediaPlayers => {
        for (final r in rooms)
          if (r.mediaPlayer != null) r.mediaPlayer!,
      }.toList();

  // ── WebSocket subscription allowlist ─────────────────────────────────────
  /// The explicit set of entity ids the dashboard subscribes to. Keeping this
  /// tight avoids flooding the Riverpod graph with the instance's 600+ entities.
  static List<String> get allowlist {
    final ids = <String>{
      weather,
      sun,
      ...persons,
      vacuum,
      vacuumMap,
      washerStatus,
      washerTimeLeft,
      waterHeater,
      alarm,
      doorbellCamera,
      livingRoomCamera,
      frigatePerson,
      frigateBackpack,
      camPanDegrees,
      camTiltDegrees,
      lrTemperatureSensor,
      lrHumiditySensor,
      lrIlluminanceSensor,
      bedroomPm25Sensor,
      dbCabinetTemp,
      dbCabinetFanSpeed,
      dbCabinetFan,
      configSelect,
      alLivingRoom,
      alKitchen,
      alBedroom,
      alStudy,
      for (final s in powerCycleSwitches) s.entity,
      for (final r in rooms) ...[
        if (r.lightGroup != null) r.lightGroup!,
        ...r.individualLights,
        if (r.fan != null) r.fan!,
        if (r.climate != null) r.climate!,
        if (r.mediaPlayer != null) r.mediaPlayer!,
      ],
    };
    return ids.toList();
  }
}
