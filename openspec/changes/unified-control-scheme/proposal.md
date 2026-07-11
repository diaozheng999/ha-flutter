## Why

The room screen has grown a different control vocabulary for every device type, and they do not agree with each other. Lights toggle by tapping a glowing glass card; the air purifier uses a Material `Switch`; the AC and fan have no on/off affordance at all — you change a mode or drag a value instead. The AC and fan cards have no header, while the purifier and light tiles each invented their own. Mode selection is a `ChoiceChip` in two places and a `FilterChip` in another. There is no quick on/off layer, so even "turn the fan off" requires opening its detailed dial. The result reads as several mini-apps stitched together rather than one coherent product.

This change defines a single control scheme and design language — one card anatomy, one set of state semantics, one quick-toggle pattern, one environment-label vocabulary — and refits the existing room implementation to it, so every device (AC, fan, air purifier, lights) looks and behaves like a member of the same family.

## What Changes

- **Establish a shared control design language**: a single "control card" anatomy (icon + name + live status + on/off affordance in a consistent header, detailed controls in the body), unified device state semantics (on / off / unavailable / pending, expressed consistently via glow, dim, and the pending overlay), and shared interaction primitives — one toggle style, one chip style (mode selection vs. binary option), one slider style, one dial style — all reading from shared design tokens.
- **Introduce a unified quick-toggle control** usable by any on/off-capable device domain (light, fan, AC, air purifier), plus a room-level quick-controls row that surfaces every device's on/off + one-line status at a glance, before the user drills into detailed controls.
- **Define a coherent environment-label vocabulary**: a consistent reading/status pill with a shared severity colour scale (good / elevated / high), generalising the PM2.5-only colour coding to other readings and unifying how room state is summarised.
- **Refit the existing detailed controls to the new language** (concrete changes to the current room implementation):
  - **Air conditioning** — wrap the thermostat ring + step buttons + mode selector in the shared card header with a quick on/off; align mode chips to the shared chip style.
  - **Fan** — give the speed dial the shared header with a quick on/off and live status; align with the shared dial style.
  - **Air purifier** — replace the bespoke `Switch`/header/chip layout with the shared card shell, quick-toggle, and shared mode-chip + reading-pill styles.
  - **Lights** — align the group toggle, sliders, adaptive-lighting affordance, and individual tiles to the shared card anatomy and chip semantics.
- **Update the room detail screen** to present the quick-controls layer and the conformed detailed controls coherently (quick toggles available without drilling in; the air purifier promoted to a first-class conformed control rather than an ad-hoc climate tile).
- **Enforce app-wide surface and accent consistency**: the background engine already renders behind every tab; this change closes the remaining gaps — the floating navigation dock adopts the shared glass recipe (today it hand-rolls its own blur), feature widgets stop hard-coding accent colours (the scene-launch confirm green becomes a token), and mutually-exclusive selectors outside the room screen (dashboard config selector, compact section selector) adopt the shared selector treatment. Surface/token conformance only — no layout redesign of non-room screens.

No backend/HA service-call contracts change — every control still calls the same `light.*`, `fan.*`, `climate.*`, `select.*`, `switch.*` services with the same debounce behaviour. This is a presentation/interaction-coherence change.

## Capabilities

### New Capabilities
- `control-design-language`: the shared design system for all device controls — card anatomy (header/status/affordance/body), device state vocabulary (on/off/unavailable/pending and their visual treatment), the canonical toggle/chip/slider/dial/reading-pill primitives plus the tokens that drive them, **and** the quick-toggle pattern built on those primitives: a domain-agnostic quick on/off control and the room-level quick-controls row/grid that aggregates each device's toggle and live one-line status.

### Modified Capabilities
- `device-controls`: each detailed widget (AC thermostat, fan speed dial, air purifier, light toggle/tile, sliders) is restructured to conform to the shared card anatomy, state semantics, and primitive styles; the air purifier's bespoke `Switch`/chip layout is replaced with the shared shell.
- `environment-display`: environment readings adopt the shared reading-pill and severity colour scale; presentation is generalised beyond the current per-sensor special cases.
- `room-view`: the room detail screen surfaces the quick-controls layer and renders the conformed detailed controls, including the air purifier as a first-class control.

## Impact

- **Affected code (presentation layer only):**
  - Shared widgets: `lib/shared/widgets/` — `ac_thermostat_widget.dart`, `fan_speed_dial.dart`, `air_purifier_widget.dart`, `light_tile.dart`, `light_toggle_widget.dart`, `brightness_slider.dart`, `color_temperature_slider.dart`, `glass_card.dart`, `env_reading.dart`; new shared control-card / quick-toggle widgets.
  - Theme/tokens: `lib/shared/theme/app_theme.dart` (`AppTokens`) — likely new tokens for chip/toggle/status styling and the severity scale.
  - Room feature: `lib/features/room/room_detail_screen.dart`, `lib/features/room/room_sections.dart`, and `lib/features/room/widgets/` (climate/lights/media sections, sidebar).
  - App-wide surface conformance: `lib/features/app_shell.dart` (floating dock glass), `lib/features/home/widgets/scene_launch_row.dart` (confirm glow token), `lib/features/home/widgets/config_selector.dart` (selector treatment).
- **No changes to:** HA service-call contracts, the data layer (`lib/ha/`), entity/room config models, or auth.
- **Dependencies:** none added; built on the existing Flutter + Riverpod + Material 3 stack.
- **Specs:** 1 new spec file (`control-design-language`), 3 delta specs against existing capabilities.
