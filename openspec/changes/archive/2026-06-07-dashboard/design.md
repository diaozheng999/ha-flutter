## Context

The app currently implements HA OAuth (IndieAuth) and secure token storage but has no dashboard UI. The backend is a Home Assistant instance with 608 entities across 38 domains, 6 rooms, and a mix of Zigbee2MQTT, Hue, Shelly, Roborock, Mijia, and native HA integrations. HA exposes two APIs: a REST API for one-shot reads and a WebSocket API for real-time state subscriptions and service calls. State management and architecture are currently undefined — this design establishes both.

The target is a native Flutter app on Android and Windows, used as a mounted home controller and handheld remote. Controls must be large enough for arm's-length interaction, animations must feel immediate (< 100 ms perceived latency on control tap), and the app must degrade gracefully when the local HA instance is unreachable.

## Goals / Non-Goals

**Goals:**
- Real-time state for ~70 key entities with < 500 ms update latency on LAN
- Glanceable home screen: presence, active devices, weather, scenes
- Per-room full control: lights (group + individual), fan, AC, media
- Security screen: camera feeds, alarm, Frigate thumbnails
- Scenes + adaptive lighting management
- Maintenance screen: power-cycle switches, DB cabinet, HA updates, vacuum map
- Dark-primary visual design matching the ambient, low-light home environment

**Non-Goals:**
- HA configuration / admin (devices, integrations, automations YAML editing)
- Multi-home / multi-instance support
- Voice control (HA has its own assist pipeline)
- Push notifications for doorbell events (follow-on change)
- iOS / macOS builds (no Xcode toolchain; directories exist for future use)

## Decisions

### 1. State Management: Riverpod (code-gen variant)

**Chosen:** `riverpod` with `riverpod_generator` and `riverpod_annotation`.

**Rationale:** HA's data model is entity-centric — each entity has an ID and a state object that updates independently. Riverpod's provider families map directly onto this: `entityProvider(entityId)` gives a `StreamProvider<EntityState>` per entity. Providers compose cleanly (a room light group provider can watch multiple entity providers), and `AsyncValue` handles the loading/error/data states that come with a live WebSocket.

**Alternatives considered:**
- *BLoC*: Better for complex state machines (e.g., a multi-step flow), but heavy boilerplate for the simple "subscribe, display, call service" pattern used everywhere in this app.
- *GetX*: Minimal boilerplate but too implicit; hard to trace data flow when debugging connection issues.
- *Provider (package)*: Lacks the stream-first ergonomics needed for WebSocket feeds.

### 2. Architecture: Feature-first with a shared HA layer

```
lib/
  ha/                          # HA client (no Flutter dependency)
    websocket/                 #   WebSocket connection + event loop
    models/                    #   EntityState, ServiceCall, etc.
    repository/                #   EntityStateRepository
  features/
    home/                      # HomeOverviewScreen + providers
    room/                      # RoomDetailScreen + per-room providers
    security/                  # SecurityScreen (cameras, alarm)
    scenes/                    # ScenesConfigScreen
    maintenance/               # MaintenanceScreen
  shared/
    widgets/                   # Device control widgets (reusable)
    theme/                     # Color tokens, text styles
```

**Rationale:** Feature-first keeps each screen's widget tree, providers, and models co-located. The `ha/` layer is a pure Dart package boundary — screens never import `web_socket_channel` directly, only repository interfaces. This means the HA layer can be mocked in widget tests without Flutter tooling.

**Alternatives considered:**
- *Layer-first (data/domain/presentation)*: Makes cross-cutting features (e.g., environment sensors used by both home screen and room view) awkward — shared domain types end up scattered across layers.
- *Clean Architecture with use cases*: Overkill; the domain logic here is thin (map entity state to widget state, call a service).

### 3. Real-time updates: Selective entity subscription via `subscribe_entities`

**Chosen:** On WebSocket connect, call HA's `subscribe_entities` with an explicit allowlist of ~70 entity IDs. Receive diffs via `entity_registry_updated` events.

**Rationale:** The instance has 608 entities. Subscribing to all `state_changed` events would deliver irrelevant updates (diagnostic sensors, backup managers, etc.) at high frequency. An explicit allowlist reduces noise and keeps the Riverpod state graph small and predictable.

**Entity allowlist categories:**
- Lights: 23 entities
- Fans: 4, Climates: 4, Media players: 5 (de-duplicated active instances)
- Persons: 2 (`person.simon`, `person.yamin`)
- Vacuum: 1, Appliance sensors: 3, Environment sensors: 4
- Weather: 1, Alarm: 1
- Scenes: 5 (state only — activation is a service call)
- Config/helpers: `input_select.configuration` + 4 adaptive lighting switches
- Power-cycle switches: 10
- DB cabinet sensors: 2 + fan: 1
- Updates: subscribe to a count sensor or use REST poll

**Fallback:** If `subscribe_entities` is unavailable (older HA), fall back to `subscribe_events` for `state_changed` with client-side filter.

**Alternatives considered:**
- *Subscribe to all `state_changed`*: Simpler client code, but wastes bandwidth and forces all 608 entities into the Riverpod graph.
- *REST polling*: No real-time feel; 1 s polling is too chatty for a control app.

### 4. Navigation: Bottom navigation bar, 5 tabs

```
Home | Rooms | Security | Scenes | Maintenance
```

- **Home**: `HomeOverviewScreen` — glanceable summary
- **Rooms**: Room list → `RoomDetailScreen` (push, not tab switch)
- **Security**: `SecurityScreen` — cameras + alarm
- **Scenes**: `ScenesConfigScreen` — scene tiles + adaptive lighting + config mode
- **Maintenance**: `MaintenanceScreen` — power cycling + DB cabinet + updates + vacuum map

**Rationale:** 5 tabs matches the 5 functional areas in the proposal. Bottom nav is thumb-reachable on a mounted phone. Room detail is a push route from the Rooms tab (not a separate tab) because rooms are secondary navigation, not peer-level views.

**Alternatives considered:**
- *Navigation drawer*: Hidden behind a hamburger; worse discoverability for a control app used in motion or low-light.
- *Single-page with sections*: The existing dashboard-home approach — scrolling past irrelevant sections to reach the one you want.

### 5. Visual design: Time-of-day gradient sky + glassmorphic cards + room ambient tinting

**Chosen:** A three-layer visual system:

**Layer 1 — Scaffold background: `BackgroundEngine` (isolated, performance-tiered)**

The background is driven by a `BackgroundEngine` abstraction — a single `Widget` that sits behind the entire scaffold and is the only owner of background rendering. No other layer draws to the background. This isolation means the engine can be swapped or disabled without touching screen code.

```dart
abstract class BackgroundEngine extends Widget {
  // Inputs: time-of-day phase, sun elevation, weather condition
}
```

Three implementations selected at app start based on a `PerformanceTier` enum resolved once from device benchmarks (`DeviceInfoPlugin` + frame timing probe on first launch, persisted to prefs):

| Tier | Implementation | Mechanism |
|---|---|---|
| `low` | `StaticGradientBackground` | Plain `BoxDecoration` gradient, no animation, zero CPU overhead |
| `medium` | `AnimatedSkyBackground` | `AnimationController` lerping gradient stops via `ColorTween`, 1-second tick. Night phase adds a `CustomPainter` star scatter with varying opacity |
| `high` | `WeatherAnimationBackground` | Shader-based or `CustomPainter` particle system driven by `weather.forecast_home` state |

**`AnimatedSkyBackground` (medium tier) — gradient phases:**

| Phase | Time | Top → Bottom |
|---|---|---|
| Dawn | 05:00–07:00 | `#1A0A2E` deep violet → `#FF6B35` burnt orange |
| Day | 08:00–17:00 | `#0A1628` deep navy → `#1E3A5F` slate blue |
| Sunset | 17:30–19:30 | `#1A0A1A` dark plum → `#FF4500` ember |
| Night | 20:00–04:30 | `#050510` near-black → `#0D0D2B` deep indigo |

Phase transitions lerp over ~30 minutes so the shift is imperceptible in real time.

**`WeatherAnimationBackground` (high tier) — sun × weather mux:**

Rather than particles layered on top of a fixed gradient, the high tier **muxes sun position and weather condition into a single computed sky state**. There is no separate "gradient phase" lookup table — the gradient is derived continuously from two inputs:

- `sun.sun` → `elevation` attribute (−90 to +90 degrees, updated by the existing subscription)
- `weather.forecast_home` → `state` condition string

**Sun elevation → base sky colors (Singapore equatorial sky):**

Sun elevation drives a continuous parametric gradient. Key anchor points (lerped smoothly between):

| Elevation | Sky character | Top stop | Bottom stop |
|---|---|---|---|
| < −6° (astronomical night) | Deep equatorial night | `#04040F` | `#0A0A20` |
| −6° → 0° (civil twilight) | Pre-dawn violet bloom | `#120828` | `#8B2FC9` fading to `#FF6B35` |
| 0° → 10° (golden hour rising) | Warm sunrise — Singapore horizon turns vivid orange-pink | `#1A0A2E` | `#FF7043` |
| 10° → 40° (morning) | Tropical blue deepening | `#0D2137` | `#2979C7` |
| 40° → 70° (midday) | Intense equatorial blue-white | `#083260` | `#1565C0` |
| 70° → 40° (afternoon, descending) | Slight warm shift | `#0A2A50` | `#1976D2` blending `#E65100` |
| 40° → 10° (golden hour setting) | Coral-amber — richer than morning in Singapore's humid air | `#1A0820` | `#FF5722` → `#FF8F00` |
| 10° → 0° (dusk) | Mauve into indigo | `#180830` | `#7B1FA2` |

**Weather condition → gradient tint + particles:**

The condition modifies the base sky via a `ColorFilter` tint on the gradient and optional `CustomPainter` particle overlays. Singapore-relevant conditions only:

| Condition | Gradient tint | Particles / overlay |
|---|---|---|
| `sunny` / `clear-night` | None (base sky unmodified) | Night: slow-drifting star field with twinkling opacity |
| `partlycloudy` | Slight cool desaturation (−10% saturation) | Soft translucent cloud wisps drifting at 2–4 px/s |
| `cloudy` | Desaturate −30%, darken −15% | Denser cloud layer; more coverage, slower drift |
| `rainy` | Shift hue toward blue-grey, darken −25% | Diagonal rain streaks at 60° — particle count scales with `pouring` variant |
| `pouring` | Dark grey-blue, heavy desaturation | Dense rain streaks + surface splash dots at bottom |
| `lightning-rainy` | As `pouring` | Rain + randomised full-screen luminance flash (30–80 ms, max once per 8 s) |
| `fog` / `haze` | **Key Singapore condition**: overlay a warm yellow-grey tint (`#C8A96E` at 35% opacity) on the gradient; flatten contrast | Horizontal mist bands at 3 depths with parallax scroll on device tilt or slow auto-drift; no stars, no clouds |
| `windy` | None | Cloud wisps (if `partlycloudy`) move at 3× speed |
| All others | Fade gracefully to base sky | No particles |

**Haze note:** HA's `fog` condition is the closest mapping to Singapore's PSI haze events (caused by regional fires). The yellow-grey tint is intentionally unpleasant — it accurately reflects what haze days look and feel like, and gives the app an immediate environmental signal without checking PSI manually.

Weather state is read from the existing `weather.forecast_home` Riverpod provider — no additional subscription needed. Particle count scales with screen area (target: < 3 ms frame budget for particles). The `BackgroundEngine` exposes a `debugForceCondition` override for testing all weather states without waiting for real conditions.

**Layer 2 — Cards: glassmorphism**

All control cards use `BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20))` over a `Container` with `Color(0x18FFFFFF)` fill and a `Border` of `Color(0x30FFFFFF)` at 1 px. This gives a frosted-glass appearance against the animated sky background. Card corner radius: 20 px (matching iOS Home app feel).

On/Off state distinction:
- **Off**: glass card as above — subtle, recessed
- **On**: glass card + a radial `BoxShadow` glow using the entity's current color (lights use `hs_color` → HSL → Flutter `Color`; fans/ACs use a fixed warm white `#FFF4E0`). Glow spread: 0, blur: 24 px, opacity: 0.45.

**Layer 3 — Room ambient tinting**

When inside a room detail screen, the scaffold gradient gains a third stop in the middle derived from the room's dominant active light color. If all lights are off, the middle stop is transparent (no tint). Color extraction: average the `hs_color` attributes of all on lights in the room, convert HSL(h, 0.6, 0.15) to an sRGB `Color`. This gives each room a distinct but subtle personality — the Living Room glows warm Hue white, the bedroom shifts toward cooler tones when the spotlight is on, etc.

**Typography:** Platform system font throughout — no `fontFamily` set on `ThemeData`, letting Flutter resolve Roboto on Android and Segoe UI on Windows. Sensor readings (temperature, fan %, time numerals) use `TextStyle(fontFamily: 'monospace')` which resolves to the platform monospace font (Roboto Mono / Cascadia Code). No `google_fonts` dependency.

**Alternatives considered:**
- *Material You dynamic color (monet)*: Adapts to wallpaper; unpredictable contrast in a low-light room. Rejected.
- *Fixed seed color (Material You)*: More consistent than monet but static — no visual response to the time of day or room state. Too flat for a premium home app.
- *Custom typeface (DM Sans / google_fonts)*: Adds a dependency and bundle size for a marginal aesthetic gain — system fonts already look great and feel native on each platform.
- *Light mode*: Inappropriate for a home control app typically used in low-light environments.
- *Full OLED black + neon accents*: Considered a pure dark mode aesthetic but found it cold and un-homely. The sky gradient makes the app feel like it belongs in the house.

### 6. Camera display: MJPEG via authenticated HA proxy URL

**Chosen:** Use HA's `/api/camera_proxy_stream/{entity_id}` MJPEG endpoint, authenticated with the stored Bearer token. Use `flutter_mjpeg` (or a custom periodic-refresh image widget for stills in compact views).

**Rationale:** No additional streaming server needed. HA already proxies the camera streams. Frigate thumbnails use `/api/camera_proxy/{entity_id}` (still image) with a manual refresh timer.

**Alternatives considered:**
- *WebRTC via Frigate*: Better latency, but requires a separate signalling setup and a WebRTC Flutter package. Worthwhile follow-on, not required for v1.
- *HLS via Frigate*: Good for playback of recordings, not needed for live view in v1.

### 7. Offline / reconnection strategy

On disconnect: surface a non-blocking status chip ("Reconnecting…") in the AppBar. Last-known entity state remains displayed with a subtle "stale" overlay. Exponential backoff reconnection (1 s → 2 s → 4 s → … → 60 s cap). Service calls during disconnect are queued and retried once on reconnect (max 1 retry; fail with snackbar error after that).

### 8. Maintenance screen access control

Power-cycle switches are physical relay toggles that cut power to lights and fans. Mis-tapping one in a room control context would be jarring. They are grouped under the Maintenance tab (not surfaced in room views) and each requires a long-press to activate — matching the hold-action pattern in the existing Lovelace dashboard.

## Risks / Trade-offs

- **MJPEG battery drain on mobile** → Pause stream when screen is off or tab is not active. Use still-image refresh (2 s interval) in compact camera widgets on the home screen.
- **`subscribe_entities` API version dependency** → The allowlist approach requires HA 2022.9+. The instance is on 2026.5.4, so this is fine now; add a version check on connect and fall back gracefully.
- **70-entity Riverpod graph cold-start** → Initial load fetches all entity states via REST before WebSocket is ready, so the UI renders with real data immediately rather than showing 70 loading spinners. Estimated REST call time on LAN < 200 ms.
- **Adaptive lighting "pause" is a one-way action** → The existing dashboard sends `adaptive_lighting.set_manual_control` without a timer. The app will show a visual countdown (using a local timer) but cannot cancel it if the user navigates away and back — this is a limitation of the HA integration itself, not the app.
- **Windows platform**: Camera MJPEG streams work on Windows via `HttpClient`. PTZ buttons work. No platform-specific issues expected.

## Open Questions

- **Scenes configuration**: The 5 HA scenes are static. Should the app support activating HA automations (e.g., "Turn everything off") as well, or only `scene.*` entities? The existing dashboards use both. → Resolve in `scenes-config` spec.
- **Room order**: The proposal lists rooms as Living Room, Kitchen, Bedroom, Study, Entrance, Pantry. Should this be configurable in-app or hardcoded? → Hardcode for v1; make data-driven in a follow-on.
- **Vacuum cleaning zones**: Roborock supports zone cleaning. Should the Shiny card offer zone selection or only start-full / return-to-dock? → Start-full + dock only for v1 (zone data requires a separate Roborock API call outside HA).
