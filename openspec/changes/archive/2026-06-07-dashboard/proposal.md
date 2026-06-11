## Why

The existing Home Assistant dashboards (dashboard-home and dashboard-v2) are browser-bound Lovelace UIs built on custom card libraries like Bubble Card — functional, but constrained to a grid layout with no native feel, no smooth animations, and limited information hierarchy. A native Flutter app can deliver an aesthetic, opinionated home control experience comparable to Apple HomeKit or Google Home: glanceable status at a distance, fluid gesture navigation, and controls sized for comfortable one-handed use on a phone mounted in any room.

## What Changes

- **New Flutter app feature**: a full home-control dashboard as the primary screen of the app
- Replaces the need to open HA in a browser for day-to-day control
- Real-time state via the existing HA WebSocket connection (no new backend work)
- Six rooms represented: Living Room, Kitchen, Bedroom, Study, Entrance, Pantry
- All key controllable devices surfaced: lights (23 entities across 6 groups), fans (Living Room, Bedroom, Study), ACs (Living Room, Bedroom, Study), TV + speakers (4 rooms), vacuum (Shiny/Roborock), washing machine, water heater, air purifier, security cameras + doorbell
- Scene quick-launch and per-room adaptive lighting controls accessible from the dashboard
- Maintenance panel: physical power-cycle switches, DB cabinet monitor, HA update alerts, vacuum map
- Presence awareness: Simon and Ya Min's home/away status visible at a glance
- Environmental readings: temperature per room (from ACs), humidity + illuminance (ShellyWallDisplay in living room), PM2.5 (bedroom air purifier)

## Capabilities

### New Capabilities

- `home-overview`: Main dashboard screen — greeting header with time, weather (`weather.forecast_home`), and presence chips for Simon and Ya Min; active-device summary bar (lights on, fans running, Shiny status); scene quick-launch row; swipeable room grid cards each showing live room state
- `room-view`: Per-room detail screen navigated from the room grid; sections for lights (group toggle + brightness + colour temperature + individual lights), fan speed dial, AC thermostat widget (mode + setpoint + current temp), and media now-playing card; covers all 6 rooms with per-room device inventory
- `device-controls`: Shared widget library — light toggle+brightness slider, fan circular speed dial, AC thermostat (temperature ring + HVAC mode chips), media mini-player (art + track info + play/pause/skip), vacuum status+action card, appliance status chip
- `environment-display`: Environmental reading panel — current temperature (AC `current_temperature` attributes per room), humidity and illuminance (ShellyWallDisplay, `sensor.*`), PM2.5 (bedroom air purifier `sensor.zhimi_sg_433492230_mb4_pm2_5_density_p_3_4`); surfaces these in room headers and a dedicated environment section on the home screen
- `security-view`: Security and cameras screen — live feed for doorbell (`camera.doorbell_2`) and living room camera (`camera.living_room`) with PTZ controls (pan/tilt buttons + degree sliders), alarm status (`alarm_control_panel.doorbell_security_system`), Frigate event thumbnails
- `appliances-view`: Appliance status section on the home overview — Shiny vacuum (docked/cleaning/returning, start/dock actions on `vacuum.roborock_qr_798`), washing machine status+remaining time (`sensor.mibx5_sg_2047340869_f35th_status_p_2_2`, `sensor.mibx5_sg_2047340869_f35th_left_time_p_2_10`), water heater temperature (`climate.l10wfe`)
- `ha-realtime`: WebSocket real-time state subscription and service-call layer — subscribes to `state_changed` events, maps entity state to Flutter state, exposes a call-service API used by all control widgets; builds on the existing HA OAuth token from the `ha-oauth-handshake` change
- `scenes-config`: Scene and configuration controls screen — one-tap scene activation for the 5 defined scenes (`scene.daylight`, `scene.all_off`, `scene.living_room_fan_spd_3`, etc.); configuration mode selector (`input_select.configuration`); per-room adaptive lighting management (toggle + "pause 1 hour" action for each room's adaptive lighting switch)
- `maintenance-panel`: Maintenance and system screen — physical power-cycle switch grid (entry, living room hanging lights ×3, living room spotlight, living room fan, walkway spotlight, bedroom light/fan, bedroom spotlight, study light/fan); DB cabinet monitor with temperature graph and fan speed (`sensor.w02_001af7_temperature`, `sensor.w02_001af7_fan_speed`, `fan.w02_001af7`); HA update badge showing count of pending updates (4 currently on); vacuum Shiny map image (`image.shiny_map_0`) and clean history

### Modified Capabilities

- `ha-oauth-handshake`: The stored long-lived access token must be accessible to the new WebSocket client layer. No requirement changes — the handshake spec is complete; this is an implementation dependency only, not a spec delta.

## Impact

- **New screens**: `HomeOverviewScreen`, `RoomDetailScreen`, `SecurityScreen`, `ScenesConfigScreen`, `MaintenanceScreen` — all wired into the app's router
- **New services/providers**: `HaWebSocketService`, `EntityStateRepository`, room-scoped state providers
- **Entity IDs locked in** (reference inventory):
  - Lights: `light.living_room_lights`, `light.kitchen_lights`, `light.kitchen_spotlights`, `light.bedroom_light`, `light.bedroom_spotlight`, `light.entry_lights`, `light.dining_table_lights`, `light.pantry_lights`, `light.study_light`, + 14 individual Zigbee/Hue lights
  - Fans: `fan.living_room_fan`, `fan.bedroom_fan`, `fan.study_fan`
  - ACs: `climate.living_room_ac`, `climate.bedroom_ac`, `climate.study_ac`
  - Media: `media_player.lg_webos_tv_qned82asa_3`, `media_player.bedroom_speaker_2`, `media_player.study_speaker_2`, `media_player.pantry_display_2`
  - Presence: `person.simon`, `person.yamin`
  - Vacuum: `vacuum.roborock_qr_798`
  - Washing machine: `sensor.mibx5_sg_2047340869_f35th_status_p_2_2`, `sensor.mibx5_sg_2047340869_f35th_left_time_p_2_10`
  - Environment: `sensor.shellywalldisplay_00a90b9db957_temperature`, `sensor.shellywalldisplay_00a90b9db957_humidity`, `sensor.shellywalldisplay_00a90b9db957_illuminance`, `sensor.zhimi_sg_433492230_mb4_pm2_5_density_p_3_4`
  - Cameras: `camera.living_room`, `camera.doorbell_2`
  - Weather: `weather.forecast_home`
  - Scenes: `scene.daylight`, `scene.all_off`, `scene.living_room_fan_spd_3` (+ 2 remaining)
  - Configuration: `input_select.configuration`
  - Adaptive lighting switches: `switch.living_room_kitchen_adaptive_lighting_main`, `switch.bedrooms_adaptive_lighting_bedrooms`, `switch.adaptive_lighting_kitchen_lights`, `switch.study_lights_adaptive_lighting_study_lights`
  - Power cycling: `switch.entry_switch_l1`, `switch.0xa4c1388aecbb45dd_l1`–`l4`, `switch.shellywalldisplay_00a90b9db957`, `switch.bedroom_switch_l1`, `switch.bedroom_switch_l2`, `switch.study_switch_l1`
  - DB cabinet: `sensor.w02_001af7_temperature`, `sensor.w02_001af7_fan_speed`, `fan.w02_001af7`
  - Updates: `update.*` domain (41 entities, 4 pending)
  - Vacuum map: `image.shiny_map_0`
- **Dependencies**: Flutter `web_socket_channel`, `cached_network_image` (for camera stills), existing `flutter_secure_storage` token from oauth handshake
- **No backend changes** to Home Assistant required
