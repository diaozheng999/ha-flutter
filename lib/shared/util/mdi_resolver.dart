import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// Resolves an `mdi:icon-name` string (as returned by Home Assistant) to a
/// Flutter [IconData]. Returns [fallback] when the key is null or unrecognised.
IconData mdiIcon(String? mdiKey, {required IconData fallback}) {
  if (mdiKey == null) return fallback;
  final name = mdiKey.startsWith('mdi:') ? mdiKey.substring(4) : mdiKey;
  return MdiIcons.fromString(name) ?? fallback;
}

/// Default icon for a Home Assistant domain + optional device_class.
/// Widgets should call this when an entity has no explicit `attributes.icon`.
IconData domainFallback(String domain, {String? deviceClass}) {
  switch (domain) {
    case 'light':
      return MdiIcons.lightbulb;
    case 'fan':
      return MdiIcons.fan;
    case 'climate':
      return MdiIcons.airConditioner;
    case 'media_player':
      return MdiIcons.cast;
    case 'switch':
      return MdiIcons.toggleSwitchOutline;
    case 'vacuum':
      return MdiIcons.robotVacuum;
    case 'camera':
      return MdiIcons.cctv;
    case 'cover':
      return switch (deviceClass) {
        'garage' => MdiIcons.garage,
        'door' => MdiIcons.door,
        'blind' => MdiIcons.blinds,
        _ => MdiIcons.windowOpenVariant,
      };
    case 'sensor':
      return switch (deviceClass) {
        'temperature' => MdiIcons.thermometer,
        'humidity' => MdiIcons.waterPercent,
        'illuminance' => MdiIcons.brightness5,
        'pm25' => MdiIcons.airFilter,
        'battery' => MdiIcons.battery,
        'energy' => MdiIcons.lightningBolt,
        'power' => MdiIcons.flashOutline,
        _ => MdiIcons.gauge,
      };
    case 'binary_sensor':
      return switch (deviceClass) {
        'motion' => MdiIcons.motion,
        'door' || 'window' => MdiIcons.doorOpen,
        'smoke' => MdiIcons.smoke,
        'moisture' => MdiIcons.waterAlert,
        'occupancy' || 'presence' => MdiIcons.homeAccount,
        _ => MdiIcons.circle,
      };
    case 'weather':
      return MdiIcons.weatherCloudy;
    case 'person':
      return MdiIcons.account;
    case 'alarm_control_panel':
      return MdiIcons.shield;
    case 'automation':
      return MdiIcons.robot;
    case 'script':
      return MdiIcons.scriptText;
    case 'scene':
      return MdiIcons.palette;
    case 'input_select':
      return MdiIcons.formSelect;
    default:
      return MdiIcons.helpCircleOutline;
  }
}
