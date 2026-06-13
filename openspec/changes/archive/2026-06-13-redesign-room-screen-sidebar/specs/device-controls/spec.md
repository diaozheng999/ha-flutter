# Device Controls — Delta

## ADDED Requirements

### Requirement: Light tile with inline brightness
The app SHALL provide a `LightTile` widget: a compact glassmorphic tile sized for grid placement (target 160–220 dp wide) containing the light's name, an on/off toggle, and an inline brightness slider. The tile SHALL reuse the existing glow behavior (radial glow from `hs_color` when `on`, warm white fallback, none when `off`) and the existing unavailable treatment (40% opacity, interaction disabled). Inline brightness drags SHALL be debounced at 200 ms; dragging to 0 SHALL call `light.turn_off`.

#### Scenario: Tile toggle switches the light
- **WHEN** the user taps the toggle on a `LightTile` for a light that is `off`
- **THEN** the app SHALL call `light.turn_on` for that entity and the tile SHALL render its glow once the state updates

#### Scenario: Inline brightness adjusts the single light
- **WHEN** the user drags a tile's brightness slider to 40%
- **THEN** the app SHALL call `light.turn_on` with `brightness_pct: 40` on that individual entity only, debounced at 200 ms

#### Scenario: Unavailable light tile is disabled
- **WHEN** the tile's entity state is `unavailable`
- **THEN** the tile SHALL render at 40% opacity with toggle and slider non-interactive

---

### Requirement: Constrained control width
Slider-based controls (brightness, colour temperature) and dial controls (fan, thermostat) SHALL be constrained to a maximum width (480 dp for sliders) when placed in a content pane wider than that maximum, rather than stretching to the full pane width. The constraint SHALL be a shared layout constant so all controls cap consistently.

#### Scenario: Slider does not span a wide window
- **GIVEN** a content pane 1600 dp wide
- **WHEN** a brightness slider renders in a section
- **THEN** the slider's track SHALL be at most 480 dp wide

#### Scenario: Narrow layouts are unaffected
- **GIVEN** a content pane 360 dp wide
- **WHEN** a brightness slider renders
- **THEN** the slider SHALL use the available width as before
