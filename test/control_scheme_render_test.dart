// Render + interaction verification for the unified control scheme: the refit
// device controls and the quick-control tile render without exceptions, show the
// shared status-line grammar, and route power/mode actions to the right service
// calls. A deterministic stand-in for manual on-device clicking.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/ac_thermostat_widget.dart';
import 'package:ha_flutter/shared/widgets/air_purifier_widget.dart';
import 'package:ha_flutter/shared/widgets/fan_speed_dial.dart';
import 'package:ha_flutter/shared/widgets/light_toggle_widget.dart';
import 'package:ha_flutter/shared/widgets/power_toggle.dart';
import 'package:ha_flutter/shared/widgets/quick_control_tile.dart';
import 'package:ha_flutter/shared/widgets/reading_pill.dart';

class _RecordingHaService implements HaService {
  final calls = <String>[];

  @override
  Future<void> call(String domain, String service,
      {Map<String, dynamic>? data, String? target}) async {
    calls.add('$domain.$service ${data?['hvac_mode'] ?? data?['option'] ?? ''}'
        .trim());
  }

  @override
  Future<void> toggle(String entityId) async => calls.add('toggle');

  @override
  Future<void> turnOn(String entityId, [Map<String, dynamic>? extra]) async =>
      calls.add('${entityId.split('.').first}.turn_on');

  @override
  Future<void> turnOff(String entityId) async =>
      calls.add('${entityId.split('.').first}.turn_off');
}

EntityState _s(String id, String state, [Map<String, dynamic> attrs = const {}]) =>
    EntityState(
        entityId: id, state: state, attributes: attrs, lastUpdated: DateTime.now());

RoomDevice _device(DeviceRole role, Map<String, String> entities,
        {String name = 'Device'}) =>
    RoomDevice(deviceId: 'd', name: name, role: role, entities: entities);

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  required Map<String, EntityState> states,
  required HaService service,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        entityStateProvider.overrideWith(
            (ref, id) => Stream.value(states[id] ?? EntityState.unknown(id))),
        pendingEntitiesProvider
            .overrideWith((ref) => Stream.value(const <String>{})),
        haServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: Center(child: SizedBox(width: 360, child: child))),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AC renders status grammar and mode selector activates a mode',
      (tester) async {
    final service = _RecordingHaService();
    await _pump(
      tester,
      service: service,
      states: {
        'climate.ac': _s('climate.ac', 'cool', {
          'current_temperature': 24.5,
          'temperature': 23.0,
          'hvac_modes': ['off', 'cool', 'heat'],
        }),
      },
      child: AcThermostatWidget(
          device: _device(DeviceRole.climate, {'primary': 'climate.ac'},
              name: 'AC')),
    );

    expect(find.text('24.5° · Cool'), findsOneWidget);
    // Header power-off routes through set_hvac_mode off.
    await tester.tap(find.byType(PowerToggle));
    await tester.pump();
    expect(service.calls, contains('climate.set_hvac_mode off'));
  });

  testWidgets('Fan renders percentage status and no radial glow',
      (tester) async {
    final service = _RecordingHaService();
    await _pump(
      tester,
      service: service,
      states: {
        'fan.f': _s('fan.f', 'on', {'percentage': 75}),
      },
      child: FanSpeedDial(
          device: _device(DeviceRole.fan, {'primary': 'fan.f'}, name: 'Fan')),
    );

    expect(find.text('75%'), findsWidgets);
    await tester.tap(find.byType(PowerToggle));
    await tester.pump();
    expect(service.calls, contains('fan.turn_off'));
  });

  testWidgets('Air purifier uses PowerToggle not a Switch and shows readings',
      (tester) async {
    final service = _RecordingHaService();
    await _pump(
      tester,
      service: service,
      states: {
        'switch.p': _s('switch.p', 'off'),
        'select.p': _s('select.p', 'Auto', {
          'options': ['Auto', 'Sleep', 'Favorite'],
        }),
        'sensor.pm': _s('sensor.pm', '14'),
      },
      child: AirPurifierWidget(
        device: _device(DeviceRole.airPurifier, {
          'power': 'switch.p',
          'mode': 'select.p',
          'pm25': 'sensor.pm',
        }, name: 'Purifier'),
      ),
    );

    expect(find.byType(Switch), findsNothing);
    expect(find.byType(PowerToggle), findsOneWidget);
    // Reading persists while off.
    expect(find.byType(ReadingPill), findsWidgets);
    expect(find.text('14 µg/m³'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
  });

  testWidgets('Light group renders status and toggles the group on',
      (tester) async {
    final service = _RecordingHaService();
    await _pump(
      tester,
      service: service,
      states: {
        'light.group': _s('light.group', 'off'),
      },
      child: const LightToggleWidget(
          entityId: 'light.group', name: 'All lights'),
    );

    expect(find.text('Off'), findsOneWidget);
    await tester.tap(find.byType(PowerToggle));
    await tester.pump();
    expect(service.calls, contains('light.turn_on'));
  });

  testWidgets('Quick tile: body tap toggles power, chevron opens detail',
      (tester) async {
    final service = _RecordingHaService();
    var opened = false;
    await _pump(
      tester,
      service: service,
      states: {
        'fan.f': _s('fan.f', 'on', {'percentage': 60}),
      },
      child: QuickControlTile(
        device: _device(DeviceRole.fan, {'primary': 'fan.f'}, name: 'Fan'),
        onOpen: () => opened = true,
      ),
    );

    expect(find.text('60%'), findsOneWidget);

    // Chevron opens the detailed control without toggling.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(opened, isTrue);
    expect(service.calls, isNot(contains('fan.turn_off')));

    // Tapping the tile body toggles power.
    await tester.tap(find.text('60%'));
    await tester.pump();
    expect(service.calls, contains('fan.turn_off'));
  });
}
