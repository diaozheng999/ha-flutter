import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/shared/util/hs_color_converter.dart';
import 'package:ha_flutter/shared/util/mdi_resolver.dart';
import 'package:ha_flutter/shared/widgets/reading_pill.dart';

/// Single label formatter for HVAC / climate modes, shared by every device
/// status line (D13).
String hvacModeLabel(String mode) => switch (mode) {
      'off' => 'Off',
      'cool' => 'Cool',
      'heat' => 'Heat',
      'fan_only' => 'Fan',
      'dry' => 'Dry',
      'auto' || 'heat_cool' => 'Auto',
      _ => mode,
    };

/// The rationed climate glow hue (D10): a cold hue for cooling modes, a warm hue
/// for heating modes. Returns null for modes that carry no colour signal.
Color? climateGlowFor(String mode) => switch (mode) {
      'cool' || 'dry' => const Color(0xFF4FC3F7),
      'heat' || 'heat_cool' || 'auto' => const Color(0xFFFF8A65),
      _ => null,
    };

/// The single source of truth for a room device's control-relevant facts,
/// resolved once per [DeviceRole]. Both the quick-controls layer and the section
/// status lines read from it, so a device renders one identical status string
/// everywhere.
class DeviceControlDescriptor {
  final IconData icon;
  final String name;
  final bool isAvailable;
  final bool isOn;
  final List<ReadingSpec> sensors;
  final String statusLine;

  /// Toggles the device's power. Null when the device is unavailable.
  final VoidCallback? togglePower;

  /// Rationed glow colour (D10): the light's `hs_color`, the climate mode hue,
  /// or null (fan / purifier signal "on" via the accent treatment only).
  final Color? glowColor;

  const DeviceControlDescriptor({
    required this.icon,
    required this.name,
    required this.isAvailable,
    required this.isOn,
    required this.sensors,
    required this.statusLine,
    required this.togglePower,
    required this.glowColor,
  });

  /// Resolves a descriptor for [device], watching the relevant entity states.
  /// For light groups, [roomLights] supplies the individual light entities used
  /// for the "N on" count.
  static DeviceControlDescriptor describe(
    WidgetRef ref,
    RoomDevice device, {
    List<String> roomLights = const [],
  }) {
    return switch (device.role) {
      DeviceRole.climate => _climate(ref, device),
      DeviceRole.fan => _fan(ref, device),
      DeviceRole.airPurifier => _airPurifier(ref, device),
      DeviceRole.light => _light(ref, device, roomLights),
      DeviceRole.mediaPlayer => _media(ref, device),
      DeviceRole.unknown => _unknown(device),
    };
  }

  static EntityState? _watch(WidgetRef ref, String? id) =>
      id == null ? null : ref.watch(entityStateProvider(id)).valueOrNull;

  /// A state is available when present and neither `unavailable` nor `unknown`.
  static bool _available(EntityState? s) =>
      s != null && !s.isUnavailable && !s.isUnknown;

  static DeviceControlDescriptor _climate(WidgetRef ref, RoomDevice device) {
    final id = device.entity('primary')!;
    final state = _watch(ref, id);
    final available = _available(state);
    final mode = state?.state ?? 'unknown';
    final isOn = available && mode != 'off';
    final service = ref.read(haServiceProvider);
    final modes = state?.attrList<String>('hvac_modes') ?? const ['off', 'cool'];

    final current = state?.attrDouble('current_temperature');
    final humidity = state?.attrDouble('current_humidity');

    final sensors = <ReadingSpec>[
      if (current != null)
        ReadingSpec(
            icon: MdiIcons.thermometer,
            text: '${current.toStringAsFixed(1)}°C'),
      if (humidity != null)
        ReadingSpec(
            icon: MdiIcons.waterPercent, text: '${humidity.round()}%'),
    ];

    String status;
    if (!available) {
      status = 'Unavailable';
    } else if (!isOn) {
      status = 'Off';
    } else {
      final temp = current != null ? '${current.toStringAsFixed(1)}°' : '';
      final label = hvacModeLabel(mode);
      status = temp.isEmpty ? label : '$temp · $label';
    }

    String? powerOnMode() {
      if (modes.contains('cool')) return 'cool';
      for (final m in modes) {
        if (m != 'off') return m;
      }
      return null;
    }

    VoidCallback? toggle;
    if (available) {
      toggle = () {
        if (isOn) {
          service.call('climate', 'set_hvac_mode',
              data: {'entity_id': id, 'hvac_mode': 'off'});
        } else {
          final target = powerOnMode();
          if (target != null) {
            service.call('climate', 'set_hvac_mode',
                data: {'entity_id': id, 'hvac_mode': target});
          }
        }
      };
    }

    return DeviceControlDescriptor(
      icon: mdiIcon(state?.icon, fallback: domainFallback('climate')),
      name: device.name,
      isAvailable: available,
      isOn: isOn,
      sensors: sensors,
      statusLine: status,
      togglePower: toggle,
      glowColor: isOn ? climateGlowFor(mode) : null,
    );
  }

  static DeviceControlDescriptor _fan(WidgetRef ref, RoomDevice device) {
    final id = device.entity('primary')!;
    final state = _watch(ref, id);
    final available = _available(state);
    final isOn = available && (state?.isOn ?? false);
    final service = ref.read(haServiceProvider);
    final pct = state?.attrInt('percentage') ?? 0;

    final status = !available
        ? 'Unavailable'
        : !isOn
            ? 'Off'
            : '$pct%';

    return DeviceControlDescriptor(
      icon: mdiIcon(state?.icon, fallback: domainFallback('fan')),
      name: device.name,
      isAvailable: available,
      isOn: isOn,
      sensors: const [],
      statusLine: status,
      togglePower: available
          ? () => isOn ? service.turnOff(id) : service.turnOn(id)
          : null,
      glowColor: null,
    );
  }

  static DeviceControlDescriptor _airPurifier(
      WidgetRef ref, RoomDevice device) {
    final powerId = device.entity('power');
    final modeId = device.entity('mode');
    final pm25Id = device.entity('pm25');
    final filterId = device.entity('filter');

    final powerState = _watch(ref, powerId);
    final modeState = _watch(ref, modeId);
    final pm25State = _watch(ref, pm25Id);
    final filterState = _watch(ref, filterId);

    final available = _available(powerState);
    final isOn = available && (powerState?.isOn ?? false);
    final service = ref.read(haServiceProvider);
    final mode = modeState?.state;
    final pm25 = pm25State != null && !pm25State.isUnavailable
        ? double.tryParse(pm25State.state)
        : null;
    final filter = filterState != null && !filterState.isUnavailable
        ? double.tryParse(filterState.state)
        : null;

    final sensors = <ReadingSpec>[
      if (pm25 != null)
        ReadingSpec(
          icon: MdiIcons.airFilter,
          text: '${pm25.round()} µg/m³',
          value: pm25,
          severity: ReadingSpec.pm25,
        ),
      if (filter != null)
        ReadingSpec(
          icon: MdiIcons.filterOutline,
          text: '${filter.round()}%',
        ),
    ];

    String status;
    if (!available) {
      status = 'Unavailable';
    } else if (!isOn) {
      status = 'Off';
    } else {
      final parts = <String>[
        if (mode != null && mode.isNotEmpty) mode,
        if (pm25 != null) 'PM2.5 ${pm25.round()}',
      ];
      status = parts.isEmpty ? 'On' : parts.join(' · ');
    }

    return DeviceControlDescriptor(
      icon: mdiIcon(powerState?.icon, fallback: MdiIcons.airPurifier),
      name: device.name,
      isAvailable: available,
      isOn: isOn,
      sensors: sensors,
      statusLine: status,
      togglePower: (available && powerId != null)
          ? () => isOn ? service.turnOff(powerId) : service.turnOn(powerId)
          : null,
      glowColor: null,
    );
  }

  static DeviceControlDescriptor _light(
      WidgetRef ref, RoomDevice device, List<String> roomLights) {
    final id = device.entity('primary')!;
    final state = _watch(ref, id);
    final available = _available(state);
    final service = ref.read(haServiceProvider);

    final onCount = roomLights
        .where((l) => _watch(ref, l)?.isOn ?? false)
        .length;
    final groupOn = state?.isOn ?? false;
    final isOn = available && (groupOn || onCount > 0);

    String status;
    if (!available) {
      status = 'Unavailable';
    } else if (onCount > 0) {
      status = '$onCount on';
    } else if (groupOn) {
      status = 'On';
    } else {
      status = 'Off';
    }

    return DeviceControlDescriptor(
      icon: mdiIcon(state?.icon, fallback: domainFallback('light')),
      name: device.name,
      isAvailable: available,
      isOn: isOn,
      sensors: const [],
      statusLine: status,
      togglePower: available
          ? () => isOn ? service.turnOff(id) : service.turnOn(id)
          : null,
      glowColor: isOn && state != null ? HsColorConverter.glowFor(state) : null,
    );
  }

  static DeviceControlDescriptor _media(WidgetRef ref, RoomDevice device) {
    final id = device.entity('primary')!;
    final state = _watch(ref, id);
    final available = _available(state);
    final raw = state?.state ?? 'idle';
    final status = available
        ? raw[0].toUpperCase() + raw.substring(1)
        : 'Unavailable';
    return DeviceControlDescriptor(
      icon: mdiIcon(state?.icon, fallback: domainFallback('media_player')),
      name: device.name,
      isAvailable: available,
      isOn: available && (state?.isOn ?? false),
      sensors: const [],
      statusLine: status,
      togglePower: null,
      glowColor: null,
    );
  }

  static DeviceControlDescriptor _unknown(RoomDevice device) =>
      DeviceControlDescriptor(
        icon: MdiIcons.helpCircleOutline,
        name: device.name,
        isAvailable: false,
        isOn: false,
        sensors: const [],
        statusLine: 'Unavailable',
        togglePower: null,
        glowColor: null,
      );
}
