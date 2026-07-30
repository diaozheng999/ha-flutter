import 'package:ha_flutter/ha/models/light_capabilities.dart';

/// A single controllable lighting fixture. Spans the `light.*` domain and any
/// `switch.*` entity that carries a lighting-role label (a wall switch driving
/// lights is lighting, just at the bottom capability rung).
class LightingFixture {
  final String entityId;
  final String name;
  final LightCapabilities capabilities;

  /// Member entity ids when this fixture is an HA group; empty for leaves.
  /// Read from the group's `entity_id` **state** attribute, so it is empty
  /// until state has loaded.
  final List<String> memberIds;

  /// True for HA group helpers (members expandable, capabilities pre-unioned
  /// by HA).
  final bool isGroup;

  /// True for template entities — opaque leaves that are never expanded, and
  /// whose ranges may be quantised.
  final bool isTemplate;

  const LightingFixture({
    required this.entityId,
    required this.name,
    required this.capabilities,
    this.memberIds = const [],
    this.isGroup = false,
    this.isTemplate = false,
  });

  String get domain => entityId.split('.').first;

  /// A group whose members are known can be drilled into. Template fixtures are
  /// never expandable regardless of what they advertise.
  bool get isExpandable => !isTemplate && memberIds.isNotEmpty;

  LightingFixture copyWith({
    LightCapabilities? capabilities,
    List<String>? memberIds,
  }) =>
      LightingFixture(
        entityId: entityId,
        name: name,
        capabilities: capabilities ?? this.capabilities,
        memberIds: memberIds ?? this.memberIds,
        isGroup: isGroup,
        isTemplate: isTemplate,
      );
}

/// One lighting-role layer of a room (e.g. overhead / task / ambient).
///
/// [unit] is the canonical control unit — the role-labelled entity. When it is
/// a group, [members] are its resolved member fixtures, forming the layer's
/// drill-down.
class LightingLayer {
  /// Role name as it appears after the `role:` label prefix, e.g. `overhead`.
  final String role;

  /// Human-facing label for the layer.
  final String displayName;

  final LightingFixture unit;
  final List<LightingFixture> members;

  const LightingLayer({
    required this.role,
    required this.displayName,
    required this.unit,
    this.members = const [],
  });

  bool get isExpandable => members.isNotEmpty;

  /// Every entity this layer controls: the unit plus any members.
  List<String> get entityIds => [
        unit.entityId,
        for (final m in members) m.entityId,
      ];
}

/// A room's resolved lighting: ordered role layers plus the fixtures that carry
/// no role label.
class RoomLighting {
  final List<LightingLayer> layers;

  /// Fixtures with no lighting-role label — reachable, but not part of a layer.
  final List<LightingFixture> ungrouped;

  /// True when no role labels were found and [layers] holds a single synthetic
  /// layer standing in for the room's lights, preserving the pre-layer
  /// behaviour for unlabelled rooms.
  final bool isImplicit;

  const RoomLighting({
    this.layers = const [],
    this.ungrouped = const [],
    this.isImplicit = false,
  });

  bool get isEmpty => layers.isEmpty && ungrouped.isEmpty;

  /// Every distinct fixture in the room, layers first then the ungrouped
  /// bucket. Used for the room-wide off/on actions.
  List<String> get allFixtureIds {
    final seen = <String>{};
    for (final l in layers) {
      seen.addAll(l.entityIds);
    }
    for (final f in ungrouped) {
      seen.add(f.entityId);
    }
    return seen.toList(growable: false);
  }

  /// Distinct top-level control units (layer units + ungrouped fixtures).
  /// Turning these off covers the room without redundantly targeting members
  /// that a group already commands.
  List<String> get controlUnitIds => [
        for (final l in layers) l.unit.entityId,
        for (final f in ungrouped) f.entityId,
      ];
}
