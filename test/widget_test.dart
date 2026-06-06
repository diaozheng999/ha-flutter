// Unit tests for the dashboard's HA layer and helpers. These run without a
// live Home Assistant connection.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/ha/repository/entity_state_repository.dart';
import 'package:ha_flutter/shared/util/hs_color_converter.dart';

void main() {
  group('EntityState', () {
    test('parses HA /api/states JSON', () {
      final s = EntityState.fromJson({
        'entity_id': 'light.kitchen',
        'state': 'on',
        'attributes': {'brightness': 128, 'hs_color': [30, 80]},
        'last_updated': '2026-06-06T10:00:00+00:00',
      });
      expect(s.domain, 'light');
      expect(s.isOn, isTrue);
      expect(s.attrInt('brightness'), 128);
      expect(s.hsColor?.hue, 30);
    });

    test('applyDiff merges and removes attributes', () {
      final base = EntityState.fromJson({
        'entity_id': 'climate.living_room_ac',
        'state': 'cool',
        'attributes': {'temperature': 24.0, 'stale': 1},
      });
      final next = base.applyDiff(
        state: 'off',
        changedAttributes: {'temperature': 22.5},
        removedAttributes: ['stale'],
      );
      expect(next.state, 'off');
      expect(next.attrDouble('temperature'), 22.5);
      expect(next.attributes.containsKey('stale'), isFalse);
    });
  });

  group('EntityStateRepository', () {
    test('stream replays the cached value then emits updates', () async {
      final repo = EntityStateRepository();
      repo.put(EntityState.fromJson({
        'entity_id': 'fan.study_fan',
        'state': 'on',
        'attributes': {'percentage': 50},
      }));

      final first = await repo.stream('fan.study_fan').first;
      expect(first.attrInt('percentage'), 50);
      repo.dispose();
    });
  });

  group('HsColorConverter', () {
    test('falls back to warm white when no hs_color', () {
      final light = EntityState.fromJson({
        'entity_id': 'light.x',
        'state': 'on',
        'attributes': {},
      });
      expect(HsColorConverter.glowFor(light), HsColorConverter.warmWhite);
    });

    test('ambientTint returns null when all lights are off', () {
      final off = EntityState.fromJson({
        'entity_id': 'light.x',
        'state': 'off',
        'attributes': {'hs_color': [200, 80]},
      });
      expect(HsColorConverter.ambientTint([off]), isNull);
    });
  });

  group('HaEntities', () {
    test('allowlist covers room devices and is de-duplicated', () {
      final list = HaEntities.allowlist;
      expect(list.toSet().length, list.length);
      expect(list, contains('light.living_room_lights'));
      expect(list, contains(HaEntities.weather));
      expect(list, contains(HaEntities.sun));
    });

    test('every room resolves by id', () {
      for (final room in HaEntities.rooms) {
        expect(HaEntities.roomById(room.id).name, room.name);
      }
    });
  });

  test('app theme builds', () {
    expect(ThemeData(brightness: Brightness.dark), isA<ThemeData>());
  });
}
