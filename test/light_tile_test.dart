// LightTile behavior: dragging the inline brightness slider to zero must call
// light.turn_off rather than turn_on with zero brightness.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/light_tile.dart';

class _RecordingHaService implements HaService {
  final calls = <String>[];

  @override
  Future<void> call(String domain, String service,
      {Map<String, dynamic>? data, String? target}) async {
    calls.add('$domain.$service');
  }

  @override
  Future<void> toggle(String entityId) async => calls.add('toggle');

  @override
  Future<void> turnOn(String entityId, [Map<String, dynamic>? extra]) async =>
      calls.add('turn_on');

  @override
  Future<void> turnOff(String entityId) async => calls.add('turn_off');
}

void main() {
  testWidgets('dragging brightness to 0 calls light.turn_off', (tester) async {
    final service = _RecordingHaService();
    final state = EntityState(
      entityId: 'light.test',
      state: 'on',
      attributes: const {
        'friendly_name': 'Test light',
        'brightness': 200,
        'supported_color_modes': ['brightness'],
      },
      lastUpdated: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entityStateProvider.overrideWith((ref, id) => Stream.value(state)),
          pendingEntitiesProvider
              .overrideWith((ref) => Stream.value(const <String>{})),
          haServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: LightTile(entityId: 'light.test'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test light'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    // Drag the thumb well past the left edge → value 0 → turn_off.
    await tester.drag(find.byType(Slider), const Offset(-400, 0));
    // Let the 200 ms debouncer fire.
    await tester.pump(const Duration(milliseconds: 300));

    expect(service.calls, contains('turn_off'));
    expect(service.calls, isNot(contains('turn_on')));
  });

  testWidgets('unavailable light renders disabled with no slider interaction',
      (tester) async {
    final service = _RecordingHaService();
    final state = EntityState(
      entityId: 'light.test',
      state: 'unavailable',
      attributes: const {'friendly_name': 'Test light'},
      lastUpdated: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entityStateProvider.overrideWith((ref, id) => Stream.value(state)),
          pendingEntitiesProvider
              .overrideWith((ref) => Stream.value(const <String>{})),
          haServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: LightTile(entityId: 'light.test'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unavailable'), findsOneWidget);
    await tester.tap(find.byType(LightTile), warnIfMissed: false);
    await tester.pump();
    expect(service.calls, isEmpty);
  });
}
