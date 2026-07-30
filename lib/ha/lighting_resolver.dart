// Resolves a room's lighting fixtures into ordered role layers plus an
// ungrouped bucket.
//
// Pure functions over the entity registry + a state lookup, so the whole
// resolution is unit-testable without a live Home Assistant.
//
// Role lives in HA as a `role:<name>` entity label; group membership lives in
// the group's `entity_id` **state** attribute (not the registry), so callers
// must have loaded lighting states before resolving.

import 'package:flutter/foundation.dart';
import 'package:ha_flutter/config/lighting_config.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/ha/models/light_capabilities.dart';
import 'package:ha_flutter/ha/models/registry_entry.dart';
import 'package:ha_flutter/ha/models/room_lighting.dart';

/// Signature for a synchronous state lookup (never null; unknown states are
/// placeholders).
typedef StateLookup = EntityState Function(String entityId);

/// The lighting role declared by an entity's labels, or null when unlabelled.
String? roleOfLabels(List<String> labels) {
  for (final l in labels) {
    if (l.startsWith(roleLabelPrefix)) {
      final role = l.substring(roleLabelPrefix.length).trim();
      if (role.isNotEmpty) return role;
    }
  }
  return null;
}

/// True when the entity is a candidate lighting fixture: any enabled `light.*`,
/// or a `switch.*` that carries a lighting-role label (an unlabelled switch is
/// not assumed to be a light).
bool isLightingCandidate(EntityRegistryEntry e) {
  if (e.disabledBy != null) return false;
  if (e.domain == 'light') return true;
  if (e.domain == 'switch') return roleOfLabels(e.labels) != null;
  return false;
}

/// The area an entity belongs to directly: its own assignment, else its
/// device's. Returns null for area-less entities (notably group helpers), which
/// [resolveRoomLighting] then attributes via their members.
String? directArea(
  EntityRegistryEntry e,
  Map<String, String?> deviceAreaById,
) =>
    e.areaId ?? (e.deviceId == null ? null : deviceAreaById[e.deviceId]);

/// Member entity ids of a group fixture, read from live state. Empty for
/// non-groups, template entities, and groups whose state has not loaded.
List<String> groupMemberIds(EntityRegistryEntry e, StateLookup stateOf) {
  if (e.isTemplatePlatform) return const [];
  final raw = stateOf(e.entityId).attributes['entity_id'];
  if (raw is! List) return const [];
  return [
    for (final m in raw)
      if (m is String) m,
  ];
}

/// Resolves the lighting structure for one area.
///
/// [roleOrder] defaults to [defaultRoleOrder]; roles found on labels but absent
/// from it are appended after, preserving discovery order.
RoomLighting resolveRoomLighting({
  required String areaId,
  required List<EntityRegistryEntry> entities,
  required Map<String, String?> deviceAreaById,
  required StateLookup stateOf,
  List<String>? roleOrder,
}) {
  final byId = {for (final e in entities) e.entityId: e};
  final candidates = entities.where(isLightingCandidate).toList();

  // ── Attribute each candidate to an area ────────────────────────────────────
  // Area-less groups are rescued via their members' areas (D7): the missing
  // area_id on group helpers is a data-hygiene gap, not a modelling constraint.
  final inArea = <EntityRegistryEntry>[];
  for (final e in candidates) {
    final direct = directArea(e, deviceAreaById);
    if (direct != null) {
      if (direct == areaId) inArea.add(e);
      continue;
    }
    final members = groupMemberIds(e, stateOf);
    if (members.isEmpty) continue;
    if (_inferAreaFromMembers(members, byId, deviceAreaById) == areaId) {
      inArea.add(e);
    }
  }
  if (inArea.isEmpty) return const RoomLighting();

  LightingFixture fixtureOf(EntityRegistryEntry e) {
    final state = stateOf(e.entityId);
    final members = groupMemberIds(e, stateOf);
    return LightingFixture(
      entityId: e.entityId,
      name: _nameOf(e, state),
      capabilities: LightCapabilities.fromState(
        state,
        colorTempSteps: steppedColorTempKelvins[e.entityId] ?? const [],
      ),
      memberIds: members,
      isGroup: e.isGroupPlatform || members.isNotEmpty,
      isTemplate: e.isTemplatePlatform,
    );
  }

  /// Member fixtures are synthesised even when the member has no registry entry
  /// of its own, so a group never renders an empty drill-down.
  LightingFixture memberFixture(String entityId) {
    final entry = byId[entityId];
    if (entry != null) return fixtureOf(entry);
    final state = stateOf(entityId);
    return LightingFixture(
      entityId: entityId,
      name: state.attributes.containsKey('friendly_name')
          ? state.friendlyName
          : _prettify(entityId),
      capabilities: LightCapabilities.fromState(state),
    );
  }

  // ── Group candidates by role label ─────────────────────────────────────────
  final labelled = <String, List<EntityRegistryEntry>>{};
  final unlabelled = <EntityRegistryEntry>[];
  for (final e in inArea) {
    final role = roleOfLabels(e.labels);
    if (role == null) {
      unlabelled.add(e);
    } else {
      labelled.putIfAbsent(role, () => []).add(e);
    }
  }

  // ── Build layers in configured order ───────────────────────────────────────
  final order = [
    for (final r in roleOrder ?? defaultRoleOrder)
      if (labelled.containsKey(r)) r,
    for (final r in labelled.keys)
      if (!(roleOrder ?? defaultRoleOrder).contains(r)) r,
  ];

  final layers = <LightingLayer>[];
  final claimed = <String>{}; // entity ids already owned by an earlier layer

  for (final role in order) {
    final contenders = labelled[role]!;
    final unit = _pickCanonicalUnit(contenders, stateOf);
    if (contenders.length > 1 && kDebugMode) {
      debugPrint(
        '[Lighting] $areaId: ${contenders.length} entities labelled '
        '"$roleLabelPrefix$role" '
        '(${contenders.map((e) => e.entityId).join(', ')}); '
        'using ${unit.entityId}',
      );
    }

    final unitFixture = fixtureOf(unit);
    // A member already claimed by an earlier layer stays there — a fixture is
    // never controlled from two layers.
    final members = <LightingFixture>[];
    for (final id in unitFixture.memberIds) {
      if (claimed.contains(id)) {
        if (kDebugMode) {
          debugPrint(
            '[Lighting] $areaId: ${unit.entityId} member $id already claimed '
            'by an earlier layer; not repeated under "$role"',
          );
        }
        continue;
      }
      claimed.add(id);
      members.add(memberFixture(id));
    }
    claimed.add(unit.entityId);

    layers.add(LightingLayer(
      role: role,
      displayName: roleDisplayName(role),
      unit: unitFixture,
      members: unitFixture.isTemplate ? const [] : members,
    ));
  }

  // ── Ungrouped bucket ───────────────────────────────────────────────────────
  // An unlabelled group that overlaps a layer is redundant (commanding it would
  // reach fixtures a layer already owns), so it is suppressed and only its
  // uncovered members surface. An unlabelled group with no overlap is kept
  // whole, since it is still a useful single unit.
  final ungrouped = <LightingFixture>[];
  final promoted = <String>[];

  for (final e in unlabelled.where((e) => !claimed.contains(e.entityId))) {
    final members = groupMemberIds(e, stateOf);
    final isGroup = e.isGroupPlatform || members.isNotEmpty;
    if (isGroup && members.any(claimed.contains)) {
      claimed.add(e.entityId);
      promoted.addAll(members.where((m) => !claimed.contains(m)));
      if (kDebugMode) {
        debugPrint(
          '[Lighting] $areaId: suppressing unlabelled group ${e.entityId} '
          '(overlaps a role layer); promoting uncovered members',
        );
      }
      continue;
    }
    claimed.add(e.entityId);
    claimed.addAll(members);
    ungrouped.add(fixtureOf(e));
  }

  for (final id in promoted) {
    if (claimed.contains(id)) continue;
    claimed.add(id);
    ungrouped.add(memberFixture(id));
  }

  // ── Implicit fallback ──────────────────────────────────────────────────────
  // With no role labels there are no layers; the previous flat behaviour is
  // preserved by promoting the room's widest light group (or its single light)
  // to a synthetic layer so the screen still leads with a room-level control.
  if (layers.isEmpty && ungrouped.isNotEmpty) {
    final implicitUnit = _pickImplicitUnit(ungrouped);
    if (implicitUnit != null) {
      return RoomLighting(
        layers: [
          LightingLayer(
            role: '',
            displayName: 'Lights',
            unit: implicitUnit,
            members: [
              for (final f in ungrouped)
                if (f.entityId != implicitUnit.entityId &&
                    !implicitUnit.memberIds.contains(f.entityId))
                  f,
            ],
          ),
        ],
        ungrouped: const [],
        isImplicit: true,
      );
    }
  }

  return RoomLighting(layers: layers, ungrouped: ungrouped);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// The most common non-null area among a group's members.
String? _inferAreaFromMembers(
  List<String> memberIds,
  Map<String, EntityRegistryEntry> byId,
  Map<String, String?> deviceAreaById,
) {
  final counts = <String, int>{};
  for (final id in memberIds) {
    final entry = byId[id];
    if (entry == null) continue;
    final area = directArea(entry, deviceAreaById);
    if (area == null) continue;
    counts[area] = (counts[area] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  final best = counts.entries.reduce((a, b) {
    if (a.value != b.value) return a.value > b.value ? a : b;
    return a.key.compareTo(b.key) <= 0 ? a : b; // stable tie-break
  });
  return best.key;
}

/// Deterministic canonical-unit choice when several entities share a role:
/// prefer a group (it commands more), then the larger group, then the lowest
/// entity id so the result is stable across runs.
EntityRegistryEntry _pickCanonicalUnit(
  List<EntityRegistryEntry> contenders,
  StateLookup stateOf,
) {
  if (contenders.length == 1) return contenders.first;
  final sorted = [...contenders];
  sorted.sort((a, b) {
    final am = groupMemberIds(a, stateOf).length;
    final bm = groupMemberIds(b, stateOf).length;
    final aIsGroup = a.isGroupPlatform || am > 0;
    final bIsGroup = b.isGroupPlatform || bm > 0;
    if (aIsGroup != bIsGroup) return aIsGroup ? -1 : 1;
    if (am != bm) return bm.compareTo(am);
    return a.entityId.compareTo(b.entityId);
  });
  return sorted.first;
}

/// For the implicit (unlabelled) fallback: the widest group, else the single
/// fixture when the room has exactly one.
LightingFixture? _pickImplicitUnit(List<LightingFixture> fixtures) {
  final groups = fixtures.where((f) => f.isExpandable).toList()
    ..sort((a, b) => b.memberIds.length.compareTo(a.memberIds.length));
  if (groups.isNotEmpty) return groups.first;
  return fixtures.length == 1 ? fixtures.first : null;
}

String _nameOf(EntityRegistryEntry e, EntityState state) {
  if (state.attributes.containsKey('friendly_name')) return state.friendlyName;
  return _prettify(e.entityId);
}

String _prettify(String entityId) =>
    entityId.split('.').skip(1).join('.').replaceAll('_', ' ');
