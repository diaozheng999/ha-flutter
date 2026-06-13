# Room View

## Purpose

Defines the room detail screen: navigation, responsive layout shell (sidebar on wide / compact on narrow), room header with environment data, ambient background tinting, concept section navigation, lights section, fan section, AC thermostat section, environment trend graph, media player section, and the per-room entity inventory.

## Requirements

### Requirement: Room detail screen navigation
The app SHALL push a `RoomDetailScreen` when a room card is tapped from the home grid or Rooms tab. The screen SHALL receive the room identifier and load all entities assigned to that room. The back action SHALL pop to the originating screen. The screen SHALL NOT be a separate bottom-nav tab.

#### Scenario: Navigate to Living Room
- **WHEN** the user taps the Living Room room card
- **THEN** `RoomDetailScreen` SHALL push with the Living Room room identifier and display Living Room entities

#### Scenario: Back navigation returns to home grid
- **WHEN** the user presses back from a room detail screen reached via the home grid
- **THEN** the app SHALL pop back to the home screen with the room grid visible

---

### Requirement: Room header with environment data
The room detail screen SHALL display the room name, room icon, and the room's environment readings (temperature from AC `current_temperature`, humidity and illuminance from ShellyWallDisplay for Living Room only, PM2.5 from the air purifier sensor for Bedroom only). In the wide layout these SHALL render in the room sidebar; in the compact layout they SHALL render as a slim header row above the section selector. The screen SHALL NOT render a separate full-width header card.

#### Scenario: Living Room shows temperature, humidity, illuminance
- **WHEN** the Living Room detail screen is displayed
- **THEN** temperature from `climate.living_room_ac` `current_temperature`, humidity from `sensor.shellywalldisplay_00a90b9db957_humidity`, and illuminance from `sensor.shellywalldisplay_00a90b9db957_illuminance` SHALL be visible in the sidebar (wide) or header row (compact)

#### Scenario: Bedroom shows PM2.5
- **WHEN** the Bedroom detail screen is displayed
- **THEN** PM2.5 from `sensor.zhimi_sg_433492230_mb4_pm2_5_density_p_3_4` SHALL be shown alongside the AC temperature

#### Scenario: Pantry shows no environment data
- **WHEN** the Pantry detail screen is displayed
- **THEN** no temperature, humidity, or PM2.5 readings SHALL be displayed

---

### Requirement: Responsive room layout shell
The room detail screen SHALL adapt its layout to the available width using a single breakpoint at 840 dp. At widths ≥ 840 dp the screen SHALL render a sidebar layout: a fixed-width (~300 dp) room sidebar on the left and a content pane on the right. At widths < 840 dp the screen SHALL render a compact layout: a slim room header row, a horizontal section selector, and the section content below. Section selection state SHALL be preserved when the window is resized across the breakpoint.

#### Scenario: Wide window shows sidebar
- **WHEN** the room detail screen is displayed in a window 1200 dp wide
- **THEN** a room sidebar SHALL render on the left and the selected section's controls SHALL render in the content pane on the right

#### Scenario: Phone portrait shows compact layout
- **WHEN** the room detail screen is displayed at 400 dp width
- **THEN** the screen SHALL show a compact header row and a horizontal section selector instead of a sidebar

#### Scenario: Resize across breakpoint preserves selection
- **GIVEN** the user selected the Media section in the wide layout
- **WHEN** the window is resized to 600 dp wide
- **THEN** the compact layout SHALL render with the Media section still selected

---

### Requirement: Room sidebar content
In the wide layout, the sidebar SHALL contain, top to bottom: the room icon and name, the room's environment readings (temperature, humidity, illuminance, PM2.5 — whichever the room provides), the room alert strip (per `room-status-alerts`, only when alerts exist), and one navigation item per available section. Each section navigation item SHALL display a live secondary status line: Lights SHALL show the count of lights currently on (or "Off"), Climate & Air SHALL show the AC current temperature and HVAC mode (or fan percentage when no AC exists), and Media SHALL show the player state.

#### Scenario: Sidebar shows live section state
- **GIVEN** the Living Room has 2 lights on and the AC is cooling at 24.5°C
- **WHEN** the sidebar renders
- **THEN** the Lights item SHALL read "2 on" and the Climate & Air item SHALL show "24.5°" with the cool mode

#### Scenario: Environment readings move to sidebar
- **WHEN** the Living Room detail screen renders in the wide layout
- **THEN** temperature, humidity, and illuminance readings SHALL appear in the sidebar and the screen SHALL NOT render a separate full-width header card

---

### Requirement: Concept section navigation
The room detail screen SHALL organize controls into concept sections: **Climate & Air** (available when the room has a climate or fan entity), **Lights & Ambiance** (available when the room has any light entity), and **Media** (available when the room's media player is in an active state: `playing`, `paused`, `idle`). Exactly one section SHALL be visible at a time, selected via the sidebar items (wide) or selector chips (compact). The default selection SHALL be the first available section in the order Climate & Air, Lights & Ambiance, Media. When only one section is available, the navigation items SHALL be hidden and that section SHALL render directly.

#### Scenario: Section switch
- **GIVEN** the Living Room detail screen shows the Climate & Air section
- **WHEN** the user selects the Lights & Ambiance item
- **THEN** the content pane SHALL replace the climate controls with the lights controls

#### Scenario: Single-section room hides navigation
- **WHEN** the Pantry detail screen is displayed (lights only)
- **THEN** no section navigation SHALL render and the Lights & Ambiance section SHALL be shown directly

#### Scenario: Media section appears when playback starts
- **GIVEN** the Bedroom speaker is `off` and no Media item is shown
- **WHEN** the speaker state changes to `playing`
- **THEN** a Media navigation item SHALL appear with the player state as its status line

---

### Requirement: Climate & Air section
The Climate & Air section SHALL combine the room's AC thermostat and fan controls in one section. In the wide layout the thermostat and fan dial SHALL render side by side; in the compact layout they SHALL stack vertically. Each control SHALL retain its existing behavior (setpoint ±0.5°C via `climate.set_temperature`, HVAC mode chips via `climate.set_hvac_mode`, fan percentage via `fan.turn_on`/`fan.turn_off`, 200 ms debounce). Rooms with only a fan or only an AC SHALL render only the control they have.

#### Scenario: Living Room shows thermostat and fan together
- **WHEN** the Living Room Climate & Air section renders at ≥ 840 dp
- **THEN** the AC thermostat and the fan speed dial SHALL render side by side within the section

#### Scenario: Fan-only room renders fan control alone
- **GIVEN** a room with a fan entity and no climate entity
- **WHEN** its Climate & Air section renders
- **THEN** only the fan control SHALL render and no thermostat placeholder SHALL appear

---

### Requirement: Environment trend graph
The Climate & Air section SHALL display a 24-hour trend graph below the climate controls, plotting the room's temperature history and, where the room has the sensors, humidity and PM2.5. History SHALL be fetched via the HA REST history API (`GET /api/history/period/<start>?filter_entity_id=…`) when the section is opened, cached per room for 5 minutes, and rendered as a non-interactive line chart. The section's controls SHALL render immediately while history loads; if the history fetch fails, the section SHALL render without the graph and without an error placeholder.

#### Scenario: Temperature trend renders for Living Room
- **WHEN** the Living Room Climate & Air section opens
- **THEN** a line chart SHALL render showing the last 24 hours of temperature, with the current value as the final point

#### Scenario: Controls render before history arrives
- **WHEN** the Climate & Air section opens and the history request is in flight
- **THEN** the thermostat and fan controls SHALL be interactive immediately and the graph SHALL appear when data arrives

#### Scenario: Re-entry within cache window skips refetch
- **GIVEN** the section was opened less than 5 minutes ago
- **WHEN** the user navigates away and back to the section
- **THEN** the graph SHALL render from the cached series without a new REST request

---

### Requirement: Room ambient background tinting
When inside a room detail screen, the `BackgroundEngine` gradient SHALL gain a third colour stop in the middle derived from the average `hs_color` of all currently-on lights in that room, expressed as HSL(h, 0.6, 0.15). When all room lights are off the ambient tint SHALL be transparent. The tint SHALL animate in/out over 600 ms when lights turn on or off.

#### Scenario: Warm tint when Hue lights are on
- **WHEN** `light.hue_living_room_window` is on with `hs_color: [30, 80]` (warm amber)
- **THEN** the Living Room detail screen background SHALL blend a warm amber tint into the gradient middle stop

#### Scenario: Tint clears when all lights off
- **WHEN** all Living Room lights turn off
- **THEN** the ambient tint SHALL fade to transparent over 600 ms

---

### Requirement: Lights section
The Lights & Ambiance section SHALL be available for all rooms that have light entities. It SHALL contain: a group-level toggle (on/off) for the room's primary light group entity, a brightness slider, a colour-temperature slider (shown only if the group supports `color_temp_kelvin`), an adaptive-lighting toggle chip when the room has an `adaptiveLightingSwitch`, and the room's individual lights rendered as light tiles with per-tile toggle and inline brightness. In the wide layout the individual light tiles SHALL render as an always-visible responsive grid; in the compact layout they SHALL be collapsed behind a "Show individual lights" affordance that expands the list ("Hide individual lights" when expanded). Group slider drags SHALL be debounced at 200 ms.

#### Scenario: Group toggle turns all room lights on
- **WHEN** the user taps the group toggle while all lights are off
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
- **WHEN** the user taps the adaptive-lighting chip while the switch is `on`
- **THEN** the app SHALL call `switch.turn_off` on the room's adaptive-lighting switch entity

---

### Requirement: Fan section
The room's fan control SHALL render inside the Climate & Air section for rooms that have a `fan.*` entity (Living Room, Bedroom, Study). The control SHALL be a circular speed dial (0–100% mapped to the fan's `percentage` attribute) with a label showing the current speed percentage, constrained to a compact size rather than spanning the content pane. Setting speed to 0 SHALL call `fan.turn_off`; any value above 0 SHALL call `fan.turn_on` with `percentage`.

#### Scenario: Fan speed dial sets percentage
- **WHEN** the user drags the speed dial to 75%
- **THEN** the app SHALL call `fan.turn_on` with `entity_id` of the room fan and `percentage: 75`, debounced at 200 ms

#### Scenario: Fan turns off at zero
- **WHEN** the user drags the speed dial to 0
- **THEN** the app SHALL call `fan.turn_off` on the room fan entity

---

### Requirement: AC thermostat section
The room's AC thermostat SHALL render inside the Climate & Air section for rooms with a `climate.*` entity (Living Room, Bedroom, Study). It SHALL contain: a temperature ring showing current temperature and setpoint, +/− buttons to adjust setpoint in 0.5°C increments, and an HVAC mode chip selector (`off`, `cool`, `heat`, `fan_only`, `auto` — only modes supported by the entity). Changing the setpoint SHALL call `climate.set_temperature`; changing the mode SHALL call `climate.set_hvac_mode`.

#### Scenario: Setpoint increment
- **WHEN** the user taps "+" once while setpoint is 24°C
- **THEN** the app SHALL call `climate.set_temperature` with `temperature: 24.5` on the room AC entity

#### Scenario: Mode changes to cool
- **WHEN** the user taps the "Cool" mode chip
- **THEN** the app SHALL call `climate.set_hvac_mode` with `hvac_mode: cool`

#### Scenario: Climate & Air section absent for rooms without AC or fan
- **WHEN** the Kitchen or Entrance detail screen is displayed
- **THEN** no Climate & Air section or navigation item SHALL render

---

### Requirement: Media player section
The Media section SHALL be available when the room has an associated `media_player.*` entity in an active state (`playing`, `paused`, `idle`), and SHALL show a `MediaMiniPlayer` widget. Rooms without a media player entity, or where the entity is `off` or `unavailable`, SHALL NOT show a Media section or its navigation item.

#### Scenario: TV now-playing displayed in Living Room
- **WHEN** `media_player.lg_webos_tv_qned82asa_3` is `playing`
- **THEN** the Living Room Media section SHALL render the media player with the TV's current track/channel metadata

#### Scenario: Media section hidden when player is off
- **WHEN** `media_player.bedroom_speaker_2` is `off`
- **THEN** the Bedroom detail screen SHALL NOT show a Media section or navigation item

---

### Requirement: Room entity inventory (per-room device mapping)
The app SHALL use the following fixed entity-to-room mapping for v1. This mapping SHALL be hardcoded and not user-configurable in v1.

| Room | Lights group | Individual lights | Fan | AC | Media player |
|---|---|---|---|---|---|
| Living Room | `light.living_room_lights` | hue_window, hue_entrance, walkway_spotlight | `fan.living_room_fan` | `climate.living_room_ac` | `media_player.lg_webos_tv_qned82asa_3` |
| Kitchen | `light.kitchen_lights` | ceiling, spot 1–3, coffee 1–2, pantry_lights, dining_table_lights | — | — | `media_player.pantry_display_2` |
| Bedroom | `light.bedroom_light` | bedroom_spotlight | `fan.bedroom_fan` | `climate.bedroom_ac` | `media_player.bedroom_speaker_2` |
| Study | `light.study_light` | — | `fan.study_fan` | `climate.study_ac` | `media_player.study_speaker_2` |
| Entrance | `light.entry_lights` | dining_table_lights | — | — | — |
| Pantry | `light.pantry_lights` | walkway_spotlight_inner, walkway_spotlight_outer | — | — | `media_player.pantry_display_2` |

#### Scenario: Kitchen shows no fan or AC section
- **WHEN** the Kitchen detail screen is displayed
- **THEN** the fan section and AC thermostat section SHALL NOT render
