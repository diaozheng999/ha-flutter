import 'package:flutter_test/flutter_test.dart';
import 'package:ha_flutter/ha/lighting_resolver.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/ha/models/light_capabilities.dart';
import 'package:ha_flutter/ha/models/registry_entry.dart';

EntityRegistryEntry _entry(
  String entityId, {
  String? areaId,
  String? deviceId,
  List<String> labels = const [],
  String? platform,
}) =>
    EntityRegistryEntry(
      entityId: entityId,
      areaId: areaId,
      deviceId: deviceId,
      labels: labels,
      platform: platform,
    );

EntityState _state(
  String entityId, {
  String state = 'off',
  List<String>? members,
  List<String> colorModes = const ['brightness'],
  List<String> effects = const [],
  String? friendlyName,
}) =>
    EntityState(
      entityId: entityId,
      state: state,
      attributes: {
        if (members != null) 'entity_id': members,
        if (entityId.startsWith('light.')) 'supported_color_modes': colorModes,
        if (effects.isNotEmpty) 'effect_list': effects,
        if (friendlyName != null) 'friendly_name': friendlyName,
      },
      lastUpdated: DateTime(2026),
    );

StateLookup _lookup(List<EntityState> states) {
  final byId = {for (final s in states) s.entityId: s};
  return (id) => byId[id] ?? EntityState.unknown(id);
}

void main() {
  group('role labels', () {
    test('reads role from a role: label, ignoring unrelated labels', () {
      expect(roleOfLabels(['matterbridge', 'role:task']), 'task');
      expect(roleOfLabels(['matterbridge']), isNull);
      expect(roleOfLabels(['role:']), isNull);
    });
  });

  group('lighting candidates', () {
    test('all enabled lights qualify; switches only when role-labelled', () {
      expect(isLightingCandidate(_entry('light.a')), isTrue);
      expect(isLightingCandidate(_entry('switch.plain')), isFalse);
      expect(
        isLightingCandidate(_entry('switch.wall', labels: ['role:overhead'])),
        isTrue,
      );
    });

    test('disabled entities are excluded', () {
      final e = EntityRegistryEntry(
        entityId: 'light.disabled',
        disabledBy: 'user',
      );
      expect(isLightingCandidate(e), isFalse);
    });
  });

  group('capabilities', () {
    test('brightness-only light exposes on/off + brightness', () {
      final caps = LightCapabilities.fromState(
        _state('light.walkway_spotlight_inner', colorModes: ['brightness']),
      );
      expect(caps.supports(LightRung.brightness), isTrue);
      expect(caps.supports(LightRung.colorTemp), isFalse);
      expect(caps.supports(LightRung.color), isFalse);
    });

    test('onoff-only light is not dimmable', () {
      final caps = LightCapabilities.fromState(
        _state('light.binary', colorModes: ['onoff']),
      );
      expect(caps.isOnOffOnly, isTrue);
    });

    test('switch fixture is on/off only', () {
      final caps = LightCapabilities.fromState(_state('switch.wall'));
      expect(caps.isOnOffOnly, isTrue);
    });

    test('union group exposes colour temp and colour', () {
      // Mirrors light.entry_lights: ["color_temp","rgb","xy"].
      final caps = LightCapabilities.fromState(_state(
        'light.entry_lights',
        colorModes: ['color_temp', 'rgb', 'xy'],
        effects: ['Color', 'blink'],
      ));
      expect(caps.supports(LightRung.colorTemp), isTrue);
      expect(caps.supports(LightRung.color), isTrue);
      expect(caps.supports(LightRung.effects), isTrue);
      expect(caps.effects, contains('blink'));
    });

    test('stepped colour temp comes from config, not detection', () {
      final continuous = LightCapabilities.fromState(
        _state('light.bedroom_light', colorModes: ['color_temp']),
      );
      expect(continuous.isSteppedColorTemp, isFalse);

      final stepped = LightCapabilities.fromState(
        _state('light.bedroom_light', colorModes: ['color_temp']),
        colorTempSteps: [2700, 4000, 6500],
      );
      expect(stepped.isSteppedColorTemp, isTrue);
      expect(stepped.colorTempSteps, [2700, 4000, 6500]);
    });
  });

  group('resolveRoomLighting', () {
    test('area-less group is rescued via its members areas', () {
      // light.kitchen_spotlights has area_id: null in the real instance.
      final entities = [
        _entry('light.kitchen_spotlights', platform: 'group'),
        _entry('light.spot1', deviceId: 'd1'),
        _entry('light.spot2', deviceId: 'd2'),
      ];
      final lighting = resolveRoomLighting(
        areaId: 'kitchen',
        entities: entities,
        deviceAreaById: {'d1': 'kitchen', 'd2': 'kitchen'},
        stateOf: _lookup([
          _state('light.kitchen_spotlights',
              members: ['light.spot1', 'light.spot2']),
          _state('light.spot1'),
          _state('light.spot2'),
        ]),
      );
      expect(lighting.isEmpty, isFalse);
      expect(
        lighting.allFixtureIds,
        contains('light.kitchen_spotlights'),
      );
    });

    test('role-labelled group becomes the layer unit with members as drilldown',
        () {
      final entities = [
        _entry('light.kitchen_spotlights',
            platform: 'group', labels: ['role:task']),
        _entry('light.spot1', areaId: 'kitchen'),
        _entry('light.spot2', areaId: 'kitchen'),
      ];
      final lighting = resolveRoomLighting(
        areaId: 'kitchen',
        entities: entities,
        deviceAreaById: const {},
        stateOf: _lookup([
          _state('light.kitchen_spotlights',
              members: ['light.spot1', 'light.spot2']),
          _state('light.spot1'),
          _state('light.spot2'),
        ]),
      );
      expect(lighting.layers, hasLength(1));
      final layer = lighting.layers.single;
      expect(layer.role, 'task');
      expect(layer.unit.entityId, 'light.kitchen_spotlights');
      expect(layer.members.map((m) => m.entityId),
          containsAll(['light.spot1', 'light.spot2']));
      // Members must not also appear in the ungrouped bucket.
      expect(lighting.ungrouped, isEmpty);
    });

    test('unlabelled overlapping parent group is suppressed, extras promoted',
        () {
      // kitchen_lights ⊃ kitchen_spotlights, differing by the ceiling light.
      final entities = [
        _entry('light.kitchen_lights', areaId: 'kitchen', platform: 'group'),
        _entry('light.kitchen_spotlights',
            areaId: 'kitchen', platform: 'group', labels: ['role:task']),
        _entry('light.spot1', areaId: 'kitchen'),
        _entry('light.ceiling', areaId: 'kitchen'),
      ];
      final lighting = resolveRoomLighting(
        areaId: 'kitchen',
        entities: entities,
        deviceAreaById: const {},
        stateOf: _lookup([
          _state('light.kitchen_lights',
              members: ['light.spot1', 'light.ceiling']),
          _state('light.kitchen_spotlights', members: ['light.spot1']),
          _state('light.spot1'),
          _state('light.ceiling'),
        ]),
      );
      expect(lighting.layers, hasLength(1));
      expect(lighting.layers.single.unit.entityId, 'light.kitchen_spotlights');
      final ungroupedIds = lighting.ungrouped.map((f) => f.entityId).toList();
      // The redundant parent group is gone...
      expect(ungroupedIds, isNot(contains('light.kitchen_lights')));
      // ...but its uncovered member is still reachable.
      expect(ungroupedIds, contains('light.ceiling'));
      expect(ungroupedIds, isNot(contains('light.spot1')));
    });

    test('unlabelled fixture with no overlap lands in the ungrouped bucket', () {
      final entities = [
        _entry('light.overhead', areaId: 'living_room', labels: ['role:overhead']),
        _entry('light.living_room_donut', areaId: 'living_room'),
      ];
      final lighting = resolveRoomLighting(
        areaId: 'living_room',
        entities: entities,
        deviceAreaById: const {},
        stateOf: _lookup([
          _state('light.overhead'),
          _state('light.living_room_donut'),
        ]),
      );
      expect(lighting.layers, hasLength(1));
      expect(lighting.ungrouped.map((f) => f.entityId),
          ['light.living_room_donut']);
    });

    test('layers follow the configured role order', () {
      final entities = [
        _entry('light.a', areaId: 'r', labels: ['role:ambient']),
        _entry('light.b', areaId: 'r', labels: ['role:overhead']),
        _entry('light.c', areaId: 'r', labels: ['role:task']),
      ];
      final stateOf = _lookup([
        _state('light.a'),
        _state('light.b'),
        _state('light.c'),
      ]);
      final def = resolveRoomLighting(
        areaId: 'r',
        entities: entities,
        deviceAreaById: const {},
        stateOf: stateOf,
      );
      expect(def.layers.map((l) => l.role), ['overhead', 'task', 'ambient']);

      final overridden = resolveRoomLighting(
        areaId: 'r',
        entities: entities,
        deviceAreaById: const {},
        stateOf: stateOf,
        roleOrder: ['task', 'ambient'],
      );
      // Overridden roles first, then roles outside the override appended.
      expect(overridden.layers.map((l) => l.role),
          ['task', 'ambient', 'overhead']);
    });

    test('non-default role label is honoured', () {
      final lighting = resolveRoomLighting(
        areaId: 'r',
        entities: [
          _entry('light.b', areaId: 'r', labels: ['role:overhead']),
          _entry('light.x', areaId: 'r', labels: ['role:accent']),
        ],
        deviceAreaById: const {},
        stateOf: _lookup([_state('light.b'), _state('light.x')]),
      );
      expect(lighting.layers.map((l) => l.role), ['overhead', 'accent']);
      expect(lighting.layers.last.displayName, 'Accent');
    });

    test('duplicate role picks the group deterministically', () {
      final lighting = resolveRoomLighting(
        areaId: 'r',
        entities: [
          _entry('light.leaf', areaId: 'r', labels: ['role:task']),
          _entry('light.grp',
              areaId: 'r', platform: 'group', labels: ['role:task']),
        ],
        deviceAreaById: const {},
        stateOf: _lookup([
          _state('light.leaf'),
          _state('light.grp', members: ['light.leaf']),
        ]),
      );
      expect(lighting.layers, hasLength(1));
      expect(lighting.layers.single.unit.entityId, 'light.grp');
    });

    test('a member claimed by an earlier layer is not repeated', () {
      // The real overlap: one yeelight belongs to two groups.
      final shared = 'light.yeelink_shared';
      final lighting = resolveRoomLighting(
        areaId: 'r',
        entities: [
          _entry('light.g1',
              areaId: 'r', platform: 'group', labels: ['role:overhead']),
          _entry('light.g2',
              areaId: 'r', platform: 'group', labels: ['role:ambient']),
          _entry(shared, areaId: 'r'),
        ],
        deviceAreaById: const {},
        stateOf: _lookup([
          _state('light.g1', members: [shared]),
          _state('light.g2', members: [shared]),
          _state(shared),
        ]),
      );
      final overhead = lighting.layers.firstWhere((l) => l.role == 'overhead');
      final ambient = lighting.layers.firstWhere((l) => l.role == 'ambient');
      expect(overhead.members.map((m) => m.entityId), [shared]);
      expect(ambient.members, isEmpty);
    });

    test('template light is an opaque leaf, never expanded', () {
      final lighting = resolveRoomLighting(
        areaId: 'bedroom',
        entities: [
          _entry('light.bedroom_light',
              areaId: 'bedroom',
              platform: 'template',
              labels: ['role:overhead']),
        ],
        deviceAreaById: const {},
        stateOf: _lookup([
          // Even if a stray entity_id attribute appeared, it must be ignored.
          _state('light.bedroom_light',
              members: ['light.hidden'], colorModes: ['color_temp']),
        ]),
      );
      final unit = lighting.layers.single.unit;
      expect(unit.isTemplate, isTrue);
      expect(unit.isExpandable, isFalse);
      expect(lighting.layers.single.members, isEmpty);
    });

    test('role-labelled switch resolves as an on/off lighting fixture', () {
      final lighting = resolveRoomLighting(
        areaId: 'entrance',
        entities: [
          _entry('switch.entry_switch_l1',
              areaId: 'entrance', labels: ['role:overhead']),
        ],
        deviceAreaById: const {},
        stateOf: _lookup([_state('switch.entry_switch_l1')]),
      );
      final unit = lighting.layers.single.unit;
      expect(unit.entityId, 'switch.entry_switch_l1');
      expect(unit.capabilities.isOnOffOnly, isTrue);
    });

    test('unlabelled room falls back to a single implicit layer', () {
      final lighting = resolveRoomLighting(
        areaId: 'kitchen',
        entities: [
          _entry('light.kitchen_lights', areaId: 'kitchen', platform: 'group'),
          _entry('light.spot1', areaId: 'kitchen'),
        ],
        deviceAreaById: const {},
        stateOf: _lookup([
          _state('light.kitchen_lights', members: ['light.spot1']),
          _state('light.spot1'),
        ]),
      );
      expect(lighting.isImplicit, isTrue);
      expect(lighting.layers, hasLength(1));
      expect(lighting.layers.single.unit.entityId, 'light.kitchen_lights');
      expect(lighting.ungrouped, isEmpty);
    });

    test('room with no lighting resolves empty', () {
      final lighting = resolveRoomLighting(
        areaId: 'garage',
        entities: [_entry('light.elsewhere', areaId: 'kitchen')],
        deviceAreaById: const {},
        stateOf: _lookup([_state('light.elsewhere')]),
      );
      expect(lighting.isEmpty, isTrue);
    });
  });
}
