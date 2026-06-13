// Section availability and ordering rules for the room detail screen.

import 'package:flutter_test/flutter_test.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/features/room/room_sections.dart';

void main() {
  group('availableSections', () {
    test('living room with active media exposes all sections in order', () {
      final room = HaEntities.roomById('living_room');
      final sections = availableSections(room, mediaActive: true);
      expect(sections,
          [RoomSection.climate, RoomSection.lights, RoomSection.media]);
    });

    test('media section requires an active player', () {
      final room = HaEntities.roomById('living_room');
      final sections = availableSections(room, mediaActive: false);
      expect(sections, isNot(contains(RoomSection.media)));
    });

    test('pantry is lights-only (single section, nav hidden)', () {
      final room = HaEntities.roomById('pantry');
      // Pantry has a media player entity but availability still depends on
      // it being active.
      expect(availableSections(room, mediaActive: false),
          [RoomSection.lights]);
    });

    test('kitchen has no climate section', () {
      final room = HaEntities.roomById('kitchen');
      expect(availableSections(room, mediaActive: false),
          isNot(contains(RoomSection.climate)));
    });

    test('default selection is the first available section', () {
      for (final room in HaEntities.rooms) {
        final sections = availableSections(room, mediaActive: true);
        expect(sections, isNotEmpty,
            reason: 'every room has at least lights');
        // Climate-capable rooms default to Climate & Air, others to Lights.
        if (room.climate != null || room.fan != null) {
          expect(sections.first, RoomSection.climate);
        } else {
          expect(sections.first, RoomSection.lights);
        }
      }
    });
  });

  group('isMediaActiveState', () {
    test('playing, paused, idle are active', () {
      expect(isMediaActiveState('playing'), isTrue);
      expect(isMediaActiveState('paused'), isTrue);
      expect(isMediaActiveState('idle'), isTrue);
    });

    test('off, unavailable, null are inactive', () {
      expect(isMediaActiveState('off'), isFalse);
      expect(isMediaActiveState('unavailable'), isFalse);
      expect(isMediaActiveState(null), isFalse);
    });
  });
}
