## ADDED Requirements

### Requirement: Fixture capability descriptor
The app SHALL derive a capability descriptor for each lighting fixture from its
live state. For `light.*` fixtures the descriptor SHALL be built from
`supported_color_modes` and `effect_list`. For `switch.*` fixtures the descriptor
SHALL be on/off only. The descriptor SHALL expose which rungs of the ladder are
supported: on/off, brightness, colour-temperature, colour, effects.

#### Scenario: Brightness-only descriptor
- **WHEN** `light.walkway_spotlight_inner` reports `supported_color_modes: ["brightness"]`
- **THEN** its descriptor SHALL support on/off and brightness only

#### Scenario: Full-capability descriptor
- **WHEN** a fixture reports `supported_color_modes: ["color_temp","rgb"]` with a non-empty `effect_list`
- **THEN** its descriptor SHALL support on/off, brightness, colour-temperature, colour, and effects

#### Scenario: Switch fixture descriptor is on/off only
- **WHEN** a role-labelled `switch.*` fixture is described
- **THEN** its descriptor SHALL support on/off only

### Requirement: Capability-typed rendering
The app SHALL provide a single light-control primitive that renders exactly the
rungs the fixture's descriptor supports — no empty slider slots for unsupported
rungs, no hidden capability for supported ones. The same primitive SHALL be used
for a layer's canonical control unit and for individual members.

#### Scenario: Binary/switch fixture shows only a toggle
- **WHEN** the primitive renders a fixture whose descriptor is on/off only
- **THEN** it SHALL render only an on/off affordance and no brightness/colour controls

#### Scenario: Tunable-white fixture shows brightness and colour-temp, not colour
- **WHEN** the primitive renders a fixture supporting brightness + colour-temperature but not colour
- **THEN** it SHALL render brightness and colour-temperature controls and SHALL NOT render a colour control

### Requirement: Group control uses HA-unioned capabilities
When the primitive renders an HA group as a layer's control unit, it SHALL use the
group entity's already-unioned `supported_color_modes`/`effect_list` (D3) rather
than recomputing a union client-side. Adjusting a rung SHALL apply to the group
entity, letting HA fan the change out to members that support it.

#### Scenario: Heterogeneous group offers the union of member rungs
- **WHEN** `light.entry_lights` reports `supported_color_modes: ["color_temp","rgb","xy"]` (union of a colour bulb and a tunable bulb)
- **THEN** the entry layer control SHALL offer colour-temperature and colour, applied to `light.entry_lights`

### Requirement: Template lights are opaque and may be stepped
The app SHALL treat template lights (`platform: "template"`) as opaque leaves — it
SHALL NOT attempt to expand them into members — and SHALL tolerate discrete
(stepped) capability ranges rather than assuming continuous ones (D4).

#### Scenario: Template light renders as a leaf, not a group
- **WHEN** `light.bedroom_light` is a template light advertising `["color_temp"]` with no `entity_id` attribute
- **THEN** the primitive SHALL render it as a single fixture with a colour-temperature control and SHALL NOT show a member drill-down

#### Scenario: Stepped colour-temperature is honoured
- **WHEN** a template light exposes discrete colour temperatures (e.g. 2700/4000/6500 K)
- **THEN** the colour-temperature control SHALL present discrete steps rather than a continuous sweep

### Requirement: Colour and effects are capability-gated
Colour selection and effect selection SHALL be offered only on fixtures/layers
whose descriptor advertises the capability (D11). A fixture without colour support
SHALL never present a colour control; a fixture with an empty `effect_list` SHALL
never present an effect control.

#### Scenario: Effects shown only when available
- **WHEN** a fixture's `effect_list` is non-empty
- **THEN** the primitive SHALL offer effect selection at the expression level

#### Scenario: Colour hidden for colour-temp-only fixtures
- **WHEN** a fixture supports only `color_temp`
- **THEN** the primitive SHALL NOT offer a colour picker
