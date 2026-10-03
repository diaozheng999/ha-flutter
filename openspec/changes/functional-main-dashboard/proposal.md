## Why

The home dashboard is read-mostly: to control a device the user must tap into a room, and the `RoomCard` is oversized for how little it lets them touch — a single quick light-toggle on a large surface. The recently completed `unified-control-scheme` change built reusable control primitives (`PowerToggle`, `QuickControlTile`, `DeviceControlDescriptor`) consumed only by the room detail screen; the home dashboard never adopted them. The cheapest, highest-value gap is control-without-navigating, delivered on a tighter card that reuses those primitives.

## What Changes

- **Compact `RoomCard` redesign.** Shrink the room card so its footprint matches its content. Make **grouped quick toggles the primary interactive surface**, reusing `PowerToggle` / `QuickControlTile` from the unified control scheme. The resting card is toggles-only — no inline sliders, dials, or thermostats on the home card. Richer controls remain on the room detail screen.
- **Header is the secondary navigate-into-room affordance.** The room-identity strip (icon + name) is the tap target that pushes `RoomDetailScreen`; the toggles are separate hit targets that control devices directly. Tapping a toggle controls a device; tapping the header dives into the room. No long-press gesture is introduced in this change.
- **Per-room featured devices, config-driven with sensible defaults.** Extend `lib/config/room_overrides.dart` with a per-room featured-device list that selects which 1–N devices each room's card surfaces. A heuristic (lights → climate → fan → media, top N that exist) fills in when no override is set, so unconfigured rooms still render useful defaults.
- **Remove the `ActiveDevicesBar` section.** Its aggregate on-state ("3 lights on", "2 fans", "Cleaning") is now redundant with the live per-device toggles visible across the room grid. The section is removed from both narrow and wide dashboard layouts.
- **Deferred overlap judgment.** Whether `EnvironmentSummary` or `AppliancesRow` also overlap the new cards is left to the design phase, once the compact card is concrete. Not committed here.

## Capabilities

### New Capabilities
- `room-quick-controls`: Per-room featured-device selection (config override + heuristic defaults) and the compact quick-toggle room-card surface that turns the home dashboard's room grid into a primary control surface.

### Modified Capabilities
- `home-overview`: The room grid requirement changes — room cards become compact grouped-toggle surfaces with a header navigate affordance, surfaced per the `room-quick-controls` capability. The active-device summary bar requirement is removed (redundant with live toggles on the room cards).

## Impact

- **Code:** `lib/features/home/widgets/room_grid.dart` and the `RoomCard` widget are rewritten to the compact toggle layout; `lib/features/home/home_overview_screen.dart` drops `ActiveDevicesBar` from both `_NarrowLayout` and `_WideLayout`; `lib/config/room_overrides.dart` gains a featured-device field and merge logic; room-discovery (`lib/ha/room_registry_provider.dart`) exposes featured-device selection to the card.
- **Reused primitives:** `PowerToggle`, `QuickControlTile`, `DeviceControlDescriptor`, `ControlCard` from `lib/shared/widgets/` (built by the `unified-control-scheme` change) — no new control widgets.
- **Specs:** New `specs/room-quick-controls/spec.md`; modified `specs/home-overview/spec.md` (room grid requirement + active-device bar removal).
- **No API/data-layer changes:** entity subscription, REST bootstrap, and `entityStateProvider` are unchanged — the card reads the same live state streams the room detail screen already uses.
- **Platforms:** Both Android and Windows layouts (narrow and wide) adopt the new card and drop the active-device bar.
