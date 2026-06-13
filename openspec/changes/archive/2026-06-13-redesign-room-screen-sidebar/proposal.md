# Redesign Room Screen with Sidebar Layout

## Why

The room detail screen is a single vertical `ListView` that stacks full-width sliders, an oversized fan dial, and a thermostat ring one after another. On Windows (the primary wide-screen target) most of the canvas is empty, controls stretch absurdly wide, and reaching the climate or media section requires scrolling past everything above it. The screen is inefficient (one device visible at a time, no glanceable summary) and visually flat.

## What Changes

- Replace the vertical-stack room layout with a **sidebar-based layout**:
  - A persistent **room sidebar** showing room identity (icon, name), live environment summary (temperature, humidity, air quality, illuminance), critical status alerts, and navigation between control sections.
  - A **main content pane** that renders the selected section with controls laid out in an adaptive grid instead of a single column.
- Organize device controls into **concept sections** (per the app's concept-driven rendering principle, not raw HA domains):
  - **Climate & Air** — thermostat, fan, air-quality readings, and a 24 h environment trend graph (temperature, plus humidity/PM2.5 where available) in one coordinated section.
  - **Lights & Ambiance** — group toggle + brightness/colour temperature, individual lights as a tile grid (no more hidden "show individual lights" expander on wide screens), adaptive-lighting state.
  - **Media** — media player controls when the room has an active player.
- Add **critical status indicators**: a sidebar alert strip with five severity tiers — safety (leak/gas/smoke), activity notices (doorbell rang, laundry/dishwasher done), offline devices, maintenance (filter lifespan, appliance service intervals), and low battery. Safety, battery, and problem sensors are **autodiscovered** from HA's entity/device registries by area; semantic alerts (activity, service intervals) come from declarative config rules. Quiet when everything is healthy.
- Make the layout **responsive**: full sidebar on wide windows (Windows, tablets, landscape), collapsing to a compact header + horizontal section selector on narrow phone screens (Android portrait). Existing back-navigation and ambient light tinting behavior is preserved.
- Promote **fine-grained controls** (per-light brightness/colour, fan percentage, AC mode details) into their owning sections instead of burying them — wide layouts show them inline, narrow layouts reveal them per device.

No breaking changes to data layer, entity mapping, or navigation entry points.

## Capabilities

### New Capabilities
- `room-status-alerts`: Detection and display of room alert conditions in five severity tiers — safety (leak/gas/smoke), activity notices (doorbell, laundry/dishwasher done), offline devices, maintenance (filter lifespan, service intervals), low battery — sourced from area-based registry autodiscovery plus declarative config rules, with an all-clear (hidden) state when healthy.

### Modified Capabilities
- `room-view`: Layout requirement changes — replaces the single-column section stack with a responsive sidebar layout (sidebar + content pane on wide screens, compact selector on narrow screens); moves environment readings from a header card into the sidebar summary; restructures sections into Climate & Air (including a 24 h environment trend graph), Lights & Ambiance, and Media; individual lights become a visible tile grid on wide layouts instead of a collapsed expander.
- `device-controls`: Adds compact/inline control variants required by the new layout — a light tile with inline brightness, a compact fan control, and constrained-width slider behavior so controls stop stretching to full window width.
- `ha-realtime`: The entity subscription requirement changes — the compile-time allowlist remains the base, but registry-discovered alert entities are appended to the subscription at runtime (and re-applied on reconnect).

## Impact

- **Code**: `lib/features/room/room_detail_screen.dart` (rewritten), `lib/features/room/widgets/room_lights_section.dart` (restructured), new widgets under `lib/features/room/widgets/` (sidebar, section pages, alert strip, trend graph); `lib/shared/widgets/` gains compact control variants; `lib/config/ha_entities.dart` gains per-room declarative alert rules; `lib/ha/` gains entity/device registry fetch, runtime subscription extension, and a REST history fetch for the trend graph.
- **Specs**: `room-view`, `device-controls`, and `ha-realtime` delta specs; new `room-status-alerts` spec.
- **Dependencies**: none new — graph is custom-painted; uses existing Riverpod entity providers, `GlassCard`, theme tokens, `HaRestClient`.
- **Platforms**: behavior identical on Android and Windows; layout adapts by width, not platform.
