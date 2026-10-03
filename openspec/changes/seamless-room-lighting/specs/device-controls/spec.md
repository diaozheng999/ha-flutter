## MODIFIED Requirements

### Requirement: Colour temperature slider
The app SHALL provide a `ColorTemperatureSlider` that maps the entity's
`color_temp_kelvin` attribute range (from entity min/max attributes) to a visual
warm-to-cool gradient track. The slider SHALL only render when the entity reports
`color_temp` in its supported colour modes. Dragging SHALL call `light.turn_on`
with `color_temp_kelvin`, debounced at 200 ms. When the fixture exposes a discrete
set of colour temperatures rather than a continuous range (e.g. a stepped template
light), the control SHALL present those discrete steps rather than a continuous
sweep.

#### Scenario: Slider renders for CCT-capable lights
- **WHEN** a light entity's `supported_color_modes` includes `color_temp`
- **THEN** the `ColorTemperatureSlider` SHALL render with a warm-to-cool gradient track

#### Scenario: Slider absent for RGB-only lights
- **WHEN** a light entity's `supported_color_modes` is `['hs']` only
- **THEN** the `ColorTemperatureSlider` SHALL NOT render

#### Scenario: Stepped colour temperature presents discrete steps
- **WHEN** a template light exposes discrete colour temperatures (e.g. 2700/4000/6500 K)
- **THEN** the control SHALL offer those discrete steps and each selection SHALL call `light.turn_on` with the chosen `color_temp_kelvin`

### Requirement: Light tile with inline brightness
The app SHALL provide a capability-typed light control (superseding the
brightness-only `LightTile`): a compact glassmorphic tile sized for grid placement
(target 160–220 dp wide) containing the fixture's name, an on/off affordance, and
the control rungs its capability descriptor supports. The tile SHALL render only
the supported rungs — a brightness slider for dimmable fixtures, none for
on/off-only fixtures — and SHALL surface colour-temperature, colour, and effects
where the descriptor advertises them. It SHALL reuse the existing glow behavior
(radial glow from `hs_color` when `on`, warm white fallback, none when `off`) and
the existing unavailable treatment (40% opacity, interaction disabled). Inline
brightness drags SHALL be debounced at 200 ms; dragging to 0 SHALL call
`light.turn_off`.

#### Scenario: Tile toggle switches the light
- **WHEN** the user taps the toggle on a tile for a light that is `off`
- **THEN** the app SHALL call `light.turn_on` for that entity and the tile SHALL render its glow once the state updates

#### Scenario: Inline brightness adjusts the single light
- **WHEN** the user drags a dimmable tile's brightness slider to 40%
- **THEN** the app SHALL call `light.turn_on` with `brightness_pct: 40` on that individual entity only, debounced at 200 ms

#### Scenario: On/off-only fixture renders no brightness slider
- **WHEN** the tile's fixture descriptor is on/off only (e.g. a brightness-incapable light or a role-labelled switch)
- **THEN** the tile SHALL render only an on/off affordance and no brightness slider

#### Scenario: Unavailable light tile is disabled
- **WHEN** the tile's entity state is `unavailable`
- **THEN** the tile SHALL render at 40% opacity with its controls non-interactive

## ADDED Requirements

### Requirement: Colour picker control
The app SHALL provide a colour picker control, shown only for fixtures/layers whose
capability descriptor supports colour (`hs`/`rgb`/`rgbw`/`xy`). Selecting a colour
SHALL call `light.turn_on` with the appropriate colour parameter for the fixture,
debounced consistently with the other light controls.

#### Scenario: Colour applied to a colour-capable fixture
- **WHEN** the user picks a colour on a fixture whose descriptor supports colour
- **THEN** the app SHALL call `light.turn_on` with a colour parameter (e.g. `rgb_color` / `hs_color`) for that fixture

#### Scenario: Colour picker absent without colour support
- **WHEN** a fixture's descriptor supports only brightness and/or colour-temperature
- **THEN** no colour picker SHALL be shown

### Requirement: Effect selector control
The app SHALL provide an effect selector control, shown only for fixtures/layers
whose `effect_list` is non-empty. Selecting an effect SHALL call `light.turn_on`
with `effect`. The available effects SHALL be those advertised by the fixture (or,
for a group, the group's unioned `effect_list`).

#### Scenario: Effect applied from the fixture's effect list
- **WHEN** the user selects an effect offered for a fixture with a non-empty `effect_list`
- **THEN** the app SHALL call `light.turn_on` with `effect` set to the chosen value

#### Scenario: Effect selector absent when no effects
- **WHEN** a fixture reports an empty `effect_list`
- **THEN** no effect selector SHALL be shown
