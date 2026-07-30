# Tasks: Seamless Room Lighting

Phased per the design's migration plan (coherence → speed → expression →
comfort). Each phase is independently shippable; groups are dependency-ordered.

## 1. Data layer — labels & fixture model (Phase 1: coherence)

- [x] 1.1 Add `labels` (List<String>) to `EntityRegistryEntry`
      (`lib/ha/models/registry_entry.dart`) and parse it in the WS
      `fetchEntityRegistry` mapping (`lib/ha/websocket/ha_websocket_service.dart`)
- [x] 1.2 Add a `LightingFixture` model (entity id, domain, capability descriptor,
      optional group members, `isTemplate`, `isGroup`) spanning `light.*` and
      `switch.*`
- [x] 1.3 Add a `LightingLayer` model (role name, canonical `LightingFixture`,
      member fixtures) and a room-scoped `RoomLighting` (ordered layers +
      ungrouped bucket)
- [x] 1.4 Define the capability descriptor: derive supported rungs (on/off,
      brightness, colour-temp, colour, effects) from `supported_color_modes` /
      `effect_list` for lights, on/off-only for switches; carry a discrete-steps
      flag for stepped colour-temp (template lights)

## 2. Data layer — resolution (Phase 1: coherence)

- [x] 2.1 Read group members from the group entity's `entity_id` **state**
      attribute (via `entityRepository` after the existing REST bootstrap), not
      the registry
- [x] 2.2 Area-less group rescue: when a group light lacks `area_id`, attribute it
      to the room derived from its members' areas (extend the room build in
      `lib/ha/room_registry_provider.dart`)
- [x] 2.3 Include role-labelled `switch.*` entities as lighting fixtures; exclude
      unlabelled switches (do not sweep the whole `switch` domain)
- [x] 2.4 Resolve layers: read `role:<name>` labels, pick the labelled entity as
      the canonical unit per (room, role), attach its members, and suppress
      unlabelled nested/overlapping groups from forming their own layer
- [x] 2.5 Apply the default ordered taxonomy `overhead / task / ambient` with
      per-room override support; append non-default `role:<name>` layers after the
      defaults; route unlabelled fixtures to the "Other" bucket
- [x] 2.6 Handle mislabelling deterministically (two entities one role, or a member
      reachable from two labelled units) per the resolver rule chosen for the
      design Open Question; emit a debug warning rather than silently picking
- [x] 2.7 Expose `RoomLighting` off `RoomConfig` / a provider; keep a single
      implicit layer as the fallback when a room has no role labels so the screen
      never regresses

## 3. Capability-typed control primitive (Phase 1: coherence)

- [x] 3.1 Build `CapabilityLightControl` (on the existing `ControlCard` /
      `DeviceControlDescriptor` pattern) rendering only the rungs the descriptor
      supports; reuse glow, dim/unavailable, and pending-overlay behaviour
- [x] 3.2 Stepped colour-temperature: `ColorTemperatureSlider` presents discrete
      steps when the fixture exposes a discrete set (template lights)
- [x] 3.3 On/off-only rendering for binary lights and switch fixtures (toggle only,
      no brightness slot)
- [x] 3.4 Group control unit applies rung changes to the group entity using its
      HA-unioned capabilities (no client-side union)

## 4. Room lighting section restructure (Phase 1: coherence)

- [x] 4.1 Rebuild `lib/features/room/widgets/room_lights_section.dart` around
      `RoomLighting`: L1 layer cards (collapsed) + the "Other" bucket, replacing
      the flat group-toggle + always-on sliders + tile list
- [x] 4.2 Add `LightingLayerCard` (a `ControlCard` wrapping the layer's
      `CapabilityLightControl`), variable count, collapsed by default
- [x] 4.3 L2 drill-down: expanding a layer reveals member fixtures as
      `CapabilityLightControl`s
- [x] 4.4 Remove the always-visible top-level group brightness/colour-temp slider
      block; migrate the adaptive-lighting chip into the new L0 row

## 5. Speed layer — scenes & smart master (Phase 2)

- [x] 5.1 Per-room scene association: select scenes whose `entity_id` members
      overlap the room's lighting fixtures; exclude scenes whose members are not
      lighting fixtures (fan-speed scenes)
- [x] 5.2 Render L0 scene chips that call `scene.turn_on`
- [x] 5.3 Smart master control: "off" turns off all resolved room lighting
      fixtures (light + switch), never `scene.all_off`
- [x] 5.4 Smart master "on": recall the room's comfort scene when resolvable, else
      plain `turn_on` fallback; master shows plain on/off status (no false
      "comfort active")
- [x] 5.5 Assemble the L0 row (scene chips + master + adaptive toggle) at the top
      of the section

## 6. Expression layer — colour & effects (Phase 3)

- [x] 6.1 Colour picker control, shown only for colour-capable fixtures/layers;
      calls `light.turn_on` with the appropriate colour param
- [x] 6.2 Effect selector control, shown only when `effect_list` is non-empty
      (group uses unioned list); calls `light.turn_on` with `effect`
- [x] 6.3 Wire colour + effects into the L3 drill-down of
      `CapabilityLightControl`, capability-gated

## 7. Comfort scenes (Phase 4 — last, hand-configured per room)

- [x] 7.1 Decide + implement comfort-scene resolution (naming convention
      `scene.<room>_comfort` vs scene label) per the design Open Question
- [x] 7.2 Switch the smart master "on" action to recall the resolved comfort scene
      (fallback remains for rooms without one)
- [ ] 7.3 Author comfort scenes per room in HA (manual, user-driven; not app code)

## 8. Verification

- [x] 8.1 `flutter analyze` clean; add/adjust widget tests for the capability
      primitive (each ladder rung, stepped temp, switch on/off) and the layer
      resolver (area-less rescue, de-tangle, ungrouped bucket, scene filter)
- [x] 8.2 `flutter build windows` succeeds
- [ ] 8.3 Verify the room screen end-to-end at compact (< 840 dp) and wide
      (≥ 840 dp): layers collapse/expand, capability-typed controls, scene chips,
      smart master off=all / on=fallback, colour + effects on capable fixtures
- [ ] 8.4 Confirm heterogeneous real fixtures render correctly: `bedroom_light`
      (stepped template), `walkway_spotlight_inner` (brightness-only),
      `entry_lights` (union group), a role-labelled switch

## 9. HA data-hygiene recommendations (surfaced to user; not app code)

- [x] 9.1 Recommend assigning `area_id` to area-less group entities
      (`kitchen_spotlights`, `dining_table_lights`, `entry_lights`, `pantry_lights`)
- [x] 9.2 Recommend applying `role:<name>` labels per fixture to populate layers
- [x] 9.3 Note the drifting `scene.all_off` (incomplete + captures non-light config
      entities) as a latent footgun the app deliberately does not reuse
