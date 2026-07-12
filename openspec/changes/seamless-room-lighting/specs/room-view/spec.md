## MODIFIED Requirements

### Requirement: Lights section
The Lights & Ambiance section SHALL be available for all rooms that have lighting
fixtures, and SHALL present per-room lighting as a progressively-disclosed surface
rather than a flat group-plus-tiles list:

- **L0 (glance):** per-room lighting scene chips (the scenes associated with the
  room's fixtures), a **master control** whose "off" turns off all of the room's
  lighting and whose "on" recalls the room's comfort scene when available else
  performs a plain turn-on, and an adaptive-lighting toggle chip when the room has
  an `adaptiveLightingSwitch`.
- **L1 (layers):** one collapsed layer card per resolved role layer (default
  overhead / task / ambient, in order), each a capability-typed control over the
  layer's canonical unit, plus an "Other" bucket for unlabelled fixtures.
- **L2 (members):** expanding a layer reveals its member fixtures, each a
  capability-typed control.
- **L3 (expression):** colour and effect controls, shown only where the fixture's
  or layer's capability descriptor advertises them.

Continuous adjustments (brightness, colour-temperature, colour) SHALL be debounced
at 200 ms. The always-visible group brightness/colour-temperature sliders of the
previous flat layout SHALL NOT occupy the top level; dials live within the layer /
member controls.

#### Scenario: Scene chip recalls a room lighting scene
- **WHEN** the user taps a room lighting scene chip at L0
- **THEN** the app SHALL call `scene.turn_on` for that scene

#### Scenario: Master off turns off all room lighting
- **WHEN** the user triggers the master "off" while room lights are on
- **THEN** the app SHALL turn off every resolved room lighting fixture and SHALL NOT invoke `scene.all_off`

#### Scenario: Master on falls back to turn-on without a comfort scene
- **WHEN** the user triggers master "on" for a room with no comfort scene
- **THEN** the app SHALL perform a plain `turn_on` of the room's lighting fixtures

#### Scenario: Layers render collapsed with capability-typed controls
- **WHEN** a room's Lights section renders
- **THEN** each resolved role layer SHALL render as a collapsed card exposing only the rungs its canonical unit supports

#### Scenario: Expanding a layer reveals its members
- **WHEN** the user expands a layer whose canonical unit is a group
- **THEN** the layer's member fixtures SHALL render, each as a capability-typed control

#### Scenario: Unlabelled fixtures appear in the Other bucket
- **WHEN** a room contains a lighting fixture with no `role:<name>` label
- **THEN** that fixture SHALL render under the "Other" bucket rather than a role layer

#### Scenario: Adaptive lighting chip toggles the AL switch
- **GIVEN** a room with an adaptive-lighting switch entity
- **WHEN** the user taps the adaptive-lighting chip while the switch is `on`
- **THEN** the app SHALL call `switch.turn_off` on the room's adaptive-lighting switch entity

#### Scenario: Colour and effects only at expression level for capable fixtures
- **WHEN** the user drills into a fixture whose descriptor supports colour and effects
- **THEN** colour and effect controls SHALL be available; for a fixture without those capabilities they SHALL be absent
