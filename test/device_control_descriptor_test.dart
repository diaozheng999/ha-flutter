// Descriptor power semantics (incl. climate cool fallback), status-line
// grammar (D13), and severity mapping directions (rising-bad / falling-bad).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/shared/widgets/device_control_descriptor.dart';
import 'package:ha_flutter/shared/widgets/reading_pill.dart';

class _Call {
  final String domain;
  final String service;
  final Map<String, dynamic>? data;
  _Call(this.domain, this.service, this.data);
  @override
  String toString() => '$domain.$service ${data ?? {}}';
}

class _RecordingHaService implements HaService {
  final calls = <_Call>[];

  @override
  Future<void> call(String domain, String service,
      {Map<String, dynamic>? data, String? target}) async {
    calls.add(_Call(domain, service, data));
  }

  @override
  Future<void> toggle(String entityId) async {
    calls.add(_Call(entityId.split('.').first, 'toggle', {'entity_id': entityId}));
  }

  @override
  Future<void> turnOn(String entityId, [Map<String, dynamic>? extra]) async {
    calls.add(_Call(entityId.split('.').first, 'turn_on',
        {'entity_id': entityId, ...?extra}));
  }

  @override
  Future<void> turnOff(String entityId) async {
    calls.add(_Call(entityId.split('.').first, 'turn_off', {'entity_id': entityId}));
  }
}

EntityState _state(String id, String state,
        [Map<String, dynamic> attrs = const {}]) =>
    EntityState(
        entityId: id, state: state, attributes: attrs, lastUpdated: DateTime.now());

/// Pumps a Consumer that resolves the descriptor once and hands it back.
Future<DeviceControlDescriptor> _resolve(
  WidgetTester tester, {
  required RoomDevice device,
  required Map<String, EntityState> states,
  required HaService service,
  List<String> roomLights = const [],
}) async {
  late DeviceControlDescriptor captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        entityStateProvider.overrideWith(
            (ref, id) => Stream.value(states[id] ?? EntityState.unknown(id))),
        haServiceProvider.overrideWithValue(service),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          captured = DeviceControlDescriptor.describe(ref, device,
              roomLights: roomLights);
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pump();
  return captured;
}

RoomDevice _device(DeviceRole role, Map<String, String> entities,
        {String name = 'Test'}) =>
    RoomDevice(deviceId: 'd', name: name, role: role, entities: entities);

void main() {
  group('severity mappings', () {
    test('rising-bad (PM2.5) escalates with the value', () {
      final m = ReadingSpec.pm25;
      expect(m(8), Severity.nominal);
      expect(m(20), Severity.warning);
      expect(m(35), Severity.warning); // inclusive upper of the warning band
      expect(m(45), Severity.critical);
    });

    test('falling-bad (battery) escalates as the value drops', () {
      final m = ReadingSpec.fallingBad(warning: 20, critical: 10);
      expect(m(50), Severity.nominal);
      expect(m(20), Severity.warning);
      expect(m(8), Severity.critical);
    });
  });

  group('hvac mode label', () {
    test('canonical labels', () {
      expect(hvacModeLabel('cool'), 'Cool');
      expect(hvacModeLabel('heat_cool'), 'Auto');
      expect(hvacModeLabel('fan_only'), 'Fan');
    });
  });

  group('climate descriptor', () {
    testWidgets('status combines temperature and mode', (tester) async {
      final d = await _resolve(
        tester,
        device: _device(DeviceRole.climate, {'primary': 'climate.ac'}),
        service: _RecordingHaService(),
        states: {
          'climate.ac': _state('climate.ac', 'cool', {
            'current_temperature': 24.5,
            'hvac_modes': ['off', 'cool'],
          }),
        },
      );
      expect(d.statusLine, '24.5° · Cool');
      expect(d.isOn, isTrue);
      expect(d.glowColor, isNotNull); // cooling glows
    });

    testWidgets('off is just Off', (tester) async {
      final d = await _resolve(
        tester,
        device: _device(DeviceRole.climate, {'primary': 'climate.ac'}),
        service: _RecordingHaService(),
        states: {
          'climate.ac': _state('climate.ac', 'off', {
            'hvac_modes': ['off', 'cool'],
          }),
        },
      );
      expect(d.statusLine, 'Off');
      expect(d.isOn, isFalse);
      expect(d.glowColor, isNull);
    });

    testWidgets('power-on selects cool when available', (tester) async {
      final service = _RecordingHaService();
      final d = await _resolve(
        tester,
        device: _device(DeviceRole.climate, {'primary': 'climate.ac'}),
        service: service,
        states: {
          'climate.ac': _state('climate.ac', 'off', {
            'hvac_modes': ['off', 'cool', 'heat'],
          }),
        },
      );
      d.togglePower!();
      final last = service.calls.last;
      expect(last.service, 'set_hvac_mode');
      expect(last.data!['hvac_mode'], 'cool');
    });

    testWidgets('power-on falls back to first non-off mode', (tester) async {
      final service = _RecordingHaService();
      final d = await _resolve(
        tester,
        device: _device(DeviceRole.climate, {'primary': 'climate.ac'}),
        service: service,
        states: {
          'climate.ac': _state('climate.ac', 'off', {
            'hvac_modes': ['off', 'heat'],
          }),
        },
      );
      d.togglePower!();
      final last = service.calls.last;
      expect(last.service, 'set_hvac_mode');
      expect(last.data!['hvac_mode'], 'heat');
    });

    testWidgets('unavailable disables toggle and reads Unavailable',
        (tester) async {
      final d = await _resolve(
        tester,
        device: _device(DeviceRole.climate, {'primary': 'climate.ac'}),
        service: _RecordingHaService(),
        states: {
          'climate.ac': _state('climate.ac', 'unavailable'),
        },
      );
      expect(d.statusLine, 'Unavailable');
      expect(d.togglePower, isNull);
    });
  });

  group('fan descriptor', () {
    testWidgets('running fan reads a percentage and does not glow',
        (tester) async {
      final d = await _resolve(
        tester,
        device: _device(DeviceRole.fan, {'primary': 'fan.f'}),
        service: _RecordingHaService(),
        states: {
          'fan.f': _state('fan.f', 'on', {'percentage': 75}),
        },
      );
      expect(d.statusLine, '75%');
      expect(d.glowColor, isNull);
    });

    testWidgets('toggle turns a running fan off', (tester) async {
      final service = _RecordingHaService();
      final d = await _resolve(
        tester,
        device: _device(DeviceRole.fan, {'primary': 'fan.f'}),
        service: service,
        states: {
          'fan.f': _state('fan.f', 'on', {'percentage': 60}),
        },
      );
      d.togglePower!();
      expect(service.calls.last.service, 'turn_off');
    });
  });

  group('air purifier descriptor', () {
    testWidgets('status combines mode and PM2.5', (tester) async {
      final d = await _resolve(
        tester,
        device: _device(DeviceRole.airPurifier, {
          'power': 'switch.p',
          'mode': 'select.p',
          'pm25': 'sensor.pm',
        }),
        service: _RecordingHaService(),
        states: {
          'switch.p': _state('switch.p', 'on'),
          'select.p': _state('select.p', 'Auto'),
          'sensor.pm': _state('sensor.pm', '8'),
        },
      );
      expect(d.statusLine, 'Auto · PM2.5 8');
    });

    testWidgets('readings persist while off with severity colour',
        (tester) async {
      final d = await _resolve(
        tester,
        device: _device(DeviceRole.airPurifier, {
          'power': 'switch.p',
          'pm25': 'sensor.pm',
        }),
        service: _RecordingHaService(),
        states: {
          'switch.p': _state('switch.p', 'off'),
          'sensor.pm': _state('sensor.pm', '14'),
        },
      );
      expect(d.statusLine, 'Off');
      expect(d.sensors, hasLength(1));
      expect(d.sensors.first.level, Severity.warning);
    });
  });

  group('light group descriptor', () {
    testWidgets('counts individual lights on', (tester) async {
      final d = await _resolve(
        tester,
        device: _device(DeviceRole.light, {'primary': 'light.group'}),
        roomLights: ['light.a', 'light.b'],
        service: _RecordingHaService(),
        states: {
          'light.group': _state('light.group', 'on'),
          'light.a': _state('light.a', 'on'),
          'light.b': _state('light.b', 'off'),
        },
      );
      expect(d.statusLine, '1 on');
    });

    testWidgets('group on with no individuals reads On', (tester) async {
      final d = await _resolve(
        tester,
        device: _device(DeviceRole.light, {'primary': 'light.group'}),
        service: _RecordingHaService(),
        states: {
          'light.group': _state('light.group', 'on'),
        },
      );
      expect(d.statusLine, 'On');
    });
  });
}
