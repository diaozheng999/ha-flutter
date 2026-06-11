## ADDED Requirements

### Requirement: Light toggle widget
The app SHALL provide a `LightToggleWidget` that renders a glassmorphic card with an on/off toggle. When the light is `on`, the card SHALL display a radial glow `BoxShadow` using the entity's `hs_color` attribute converted to an sRGB `Color` (saturation clamped to 0.6, lightness 0.45); if `hs_color` is absent, a warm white `#FFF4E0` glow SHALL be used. Glow blur radius SHALL be 24 px at 45% opacity. When `off`, no glow is rendered. When `unavailable`, the card SHALL render at 40% opacity with interaction disabled.

#### Scenario: Toggle on renders glow
- **WHEN** a light entity state is `on` with `hs_color: [45, 90]`
- **THEN** the card SHALL render a radial glow with a warm amber colour derived from hue 45°, saturation 0.6, lightness 0.45

#### Scenario: Toggle off removes glow
- **WHEN** a light entity state transitions to `off`
- **THEN** the glow BoxShadow SHALL animate out over 300 ms

#### Scenario: Unavailable state disables interaction
- **WHEN** a light entity state is `unavailable`
- **THEN** the toggle SHALL be non-interactive and the card SHALL render at 40% opacity

---

### Requirement: Brightness slider
The app SHALL provide a `BrightnessSlider` that maps the entity's `brightness` attribute (0–255) to a 0–100% display range. Dragging SHALL debounce service calls at 200 ms. The slider SHALL support dragging to 0, which SHALL call `light.turn_off` instead of `light.turn_on` with `brightness: 0`.

#### Scenario: Drag to 0 calls turn_off
- **WHEN** the user drags the brightness slider to 0%
- **THEN** the app SHALL call `light.turn_off` on the entity, not `light.turn_on` with brightness 0

#### Scenario: Drag debounce
- **WHEN** the user drags the slider rapidly across multiple positions within 200 ms
- **THEN** only the final position's value SHALL be sent as a service call

---

### Requirement: Colour temperature slider
The app SHALL provide a `ColorTemperatureSlider` that maps the entity's `color_temp_kelvin` attribute range (from entity min/max attributes) to a visual warm-to-cool gradient track. The slider SHALL only render when the entity reports `color_temp_kelvin` in its supported colour modes. Dragging SHALL call `light.turn_on` with `color_temp_kelvin`, debounced at 200 ms.

#### Scenario: Slider renders for CCT-capable lights
- **WHEN** a light entity's `supported_color_modes` includes `color_temp`
- **THEN** the `ColorTemperatureSlider` SHALL render with a warm-to-cool gradient track

#### Scenario: Slider absent for RGB-only lights
- **WHEN** a light entity's `supported_color_modes` is `['hs']` only
- **THEN** the `ColorTemperatureSlider` SHALL NOT render

---

### Requirement: Fan speed dial
The app SHALL provide a `FanSpeedDial` — a circular arc-style dial — that maps 0–100% to the fan's `percentage` attribute. The arc fill SHALL animate smoothly when the percentage changes. A numeric label in the centre SHALL display the current percentage. Dragging the dial to 0 SHALL call `fan.turn_off`; any value > 0 SHALL call `fan.turn_on` with `percentage`, debounced at 200 ms.

#### Scenario: Dial reflects live fan state
- **WHEN** `fan.bedroom_fan` `percentage` attribute changes from 50 to 75 via a WebSocket event
- **THEN** the arc fill SHALL animate from 50% to 75% and the centre label SHALL update to "75%"

#### Scenario: Dial at zero calls turn_off
- **WHEN** the user releases the dial at 0%
- **THEN** the app SHALL call `fan.turn_off` on the entity

---

### Requirement: AC thermostat widget
The app SHALL provide an `AcThermostatWidget` containing: a temperature ring that displays `current_temperature` on the outer arc and `temperature` (setpoint) prominently in the centre; +/− step buttons (0.5°C increment); an HVAC mode chip row showing only the modes present in the entity's `hvac_modes` attribute. The ring arc fill SHALL represent the setpoint relative to a 16–30°C display range. AC off state SHALL dim the ring and disable step buttons while keeping the mode chips active.

#### Scenario: Temperature ring shows current vs setpoint
- **WHEN** `climate.living_room_ac` reports `current_temperature: 27.2` and `temperature: 25.0`
- **THEN** the outer arc SHALL show 27.2 and the centre SHALL prominently display "25.0°C"

#### Scenario: Mode chip activates correct mode
- **WHEN** the user taps the "Cool" chip
- **THEN** the app SHALL call `climate.set_hvac_mode` with `hvac_mode: cool`

#### Scenario: Step button disabled when off
- **WHEN** the climate entity's `hvac_mode` is `off`
- **THEN** the +/− step buttons SHALL be disabled (non-interactive, 40% opacity)

---

### Requirement: Media mini-player widget
The app SHALL provide a `MediaMiniPlayer` widget displaying: album art (from `entity_picture` attribute, loaded via authenticated HA image proxy URL), track name and artist (from `media_title` and `media_artist` attributes), play/pause toggle button, previous and next track buttons. The widget SHALL adapt gracefully when metadata is absent (e.g., TV broadcast with no album art: show a placeholder icon).

#### Scenario: Play/pause toggle
- **WHEN** the user taps the play/pause button while the player is `paused`
- **THEN** the app SHALL call `media_player.media_play` on the entity

#### Scenario: Album art loads via authenticated proxy
- **WHEN** `entity_picture` attribute is present
- **THEN** the widget SHALL load the image via the HA base URL with a `Bearer` token `Authorization` header

#### Scenario: No metadata fallback
- **WHEN** `media_title` and `media_artist` are absent (e.g., TV on live broadcast)
- **THEN** the widget SHALL display "—" for both fields and a generic TV icon in place of album art

---

### Requirement: Glassmorphic card surface
All control cards SHALL use a consistent glassmorphic surface: `BackdropFilter` with `ImageFilter.blur(sigmaX: 20, sigmaY: 20)`, a `Container` fill of `Color(0x18FFFFFF)`, a 1 px border of `Color(0x30FFFFFF)`, and a corner radius of 20 px. This surface SHALL be applied uniformly by a shared `GlassCard` widget that wraps any child.

#### Scenario: Glass card blurs background
- **WHEN** a `GlassCard` is rendered over the animated sky background
- **THEN** the card content area SHALL visually blur the background behind it

#### Scenario: On-state glow
- **WHEN** a device entity is `on` and a glow colour is provided to `GlassCard`
- **THEN** the card SHALL render a `BoxShadow` with the given colour at blur 24 px and opacity 0.45
