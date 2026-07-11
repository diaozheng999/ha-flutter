## ADDED Requirements

### Requirement: Quick-controls layer
The room detail screen SHALL surface a quick-controls layer with one `QuickControlTile` per on/off-capable device in the room (AC, fan, air purifier, light group). In the wide layout the tiles SHALL render as a quick-controls block inside the room sidebar, alongside — not replacing — the section navigation items and their status lines. In the compact layout the tiles SHALL render as a horizontal strip above the section selector. Tapping a tile SHALL toggle that device's power via its descriptor without navigating into a section.

#### Scenario: Wide layout augments the sidebar
- **WHEN** the Living Room detail screen renders at 1200 dp
- **THEN** the sidebar SHALL contain a quick-controls block with tiles for the AC, fan, and lights group, in addition to the section navigation items

#### Scenario: Compact layout shows a strip
- **WHEN** the Bedroom detail screen renders at 400 dp
- **THEN** a horizontal quick-controls strip SHALL render above the section selector

#### Scenario: Fan off in one tap
- **GIVEN** the Bedroom fan runs at 60%
- **WHEN** the user taps the fan quick tile
- **THEN** `fan.turn_off` SHALL be called without the Climate & Air section opening

## MODIFIED Requirements

### Requirement: Room sidebar content
In the wide layout, the sidebar SHALL contain, top to bottom: the room icon and name, the room's environment readings (temperature, humidity, illuminance, PM2.5 — whichever the room provides), the room alert strip (per `room-status-alerts`, only when alerts exist), the quick-controls block (one `QuickControlTile` per on/off-capable device), and one navigation item per available section. Each section navigation item SHALL display a live secondary status line sourced from the shared device descriptors and status-line grammar: Lights SHALL show the count of lights currently on (or "Off"), Climate & Air SHALL show the AC current temperature and HVAC mode (or fan percentage when no AC exists), and Media SHALL show the player state.

#### Scenario: Sidebar shows live section state
- **GIVEN** the Living Room has 2 lights on and the AC is cooling at 24.5°C
- **WHEN** the sidebar renders
- **THEN** the Lights item SHALL read "2 on" and the Climate & Air item SHALL show "24.5°" with the cool mode

#### Scenario: Status lines and quick tiles agree
- **GIVEN** the Living Room has 2 lights on
- **WHEN** the sidebar renders
- **THEN** the Lights navigation item and the lights quick tile SHALL both read "2 on"

#### Scenario: Environment readings move to sidebar
- **WHEN** the Living Room detail screen renders in the wide layout
- **THEN** temperature, humidity, and illuminance readings SHALL appear in the sidebar and the screen SHALL NOT render a separate full-width header card

### Requirement: Climate & Air section
The Climate & Air section SHALL combine the room's AC thermostat, fan, and air purifier controls in one section, each rendered as a `ControlCard` conforming to the shared control design language. In the wide layout the controls SHALL render side by side; in the compact layout they SHALL stack vertically. Each control SHALL retain its existing behavior (setpoint ±0.5°C via `climate.set_temperature`, HVAC mode selection via `climate.set_hvac_mode`, fan percentage via `fan.turn_on`/`fan.turn_off`, purifier power via its `switch` entity, 200 ms debounce). Rooms SHALL render only the controls for devices they have.

#### Scenario: Living Room shows thermostat and fan together
- **WHEN** the Living Room Climate & Air section renders at ≥ 840 dp
- **THEN** the AC thermostat and the fan speed dial SHALL render side by side within the section

#### Scenario: Purifier is a first-class control
- **WHEN** the Bedroom Climate & Air section renders
- **THEN** the air purifier SHALL render as a `ControlCard` with the shared header and `PowerToggle`, as a peer of the AC and fan

#### Scenario: Fan-only room renders fan control alone
- **GIVEN** a room with a fan entity and no climate entity
- **WHEN** its Climate & Air section renders
- **THEN** only the fan control SHALL render and no thermostat placeholder SHALL appear

### Requirement: Lights section
The Lights & Ambiance section SHALL be available for all rooms that have light entities. It SHALL contain: a group-level `ControlCard` whose header `PowerToggle` toggles the room's primary light group entity, a brightness slider, a colour-temperature slider (shown only if the group supports `color_temp_kelvin`), an adaptive-lighting `OptionChip` when the room has an `adaptiveLightingSwitch`, and the room's individual lights rendered as light tiles with per-tile toggle and inline brightness. In the wide layout the individual light tiles SHALL render as an always-visible responsive grid; in the compact layout they SHALL be collapsed behind a "Show individual lights" affordance that expands the list ("Hide individual lights" when expanded). Group slider drags SHALL be debounced at 200 ms.

#### Scenario: Group toggle turns all room lights on
- **WHEN** the user taps the group card's `PowerToggle` while all lights are off
- **THEN** the app SHALL call `light.turn_on` on the room's primary group entity and all individual light tiles SHALL reflect the updated state

#### Scenario: Brightness slider controls group brightness
- **WHEN** the user drags the group brightness slider to 60%
- **THEN** the app SHALL call `light.turn_on` with `brightness_pct: 60` on the group entity, debounced at 200 ms

#### Scenario: Colour temperature slider hidden for non-CCT groups
- **WHEN** the room's light group does not report `color_temp_kelvin` in its attribute list
- **THEN** the colour-temperature slider SHALL NOT render

#### Scenario: Individual lights always visible on wide layout
- **WHEN** the Kitchen Lights & Ambiance section renders at ≥ 840 dp
- **THEN** all individual lights SHALL render as a tile grid without requiring an expand action

#### Scenario: Individual lights expandable on compact layout
- **GIVEN** the compact layout
- **WHEN** the user taps "Show individual lights"
- **THEN** the individual light tiles SHALL appear and the affordance label SHALL change to "Hide individual lights"

#### Scenario: Adaptive lighting chip toggles the AL switch
- **GIVEN** a room with an adaptive-lighting switch entity
- **WHEN** the user taps the adaptive-lighting `OptionChip` while the switch is `on`
- **THEN** the app SHALL call `switch.turn_off` on the room's adaptive-lighting switch entity
