## 1. Project Foundation

- [x] 1.1 Add dependencies to `pubspec.yaml`: `web_socket_channel`, `cached_network_image`, `flutter_riverpod`, `device_info_plus`, `shared_preferences` (used manual Riverpod providers, so `riverpod_annotation`/`riverpod_generator` were intentionally omitted)
- [x] 1.2 Add dev dependencies (N/A — code-gen variant not used; no `build_runner`/`riverpod_lint`/`custom_lint` needed with manual providers)
- [x] 1.3 Create `lib/` directory layout: `ha/`, `features/home/`, `features/room/`, `features/security/`, `features/scenes/`, `features/maintenance/`, `shared/widgets/`, `shared/theme/`
- [x] 1.4 Wire app router (Navigator 2.0 via `IndexedStack` tabs + `MaterialPageRoute` for `RoomDetailScreen`)
- [x] 1.5 Create `AppShell` widget with 5-tab `NavigationBar` (Home, Rooms, Security, Scenes, Maintenance)

## 2. Theme & Design System

- [x] 2.1 Create `AppTheme` in `shared/theme/app_theme.dart`: dark `ThemeData` with no `fontFamily`, monospace token for sensor readings, `colorSchemeSeed`, corner radius 20 px
- [x] 2.2 Create `GlassCard` widget: `BackdropFilter` blur (sigmaX/Y 20), `Color(0x18FFFFFF)` fill, `Color(0x30FFFFFF)` 1 px border, optional `glowColor` `BoxShadow` (blur 24 px, opacity 0.45)
- [x] 2.3 Create `HsColorConverter` utility: convert HS pair to Flutter `Color` (saturation clamped 0.6, lightness 0.45)
- [x] 2.4 Define `PerformanceTier` enum (low / medium / high) and `PerformanceTierProbe` service that runs a frame-timing benchmark on first launch and persists result to `SharedPreferences`

## 3. Background Engine

- [x] 3.1 Define `BackgroundEngine` abstract widget interface and `AppBackground` factory that instantiates the correct tier from persisted `PerformanceTier`
- [x] 3.2 Implement `StaticGradientBackground` (low tier): plain `BoxDecoration` gradient derived from current time-of-day phase; zero animation
- [x] 3.3 Implement sun-elevation → gradient colour mapping: 8 anchor points covering astronomical night through post-sunset; lerp helper between adjacent anchors
- [x] 3.4 Implement `AnimatedSkyBackground` (medium tier): gradient transition (`SkyGradient` tween), star scatter `CustomPainter` with twinkling opacity at night
- [x] 3.5 Implement `WeatherAnimationBackground` (high tier) — rain: diagonal rain-streak particles at 60°, density scaled for `rainy` vs `pouring`; gradient tint (darken, shift to blue-grey)
- [x] 3.6 Implement high tier — haze/fog: yellow-grey tint overlay (`#C8A96E` at 35%) + horizontal parallax mist bands; no cloud or star particles
- [x] 3.7 Implement high tier — cloud / partly cloudy: translucent cloud wisp shapes drifting laterally; `partlycloudy` half coverage, `cloudy` full
- [x] 3.8 Implement high tier — lightning: rain particle layer + random full-screen luminance flash (30–80 ms, max once per 8 s)
- [x] 3.9 Implement high tier — clear night: slow-drifting star field with twinkling opacity; active only when sun elevation < −6°
- [x] 3.10 Wire `WeatherAnimationBackground` to mux sun elevation gradient with weather condition colour filter; add `debugForceCondition` override
- [x] 3.11 Pause `WeatherAnimationBackground` particle animations when app is backgrounded (`AppLifecycleListener`)

## 4. HA Real-time Layer

- [x] 4.1 Create `EntityState` model: `entityId`, `state`, `attributes`, `lastUpdated`; `fromJson` factory
- [x] 4.2 Implement `HaWebSocketService`: connect, handle `auth_required` → auth → `auth_ok`/`auth_invalid`; logout on `auth_invalid`
- [x] 4.3 Implement entity allowlist constant (`HaEntities.allowlist`, derived from rooms + standalone entities)
- [x] 4.4 Implement `subscribe_entities` call with allowlist; parse compressed `a`/`c` diffs into `EntityState` updates
- [x] 4.5 Implement fallback: on `subscribe_entities` error, subscribe to `state_changed` and apply client-side allowlist filter
- [x] 4.6 Implement `EntityStateRepository`: in-memory cache, per-entity broadcast `StreamController`, replay-on-subscribe `stream(entityId)`
- [x] 4.7 Create `entityStateProvider(String entityId)` Riverpod `StreamProvider` family backed by the repository
- [x] 4.8 Create `connectionStatusProvider` from the service status stream (connecting / connected / reconnecting / disconnected)
- [x] 4.9 Implement `callService()`: auto-increment id, `call_service` message, await `result_ok`/`result_error`, throw on error
- [x] 4.10 Implement exponential-backoff reconnection (1 s → … → 60 s cap) with subscription re-establishment
- [x] 4.11 Implement REST bootstrap: `GET /api/states`, filter to allowlist, populate cache before first WS diff (`dashboardInitProvider`)
- [x] 4.12 Implement pending service-call tracking: per-entity `entityPendingProvider`; 5 s timeout in `callService`

## 5. Shared Device Control Widgets

- [x] 5.1 Implement `LightToggleWidget`: glass card, on-state glow from `hs_color`, unavailable → dimmed + non-interactive
- [x] 5.2 Implement `BrightnessSlider`: 0–100% (maps 0–255); drag to 0 → `light.turn_off`; debounce 200 ms
- [x] 5.3 Implement `ColorTemperatureSlider`: warm→cool gradient track; renders only when `color_temp` supported; debounce 200 ms
- [x] 5.4 Implement `FanSpeedDial`: circular arc `CustomPainter`; centre label; drag to 0 → `fan.turn_off`; debounce 200 ms
- [x] 5.5 Implement `AcThermostatWidget`: temperature ring, +/- 0.5 °C steps, HVAC mode chips from `hvac_modes`, off dims ring + disables steps
- [x] 5.6 Implement `MediaMiniPlayer`: album art via HA proxy (`cached_network_image`), title/artist with `—` fallback, play/pause/prev/next

## 6. Home Overview Screen

- [x] 6.1 Implement `HomeOverviewScreen` (background supplied by `AppShell`)
- [x] 6.2 Implement greeting header: clock (monospace, 1-minute timer), date, weather summary, greeting
- [x] 6.3 Implement presence strip: chips for Simon/Ya Min; home green filled, not_home grey outlined, unknown amber outlined
- [x] 6.4 Implement environment summary row: LR temperature + humidity, Bedroom PM2.5; hides chip when sensor unavailable
- [x] 6.5 Implement active-device summary bar: counts for lights/fans/ACs/Shiny; "All quiet" when idle; tap switches tab
- [x] 6.6 Implement scene quick-launch row: tiles from all `scene.*`; tap `scene.turn_on`; checkmark confirmation
- [x] 6.7 Implement room grid: responsive grid of `RoomCard`; icon, name, light indicator, temperature; tap pushes `RoomDetailScreen`
- [x] 6.8 Implement `RoomCard` glow from average `hs_color` of on lights
- [x] 6.9 Implement now-playing widget: shows when any player is playing; cycles across active players; animates in/out
- [x] 6.10 Implement "Reconnecting…" chip driven by `connectionStatusProvider`

## 7. Room Detail Screen

- [x] 7.1 Implement `RoomDetailScreen` push route; back returns to caller
- [x] 7.2 Implement room header with per-room environment readings
- [x] 7.3 Implement room ambient tinting: average `hs_color` → animated middle-gradient overlay (600 ms)
- [x] 7.4 Implement lights section: group toggle, brightness, colour temperature (conditional), individual-lights expansion
- [x] 7.5 Implement fan section (`FanSpeedDial`) for Living Room, Bedroom, Study
- [x] 7.6 Implement AC section (`AcThermostatWidget`) for Living Room, Bedroom, Study
- [x] 7.7 Implement media section (`MediaMiniPlayer`) when room player is active
- [x] 7.8 Define and wire hardcoded entity-to-room mapping (`HaEntities.rooms`)

## 8. Environment Display

- [x] 8.1 Wire temperature to room AC `current_temperature`; "—" when unavailable
- [x] 8.2 Wire humidity to ShellyWallDisplay in Living Room header only
- [x] 8.3 Wire illuminance to ShellyWallDisplay in Living Room header only
- [x] 8.4 Wire PM2.5 in Bedroom header with WHO-threshold colour coding (<12 green, 12–35 amber, >35 red)

## 9. Security Screen

- [x] 9.1 Implement `SecurityScreen` (third tab)
- [x] 9.2 Implement alarm status chip: colour-coded, pulsing for `triggered`
- [x] 9.3 Implement camera view (authenticated still-image refresh; ~1 s active, 2 s when tab inactive — pauses on inactive per spec, MJPEG decoder dependency avoided)
- [x] 9.4 Implement doorbell feed (`camera.doorbell_2`)
- [x] 9.5 Implement Living Room feed (`camera.living_room`)
- [x] 9.6 Implement PTZ control cluster: directional buttons (`button.press`) + pan/tilt degree sliders (`number.set_value`)
- [x] 9.7 Implement Frigate thumbnail row: proxy stills, 30 s auto-refresh, tap → modal full image
- [x] 10.1 Implement appliances row (Shiny, washer, water heater)
- [x] 10.2 Implement `ShinyCard`: state label, spinning icon when cleaning, Start/Return, error in red
- [x] 10.3 Implement `WashingMachineCard`: status + remaining time (hidden when 0); display-only
- [x] 10.4 Implement `WaterHeaterCard`: temperature + state; "—"/"Unknown" when unknown

## 11. Scenes & Config Screen

- [x] 11.1 Implement `ScenesConfigScreen` (fourth tab)
- [x] 11.2 Implement scene tile grid (dynamic from discovered `scene.*`); tap `scene.turn_on` + checkmark
- [x] 11.3 Implement configuration mode selector: segmented for ≤4, bottom-sheet for >4; `input_select.select_option`
- [x] 11.4 Implement adaptive lighting section: per-room toggle + "Pause 1h" (`adaptive_lighting.set_manual_control`); pause disabled when off

## 12. Maintenance Screen

- [x] 12.1 Implement `MaintenanceScreen` (fifth tab)
- [x] 12.2 Implement HA updates badge: count of `update.*` on; "Up to date" when zero; nav tab badge dot when > 0
- [x] 12.3 Implement power-cycling switch grid: tap → "Hold to toggle"; long-press toggles + confirmation snackbar
- [x] 12.4 Implement DB cabinet readings: temperature + fan speed with unit suffixes
- [x] 12.5 Implement DB cabinet 24-hour temperature graph (`CustomPainter` from REST history; refresh button)
- [x] 12.6 Implement vacuum map: `image.shiny_map_0` via proxy; refresh with cache-busting; state label

## 13. Polish & Integration

- [x] 13.1 Pending service-call infrastructure (`PendingOverlay`, 500 ms grace, 5 s timeout) wired to toggle controls; sliders use debounce + optimistic local state
- [x] 13.2 Responsive layout: room/scene/power grids reflow (2 cols phone, 3 cols wide/desktop); Windows debug build succeeds
- [x] 13.3 `flutter analyze` clean (0 issues); `flutter test` green (build_runner N/A — manual providers)
- [ ] 13.4 Smoke-test all 5 screens + room details against the live HA instance on Android — REQUIRES a real device + authenticated HA session (run `flutter run`)
- [ ] 13.5 Verify `BackgroundEngine` tier selection + high-tier particle frame budget (<3 ms) via Flutter DevTools — REQUIRES a running session with DevTools attached
