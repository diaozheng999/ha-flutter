## Context

Per-room lighting today is a flat section (`room_lights_section.dart`): a group
toggle, group brightness/colour-temp sliders, an adaptive-lighting chip, and a
list of individual `LightTile`s. Every fixture is rendered brightness-only; there
is no colour, no effects, no notion of lighting role, and no fast path to a
desired state. See `proposal.md` for motivation.

The data layer (`lib/ha/room_registry_provider.dart`) builds `RoomConfig`s from
the HA area/device/entity registries. Two facts, verified against the live
instance (`2026.7.2`), shape this design:

- **Group helpers self-describe but are area-ragged.** A `platform: "group"`
  light exposes its members in the `entity_id` **state attribute** (not the
  registry) and HA unions members' `supported_color_modes`/`effect_list`. But
  many group entities carry `area_id: null`, and the current builder's
  standalone path (`standaloneByArea`) requires `e.areaId != null`, so those
  groups are silently dropped from their room.
- **Fixtures are heterogeneous, including non-`light` fixtures.** The fleet spans
  on/off, stepped-colour-temp templates, tunable white, and RGB(W); some lighting
  is driven by `switch.*` (per `scene.all_off`). Role is encoded nowhere in HA.

All firm decisions referenced below have dated entries in `decisions.md`
(D1–D17); this document distills the architecture, it does not re-decide.

## Goals / Non-Goals

**Goals:**
- A lighting-role **layer** model per room (D1), resolved from HA labels (D14),
  with the role-labelled entity as the canonical control unit (D15).
- One **capability-typed** control primitive (D4/D11) spanning the ladder
  on/off → brightness → colour-temp → colour → effects, driven by advertised
  capabilities, degrading gracefully for binary/switch fixtures and stepped
  templates.
- **Progressive disclosure** L0–L3 (D2): scene chips + smart master + adaptive
  toggle up front; layers, members, and colour/effects on drill-down.
- Data-layer resolution robust to area-less groups (D7) and spanning `light.*` +
  role-labelled `switch.*` fixtures (D16), with an ungrouped bucket (D5).
- A smart master (D9): off = all room lighting off; on = comfort scene or plain
  turn-on fallback.

**Non-Goals:**
- Authoring comfort scenes (D12) — deferred to the final phase, hand-configured
  per room; earlier phases must not depend on them existing.
- Fixing the missing `area_id`s or the drifting `scene.all_off` in HA — surfaced
  as recommendations, owned by the user, not by app code.
- Changing HA service-call semantics for individual fixtures, auth, or the
  Riverpod transport layer.
- Redesigning non-lighting room controls (AC/fan/purifier/media) — untouched.

## Decisions

### Model: three axes, resolved into layers
A room's lighting is resolved into an **ordered list of layers** plus an
**ungrouped bucket**, from three independent axes (per exploration): *room*
(which space), *role* (the layer), *control unit* (what the service is called
on). Concretely:

- **Role** comes from a `role:<name>` HA label (D14); the taxonomy and layer
  order are configurable (D17), not a fixed overhead/task/ambient enum.
- **Canonical unit** per (room, role) is the labelled entity (D15). If it is a
  group, its members become its drill-down; unlabelled overlapping/nested groups
  do not form layers, avoiding the double-control problem (kitchen_lights ⊃
  kitchen_spotlights; a bulb in two groups).
- **Fixtures** span `light.*` and role-labelled `switch.*` (D16). Anything in the
  room that is a light fixture but carries no role label falls to the ungrouped
  bucket (D5).

### Data layer: a resolution pass over registry + state
A new resolver (extending `room_registry_provider.dart`) produces the layer
structure. It needs three things the current builder lacks:

1. **Entity labels** — extend `EntityRegistryEntry` (and the WS
   `fetchEntityRegistry` parse) with `labels`, so role labels are readable.
2. **Area-less group rescue** (D7) — when a group light lacks `area_id`, infer
   its room from its members' areas rather than dropping it. Members come from
   the group's `entity_id` **state attribute**, so the resolver reads state
   (`entityRepository`/REST bootstrap) in addition to the registry.
3. **Switch fixtures** (D16) — include `switch.*` entities that carry a
   `role:<name>` label as lighting fixtures (a switch is lighting *iff* it is
   role-labelled, avoiding a domain-wide sweep).

Output is a room-scoped structure — e.g. `RoomLighting { layers: [LightingLayer],
ungrouped: [LightingFixture] }` where a `LightingLayer` has a role, a canonical
`LightingFixture` control unit, and its member fixtures. This supersedes the flat
`lightGroup`/`individualLights` getters on `RoomConfig`.

### Capability model: one descriptor, one primitive
A `LightingFixture` carries a **capability descriptor** derived from state:
`supported_color_modes` + `effect_list` for `light.*`; on/off-only for `switch.*`.
A group's descriptor is HA's already-unioned attributes (no client math, D3).
Template lights are opaque leaves whose colour-temp range may be discrete (D4).

One `CapabilityLightControl` primitive renders exactly the supported rungs; it is
reused for a layer's canonical unit and for each member. This replaces the
brightness-only assumption baked into `LightTile`/`BrightnessSlider` today.

### Presentation: built on the existing control language
Reuse the `ControlCard` shell and `DeviceControlDescriptor` pattern from
`unified-control-scheme`:
- **L0** — per-room scene chips (scenes whose members overlap the room's
  fixtures, D10; fan-speed scenes excluded), the smart master (D9), the
  adaptive-lighting toggle (already present).
- **L1** — a `LightingLayerCard` per layer (a `ControlCard` with the layer's
  capability-typed group control), variable count (D17), collapsed by default.
- **L2** — expanding a layer reveals its member fixtures, each a
  `CapabilityLightControl`.
- **L3** — colour picker + effect selector, shown only where the descriptor
  advertises the capability (D11).

### Smart master
Off calls `turn_off` across the room's resolved fixtures (light + switch),
**not** `scene.all_off` (brittle, D9). On calls `scene.turn_on` for the room's
comfort scene when one is resolvable, else a plain `turn_on` (D9/D12).

## Risks / Trade-offs

- **Group members live in state, not the registry** → the resolver depends on
  state being loaded before it can enumerate members / rescue area-less groups.
  *Mitigation:* the provider already REST-bootstraps room entity states before
  building; sequence member resolution after that bootstrap and treat a
  not-yet-loaded group as "collapsed, members pending" rather than empty.
- **Mislabelling** (two entities same role in a room; a bulb reachable from two
  labelled units) → ambiguous layers or double control. *Mitigation:* define a
  deterministic resolver rule (see Open Questions) and surface a debug warning
  rather than silently picking.
- **Configurable taxonomy** (D17) adds a config surface and variable-length
  layout. *Mitigation:* ship a sensible default ordered role list; unknown roles
  fall back to the ungrouped bucket so the UI never breaks on an unmapped label.
- **Switch fixtures in scope** (D16) widen the fixture abstraction beyond
  `light.*`. *Mitigation:* a switch is just the bottom rung of the existing
  ladder; the capability primitive already degrades to on/off, so it is the
  minimal case, not a parallel code path.
- **Comfort scenes absent for most rooms** (D12) → master On mostly hits the
  fallback initially. *Accepted:* that is the intended interim behaviour; the
  fallback is a plain turn-on, never a no-op.
- **HA data hygiene** (area-less groups, drifting `scene.all_off`) is outside app
  control. *Mitigation:* the resolver degrades gracefully; the fixes are
  surfaced to the user as recommendations.

## Migration Plan

Phased per the proposal's priority order; each phase is independently shippable.

1. **Coherence (data + core UI):** extend `EntityRegistryEntry` with labels;
   add the lighting resolver (layers + ungrouped, area-less rescue, switch
   inclusion); build `CapabilityLightControl` and `LightingLayerCard`; replace
   `room_lights_section` internals. Existing flat behaviour is the fallback when
   no role labels exist (a single implicit layer), so the screen never regresses
   for unlabelled rooms.
2. **Speed:** per-room scene chips, smart master (off=all / on=turn-on fallback),
   adaptive toggle at L0.
3. **Expression:** colour picker + effects at L3, capability-gated.
4. **Comfort scenes (last, manual):** author `scene.<room>_comfort` per room and
   switch master On to recall it. No code dependency from earlier phases.

Rollback: the change is additive to the data model and swaps one room section's
internals; reverting restores the flat section. No HA-side state is mutated by
the app beyond the same service calls used today.

## Open Questions

- **Resolver rule for mislabelling** — when two entities share a role in one
  room, or a member is reachable from two labelled units: pick-first + warn,
  or surface a user-visible config warning? (Feeds a spec scenario.)
- ~~Default role taxonomy & ordering (D17)~~ — **resolved (D18):** default
  ordered list is `overhead / task / ambient`; rooms may override.
- **Which entity carries the role label for switch-controlled lighting** (D16) —
  the `switch.*` entity directly, or a wrapping group? Affects the resolver's
  fixture-discovery query.
- **Scene chip filtering** (D10) — "lighting scene" = members are all lighting
  fixtures, or ≥1 lighting fixture? The fan-speed scenes must be excluded either
  way; confirm the predicate.
- **Comfort scene resolution** (D12) — naming convention (`scene.<room>_comfort`)
  vs a `role`-style label on the scene. Decide when phase 4 begins.
