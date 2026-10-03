// CapabilityLightControl renders exactly the rungs a fixture advertises, and
// routes each rung to the right service call. Covers the heterogeneous fleet:
// on/off-only fixtures (including role-labelled switches), dimmable lights,
// tunable white, stepped-colour-temp template lights, and full-colour bulbs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/ha/models/light_capabilities.dart';
import 'package:ha_flutter/ha/models/room_lighting.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/capability_light_control.dart';
import 'package:ha_flutter/shared/widgets/light_color_picker.dart';
import 'package:ha_flutter/shared/widgets/light_effect_selector.dart';
import 'package:ha_flutter/shared/widgets/power_toggle.dart';

class _RecordingHaService implements HaService {
  final calls = <String>[];
  final data = <Map<String, dynamic>?>[];

  @override
  Future<void> call(String domain, String service,
      {Map<String, dynamic>? data, String? target}) async {
    calls.add('$domain.$service');
    this.data.add(data);
  }

  @override
  Future<void> toggle(String entityId) async => calls.add('toggle');

  @override
  Future<void> turnOn(String entityId, [Map<String, dynamic>? extra]) async {
    calls.add('${entityId.split('.').first}.turn_on');
    data.add(extra);
  }

  @override
  Future<void> turnOff(String entityId) async =>
      calls.add('${entityId.split('.').first}.turn_off');
}

EntityState _s(String id, String state,
        [Map<String, dynamic> attrs = const {}]) =>
    EntityState(
      entityId: id,
      state: state,
      attributes: attrs,
      lastUpdated: DateTime(2026),
    );

LightingFixture _fixture(
  String entityId, {
  String name = 'Fixture',
  List<int> steps = const [],
  bool isTemplate = false,
}) =>
    LightingFixture(
      entityId: entityId,
      name: name,
      capabilities: LightCapabilities(
        rungs: const {LightRung.onOff},
        colorTempSteps: steps,
      ),
      isTemplate: isTemplate,
    );

Future<void> _pump(
  WidgetTester tester, {
  required LightingFixture fixture,
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
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: CapabilityLightControl(fixture: fixture),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('on/off-only light renders a toggle and no sliders',
      (tester) async {
    final service = _RecordingHaService();
    await _pump(
      tester,
      fixture: _fixture('light.binary'),
      states: {
        'light.binary': _s('light.binary', 'off', const {
          'friendly_name': 'Binary',
          'supported_color_modes': ['onoff'],
        }),
      },
      service: service,
    );

    expect(find.byType(PowerToggle), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(find.text('Off'), findsOneWidget);
  });

  testWidgets('role-labelled switch renders as an on/off fixture',
      (tester) async {
    final service = _RecordingHaService();
    await _pump(
      tester,
      fixture: _fixture('switch.entry_switch_l1', name: 'Entry'),
      states: {
        'switch.entry_switch_l1': _s('switch.entry_switch_l1', 'on',
            const {'friendly_name': 'Entry switch'}),
      },
      service: service,
    );

    expect(find.byType(Slider), findsNothing);
    expect(find.text('On'), findsOneWidget);

    await tester.tap(find.byType(PowerToggle));
    await tester.pump();
    // Domain is derived from the entity id, so a switch fixture turns off via
    // switch.turn_off without any special-casing.
    expect(service.calls, contains('switch.turn_off'));
  });

  testWidgets('dimmable light exposes brightness; drag to 0 turns it off',
      (tester) async {
    final service = _RecordingHaService();
    await _pump(
      tester,
      fixture: _fixture('light.dimmable'),
      states: {
        'light.dimmable': _s('light.dimmable', 'on', const {
          'friendly_name': 'Dimmable',
          'brightness': 200,
          'supported_color_modes': ['brightness'],
        }),
      },
      service: service,
    );

    expect(find.byType(Slider), findsOneWidget);
    // Status reports the live brightness percentage.
    expect(find.textContaining('78%'), findsWidgets);

    await tester.drag(find.byType(Slider), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(service.calls, contains('light.turn_off'));
  });

  testWidgets('tunable white exposes brightness + colour temp, not colour',
      (tester) async {
    final service = _RecordingHaService();
    await _pump(
      tester,
      fixture: _fixture('light.tunable'),
      states: {
        'light.tunable': _s('light.tunable', 'on', const {
          'friendly_name': 'Tunable',
          'brightness': 255,
          'supported_color_modes': ['color_temp'],
          'min_color_temp_kelvin': 2000,
          'max_color_temp_kelvin': 6500,
          'color_temp_kelvin': 4000,
        }),
      },
      service: service,
    );

    // Brightness + colour temperature.
    expect(find.byType(Slider), findsNWidgets(2));
    // No expression disclosure at all for a fixture with neither colour
    // nor effects.
    expect(find.text('Colour & effects'), findsNothing);
    expect(find.byType(LightColorPicker), findsNothing);
  });

  testWidgets('stepped template light snaps colour temp to discrete values',
      (tester) async {
    final service = _RecordingHaService();
    await _pump(
      tester,
      fixture: _fixture(
        'light.bedroom_light',
        steps: const [2700, 4000, 6500],
        isTemplate: true,
      ),
      states: {
        'light.bedroom_light': _s('light.bedroom_light', 'on', const {
          'friendly_name': 'Bedroom Light',
          'brightness': 255,
          'supported_color_modes': ['color_temp'],
          'color_temp_kelvin': 2700,
        }),
      },
      service: service,
    );

    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    // Indexed over the accepted values (0..2), not swept over kelvin — which is
    // what distinguishes it from the continuous brightness slider (max 100).
    final stepped = sliders.firstWhere((s) => s.max == 2);
    expect(stepped.divisions, 2);

    await tester.drag(find.byType(Slider).last, const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(service.calls, contains('light.turn_on'));
    // Whatever the drag distance, the applied value is one of the steps.
    final applied = service.data
        .whereType<Map<String, dynamic>>()
        .where((d) => d.containsKey('color_temp_kelvin'))
        .map((d) => d['color_temp_kelvin'] as int)
        .toList();
    expect(applied, isNotEmpty);
    for (final k in applied) {
      expect([2700, 4000, 6500], contains(k));
    }
  });

  testWidgets('colour-capable light offers colour and effects on disclosure',
      (tester) async {
    final service = _RecordingHaService();
    await _pump(
      tester,
      fixture: _fixture('light.rgbw'),
      states: {
        'light.rgbw': _s('light.rgbw', 'on', const {
          'friendly_name': 'RGBW',
          'brightness': 255,
          'supported_color_modes': ['color_temp', 'rgb'],
          'effect_list': ['none', 'colorloop'],
          'effect': 'colorloop',
        }),
      },
      service: service,
    );

    // Collapsed by default — expression stays out of the way.
    expect(find.byType(LightColorPicker), findsNothing);
    expect(find.byType(LightEffectSelector), findsNothing);
    expect(find.text('Colour & effects'), findsOneWidget);

    await tester.tap(find.text('Colour & effects'));
    await tester.pumpAndSettle();

    expect(find.byType(LightColorPicker), findsOneWidget);
    expect(find.byType(LightEffectSelector), findsOneWidget);
    // Active effect appears in the status line.
    expect(find.textContaining('colorloop'), findsWidgets);
  });

  testWidgets('unavailable fixture is dimmed and non-interactive',
      (tester) async {
    final service = _RecordingHaService();
    await _pump(
      tester,
      fixture: _fixture('light.gone'),
      states: {
        'light.gone': _s('light.gone', 'unavailable',
            const {'friendly_name': 'Gone'}),
      },
      service: service,
    );

    expect(find.text('Unavailable'), findsOneWidget);
    await tester.tap(find.byType(PowerToggle), warnIfMissed: false);
    await tester.pump();
    expect(service.calls, isEmpty);
  });
}
