## ADDED Requirements

### Requirement: Role-based layer resolution
The app SHALL resolve a room's lighting fixtures into an ordered list of
**layers** by lighting role. Role SHALL be read from an HA label of the form
`role:<name>` on the fixture's entity (D14). The default ordered role set SHALL
be `overhead`, `task`, `ambient` (D18); a room MAY override the set and order via
configuration (D17). Roles present as `role:<name>` labels but outside the
default set SHALL be honoured and appended after the defaults unless the room
overrides ordering.

#### Scenario: Default rooms expose the three role layers in order
- **WHEN** a room has no layer-ordering override
- **THEN** its lighting layers SHALL render in the order overhead, task, ambient

#### Scenario: A role layer with no labelled fixtures does not render as an error
- **WHEN** a default role (e.g. `task`) has no fixture labelled `role:task` in a room
- **THEN** that layer SHALL be absent (or empty) rather than rendering a broken/error state

#### Scenario: A non-default role label is honoured
- **WHEN** a fixture carries the label `role:accent`
- **THEN** an `accent` layer SHALL render, appended after overhead/task/ambient

### Requirement: Canonical control unit per layer
For each (room, role) the app SHALL treat the role-labelled entity as the single
**canonical control unit** for that layer (D15). When the canonical unit is an HA
group, its members SHALL become its drill-down. Fixtures reachable only as members
of a non-labelled group SHALL NOT form their own layer, so a fixture is never
controlled from two layers.

#### Scenario: Labelled group is the layer's control unit
- **WHEN** `light.kitchen_spotlights` is labelled `role:task` in the Kitchen
- **THEN** the Kitchen task layer's control unit SHALL be `light.kitchen_spotlights` and its members SHALL render as that layer's drill-down

#### Scenario: Nested unlabelled group does not double-render
- **GIVEN** `light.kitchen_lights` ⊃ `light.kitchen_spotlights` and only `light.kitchen_spotlights` is role-labelled
- **WHEN** the Kitchen lighting resolves
- **THEN** `light.kitchen_lights` SHALL NOT render as a separate layer, and the shared spotlight members SHALL appear only under the task layer

### Requirement: Ungrouped fixture bucket
Room lighting fixtures that carry no `role:<name>` label SHALL be collected into a
single "Other" bucket (D5) so no fixture is unreachable. The bucket SHALL NOT be
treated as a role layer.

#### Scenario: Unlabelled standalone light falls to Other
- **WHEN** `light.living_room_donut` is in the Living Room and carries no role label
- **THEN** it SHALL render in the Living Room "Other" bucket, not in a role layer

### Requirement: Room fixture resolution robustness
Room → fixture resolution SHALL NOT depend solely on the fixture entity's
`area_id`. When a group light lacks `area_id`, the app SHALL infer its room from
its members' areas (D7). Group members SHALL be read from the group's `entity_id`
**state attribute**. The fixture set SHALL span the `light.*` domain and any
`switch.*` entity carrying a `role:<name>` label (D16).

#### Scenario: Area-less group is rescued via its members
- **GIVEN** `light.kitchen_spotlights` has `area_id: null` but its members are Kitchen entities
- **WHEN** rooms are resolved
- **THEN** `light.kitchen_spotlights` SHALL be attributed to the Kitchen room rather than dropped

#### Scenario: Role-labelled switch is a lighting fixture
- **WHEN** `switch.entry_switch_l1` carries the label `role:overhead` in the Entrance
- **THEN** it SHALL be included as an Entrance lighting fixture in the overhead layer

#### Scenario: Unlabelled switch is not treated as lighting
- **WHEN** a `switch.*` entity carries no `role:<name>` label
- **THEN** it SHALL NOT be included as a lighting fixture

### Requirement: Room lighting off computation
The room master "off" action SHALL turn off every resolved lighting fixture in the
room (across `light.*` and role-labelled `switch.*`), computed from the resolved
fixture set. It SHALL NOT invoke `scene.all_off` or any hand-curated scene (D9).

#### Scenario: Master off targets the room's resolved fixtures
- **WHEN** the user triggers master off for a room with light and switch fixtures
- **THEN** the app SHALL call `turn_off` on each resolved lighting fixture and SHALL NOT call `scene.all_off`

### Requirement: Comfort scene recall with fallback
The room master "on" action SHALL recall the room's comfort scene when one is
resolvable; otherwise it SHALL perform a plain `turn_on` of the room's lighting
(D9). Comfort scenes are authored per room as a later phase (D12); their absence
SHALL never make master "on" a no-op.

#### Scenario: Comfort scene recalled when present
- **WHEN** a resolvable comfort scene exists for the room and the user triggers master on
- **THEN** the app SHALL call `scene.turn_on` for that comfort scene

#### Scenario: Fallback to plain turn-on when no comfort scene
- **WHEN** no comfort scene is resolvable for the room and the user triggers master on
- **THEN** the app SHALL call `turn_on` on the room's lighting fixtures

### Requirement: Per-room scene association
The app SHALL associate a scene with a room when the scene's `entity_id` members
overlap the room's lighting fixtures (D10). Scenes whose members are not lighting
fixtures (e.g. fan-speed scenes) SHALL be excluded from a room's lighting scenes.

#### Scenario: Overlapping lighting scene is associated
- **GIVEN** `scene.living_room` sets exactly the Living Room's Hue bulbs
- **WHEN** the Living Room lighting surface resolves its scenes
- **THEN** `scene.living_room` SHALL be offered as a Living Room lighting scene

#### Scenario: Fan-speed scene is excluded
- **WHEN** `scene.living_room_fan_spd_1` sets only a `fan.*` entity
- **THEN** it SHALL NOT be offered as a Living Room lighting scene
