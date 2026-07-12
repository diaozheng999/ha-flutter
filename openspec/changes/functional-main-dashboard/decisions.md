# Decisions

> **This is a living document.** Append a new entry the moment a decision or
> important consideration arises — at ANY phase (planning, explore, design,
> implementation). Do not batch. Do not edit past entries; supersede them with
> a new dated entry. The next agent reads this file FIRST.

## Context

- **Change:** Make the home dashboard functional by turning room cards into compact primary control surfaces (grouped quick toggles), with header-navigates-into-room as the secondary action, and prune the now-redundant `ActiveDevicesBar`.
- **Started:** 2026-07-12
- **Related:**
  - `unified-control-scheme` change (commit `c091426`, complete except for task 7.5 manual verification) — built `ControlCard`, `PowerToggle`, `QuickControlTile`, `DeviceControlDescriptor`, `ReadingPill`, `ModeSelector` in `lib/shared/widgets/`. Consumed only by the room detail screen; deliberately left the home dashboard's *structure* untouched while harmonizing its *surfaces* (dock glass, scene glow token, config selector). This change extends those primitives onto the home screen — the natural follow-on the prior change explicitly declined.
  - `archive/2026-06-07-dashboard/` — original dashboard build; created `home-overview`, `room-view`, `device-controls`, `environment-display` specs.
  - Existing main specs touched: `home-overview` (room grid + active-device bar requirements). New spec: `room-quick-controls`.
- **Key constraint discovered:** The home dashboard is already a real, fully-wired Riverpod screen over a working HA REST+WebSocket layer — this is not a build-from-scratch change. The gap is control affordance and card density, not data plumbing.
- **Architecture note:** State management is Riverpod (`flutter_riverpod ^2.6.1`) for the HA/dashboard layer; `provider ^6.1.2` exists only for the legacy auth layer (`HaAuthService`). `entityStateProvider` (StreamProvider.family) is the read surface every widget uses — the redesigned card reuses it, no new provider needed for live state.

## Decision Log

### D1 - Problem framing: control-without-navigating (2026-07-12)
- **Decision:** The change targets the "too read-only / too many taps" pain — the dashboard shows state well but forces a tap-into-room to control anything. Making the dashboard *functional* means device control surfaces on the home screen itself.
- **Why:** The user's stated frustration was the room card being a waste of space given how little it lets you touch. Of four candidate framings (read-only, not-personalized, not-actionable, other), control-without-navigating is the highest-value gap and the one the unified-control-scheme primitives were built to cheaply address. It compounds the prior investment.
- **Alternatives considered:**
  - *Personalized/configurable layout* (rearrange, hide/show cards) — pulled in a selection+storage sub-feature; deferred.
  - *Actionable / "what needs me" surfacing* (alerts, things left on) — a different change; the room-status-alerts capability already exists for the alert subsystem.
- **Status:** Decided
- **Handoff note:** Scope is control affordance + card density. Do not let design/implementation drift into layout configurability or alert surfacing — those are separate changes.

### D2 - Controls live on the card, not behind a gesture (2026-07-12)
- **Decision:** Featured-device controls are rendered *on* the compact room card itself, as the primary surface. They are not summoned via long-press sheet, popover, or inline expansion.
- **Why:** The user's correction during grilling — "the room card on the dashboard should surface the most important parts of the room (and controls)" — established that the card IS the control surface. A summoned sheet/popover (the Q3 options) would add a navigation level and a discoverable gesture for no gain.
- **Alternatives considered:**
  - *Long-press → bottom sheet of controls* — adds a second control path and an invisible gesture; rejected after the user reframed "dive deeper" (D7).
  - *Inline grid expansion* — grid layout jank; rejected.
  - *Popover mini-panel* — too small for anything but toggles; rejected.
- **Status:** Decided
- **Handoff note:** The card renders controls inline. Any future "richer control without leaving the dashboard" desire should come back as a new change, not a late addition here.

### D3 - Per-room featured devices: config override + heuristic defaults (2026-07-12)
- **Decision:** Each room declares which devices its card surfaces via a per-room featured-device list in `lib/config/room_overrides.dart`. When no override is set, a heuristic picks the top N devices by priority (lights → climate → fan → media) from the room's discovered devices.
- **Why:** A pure heuristic (option A) gets individual rooms wrong — the bedroom may care about the fan more than the AC, which a fixed rule can't express. A runtime user-configurable system (option C) is a whole favorites/persistence sub-feature, out of scope for a single-household app. The override channel already exists and is version-controlled, so per-room tuning rides on existing config with zero new persistence surface.
- **Alternatives considered:**
  - *Pure heuristic, no override* — smallest, but produces generic cards that don't match real usage; would be back here wanting overrides in a month.
  - *Runtime user-configurable with device persistence* — over-engineering; new storage + editor UI + migrations. Deferred indefinitely.
- **Status:** Decided
- **Handoff note:** Design must specify: the override field shape, the heuristic's exact priority order and N (cap on toggles per card for density), and how the override merges with discovered `RoomDevice`s (by entity_id). The heuristic must degrade gracefully when a room has only one device.

### D4 - Resting card is toggles-only; no inline sliders/dials (2026-07-12)
- **Decision:** The compact room card shows only on/off `PowerToggle`s for its featured devices. No brightness sliders, fan-speed dials, or AC thermostats on the home card. Richer controls live on the room detail screen.
- **Why:** Direct tension between "smaller card" and "richer controls." Toggles-only is the only option that reliably delivers a smaller card *and* dashboard control without grid layout instability. Sliders/dials on a compact grid card fight the grid or break it. The unified-control-scheme already established the room detail screen as the home for sliders/dials.
- **Alternatives considered:**
  - *Toggles + one always-visible "hero" control per room* — mixed card sizes, unpredictable grid layout.
  - *Card resizes by content; masonry grid* — most honest to "no wasted space" but a responsive masonry grid on Android+Windows is meaningful layout work and visual jitter.
- **Status:** Decided
- **Handoff note:** If a future change wants inline dimming on the home card, it must revisit D4 and accept the layout cost. The `ControlCard`/`QuickControlTile` primitives support richer bodies, so the door is open — just not in this change.

### D5 - "Dive deeper" = into the room (existing RoomDetailScreen) (2026-07-12)
- **Decision:** The escalation path from the compact card is the existing `RoomDetailScreen`. There is exactly one dive-deeper destination — the full room — not a per-device focused sheet or a staged three-level dive.
- **Why:** The room detail screen already does per-device control well (sliders/dials/sections via unified-control-scheme). A per-device sheet (option B) duplicates that surface for no clear payoff. A staged dive (option C: glance → featured-device quick layer → full room) is the most seductive and the most scope, and the user did not identify "adjust featured devices without seeing the whole room" as a daily friction.
- **Alternatives considered:**
  - *Dive deeper into a specific device (new per-device sheet)* — new surface overlapping the room screen; rejected.
  - *Staged dive (featured-device quick layer + full room)* — three levels of navigation; rejected as scope.
- **Status:** Decided
- **Handoff note:** Do not build a new control surface for this change. The dive-deeper target is `RoomDetailScreen`, which already exists and is wired.

### D6 - Toggles are primary; header navigates (secondary) (2026-07-12)
- **Decision:** The card's primary interactive surface is the grouped quick toggles. The room-identity header (icon + name) is the tap target that pushes `RoomDetailScreen`. Tapping a toggle controls a device directly; tapping the header dives into the room. The two are separate hit areas.
- **Why:** The user explicitly inverted the default assumption: "navigating into the room [is] the secondary action. The primary action shall be interacting with quick toggles; grouped together in the room card." This makes the toggles the visual and interactive center, with a clear but smaller header affordance for navigation. Matches the mental model: the room identity *is* the door; the toggles *are* the controls.
- **Alternatives considered:**
  - *Tap card = navigate; toggles are separate hit targets (tap primary = nav)* — rejected; user explicitly designated toggles as primary.
  - *Tap card = toggle primary device; long-press = navigate* — overloads a room affordance with a device action and leans on an invisible gesture for navigation; rejected.
  - *Long-press = quick rich-control sheet (staged dive lite)* — reintroduces the per-device sheet declined in D5; rejected.
  - *Explicit chevron button for navigation* — adds chrome to the compact card; header affordance is cleaner.
- **Status:** Decided
- **Handoff note:** Design must specify the hit-area separation between header (navigate) and toggle group (control) so they never collide, especially on small Android cards. The header should be visibly the "door" without a heavy chevron.

### D7 - No long-press gesture in this change (2026-07-12)
- **Decision:** Long-press is not introduced. The user said "long press is an option" but the real need was "a way to dive deeper," which D5 resolved as tap-the-header → room. Long-press stays uncommitted / reserved.
- **Why:** Once navigation has a visible, learnable affordance (the header), long-press has no job. Spending it on a redundant control sheet (D5/D6 rejected that) or an edit/manage menu (out of scope) would add an invisible gesture with no payoff. Reserving it keeps the option open for a future edit/configure change.
- **Alternatives considered:**
  - *Long-press = navigate into room* — invisible secondary action; rejected in favor of visible header.
  - *Long-press = contextual "manage" menu (reorder/configure/hide rooms)* — different feature; deferred.
- **Status:** Decided
- **Handoff note:** If a future change adds room reordering or per-room configuration editing, long-press is the natural gesture to claim — note this when scoping that change.

### D8 - Scope: room grid + prune ActiveDevicesBar; defer other overlap judgment (2026-07-12)
- **Decision:** This change redesigns `RoomCard` and the per-room featured-device config/defaults, and removes `ActiveDevicesBar` from both dashboard layouts. Judgment on whether `EnvironmentSummary` or `AppliancesRow` also overlap is deferred to the design phase.
- **Why:** `ActiveDevicesBar`'s aggregate on-state ("3 lights on", "Cleaning") is the one clear overlap with live per-device toggles on the new cards — its job is exactly what the redesigned cards now do, per-room. `AppliancesRow` shows standalone appliances (vacuum/washer/water heater) not in the room grid, so it is clearly *not* an overlap and stays. `EnvironmentSummary` is a genuine judgment call that's easier to make once the new card is concrete — locking it now risks keeping a redundant row or ripping out something useful.
- **Alternatives considered:**
  - *Room grid only, no pruning* — leaves the redundant aggregate bar; rejected (user chose B in Q10).
  - *Room grid + prune ActiveDevicesBar + EnvironmentSummary now* — over-commits on a fuzzy call before the card is designed; rejected.
  - *Full dashboard re-layout* — turns into a general redesign; rejected as a different change.
- **Status:** Decided
- **Handoff note:** Design must revisit `EnvironmentSummary` (LR AC temp duplicates the LR room card's AC reading once cards show climate state) and `AppliancesRow` (likely stays, but confirm) and record the call as a new decision entry. The proposal intentionally leaves these open; do not treat their removal as committed.

### D9 - Capability split: new `room-quick-controls`, modified `home-overview` (2026-07-12)
- **Decision:** Introduce a new `room-quick-controls` capability (per-room featured-device selection + the compact quick-toggle room-card surface) and modify the existing `home-overview` capability (room grid requirement changes; active-device summary bar requirement removed).
- **Why:** The featured-device selection + compact toggle card is a coherent, reusable behavior worth its own spec — it could later apply to other glance surfaces. The `home-overview` spec already owns the room grid and active-device bar requirements, so those changes are deltas to it. Splitting keeps each spec single-purpose and makes the room-card control behavior testable in isolation.
- **Alternatives considered:**
  - *Fold everything into `home-overview` deltas* — overloads home-overview with control-surface behavior that isn't strictly "overview"; rejected.
  - *Modify `device-controls` instead of a new capability* — `device-controls` owns reusable control widgets, not the per-room selection/card-surface behavior; wrong home.
- **Status:** Proposed
- **Handoff note:** The specs artifact will create `specs/room-quick-controls/spec.md` and a delta on `specs/home-overview/spec.md`. Confirm capability naming is kebab-case and the delta references the new capability where the room grid requirement calls for quick-toggle cards.
