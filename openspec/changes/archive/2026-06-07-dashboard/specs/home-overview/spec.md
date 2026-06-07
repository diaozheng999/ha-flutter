## ADDED Requirements

### Requirement: Home screen layout
The app SHALL display a `HomeOverviewScreen` as the root destination of the bottom navigation bar. It SHALL be a scrollable screen composed of, in order: the background engine layer, a greeting header, a presence strip, an active-device summary bar, a scene quick-launch row, a room grid, and a now-playing media widget (conditionally rendered).

#### Scenario: Home screen renders on launch
- **WHEN** the app completes authentication and the WebSocket connects
- **THEN** the home screen SHALL display all sections with live entity state within 1 second on a LAN connection

#### Scenario: Home screen renders with stale data on reconnect
- **WHEN** the WebSocket is disconnected and the user opens the app
- **THEN** the home screen SHALL render last-known entity states with a "Reconnecting…" chip in the app bar

---

### Requirement: Background engine
The app SHALL render a `BackgroundEngine` widget as a full-bleed layer behind all screen content. The engine SHALL be selected once at app start based on a `PerformanceTier` (low / medium / high) resolved from a device benchmark probe persisted to local preferences.

- **Low tier**: static `BoxDecoration` gradient derived from current time-of-day phase; no animation; zero per-frame CPU cost.
- **Medium tier**: animated `LinearGradient` whose stop colors lerp continuously via `ColorTween` driven by a 1-second `AnimationController` tick; gradient anchors derived from `sun.sun` elevation attribute; night phase adds a `CustomPainter` star-scatter with slowly varying opacity.
- **High tier**: sun-elevation gradient muxed with a weather-responsive `CustomPainter` particle layer; driven by `sun.sun` elevation and `weather.forecast_home` condition; particle budget SHALL NOT exceed 3 ms per frame.

The engine SHALL expose a `debugForceCondition` override for testing all weather states.

#### Scenario: Gradient tracks sun elevation on high tier
- **WHEN** `sun.sun` elevation changes (e.g., sunrise from −2° to +5°)
- **THEN** the gradient SHALL smoothly transition from twilight violet-orange to golden-hour coral within the next animation tick

#### Scenario: Haze condition on high tier
- **WHEN** `weather.forecast_home` state is `fog` (mapped to Singapore haze)
- **THEN** the gradient SHALL apply a warm yellow-grey tint overlay at 35% opacity and horizontal mist-band particles SHALL render in place of cloud or rain particles

#### Scenario: Rain condition on high tier
- **WHEN** `weather.forecast_home` state is `rainy` or `pouring`
- **THEN** the gradient SHALL desaturate and darken, and diagonal rain-streak particles SHALL render at 60° with density scaled to `pouring` vs `rainy`

#### Scenario: Clear night on high tier
- **WHEN** `sun.sun` elevation is below −6° and condition is `sunny` or `clear-night`
- **THEN** a slow-drifting star field with twinkling opacity SHALL render

#### Scenario: Performance tier downgrade
- **WHEN** the device benchmark probe determines the device cannot sustain 60 fps with particle rendering
- **THEN** the engine SHALL select `medium` or `low` tier and SHALL NOT instantiate the particle `CustomPainter`

---

### Requirement: Greeting header
The home screen SHALL display a greeting header containing: current time (HH:mm, system font monospace), current date (weekday + day + month), a compact weather summary (condition icon + temperature from `weather.forecast_home`), and a greeting string ("Good morning / afternoon / evening") derived from local time.

#### Scenario: Time display updates
- **WHEN** the local clock minute changes
- **THEN** the displayed time SHALL update without a full screen rebuild

#### Scenario: Weather summary reflects live state
- **WHEN** `weather.forecast_home` state or temperature attribute changes
- **THEN** the condition icon and temperature SHALL update within one WebSocket event cycle

---

### Requirement: Presence strip
The home screen SHALL display a horizontal presence strip showing `person.simon` and `person.yamin`. Each person chip SHALL show: avatar initial, display name, and a home/away indicator. Home state SHALL render a filled green dot; not-home SHALL render an outlined grey dot; unknown SHALL render an outlined amber dot.

#### Scenario: Presence updates in real time
- **WHEN** `person.simon` state changes from `home` to `not_home`
- **THEN** Simon's chip SHALL update to the grey outlined indicator within one WebSocket event

#### Scenario: Both residents away
- **WHEN** both `person.simon` and `person.yamin` are `not_home`
- **THEN** the presence strip SHALL show both as outlined grey and the home screen SHALL display no ambient room tinting

---

### Requirement: Active-device summary bar
The home screen SHALL display a horizontal scrolling summary bar of currently active devices. An entry SHALL appear for each category that has at least one device on: lights (count of on lights), fans (count of running fans), ACs (count of active climate entities), Shiny vacuum (if not docked). Tapping a category chip SHALL scroll the home screen to the room grid or navigate to the relevant screen.

#### Scenario: Summary bar updates when light turns on
- **WHEN** any light entity transitions from `off` to `on`
- **THEN** the lights chip count SHALL increment within one WebSocket event

#### Scenario: Summary bar is empty when all devices are off
- **WHEN** all lights, fans, and ACs are off and Shiny is docked
- **THEN** the summary bar SHALL display a single "All quiet" label instead of chips

---

### Requirement: Scene quick-launch row
The home screen SHALL display a horizontally scrolling row of scene tiles. Each tile SHALL show the scene's friendly name and an icon. Tapping a tile SHALL call `scene.turn_on` for that scene with a visual confirmation ripple. The row SHALL include all entities in the `scene.*` domain.

#### Scenario: Scene activates on tap
- **WHEN** the user taps the "Daylight" scene tile
- **THEN** the app SHALL call `scene.turn_on` with `entity_id: scene.daylight` and display a brief confirmation animation on the tile

---

### Requirement: Room grid
The home screen SHALL display a 2-column grid of room cards covering all 6 rooms: Living Room, Kitchen, Bedroom, Study, Entrance, Pantry. Each card SHALL show: room icon, room name, light on/off state (text or icon indicator), current temperature (from the room's AC `current_temperature` attribute, if the room has an AC), and a glassmorphic frosted-glass surface. Tapping a room card SHALL push `RoomDetailScreen` for that room.

#### Scenario: Room card reflects live light state
- **WHEN** `light.living_room_lights` turns on
- **THEN** the Living Room card SHALL update its light indicator and apply a glow effect within one WebSocket event

#### Scenario: Temperature shown on rooms with AC
- **WHEN** `climate.bedroom_ac` `current_temperature` attribute is 26.5
- **THEN** the Bedroom card SHALL display "26.5°C"

#### Scenario: Room without AC shows no temperature
- **WHEN** the Pantry card is rendered (no AC in Pantry)
- **THEN** the Pantry card SHALL NOT display a temperature field

---

### Requirement: Now-playing media widget
The home screen SHALL display a collapsible now-playing widget at the bottom of the scroll area when any media player in the allowlist is in `playing` state. The widget SHALL show: album art thumbnail, track name, artist, room name, and play/pause button. If multiple players are playing, the widget SHALL cycle through them. When no player is active, the widget SHALL be hidden.

#### Scenario: Widget appears when TV starts playing
- **WHEN** `media_player.lg_webos_tv_qned82asa_3` transitions to `playing`
- **THEN** the now-playing widget SHALL animate in from the bottom and display the TV's current media metadata

#### Scenario: Widget hidden when all players idle
- **WHEN** all media players in the allowlist are in `idle`, `off`, or `unavailable` state
- **THEN** the now-playing widget SHALL not be rendered
