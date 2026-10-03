## Why

Per-room lighting control is stitched together from a flat "group toggle +
individual tiles" layout that does not match how the space is actually lit or
how the user thinks about it. Three gaps drive the friction:

- **No model of lighting roles.** A room's lights are a design system —
  overhead, task, ambient — but the UI presents one undifferentiated group plus
  a flat list. There is no way to act on "the task lights" as a unit.
- **No coherence across heterogeneous fixtures.** The fleet spans the full
  capability ladder — brightness-only (`walkway_spotlight_inner`), stepped
  color-temp template lights (`bedroom_light`, `study_light`), tunable+colour
  zigbee/hue, and RGB yeelights — yet every light is rendered with the same
  brightness-only assumption. Colour and effects are unreachable even on bulbs
  that support them; a binary light shows an empty slider slot.
- **No fast path to an intended lighting state.** Lighting is primarily driven
  by scenes and adaptive lighting, but scenes are only surfaced globally and the
  master control is a dumb on/off. Reaching a desired room state means dialling
  sliders by hand.

The goal is coherence first, then speed, then expression — presented as a simple
surface that allows deeper drilling, never several competing control vocabularies.

## What Changes

- **Introduce a lighting-role model (layers).** Each room's lights are organised
  into overhead / task / ambient layers. A layer is a single control unit that
  toggles and adjusts its members together, with capability-aware affordances.
- **Make controls capability-typed and coherent across fixtures.** One control
  primitive renders exactly the rungs a light (or layer) supports — on/off →
  brightness → colour-temp → colour → effects — driven by
  `supported_color_modes` / `effect_list`. Groups inherit HA's unioned
  capabilities; heterogeneous members degrade gracefully; template lights are
  treated as opaque (and possibly stepped) leaves.
- **Add progressive disclosure.** A simple L0 surface (scene chips + a smart
  master + adaptive-lighting toggle), with layers (L1), individual members (L2),
  and colour/effects (L3) available on drill-down rather than all at once.
- **Make the master control intelligent.** Off turns off all of the room's
  lighting (computed from the room's fixtures, not the brittle hand-curated
  `scene.all_off`); On recalls the room's comfort scene when one exists, else
  falls back to a plain turn-on. Comfort scenes are authored per room as the
  final phase (see below).
- **Surface scenes per room.** Scene chips show the scenes that affect this
  room's lights (association derived from scene member overlap), giving the
  primary one-tap path to a lighting state.
- **Handle ungrouped lights.** An "Other" bucket presents room lights that
  belong to no layer, so no fixture is unreachable.

### Phasing (priority order)

1. **Coherence** — role-layer model, capability-typed controls, group /
   individual / template handling, the ungrouped bucket, room resolution robust
   to area-less group entities.
2. **Speed** — per-room scene chips, the smart master (with plain-turn-on
   fallback), adaptive-lighting toggle at L0.
3. **Expression** — colour picker and effects, capability-gated (including
   stepped colour-temp for template lights).
4. **Comfort scenes (last, hand-configured room by room)** — author a comfort
   scene per room and switch the master's On action to recall it. Deferred and
   manual by decision; the earlier phases do not depend on it.

## Capabilities

### New Capabilities
- `lighting-layers`: the lighting-role model (overhead / task / ambient), the
  resolution of a room's fixtures into layers + an ungrouped bucket, and the
  role-assignment mechanism.
- `capability-typed-light-control`: the single light-control primitive that
  renders affordances from a fixture's advertised capabilities (on/off,
  brightness, colour-temp, colour, effects), the group-capability union, and the
  opaque/stepped handling for template lights.

### Modified Capabilities
- `device-controls`: the light group toggle, brightness/colour-temp sliders, and
  individual light tiles are restructured into the capability-typed primitive and
  the layer model; colour and effects controls are added.
- `room-view`: the room detail screen presents the L0 lighting surface (scene
  chips, smart master, adaptive toggle) and the layered drill-down in place of
  the current flat group-plus-tiles section.

## Impact

- **Affected code:**
  - Room lighting UI: `lib/features/room/widgets/room_lights_section.dart`,
    `lib/features/room/room_detail_screen.dart`.
  - Shared light widgets: `lib/shared/widgets/light_tile.dart`,
    `light_toggle_widget.dart`, `brightness_slider.dart`,
    `color_temperature_slider.dart`; new colour-picker / effects / layer-card
    widgets built on the existing `ControlCard` primitive.
  - Data / model layer (not just presentation): `lib/config/room_config.dart`,
    `lib/config/room_overrides.dart`, `lib/ha/models/room_device.dart` — room →
    fixture resolution for area-less groups, role assignment, and de-tangling
    nested/overlapping group membership to one canonical control unit per
    (room, role).
- **HA-side prerequisites (surfaced, not owned by app code):**
  - Group entities missing `area_id` should be assigned to their area (the
    user confirmed the gap is unintentional).
  - Lighting-role labels (or the chosen role mechanism) applied per fixture.
  - Comfort scenes authored per room (final phase).
- **No changes to:** auth, HA service-call semantics for individual fixtures
  (still `light.*` / `scene.*`), or the Riverpod data-fetch layer's transport.
- **Dependencies:** none added; built on the existing Flutter + Riverpod +
  Material 3 stack and the `ControlCard` language from `unified-control-scheme`.

## Open decisions

Tracked in `decisions.md`; these gate the specs/design:
- Role-assignment mechanism (labels vs naming vs app config) — leaning labels.
- De-tangling policy for nested/overlapping groups (hide covered sub-groups vs
  surface both).
- Whether switch-controlled lighting (`switch.*` acting as lights) is in scope.
- Whether the role taxonomy is fixed (overhead/task/ambient) or configurable.
