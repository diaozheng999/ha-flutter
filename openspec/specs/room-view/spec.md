# Room View

## Purpose

Defines the room detail screen: navigation, room header with environment data, ambient background tinting, lights section, fan section, AC thermostat section, media player section, and the per-room entity inventory.

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
The room detail screen SHALL display a header section containing: room name, room icon, and environment readings relevant to that room (temperature from AC `current_temperature`, humidity and illuminance from ShellyWallDisplay for Living Room only, PM2.5 from the air purifier sensor for Bedroom only).

#### Scenario: Living Room header shows temperature, humidity, illuminance
- **WHEN** the Living Room detail screen is displayed
- **THEN** the header SHALL show temperature from `climate.living_room_ac` `current_temperature`, humidity from `sensor.shellywalldisplay_00a90b9db957_humidity`, and illuminance from `sensor.shellywalldisplay_00a90b9db957_illuminance`

#### Scenario: Bedroom header shows PM2.5
- **WHEN** the Bedroom detail screen is displayed
- **THEN** the header SHALL show PM2.5 from `sensor.zhimi_sg_433492230_mb4_pm2_5_density_p_3_4` alongside the AC temperature

#### Scenario: Pantry header shows no environment data
- **WHEN** the Pantry detail screen is displayed
- **THEN** the header SHALL NOT display temperature, humidity, or PM2.5 fields

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
The room detail screen SHALL display a lights section for all rooms that have light entities. The section SHALL contain: a group-level toggle (on/off) for the primary light group entity of that room, a brightness slider, a colour-temperature slider (shown only if the group supports `color_temp_kelvin`), and a collapsed list of individual lights expandable by tapping a "Show individual lights" affordance. Each individual light SHALL have its own toggle.

#### Scenario: Group toggle turns all room lights on
- **WHEN** the user taps the group toggle while all lights are off
- **THEN** the app SHALL call `light.turn_on` on the room's primary group entity and all individual light toggles SHALL reflect the updated state

#### Scenario: Brightness slider controls group brightness
- **WHEN** the user drags the brightness slider to 60%
- **THEN** the app SHALL call `light.turn_on` with `brightness_pct: 60` on the group entity; the call SHALL be debounced at 200 ms to avoid flooding HA during drag

#### Scenario: Colour temperature slider hidden for non-CCT groups
- **WHEN** the room's light group does not report `color_temp_kelvin` in its attribute list
- **THEN** the colour-temperature slider SHALL NOT render

#### Scenario: Individual lights expand
- **WHEN** the user taps "Show individual lights"
- **THEN** the section SHALL expand to show each individual light entity with its own toggle, and the affordance label SHALL change to "Hide individual lights"

---

### Requirement: Fan section
The room detail screen SHALL display a fan section for rooms that have a `fan.*` entity (Living Room, Bedroom, Study). The section SHALL contain a circular speed dial (0–100% mapped to the fan's `percentage` attribute) and a label showing the current speed percentage. Setting speed to 0 SHALL call `fan.turn_off`; any value above 0 SHALL call `fan.turn_on` with `percentage`.

#### Scenario: Fan speed dial sets percentage
- **WHEN** the user drags the speed dial to 75%
- **THEN** the app SHALL call `fan.turn_on` with `entity_id` of the room fan and `percentage: 75`, debounced at 200 ms

#### Scenario: Fan turns off at zero
- **WHEN** the user drags the speed dial to 0
- **THEN** the app SHALL call `fan.turn_off` on the room fan entity

---

### Requirement: AC thermostat section
The room detail screen SHALL display an AC thermostat section for rooms with a `climate.*` entity (Living Room, Bedroom, Study). The section SHALL contain: a temperature ring showing current temperature and setpoint, +/− buttons to adjust setpoint in 0.5°C increments, and an HVAC mode chip selector (`off`, `cool`, `heat`, `fan_only`, `auto` — only modes supported by the entity). Changing the setpoint SHALL call `climate.set_temperature`; changing the mode SHALL call `climate.set_hvac_mode`.

#### Scenario: Setpoint increment
- **WHEN** the user taps "+" once while setpoint is 24°C
- **THEN** the app SHALL call `climate.set_temperature` with `temperature: 24.5` on the room AC entity

#### Scenario: Mode changes to cool
- **WHEN** the user taps the "Cool" mode chip
- **THEN** the app SHALL call `climate.set_hvac_mode` with `hvac_mode: cool`

#### Scenario: AC section absent for rooms without AC
- **WHEN** the Kitchen or Entrance detail screen is displayed
- **THEN** the AC thermostat section SHALL NOT render

---

### Requirement: Media player section
The room detail screen SHALL display a media player section when the room has an associated `media_player.*` entity in an active state (`playing`, `paused`, `idle`). The section SHALL show a `MediaMiniPlayer` widget. Rooms without a media player entity, or where the entity is `off` or `unavailable`, SHALL NOT render this section.

#### Scenario: TV now-playing displayed in Living Room
- **WHEN** `media_player.lg_webos_tv_qned82asa_3` is `playing`
- **THEN** the Living Room detail screen SHALL render the media section with the TV's current track/channel metadata

#### Scenario: Media section hidden when player is off
- **WHEN** `media_player.bedroom_speaker_2` is `off`
- **THEN** the Bedroom detail screen SHALL NOT render the media section

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
