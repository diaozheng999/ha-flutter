import 'package:ha_flutter/config/alert_rules.dart';

export 'package:ha_flutter/config/alert_rules.dart' show RoomAlertSeverity;

/// A single alert condition surfaced on the room screen.
class RoomAlert {
  final RoomAlertSeverity severity;

  /// Device or event name, e.g. "Hue window light" or "Laundry done".
  final String title;

  /// Short condition label, e.g. "Offline" or "12% battery".
  final String condition;

  final String entityId;

  const RoomAlert({
    required this.severity,
    required this.title,
    required this.condition,
    required this.entityId,
  });
}

/// Sensor categories selected by autodiscovery.
enum DiscoveredAlertKind { safety, battery, problem }

/// An alert sensor matched to a room via the HA registries.
class DiscoveredAlertSensor {
  final String entityId;
  final DiscoveredAlertKind kind;

  /// HA `device_class` attribute, used for condition wording (e.g. moisture
  /// → "Leak detected").
  final String deviceClass;

  const DiscoveredAlertSensor({
    required this.entityId,
    required this.kind,
    required this.deviceClass,
  });
}
