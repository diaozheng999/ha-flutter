// Derives the per-room alert list from already-subscribed entity states:
// discovered sensors (safety/battery/problem), declarative config rules
// (activity/maintenance), and offline detection. No polling.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/features/room/alerts/alert_discovery.dart';
import 'package:ha_flutter/features/room/alerts/room_alert.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';

/// How long a low battery counts as low.
const batteryAlertThreshold = 20.0;

/// Visibility window for momentary activity alerts (e.g. doorbell ring).
const momentaryAlertLifetime = Duration(minutes: 10);

/// Result of one alert computation: the alerts plus the delay until the next
/// momentary expiry (if any), so the provider can invalidate itself.
typedef RoomAlertsResult = ({List<RoomAlert> alerts, Duration? nextExpiry});

/// Pure alert derivation. Exposed for testing; [roomAlertsProvider] wraps it.
/// [momentaryTriggers] persists last-trigger times across computations and is
/// updated in place.
RoomAlertsResult computeRoomAlerts({
  required RoomConfig room,
  required List<DiscoveredAlertSensor> discovered,
  required EntityState? Function(String entityId) lookup,
  required Map<String, DateTime> momentaryTriggers,
  required DateTime now,
}) {
  final alerts = <RoomAlert>[];
  Duration? nextExpiry;

  // Discovered sensors: safety on, problem on, battery below threshold.
  for (final sensor in discovered) {
    final state = lookup(sensor.entityId);
    if (state == null || state.isUnavailable || state.isUnknown) continue;
    switch (sensor.kind) {
      case DiscoveredAlertKind.safety:
        if (state.isOn) {
          alerts.add(RoomAlert(
            severity: RoomAlertSeverity.safety,
            title: state.friendlyName,
            condition: _safetyCondition(sensor.deviceClass),
            entityId: sensor.entityId,
          ));
        }
      case DiscoveredAlertKind.problem:
        if (state.isOn) {
          alerts.add(RoomAlert(
            severity: RoomAlertSeverity.maintenance,
            title: state.friendlyName,
            condition: 'Problem reported',
            entityId: sensor.entityId,
          ));
        }
      case DiscoveredAlertKind.battery:
        final level = double.tryParse(state.state);
        if (level != null && level < batteryAlertThreshold) {
          alerts.add(RoomAlert(
            severity: RoomAlertSeverity.battery,
            title: state.friendlyName,
            condition: '${level.round()}% battery',
            entityId: sensor.entityId,
          ));
        }
    }
  }

  // Config rules: activity notices and maintenance thresholds.
  for (final rule in room.alertRules) {
    final state = lookup(rule.entity);
    if (state == null) continue;
    final matches = rule.matches(state);

    if (!rule.momentary) {
      if (!matches) continue;
    } else {
      // Momentary: remember the triggering state change, show for 10 minutes.
      final key = '${room.id}/${rule.entity}/${rule.label}';
      if (matches) momentaryTriggers[key] = state.lastUpdated;
      final triggeredAt = momentaryTriggers[key];
      if (triggeredAt == null) continue;
      final remaining = momentaryAlertLifetime - now.difference(triggeredAt);
      if (remaining <= Duration.zero) continue;
      if (nextExpiry == null || remaining < nextExpiry) nextExpiry = remaining;
    }

    alerts.add(RoomAlert(
      severity: rule.severity,
      title: rule.label,
      condition: state.friendlyName,
      entityId: rule.entity,
    ));
  }

  // Offline: any room device entity that is unavailable.
  for (final id in room.deviceEntities) {
    final state = lookup(id);
    if (state != null && state.isUnavailable) {
      alerts.add(RoomAlert(
        severity: RoomAlertSeverity.offline,
        title: state.friendlyName,
        condition: 'Offline',
        entityId: id,
      ));
    }
  }

  alerts.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return (alerts: alerts, nextExpiry: nextExpiry);
}

String _safetyCondition(String deviceClass) => switch (deviceClass) {
      'moisture' => 'Leak detected',
      'gas' => 'Gas detected',
      'smoke' => 'Smoke detected',
      'carbon_monoxide' => 'CO detected',
      _ => 'Triggered',
    };

/// Last-trigger timestamps for momentary rules, shared across recomputations.
final _momentaryTriggersProvider =
    Provider<Map<String, DateTime>>((ref) => {});

/// Severity-ordered alerts for one room. Empty list means all clear.
final roomAlertsProvider =
    Provider.autoDispose.family<List<RoomAlert>, String>((ref, roomId) {
  final room = HaEntities.roomById(roomId);
  final result = computeRoomAlerts(
    room: room,
    discovered: ref.watch(roomAlertEntitiesProvider(roomId)),
    lookup: (id) => ref.watch(entityStateProvider(id)).valueOrNull,
    momentaryTriggers: ref.watch(_momentaryTriggersProvider),
    now: DateTime.now(),
  );

  // Recompute when the soonest momentary alert expires.
  final expiry = result.nextExpiry;
  if (expiry != null) {
    final timer = Timer(expiry + const Duration(seconds: 1), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return result.alerts;
});
