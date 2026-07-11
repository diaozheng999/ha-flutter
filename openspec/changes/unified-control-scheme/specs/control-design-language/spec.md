## ADDED Requirements

### Requirement: Control card anatomy
The app SHALL provide a `ControlCard` widget that composes the existing `GlassCard` with a fixed header — a leading device icon, the device name, an optional live status line, and a trailing power-affordance slot — above an optional body holding the device's detailed controls. All detailed device controls (AC thermostat, fan, air purifier, light group control) SHALL render as a `ControlCard` with a category-specific body. The header SHALL be a single compact row and SHALL remain visually subordinate to an arc-gauge body when one is present. When the device is unavailable the card SHALL render at 40% opacity with every control non-interactive.

#### Scenario: All device families share one header anatomy
- **WHEN** the AC, fan, and air purifier controls render in the Bedroom Climate & Air section
- **THEN** each SHALL display the same header anatomy — icon, name, live status line, power affordance — above its detailed controls

#### Scenario: Unavailable device disables the whole card
- **WHEN** a device's entity state is `unavailable`
- **THEN** its `ControlCard` SHALL render at 40% opacity, all body controls SHALL be non-interactive, and the status line SHALL read "Unavailable"

### Requirement: Layered device state semantics
Device state SHALL be rendered as ordered layers: availability gates everything (an unavailable device dims, disables, and shows "—" for readings rather than stale values); on/off is meaningful only when the device is available and drives the on/off visual treatment; sensor readings SHALL be shown whenever the device is available — including when it is off; the control surface may enable or disable individual controls based on the layers above. An in-flight service call SHALL be indicated by the existing pending overlay over whatever the layers render, without altering them.

#### Scenario: Powered-off purifier still reports air quality
- **GIVEN** the Bedroom air purifier's power switch is `off` and its PM2.5 sensor reads 14
- **WHEN** the purifier control renders
- **THEN** the PM2.5 reading pill SHALL show "14 µg/m³" while the card renders the off treatment

#### Scenario: Unavailable device never shows stale readings
- **WHEN** a device's sensor entities are `unavailable`
- **THEN** its readings SHALL display "—" instead of the last known values

#### Scenario: Pending overlay is orthogonal to state
- **WHEN** a power toggle's service call is in flight
- **THEN** the pending overlay SHALL render over the card without changing the underlying on/off treatment

### Requirement: Rationed glow semantics
The radial card glow SHALL render only where colour carries information: light controls glow in the light's `hs_color`-derived colour (existing behaviour), and climate controls glow in a hue derived from the active HVAC mode (a cold hue for `cool`, a warm hue for `heat`). Fan and air purifier controls SHALL NOT render a radial glow; their on state SHALL read through the accent treatment — accent-coloured icon and lit arc or selected mode chip. Devices that are off or unavailable SHALL render no glow.

#### Scenario: Cooling AC glows in a cold hue
- **WHEN** `climate.bedroom_ac` is in `cool` mode
- **THEN** its control card SHALL render a radial glow in the cold mode hue

#### Scenario: Running fan does not glow
- **GIVEN** `fan.bedroom_fan` is on at 60%
- **WHEN** its control card renders
- **THEN** no radial glow SHALL render, and the fan icon and arc SHALL use the accent (on) colour

#### Scenario: Light keeps its colour glow
- **WHEN** a light is `on` with `hs_color: [45, 90]`
- **THEN** its card SHALL glow in the colour derived from `hs_color`, per the existing light glow behaviour

### Requirement: Power toggle
The app SHALL provide a `PowerToggle` — a circular glass icon button with a power glyph — as the single power affordance in detailed control-card headers. When off it SHALL render the glyph in the muted foreground on the glass fill; when on it SHALL render with the accent fill. Its hit target SHALL be at least 48 dp. It SHALL NOT be a Material `Switch`. Activating it SHALL invoke the device descriptor's toggle action.

#### Scenario: Toggle powers a running device off
- **GIVEN** the fan is on
- **WHEN** the user taps the header `PowerToggle`
- **THEN** the descriptor's toggle action SHALL be invoked and the fan turned off

#### Scenario: Visual state tracks power
- **WHEN** a device transitions from off to on
- **THEN** the `PowerToggle` SHALL change from the muted glyph to the accent-filled treatment

### Requirement: Device control descriptor
The app SHALL resolve one `DeviceControlDescriptor` per room device role, carrying: icon, display name, availability, on/off state, sensor reading specs, the status line, and the power-toggle action. The descriptor SHALL be the only place encoding these per-role facts; the quick-controls layer and the section status lines SHALL both read from it. Power semantics SHALL be: lights and fans toggle via their domain services (`*.turn_on` / `*.turn_off`); the air purifier toggles its power `switch` entity; climate powers off via `climate.set_hvac_mode` with `off` and powers on via `climate.set_hvac_mode` with `cool`, falling back to the first non-`off` mode in the entity's `hvac_modes` when `cool` is not supported.

#### Scenario: Climate quick power-on selects cool
- **GIVEN** `climate.study_ac` is `off` and its `hvac_modes` include `cool`
- **WHEN** the user powers it on via any `PowerToggle`
- **THEN** the app SHALL call `climate.set_hvac_mode` with `hvac_mode: cool`

#### Scenario: Climate without cool falls back
- **GIVEN** a climate entity whose `hvac_modes` is `['off', 'heat']`
- **WHEN** the user powers it on
- **THEN** the app SHALL call `climate.set_hvac_mode` with `hvac_mode: heat`

#### Scenario: Strip and section status agree
- **GIVEN** 2 of the Living Room's lights are on
- **WHEN** the lights quick tile and the Lights section navigation item render
- **THEN** both SHALL read "2 on", sourced from the same descriptor

### Requirement: Status-line grammar
Every device status line SHALL follow one grammar: "Unavailable" when the device is unavailable; "Off" when it is off; otherwise a primary value, optionally followed by " · " and a secondary descriptor. Canonical forms: AC "24.5° · Cool"; fan "75%"; air purifier "Auto · PM2.5 8"; lights "2 on" (count of individual lights on) or "On" (group on with no individual lights on). HVAC and purifier mode labels SHALL come from a single shared formatter.

#### Scenario: AC status combines temperature and mode
- **WHEN** `climate.living_room_ac` reports `current_temperature: 24.5` in `cool` mode
- **THEN** its status line SHALL read "24.5° · Cool"

#### Scenario: Purifier status combines mode and reading
- **WHEN** the purifier is on in mode `Auto` with PM2.5 at 8
- **THEN** its status line SHALL read "Auto · PM2.5 8"

#### Scenario: Off is just Off
- **WHEN** any available device is off
- **THEN** its status line SHALL read exactly "Off"

### Requirement: Selection chips
The app SHALL theme chips once via a `ChipThemeData` in the app theme and provide two semantic chip widgets: `ModeSelector`, which renders a mutually-exclusive choice set where selecting one deselects the others, and `OptionChip`, which renders an independent binary option that toggles without affecting sibling chips. HVAC mode and purifier mode SHALL use `ModeSelector`; adaptive lighting and fan oscillation (when exposed) SHALL use `OptionChip`. Both SHALL derive their visuals from the shared chip theme. Mutually-exclusive selectors elsewhere in the app — the dashboard config selector and the compact section selector — SHALL derive their selected/unselected styling from the same shared selector treatment.

#### Scenario: Mode selection is exclusive
- **GIVEN** the HVAC `ModeSelector` shows Off / Cool / Dry with Cool selected
- **WHEN** the user taps Dry
- **THEN** Dry SHALL become the single selected chip and `climate.set_hvac_mode` SHALL be called with `hvac_mode: dry`

#### Scenario: Option chips toggle independently
- **WHEN** the user taps the adaptive-lighting `OptionChip` while it is selected
- **THEN** only that chip's state SHALL change and `switch.turn_off` SHALL be called on the adaptive-lighting switch

#### Scenario: One chip style everywhere
- **WHEN** chips render in the AC, purifier, and lights controls
- **THEN** they SHALL share the same themed visual style

#### Scenario: App-wide selectors share the treatment
- **WHEN** the dashboard config selector renders on the home screen
- **THEN** its selected and unselected styling SHALL derive from the shared selector treatment, not widget-local styling

### Requirement: Shared arc gauge
The app SHALL provide a single `ArcGauge` widget drawing a 270° arc starting at 135°, with shared stroke width, rounded caps, and track/fill treatment. The AC thermostat ring and the fan speed dial SHALL both render through `ArcGauge`, supplying their own centre content and value mapping. The duplicated per-widget arc painters SHALL be removed.

#### Scenario: Ring and dial share geometry
- **WHEN** the AC ring and the fan dial render
- **THEN** both arcs SHALL be drawn by `ArcGauge` with identical sweep, caps, and stroke treatment

### Requirement: Reading pill with generic severity
The app SHALL provide a `ReadingPill` (icon + formatted value, optional severity colour) driven by a `ReadingSpec` that may carry a severity mapping resolving a numeric reading to one of three levels: nominal, warning, critical. Mapping direction (rising-bad or falling-bad) SHALL be part of the per-reading mapping. The three level colours SHALL come from theme tokens `severityNominal` / `severityWarning` / `severityCritical`, whose hues SHALL be distinguishable from the `onAccent` colour. A reading without a severity mapping SHALL render in the neutral muted foreground.

#### Scenario: Rising-bad reading escalates
- **WHEN** a PM2.5 reading of 45 µg/m³ renders with the PM2.5 severity mapping (nominal < 12, warning 12–35, critical > 35)
- **THEN** the pill SHALL use the `severityCritical` colour

#### Scenario: Falling-bad reading escalates
- **WHEN** a battery reading of 8% renders with a falling-bad mapping (warning ≤ 20, critical ≤ 10)
- **THEN** the pill SHALL use the `severityCritical` colour

#### Scenario: Unmapped reading stays neutral
- **WHEN** a filter-life reading renders without a severity mapping
- **THEN** the pill SHALL use the neutral muted colour, never a severity colour

### Requirement: Single glass surface recipe
Every blurred translucent surface in the app — control cards, tiles, and the floating navigation dock — SHALL derive its blur strength, fill, border, and corner radius from the shared glass tokens, via `GlassCard` or the same token set. No widget SHALL hard-code its own blur sigma or glass colours. All top-level screens SHALL render over the app-wide background engine, and pushed screens (room detail) SHALL render the same engine (with their ambient tint) rather than an opaque background.

#### Scenario: Dock matches the cards
- **WHEN** the floating navigation dock renders
- **THEN** its blur sigma, fill, and border SHALL come from the same shared glass tokens as `GlassCard`

#### Scenario: All tabs share one surface language
- **WHEN** the Home, Rooms, Security, Scenes, and Maintenance tabs render
- **THEN** every card surface SHALL be the shared glass surface over the app-wide background engine

### Requirement: Accent colours come from tokens
Interactive accent, feedback, and state colours SHALL resolve from the theme (`AppTokens` or the `ColorScheme`); feature widgets SHALL NOT hard-code colour literals. The scene-launch confirm glow SHALL use a theme token rather than an inline green.

#### Scenario: Scene confirm glow uses a token
- **WHEN** a scene tile enters its confirm state
- **THEN** its glow colour SHALL resolve from a theme token, not an inline literal

#### Scenario: Selected navigation treatment uses tokens
- **WHEN** a dock item or selector pill renders as selected
- **THEN** its highlight SHALL derive from the shared accent tokens

### Requirement: Quick control tile
The app SHALL provide a `QuickControlTile`: a compact tile showing a device's icon, name, and one-line status from its descriptor, where tapping anywhere on the tile toggles the device's power and a trailing affordance (chevron tap or long-press) navigates to the device's detailed control. The tile's on state SHALL follow the rationed-glow rule. A quick-controls collection SHALL render one tile per on/off-capable device, and each tile SHALL observe only its own device's entities.

#### Scenario: One-tap power from the tile
- **GIVEN** the fan quick tile shows "60%"
- **WHEN** the user taps the tile body
- **THEN** the fan SHALL turn off without its detailed control opening

#### Scenario: Chevron opens the detailed control
- **WHEN** the user taps the fan tile's trailing chevron
- **THEN** the app SHALL navigate to or reveal the fan's detailed control card

#### Scenario: Tile updates are isolated
- **WHEN** the fan's `percentage` changes via a WebSocket event
- **THEN** only the fan's tile SHALL rebuild; sibling tiles SHALL NOT rebuild
