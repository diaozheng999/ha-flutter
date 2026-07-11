## MODIFIED Requirements

### Requirement: Light toggle widget
The app SHALL provide a `LightToggleWidget` that renders as a `ControlCard`: a header with the light icon, name, live status line, and a `PowerToggle` that calls `light.turn_on` / `light.turn_off`. When the light is `on`, the card SHALL display a radial glow `BoxShadow` using the entity's `hs_color` attribute converted to an sRGB `Color` (saturation clamped to 0.6, lightness 0.45); if `hs_color` is absent, a warm white `#FFF4E0` glow SHALL be used. Glow blur radius SHALL be 24 px at 45% opacity. When `off`, no glow is rendered. When `unavailable`, the card SHALL render at 40% opacity with interaction disabled.

#### Scenario: Toggle on renders glow
- **WHEN** a light entity state is `on` with `hs_color: [45, 90]`
- **THEN** the card SHALL render a radial glow with a warm amber colour derived from hue 45°, saturation 0.6, lightness 0.45

#### Scenario: Toggle off removes glow
- **WHEN** a light entity state transitions to `off`
- **THEN** the glow BoxShadow SHALL animate out over 300 ms

#### Scenario: Power toggles via the header
- **WHEN** the user taps the header `PowerToggle` while the light is `off`
- **THEN** the app SHALL call `light.turn_on` on the entity

#### Scenario: Unavailable state disables interaction
- **WHEN** a light entity state is `unavailable`
- **THEN** the toggle SHALL be non-interactive and the card SHALL render at 40% opacity

### Requirement: Fan speed dial
The app SHALL provide a `FanSpeedDial` rendered inside a `ControlCard` whose header shows the fan icon, name, a live status line per the shared grammar ("75%" when running, "Off", "Unavailable"), and a `PowerToggle` (on → `fan.turn_on`, off → `fan.turn_off`). The dial SHALL be a circular arc drawn by the shared `ArcGauge`, mapping 0–100% to the fan's `percentage` attribute. The arc fill SHALL animate smoothly when the percentage changes. A numeric label in the centre SHALL display the current percentage. Dragging the dial to 0 SHALL call `fan.turn_off`; any value > 0 SHALL call `fan.turn_on` with `percentage`, debounced at 200 ms. When the entity exposes `oscillating`, an oscillation `OptionChip` SHALL render; when it does not, no oscillation control SHALL appear.

#### Scenario: Dial reflects live fan state
- **WHEN** `fan.bedroom_fan` `percentage` attribute changes from 50 to 75 via a WebSocket event
- **THEN** the arc fill SHALL animate from 50% to 75% and the centre label SHALL update to "75%"

#### Scenario: Dial at zero calls turn_off
- **WHEN** the user releases the dial at 0%
- **THEN** the app SHALL call `fan.turn_off` on the entity

#### Scenario: Header toggle stops the fan without the dial
- **GIVEN** the fan runs at 60%
- **WHEN** the user taps the header `PowerToggle`
- **THEN** the app SHALL call `fan.turn_off` without any dial interaction

#### Scenario: Oscillation renders only when supported
- **WHEN** the fan entity does not report an `oscillating` attribute
- **THEN** no oscillation chip SHALL render

### Requirement: AC thermostat widget
The app SHALL provide an `AcThermostatWidget` rendered as a `ControlCard` whose header shows the climate icon, name, a live status line per the shared grammar (e.g. "24.5° · Cool", "Off"), and a `PowerToggle` — powering off SHALL call `climate.set_hvac_mode` with `off`; powering on SHALL call `climate.set_hvac_mode` with `cool`, falling back to the first non-`off` supported mode when `cool` is absent. The body SHALL contain: a temperature ring drawn by the shared `ArcGauge` that displays `current_temperature` on the outer arc and `temperature` (setpoint) prominently in the centre; +/− step buttons (0.5°C increment); and an HVAC mode `ModeSelector` showing only the modes present in the entity's `hvac_modes` attribute. The ring arc fill SHALL represent the setpoint relative to a 16–30°C display range. AC off state SHALL dim the ring and disable step buttons while keeping the mode selector active.

#### Scenario: Temperature ring shows current vs setpoint
- **WHEN** `climate.living_room_ac` reports `current_temperature: 27.2` and `temperature: 25.0`
- **THEN** the outer arc SHALL show 27.2 and the centre SHALL prominently display "25.0°C"

#### Scenario: Mode chip activates correct mode
- **WHEN** the user taps the "Cool" chip
- **THEN** the app SHALL call `climate.set_hvac_mode` with `hvac_mode: cool`

#### Scenario: Header power-on selects cool
- **GIVEN** the AC is `off` and its `hvac_modes` include `cool`
- **WHEN** the user taps the header `PowerToggle`
- **THEN** the app SHALL call `climate.set_hvac_mode` with `hvac_mode: cool`

#### Scenario: Step button disabled when off
- **WHEN** the climate entity's `hvac_mode` is `off`
- **THEN** the +/− step buttons SHALL be disabled (non-interactive, 40% opacity)

### Requirement: Light tile with inline brightness
The app SHALL provide a `LightTile` widget: a compact glassmorphic tile sized for grid placement (target 160–220 dp wide) containing the light's icon and name in the shared header arrangement, a status line following the shared grammar ("Off", "<pct>%", "Unavailable"), and an inline brightness slider. The whole tile SHALL toggle the light on tap — tiles toggle by tap; detailed cards toggle via the header `PowerToggle`. The tile SHALL reuse the existing glow behaviour (radial glow from `hs_color` when `on`, warm white fallback, none when `off`) and the existing unavailable treatment (40% opacity, interaction disabled). Inline brightness drags SHALL be debounced at 200 ms; dragging to 0 SHALL call `light.turn_off`.

#### Scenario: Tile toggle switches the light
- **WHEN** the user taps a `LightTile` for a light that is `off`
- **THEN** the app SHALL call `light.turn_on` for that entity and the tile SHALL render its glow once the state updates

#### Scenario: Inline brightness adjusts the single light
- **WHEN** the user drags a tile's brightness slider to 40%
- **THEN** the app SHALL call `light.turn_on` with `brightness_pct: 40` on that individual entity only, debounced at 200 ms

#### Scenario: Unavailable light tile is disabled
- **WHEN** the tile's entity state is `unavailable`
- **THEN** the tile SHALL render at 40% opacity with toggle and slider non-interactive

### Requirement: Glassmorphic card surface
All control cards SHALL use a consistent glassmorphic surface defined by the shared glass tokens in `AppTokens`: the shared glass blur sigma (currently 20), the `glassFill` colour (`Color(0x18FFFFFF)`), a 1 px `glassBorder` (`Color(0x30FFFFFF)`), and the shared `cardRadius` (20 px). No widget SHALL hard-code these values independently; they SHALL be applied uniformly by a shared `GlassCard` widget that wraps any child.

#### Scenario: Glass card blurs background
- **WHEN** a `GlassCard` is rendered over the animated sky background
- **THEN** the card content area SHALL visually blur the background behind it

#### Scenario: On-state glow
- **WHEN** a device entity is `on` and a glow colour is provided to `GlassCard`
- **THEN** the card SHALL render a `BoxShadow` with the given colour at blur 24 px and opacity 0.45

#### Scenario: Blur derives from the shared token
- **WHEN** any glass surface (control card or the floating dock) renders its backdrop blur
- **THEN** its blur sigma SHALL come from the shared glass token, not a widget-local literal

## ADDED Requirements

### Requirement: Air purifier control card
The app SHALL provide an air purifier control rendered as a `ControlCard`: the header SHALL show the purifier icon, name, a status line per the shared grammar (e.g. "Auto · PM2.5 8"), and a `PowerToggle` that toggles the purifier's power `switch` entity — replacing the previous Material `Switch`. The body SHALL contain a `ModeSelector` built from the mode `select` entity's `options` attribute (selection calls `select.select_option`; disabled while the purifier is off) and `ReadingPill`s for PM2.5 (severity mapping: nominal < 12, warning 12–35, critical > 35 µg/m³) and filter life. Readings SHALL be visible whenever their sensors are available, including when the purifier is off.

#### Scenario: Power via the shared toggle
- **WHEN** the purifier control renders
- **THEN** its power affordance SHALL be the shared `PowerToggle` acting on the power switch entity, and no Material `Switch` SHALL render

#### Scenario: Mode selection calls select_option
- **GIVEN** the purifier is on
- **WHEN** the user taps the "Sleep" mode chip
- **THEN** the app SHALL call `select.select_option` with `option: Sleep` on the mode entity

#### Scenario: Readings persist while off
- **GIVEN** the purifier power switch is `off`
- **WHEN** the control renders with PM2.5 at 14 µg/m³
- **THEN** the PM2.5 pill SHALL display "14 µg/m³" using the `severityWarning` colour
