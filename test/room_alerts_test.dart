// Alert derivation: registry classification, severity ordering, all-clear
// emptiness, and momentary activity lifetime. All pure — no providers needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/features/room/alerts/alert_discovery.dart';
import 'package:ha_flutter/features/room/alerts/room_alert.dart';
import 'package:ha_flutter/features/room/alerts/room_alerts_provider.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/ha/models/registry_entry.dart';

EntityState _state(
  String id,
  String state, {
  Map<String, dynamic> attributes = const {},
  DateTime? lastUpdated,
}) {
  return EntityState(
    entityId: id,
    state: state,
    attributes: attributes,
    lastUpdated: lastUpdated ?? DateTime.now(),
  );
}

void main() {
  group('classifyAlertSensors', () {
    final entities = [
      // Direct area assignment.
      const EntityRegistryEntry(
          entityId: 'binary_sensor.kitchen_leak', areaId: 'kitchen'),
      // Area via device.
      const EntityRegistryEntry(
          entityId: 'sensor.button_battery', deviceId: 'dev1'),
      // Problem class.
      const EntityRegistryEntry(
          entityId: 'binary_sensor.purifier_problem', areaId: 'bedroom'),
      // No area anywhere → ignored.
      const EntityRegistryEntry(entityId: 'binary_sensor.orphan_leak'),
      // Area outside known rooms → ignored.
      const EntityRegistryEntry(
          entityId: 'binary_sensor.garage_leak', areaId: 'garage'),
      // Disabled → ignored.
      const EntityRegistryEntry(
          entityId: 'binary_sensor.disabled_leak',
          areaId: 'kitchen',
          disabledBy: 'user'),
      // No device class → ignored.
      const EntityRegistryEntry(
          entityId: 'binary_sensor.no_class', areaId: 'kitchen'),
      // Wrong domain for battery class → ignored.
      const EntityRegistryEntry(
          entityId: 'binary_sensor.battery_binary', areaId: 'kitchen'),
    ];

    final result = classifyAlertSensors(
      entities: entities,
      deviceAreas: {'dev1': 'living_room'},
      deviceClassByEntity: {
        'binary_sensor.kitchen_leak': 'moisture',
        'sensor.button_battery': 'battery',
        'binary_sensor.purifier_problem': 'problem',
        'binary_sensor.orphan_leak': 'moisture',
        'binary_sensor.garage_leak': 'moisture',
        'binary_sensor.disabled_leak': 'moisture',
        'binary_sensor.battery_binary': 'battery',
      },
      roomIds: {'living_room', 'kitchen', 'bedroom'},
    );

    test('moisture binary sensor with direct area maps to safety', () {
      expect(result['kitchen'], hasLength(1));
      expect(result['kitchen']!.single.kind, DiscoveredAlertKind.safety);
      expect(result['kitchen']!.single.entityId, 'binary_sensor.kitchen_leak');
    });

    test('battery sensor resolves area through its device', () {
      expect(result['living_room']!.single.entityId, 'sensor.button_battery');
      expect(result['living_room']!.single.kind, DiscoveredAlertKind.battery);
    });

    test('problem class maps to maintenance kind', () {
      expect(result['bedroom']!.single.kind, DiscoveredAlertKind.problem);
    });

    test('unassigned, foreign-area, disabled, and classless are ignored', () {
      final all = result.values.expand((s) => s.map((e) => e.entityId));
      expect(all, isNot(contains('binary_sensor.orphan_leak')));
      expect(all, isNot(contains('binary_sensor.garage_leak')));
      expect(all, isNot(contains('binary_sensor.disabled_leak')));
      expect(all, isNot(contains('binary_sensor.no_class')));
      expect(all, isNot(contains('binary_sensor.battery_binary')));
    });
  });

  group('computeRoomAlerts', () {
    const room = RoomConfig(
      id: 'testroom',
      name: 'Test Room',
      lightGroup: 'light.test_group',
      individualLights: ['light.test_a'],
      fan: 'fan.test_fan',
      alertRules: [
        AlertRule.stateIn(
          entity: 'sensor.washer',
          states: ['finished'],
          severity: RoomAlertSeverity.activity,
          label: 'Laundry done',
        ),
        AlertRule.stateIn(
          entity: 'binary_sensor.doorbell',
          states: ['on'],
          severity: RoomAlertSeverity.activity,
          label: 'Doorbell',
          momentary: true,
        ),
        AlertRule.numericBelow(
          entity: 'sensor.filter_life',
          threshold: 10,
          severity: RoomAlertSeverity.maintenance,
          label: 'Replace filter',
        ),
      ],
    );

    const discovered = [
      DiscoveredAlertSensor(
        entityId: 'binary_sensor.leak',
        kind: DiscoveredAlertKind.safety,
        deviceClass: 'moisture',
      ),
      DiscoveredAlertSensor(
        entityId: 'sensor.remote_battery',
        kind: DiscoveredAlertKind.battery,
        deviceClass: 'battery',
      ),
    ];

    RoomAlertsResult compute(
      Map<String, EntityState> states, {
      Map<String, DateTime>? triggers,
      DateTime? now,
    }) {
      return computeRoomAlerts(
        room: room,
        discovered: discovered,
        lookup: (id) => states[id],
        momentaryTriggers: triggers ?? {},
        now: now ?? DateTime.now(),
      );
    }

    test('healthy room produces no alerts', () {
      final result = compute({
        'light.test_group': _state('light.test_group', 'on'),
        'light.test_a': _state('light.test_a', 'off'),
        'fan.test_fan': _state('fan.test_fan', 'on'),
        'binary_sensor.leak': _state('binary_sensor.leak', 'off'),
        'sensor.remote_battery': _state('sensor.remote_battery', '85'),
        'sensor.washer': _state('sensor.washer', 'washing'),
        'sensor.filter_life': _state('sensor.filter_life', '74'),
      });
      expect(result.alerts, isEmpty);
    });

    test('alerts are ordered by severity tier', () {
      final result = compute({
        'sensor.remote_battery': _state('sensor.remote_battery', '12'),
        'light.test_a': _state('light.test_a', 'unavailable'),
        'binary_sensor.leak': _state('binary_sensor.leak', 'on'),
        'sensor.washer': _state('sensor.washer', 'finished'),
        'sensor.filter_life': _state('sensor.filter_life', '8'),
      });
      expect(result.alerts.map((a) => a.severity).toList(), [
        RoomAlertSeverity.safety,
        RoomAlertSeverity.activity,
        RoomAlertSeverity.offline,
        RoomAlertSeverity.maintenance,
        RoomAlertSeverity.battery,
      ]);
      expect(result.alerts.first.condition, 'Leak detected');
      expect(result.alerts.last.condition, '12% battery');
    });

    test('battery at threshold does not alert', () {
      final result = compute({
        'sensor.remote_battery': _state('sensor.remote_battery', '20'),
      });
      expect(result.alerts, isEmpty);
    });

    test('unavailable device produces offline alert and clears on return', () {
      final down = compute({
        'fan.test_fan': _state('fan.test_fan', 'unavailable'),
      });
      expect(down.alerts.single.severity, RoomAlertSeverity.offline);
      expect(down.alerts.single.condition, 'Offline');

      final up = compute({
        'fan.test_fan': _state('fan.test_fan', 'on'),
      });
      expect(up.alerts, isEmpty);
    });

    test('stateful activity alert clears with the state', () {
      final during = compute({
        'sensor.washer': _state('sensor.washer', 'finished'),
      });
      expect(during.alerts.single.title, 'Laundry done');

      final after = compute({
        'sensor.washer': _state('sensor.washer', 'idle'),
      });
      expect(after.alerts, isEmpty);
    });

    test('momentary alert persists after the state clears, then expires', () {
      final triggers = <String, DateTime>{};
      final rangAt = DateTime.now().subtract(const Duration(minutes: 2));

      // Ring observed while on → trigger recorded.
      final ringing = compute(
        {'binary_sensor.doorbell': _state('binary_sensor.doorbell', 'on',
            lastUpdated: rangAt)},
        triggers: triggers,
      );
      expect(ringing.alerts.single.title, 'Doorbell');

      // Sensor back off 2 minutes after the ring → still visible.
      final afterOff = compute(
        {'binary_sensor.doorbell': _state('binary_sensor.doorbell', 'off')},
        triggers: triggers,
      );
      expect(afterOff.alerts.single.title, 'Doorbell');
      expect(afterOff.nextExpiry, isNotNull);
      expect(afterOff.nextExpiry!, lessThanOrEqualTo(
          momentaryAlertLifetime - const Duration(minutes: 1)));

      // 11 minutes after the ring → expired.
      final later = compute(
        {'binary_sensor.doorbell': _state('binary_sensor.doorbell', 'off')},
        triggers: triggers,
        now: rangAt.add(const Duration(minutes: 11)),
      );
      expect(later.alerts, isEmpty);
    });

    test('unavailable rule entity never matches', () {
      final result = compute({
        'sensor.filter_life': _state('sensor.filter_life', 'unavailable'),
      });
      expect(result.alerts, isEmpty);
    });
  });
}
