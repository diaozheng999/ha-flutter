import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// Resolves an `mdi:icon-name` string (as returned by Home Assistant) to a
/// Flutter [IconData]. Returns [fallback] when the key is null or unrecognised.
IconData mdiIcon(String? mdiKey, {required IconData fallback}) {
  if (mdiKey == null) return fallback;
  final name = mdiKey.startsWith('mdi:') ? mdiKey.substring(4) : mdiKey;
  return _mdiMap[name] ?? fallback;
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

/// Mapping of common MDI icon names (kebab-case, as sent by Home Assistant)
/// to MdiIcons constants.
const _mdiMap = <String, IconData>{
  // lights
  'lightbulb': MdiIcons.lightbulb,
  'lightbulb-outline': MdiIcons.lightbulbOutline,
  'lightbulb-multiple': MdiIcons.lightbulbMultiple,
  'lightbulb-multiple-outline': MdiIcons.lightbulbMultipleOutline,
  // climate / HVAC
  'fan': MdiIcons.fan,
  'air-conditioner': MdiIcons.airConditioner,
  'air-filter': MdiIcons.airFilter,
  'thermometer': MdiIcons.thermometer,
  // sensors
  'water-percent': MdiIcons.waterPercent,
  'brightness-5': MdiIcons.brightness5,
  'lightning-bolt': MdiIcons.lightningBolt,
  'flash-outline': MdiIcons.flashOutline,
  'gauge': MdiIcons.gauge,
  'battery': MdiIcons.battery,
  'battery-outline': MdiIcons.batteryOutline,
  // covers
  'garage': MdiIcons.garage,
  'door': MdiIcons.door,
  'door-open': MdiIcons.doorOpen,
  'blinds': MdiIcons.blinds,
  'window-open-variant': MdiIcons.windowOpenVariant,
  // binary sensors
  'motion-sensor': MdiIcons.motionSensor,
  'smoke-detector': MdiIcons.smokeDetector,
  'water-alert': MdiIcons.waterAlert,
  // media / appliances
  'cast': MdiIcons.cast,
  'television': MdiIcons.television,
  'speaker': MdiIcons.speaker,
  'robot-vacuum': MdiIcons.robotVacuum,
  'robot': MdiIcons.robot,
  'cctv': MdiIcons.cctv,
  // home / people
  'home': MdiIcons.home,
  'home-outline': MdiIcons.homeOutline,
  'home-account': MdiIcons.homeAccount,
  'account': MdiIcons.account,
  'account-outline': MdiIcons.accountOutline,
  // power / switches
  'toggle-switch-outline': MdiIcons.toggleSwitchOutline,
  // weather
  'weather-sunny': MdiIcons.weatherSunny,
  'weather-night': MdiIcons.weatherNight,
  'weather-partly-cloudy': MdiIcons.weatherPartlyCloudy,
  'weather-cloudy': MdiIcons.weatherCloudy,
  'weather-rainy': MdiIcons.weatherRainy,
  'weather-pouring': MdiIcons.weatherPouring,
  'weather-lightning-rainy': MdiIcons.weatherLightningRainy,
  'weather-fog': MdiIcons.weatherFog,
  'weather-windy': MdiIcons.weatherWindy,
  // misc
  'shield': MdiIcons.shield,
  'palette': MdiIcons.palette,
  'script-text': MdiIcons.scriptText,
  'form-select': MdiIcons.formSelect,
  'help-circle-outline': MdiIcons.helpCircleOutline,
  'circle': MdiIcons.circle,
  'moon-waning-crescent': MdiIcons.moonWaningCrescent,
  'smoke': MdiIcons.smoke,
};
