# Design: Redesign Room Screen with Sidebar Layout

## Context

`RoomDetailScreen` (lib/features/room/room_detail_screen.dart) is a single `ListView`: header card → lights section → fan dial → thermostat → media. Controls stretch to full window width, so on Windows the brightness slider is ~1800 px wide and the fan dial floats alone in empty space. There is no glanceable summary and no surfacing of device problems.

The app renders by **concepts** (climate, ambiance, media), not raw HA entity domains — the new layout must follow that principle. Entity wiring is static via `HaEntities`/`RoomConfig`, state flows through Riverpod `entityStateProvider`, and visuals use `GlassCard` + theme tokens + the ambient-tint `BackgroundEngine` overlay. All of that stays.

## Goals / Non-Goals

**Goals:**
- Wide-screen-efficient room layout: persistent sidebar + content pane on Windows/tablets.
- Same conceptual model on phones: compact header + section selector, no separate phone codepath for section content.
- Concept sections: **Climate & Air**, **Lights & Ambiance**, **Media**.
- Critical status surfaced passively: safety/battery/problem sensors autodiscovered from HA's registries by area, activity notices (doorbell, laundry, dishwasher) and maintenance conditions (filter life, service intervals) via declarative config rules, offline detection from existing state.
- Climate section shows a 24 h environment trend graph, not just instantaneous readings.
- Controls have sane max widths everywhere.

**Non-Goals:**
- No changes to navigation entry points (still pushed from room grid), auth, data layer, or WebSocket protocol.
- No user-configurable room/entity mapping (control entities stay hardcoded in `HaEntities`; autodiscovery applies to alert sensors only).
- No history streaming or interactive graph tooling — the trend graph is a read-only 24 h snapshot refreshed on section open.
- No notification/toast system — alerts are in-screen indicators only.

## Decisions

### 1. Responsive shell: sidebar ≥ 840 dp, compact below

`LayoutBuilder` at screen root. Width ≥ 840 dp (Material 3 "expanded") → `Row`: fixed ~300 dp sidebar + content pane. Below → compact header strip + horizontal section chip selector + content. One breakpoint only; no third "medium" tier — Android portrait is compact, Windows is effectively always expanded.

*Alternative considered*: `NavigationRail` (icons only). Rejected — the sidebar must carry environment readings and alerts, not just nav icons; a custom `GlassCard` column matches the app's visual language.

### 2. Sidebar is a dashboard, not just navigation

Sidebar contents top-to-bottom:
1. Room identity (icon + name) — replaces the old header card.
2. Environment summary: the existing `EnvReading` rows (temperature, humidity, illuminance, PM2.5) vertically stacked.
3. Alert strip (see decision 5) — only when alerts exist.
4. Section nav items, each with live secondary state: "Lights · 3 on", "Climate · 24.5° cool", "Media · Playing". This makes the sidebar glanceable even without switching sections.

On compact, items 1–2 collapse into a slim header row and item 4 becomes scrollable chips with the same live state text; the alert strip becomes a full-width banner under the header.

### 3. Sections are concept pages, one visible at a time

`enum RoomSection { climate, lights, media }`. A section is *available* only if the room has matching entities (`climate`/`fan` → climate; `allLights` non-empty → lights; active `mediaPlayer` → media). Selected section is ephemeral local state (`ConsumerStatefulWidget`), defaulting to the first available section; no Riverpod provider — selection shouldn't survive navigation.

If only one section is available (Pantry, Entrance), nav items/chips are hidden and the lone section renders directly.

*Alternative considered*: all sections in a 2-column masonry grid, sidebar only navigates/scrolls. Rejected — it reintroduces the "everything competes for space" problem and behaves badly at intermediate widths; section pages keep each concept's fine-grained controls roomy.

### 4. Section composition (concepts, not domains)

- **Climate & Air**: `AcThermostatWidget` and `FanSpeedDial` side by side on wide (Wrap), stacked on compact; below them a **24 h environment trend graph** plotting the room's temperature (plus humidity/PM2.5 where the room has those sensors). History is fetched on section open via REST `GET /api/history/period/<start>?filter_entity_id=…&minimal_response` (existing `HaRestClient`), cached per room for 5 minutes, and rendered with a lightweight `CustomPainter` line chart — *alternative considered*: `fl_chart`; rejected to avoid a new dependency for a non-interactive trend line. Fine-grained AC mode chips stay inside `AcThermostatWidget`.
- **Lights & Ambiance**: group controls (`LightToggleWidget` + brightness + CCT sliders) at top; individual lights as a responsive **tile grid** (new `LightTile`, see 6) — always visible on wide, behind the existing expander on compact; adaptive-lighting switch (`RoomConfig.adaptiveLightingSwitch`, already in allowlist) surfaced as a chip toggle.
- **Media**: existing `MediaMiniPlayer`. The media nav item is hidden when the player is inactive (same activity predicate as today).

### 5. Alerts: autodiscovered standard sensors + config rules for semantic events

New `roomAlertsProvider(roomId)` (Riverpod) computing `List<RoomAlert>` ordered by severity:
1. **Safety** — discovered moisture/gas/smoke/CO/safety binary sensors in state `on`.
2. **Activity** — time-sensitive notices from configured rules: doorbell rang, laundry done, dishwasher done. Stateful sources (e.g. washer status sensor reporting a finished state) show while the state holds; momentary triggers (doorbell ring) show for 10 minutes after the triggering state change.
3. **Offline** — any room entity (lights, fan, climate, media player) `unavailable`.
4. **Maintenance** — consumable/service conditions: filter-life sensors below 10%, discovered `problem`-class binary sensors `on`, and configured service-interval sensors.
5. **Battery** — discovered battery sensors below 20%.

Two sourcing mechanisms:

- **Autodiscovery (primary, for standard device classes).** On connect, fetch the entity and device registries via WebSocket (`config/entity_registry/list`, `config/device_registry/list`), resolve each entity's area (`entity.area_id ?? device.area_id`), and match to rooms — room ids already equal HA area ids (the area-icons provider relies on this). Select entities by device class: `moisture`/`gas`/`smoke`/`carbon_monoxide`/`safety` → safety; `battery` → battery; `problem` → maintenance. A new `roomAlertEntitiesProvider` exposes the per-room discovered ids. *Implementation note:* the registry `list` command does not return device classes, so they are read from a one-shot REST `/api/states` snapshot (sensor + binary_sensor domains) taken during discovery; the registries supply only the area resolution.
- **Config rules (for semantics autodiscovery can't infer).** `RoomConfig` gains an `alertRules` list of declarative rules (`entity`, match condition, severity, label) for activity and maintenance alerts whose meaning is installation-specific — "washer status == finished → Laundry done", "doorbell ring → Doorbell", "purifier filter life < 10% → Replace filter". Ships with rules for the existing washer status sensor; doorbell/dishwasher rules added as their entities are identified.

Discovered and rule-referenced entity ids are appended to the WebSocket subscription at runtime (see decision 6). Offline detection needs no config and works day one. No polling — alerts are pure derivation from subscribed entity states.

*Alternative considered*: hardcoded per-room `batterySensors`/`leakSensors` lists only. Rejected — new sensors would silently never alert until someone edits config; registry-driven discovery keeps coverage complete by default, with config rules as the escape hatch for semantics.

### 6. Dynamic subscription extension

The WebSocket allowlist stays the tight compile-time base set, but after registry discovery the app issues an additional `subscribe_entities` call for discovered alert entities (re-issued on reconnect). This modifies the `ha-realtime` capability's "compile-time constant allowlist" requirement: the base list remains static; alert entities are a bounded, registry-derived runtime extension (device-class-filtered, typically a handful per room — not a fall back to subscribing everything).

### 7. New compact widgets in `device-controls`, additive only

- `LightTile`: compact glass tile = toggle + name + inline brightness slider + on-glow, sized for a grid (~160–220 dp). Reuses `Debouncer`/glow logic from `LightToggleWidget` and `BrightnessSlider`.
- `ControlWidth` constraint: shared `maxWidth` (~480 dp) applied to sliders via `ConstrainedBox` so no control ever spans the full pane.
- Existing widgets (`FanSpeedDial`, `AcThermostatWidget`, sliders) are reused unchanged apart from being placed inside constrained containers.

All spec changes to `device-controls` are ADDED requirements; no existing widget behavior changes.

### 8. Preserved behaviors

Ambient light tinting (600 ms middle-stop overlay), back navigation, `ConnectionChip` in the app bar, 200 ms debounced service calls — all unchanged. The app bar remains on compact; on wide the room name lives in the sidebar and the app bar slims down to back + connection chip.

## Risks / Trade-offs

- [Section paging adds a tap to reach a second concept on phones] → Live state text on chips keeps other sections glanceable; rooms with one section skip navigation entirely.
- [840 dp breakpoint may thrash when the Windows window is resized across it] → Selection state and providers live above the `LayoutBuilder`, so a relayout is pure visual restructure; no state loss.
- [Registry autodiscovery depends on entities/devices being assigned to areas in HA] → Unassigned sensors simply don't alert; offline detection and config rules cover the gap, and area assignment is a HA-side fix, not an app change.
- [Dynamic subscription extension weakens the "tight allowlist" guarantee] → Extension is device-class-filtered and bounded (a handful of sensors per room); the base allowlist stays compile-time and the extension list is logged for inspection.
- [History fetch adds REST latency to the Climate section] → Graph renders progressively (controls first, graph when data arrives) and the 5-minute cache makes section re-entry free.
- [LightTile duplicates glow/debounce logic] → Extract shared helpers rather than copy; covered in tasks.
- [Kitchen has 9 individual lights — tile grid could dominate the pane] → Grid is capped with scrolling within the section page, group controls stay pinned above it.

## Open Questions

- Doorbell-ring and dishwasher-done entity ids need to be identified in the HA instance to author their activity rules; the washer status sensor (`sensor.mibx5_…_status_p_2_2`) is already known. Rules are one-liners once ids are confirmed — not blocking.
