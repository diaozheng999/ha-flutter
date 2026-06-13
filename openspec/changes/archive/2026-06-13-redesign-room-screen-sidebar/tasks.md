# Tasks: Redesign Room Screen with Sidebar Layout

## 1. Registry discovery & subscription extension

- [x] 1.1 Add WebSocket commands `config/entity_registry/list` and `config/device_registry/list` to `HaWebSocketService` with typed result models (entity id, device id, area id, device class)
- [x] 1.2 Create `roomAlertEntitiesProvider`: resolve each registry entity's area (`entity.area_id ?? device.area_id`), match to room ids, and select alert sensors by device class (`moisture`/`gas`/`smoke`/`carbon_monoxide`/`safety`, `battery`, `problem`)
- [x] 1.3 Extend the subscription layer: after discovery, issue an additional `subscribe_entities` for discovered + rule-referenced entity ids; re-apply the extension on reconnect; include the extension in the `subscribe_events` fallback filter

## 2. Alert model & rules

- [x] 2.1 Create `RoomAlert` model and severity enum (safety > activity > offline > maintenance > battery) under `lib/features/room/`
- [x] 2.2 Add declarative `alertRules` to `RoomConfig` (trigger entity, state match condition, severity, label) and author initial rules: washer status finished → "Laundry done" (activity); purifier filter-life < 10% → "Replace filter" (maintenance); placeholders documented for doorbell/dishwasher pending entity ids
- [x] 2.3 Create `roomAlertsProvider(roomId)` combining discovered sensors (safety `on`, battery < 20%, problem `on`), config rules, and offline detection (`unavailable` room entities), ordered by severity
- [x] 2.4 Implement activity alert lifetime: stateful rules clear with state; momentary triggers (doorbell) persist 10 minutes after the triggering change

## 3. History & trend graph

- [x] 3.1 Add `fetchHistory` to `HaRestClient` (`GET /api/history/period/<start>?filter_entity_id=…&minimal_response`) returning typed time series
- [x] 3.2 Create a per-room history provider for the room's environment entities (temperature, humidity, PM2.5) with a 5-minute cache
- [x] 3.3 Build the `CustomPainter` trend graph widget: 24 h non-interactive line chart, multi-series, renders nothing on fetch failure

## 4. Shared control widgets

- [x] 4.1 Extract shared glow + debounce helpers from `LightToggleWidget`/`BrightnessSlider` where needed for reuse (no behavior change to existing widgets)
- [x] 4.2 Add shared max-width layout constant (480 dp sliders) and apply via `ConstrainedBox` wrappers in the new section layouts
- [x] 4.3 Implement `LightTile` in `lib/shared/widgets/light_tile.dart`: compact glass tile with name, toggle, inline debounced brightness slider, on-glow, unavailable treatment

## 5. Room sections

- [x] 5.1 Implement `RoomSection` enum (`climate`, `lights`, `media`) + availability logic (climate when fan/climate present; lights when any light; media when player active) in a small helper alongside the screen
- [x] 5.2 Build Climate & Air section widget: `AcThermostatWidget` + `FanSpeedDial` side by side (Wrap) on wide, stacked on compact, handling fan-only/AC-only rooms; trend graph below, loading progressively
- [x] 5.3 Restructure `room_lights_section.dart` into the Lights & Ambiance section: group toggle + constrained sliders + adaptive-lighting chip toggle (`switch.turn_on/off`), individual lights as always-visible `LightTile` grid on wide, expander-collapsed list on compact
- [x] 5.4 Build Media section widget wrapping `MediaMiniPlayer` with the existing activity predicate

## 6. Sidebar & responsive shell

- [x] 6.1 Build the room sidebar widget: room icon/name, stacked `EnvReading`s, alert strip slot, section nav items with live status lines (lights-on count, AC temp/mode or fan %, media state)
- [x] 6.2 Build the alert strip/banner widget rendering `RoomAlert`s with icon + device/event name + condition, rendering nothing when the list is empty
- [x] 6.3 Build the compact header row + horizontal section chip selector (same live status text) for narrow layouts
- [x] 6.4 Rewrite `room_detail_screen.dart`: hoist section-selection state above a `LayoutBuilder` with the 840 dp breakpoint; wide → sidebar + content pane; compact → header + banner + chips + content; preserve ambient tint overlay, app bar back + `ConnectionChip`, default-section and single-section rules

## 7. Verification & docs

- [x] 7.1 Add widget/unit tests: section availability per room config, default/single-section behavior, alert provider severity ordering and all-clear emptiness, registry area→room matching and device-class selection, activity alert lifetime, `LightTile` brightness-to-0 calls `light.turn_off`
- [x] 7.2 Run the app at desktop width and ~400 dp width; verify Living Room (all sections + trend graph), Pantry (lights only, no nav), an `unavailable` entity producing an offline alert, and discovered battery sensors appearing without config
- [x] 7.3 `flutter analyze` and `flutter build windows` pass
