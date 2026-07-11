## Context

The room screen is built from per-device widgets that each invented their own anatomy and interaction model (see `proposal.md` for the full gap list). The most important architectural facts of the current code:

- All controls render on a frosted `GlassCard` (`lib/shared/widgets/glass_card.dart`) that already supports a coloured `glowColor` (on-state) and a `dimmed` flag (unavailable). This is the one piece of shared language that works and should be the foundation.
- State flows through Riverpod: `entityStateProvider(id)` for live entity state, `haServiceProvider` for service calls. In-flight calls are visualised by `PendingOverlay` (`pending_overlay.dart`). This is the project's state-management answer and does not change.
- Per-role logic is **duplicated**: `room_sections.dart#sectionStatusLine` computes a one-line status per concept section, while each widget independently recomputes `isOn`, the toggle action, and the icon. There is no single place that knows "what does on/off mean for a fan vs. a climate vs. an air-purifier device."
- The AC ring (`ac_thermostat_widget.dart`) and the fan dial (`fan_speed_dial.dart`) draw the **same 270° arc** with two near-identical `CustomPainter`s.
- Chips are themed ad-hoc per widget (`ChoiceChip` for HVAC/purifier modes, `FilterChip` for adaptive lighting) because there is no `chipTheme` and no shared selector widget.

Constraint: this is a presentation/interaction-coherence change. HA service-call contracts, the data layer, and entity/room models stay fixed. Target platforms remain Android + Windows; layouts must hold at both the compact (<840 dp) and wide (≥840 dp) breakpoints already defined in `app_theme.dart`.

## Goals / Non-Goals

**Goals:**
- One **control-card anatomy** every device control is built from: leading icon, name, live status line, a power affordance, and an optional detailed body.
- One **layered device-state model** — availability, on/off, sensors, control surface, and a standard control set per category — rendered identically for every device (dim+disabled / glow / muted / reading pills / pending overlay).
- One **set of primitives**: a power toggle, a mode selector (mutually-exclusive), an option chip (independent binary), a slider, an arc gauge (ring/dial), and a reading pill — each themed once.
- A **domain-agnostic quick-toggle** so a light, fan, AC, and air purifier all power on/off through the same affordance and the same code path, plus a room-level **quick-controls strip** that shows every device's state at a glance and toggles it in one tap.
- A single **per-device descriptor** that is the only place encoding "icon / name / isOn / status / how to toggle" per `DeviceRole`, consumed by both the quick strip and the section status lines.
- Refit AC, fan, air purifier, and lights onto the above with **no change to their HA service calls or debounce behaviour**.

**Non-Goals:**
- No new device domains, no new HA services, no data-layer or model changes.
- No user-configurable theming/customisation; tokens stay compile-time constants.
- No redesign of non-room surfaces (home overview, security, maintenance) beyond what falls out of shared-widget changes; their use of the shared widgets continues to work.
- No change to the room navigation model (room detail is still pushed, not a tab) or the concept-section grouping itself — only how controls inside it look and how power is surfaced.

## Decisions

### 1. Device state is a five-layer model
Every device control is described by the same five layers, in priority order, and the design language renders each layer the same way regardless of device category:

1. **Availability** — reachable or not (HA `unavailable` / `unknown`). The outermost gate: an unavailable device dims its card (40% opacity), disables every control, and shows "—" for readings rather than stale values. A device can be available but off.
2. **On/Off (power)** — the power state, meaningful only when available. Drives the on→glow / off→muted treatment and the `PowerToggle`.
3. **Sensors** — read-only telemetry the device publishes (e.g. AC current temperature, purifier PM2.5 + filter life). Rendered as `ReadingPill`s, shown whenever the device is available — including when it is off (a purifier still reports PM2.5). Sensors are never interactive.
4. **Control surface** — the writable affordances (the card body). Individual controls may be enabled/disabled by the layers above (e.g. AC setpoint buttons disabled when off, while the mode selector stays active so the user can turn it back on).
5. **Standard controls per category** — each device category exposes a fixed, canonical control set so every AC looks like every other AC, every fan like every other fan, etc. Optional controls render only when the entity advertises support.

**Pending** (a service call in flight) is an orthogonal, transient state shown by the existing `PendingOverlay` over whatever the layers render — not a sixth layer.

The `DeviceControlDescriptor` (Decision 3) exposes layers 1–3 uniformly; `ControlCard` (Decision 2) renders layers 1–4; the per-category bodies implement layer 5.

**Standard control set per category:**

| Category | Sensors (read) | Standard controls (write) |
|---|---|---|
| Air conditioning (`climate`) | current temperature; current humidity if reported | power; setpoint ±0.5 °C (arc + buttons); HVAC mode selector; fan mode / swing if exposed |
| Fan (`fan`) | — | power; speed % (arc dial); oscillation toggle if exposed; preset mode if exposed |
| Air purifier | PM2.5; filter life | power; mode selector (Auto / Sleep / Favorite); favourite level if exposed |
| Lights (`light`) | — | power (group + per-light); brightness slider; colour-temperature slider if CCT-capable; colour control if RGB-capable; adaptive-lighting option chip when present |

- *Why:* separating availability from on/off (the current code half-conflates them) and promoting sensors to a first-class layer makes "device state" mean the same thing for every category. The per-category table is the contract the specs and the refit widgets are checked against.
- *Alternative considered:* a flat enum (`on / off / unavailable / pending`). Rejected — it cannot express "available, off, but still reporting PM2.5," which is exactly the air-purifier case the current UI gets wrong.

### 2. `ControlCard` — the single card anatomy
Add `lib/shared/widgets/control_card.dart`: a widget composing the existing `GlassCard` with a fixed header layout — `leading` icon, `title`, an optional live `status` line, and a `trailing` slot (the power toggle by default) — over an optional `body` (the detailed controls). It renders layers 1–4 of the state model: availability→dim+disable, on→glow / off→muted, the sensor `ReadingPill`s, and the control-surface body. Individual widgets stop hand-rolling glow/dim. AC, fan, purifier, and light controls all become "a `ControlCard` with a category-specific body (layer 5)."

- *Why:* the air-purifier widget and light tiles already have a header; the AC and fan have none. A shared header is the cheapest way to make them read as one family and removes per-widget glow/dim wiring.
- *Alternative considered:* a `ThemeExtension`-only approach (style primitives, leave layouts alone). Rejected — it would harmonise colours but not the structural inconsistency (missing headers, no power affordance), which is the bigger problem.

### 3. `DeviceControlDescriptor` — one source of truth per role
Add a value object resolved by a single `switch (device.role)`, e.g. `DeviceControlDescriptor describe(WidgetRef ref, RoomDevice device)` carrying state layers 1–3: `{ icon, name, isAvailable, isOn, List<ReadingSpec> sensors, statusLine, VoidCallback? togglePower }`. It watches the relevant `entityStateProvider`(s) and centralises the per-role facts currently scattered across widgets and `sectionStatusLine`.

- *Why:* makes the quick-toggle genuinely domain-agnostic — the strip iterates devices and renders descriptors without knowing about climate vs. fan. It also collapses the duplicated status logic into one place.
- *Power semantics per role (the crux of "quick toggle" for non-binary devices):*
  - **light / fan** → `toggle` (turn_on / turn_off); fan on with no remembered percentage uses HA default.
  - **air purifier** → toggle the `power` switch entity; mode/readings untouched.
  - **climate** → off = `set_hvac_mode: off`; on = `set_hvac_mode: cool` (the canonical power-on mode; the detailed card's mode selector lets the user pick another mode afterwards).
- *Alternative considered:* a polymorphic `DeviceController` class hierarchy. Rejected as heavier than needed for four roles; a descriptor + switch is idiomatic Dart and easy to read.

### 4. Power affordance: one component, two placements
Add `PowerToggle` — a single styled on/off control (pill/switch) used in the `ControlCard` trailing slot for detailed cards. The room **quick-controls strip** renders compact `QuickControlTile`s where the *whole tile* is the toggle (tap = power, glow = on) and a trailing chevron/long-press opens the detailed control. Both paths call the descriptor's `togglePower`.

- *Why:* unifies today's split between tap-the-card (lights) and Material `Switch` (purifier) into one rule — *tiles toggle by tap, detailed cards toggle via the header `PowerToggle`* — while keeping detailed cards self-sufficient (you can power on/off without leaving them).
- *Relationship to existing section nav:* concept sections (Climate & Air / Lights / Media) stay as the **detailed** grouping; the quick-controls strip is the new **at-a-glance + one-tap** layer. Section status lines now read from the same descriptor.
- *Placement:* on **wide** layouts the quick controls **augment the sidebar** — they render as a per-device quick-controls block within the existing sidebar (alongside, not replacing, the bookmark nav and its status lines), so each device gets a one-tap toggle without losing section navigation. On **compact** layouts they render as a horizontal strip above the section content.

### 5. Chips: theme once, two semantic widgets
Set a `ChipThemeData` in `app_theme.dart` so all chips share styling. Add `ModeSelector` (wraps `ChoiceChip`s for mutually-exclusive choices — HVAC mode, purifier mode) and `OptionChip` (independent binary — adaptive lighting, fan oscillation).

- *Why:* removes the `ChoiceChip`/`FilterChip` semantic mismatch and the per-widget chip styling.
- *Alternative considered:* Material `SegmentedButton` for modes. Rejected — chips already wrap/reflow gracefully in narrow cards and match the current look; `SegmentedButton` doesn't wrap well at compact widths.

### 6. Shared `ArcGauge` for ring + dial
Extract one arc painter (270° sweep, shared stroke width, caps, gradient) behind an `ArcGauge` widget. The AC ring and fan dial become `ArcGauge` with different centre content and value mapping.

- *Why:* the two painters are already the same geometry; one widget guarantees they stay visually identical and halves the painter code.

### 7. `ReadingPill` + a generic severity model
Generalise `EnvReading` into a `ReadingPill` (icon + value, optional severity colour). Severity is a **generic, reading-agnostic** model, not tied to environment sensors or to the room device categories: a `ReadingSpec` carries an optional `severity` mapping (a threshold→level function) that resolves any numeric reading to one of three levels. The three-step scale lives in `AppTokens` as `severityNominal / severityWarning / severityCritical`, and any reading anywhere in the app can opt in:
- PM2.5 — keeps its WHO thresholds (good / elevated / high).
- Battery level — low / critical.
- Temperatures — critical-high / critical-low (e.g. an appliance or machine overheating).
- Filter life, machine-health / diagnostic indicators, etc.

Direction (rising-bad vs. falling-bad, e.g. PM2.5 vs. battery) is part of the per-reading `severity` mapping, so the same three tokens render both. A reading with no `severity` mapping is shown in the neutral `offMuted` colour.

- *Why:* today only PM2.5 is colour-coded and the colours are inline literals. A generic three-level model with shared tokens makes "nominal / warning / critical" one coherent signal usable for environment, power, and machine-health readings alike — including outside the room screen (e.g. the maintenance panel).

### 8. New tokens
Extend `AppTokens` with the severity triple (`severityNominal / severityWarning / severityCritical`) and any chip/toggle accents not already derivable from the `ColorScheme`. Existing `onAccent` / `offMuted` remain the on/off foreground pair.

## Risks / Trade-offs

- **AC quick-toggle target mode** → Resolved: power-on always sets `hvac_mode: cool`; the detailed card's `ModeSelector` lets the user switch afterwards. Edge case: an entity whose `hvac_modes` omits `cool` — fall back to the first non-`off` mode and document it in the spec.
- **Visual redundancy** between the quick-controls strip and the per-card header toggles → The strip is the at-a-glance/one-tap entry point; detailed cards keep an inline toggle so they're self-sufficient. This is intentional, not duplication, but it must be validated for density on compact layouts (mitigate by making the strip compact and collapsible if needed).
- **Regression surface across other screens** — the shared widgets (`GlassCard`, `LightTile`, sliders) are also used by home/security/maintenance → Keep the existing widget public APIs source-compatible; refactor internals and add new widgets rather than rename. Verify those screens still build and render.
- **Descriptor watches inside a list** could over-rebuild the strip → Each `QuickControlTile` is its own `ConsumerWidget` watching only its entity, so a single device update doesn't rebuild the whole strip.
- **Touch vs. pointer** (Android touch, Windows mouse) for tap-to-toggle tiles → Reuse the existing `InkWell`/`GestureDetector` patterns already shipping on both platforms; no new gesture model.

## Migration Plan

Incremental, each step leaves the app compiling and runnable:
1. **Tokens + theme**: add severity tokens and `ChipThemeData`.
2. **Primitives**: add `ControlCard`, `PowerToggle`, `ModeSelector`, `OptionChip`, `ArcGauge`, `ReadingPill`, and the `DeviceControlDescriptor`. Nothing consumes them yet.
3. **Refit detailed widgets** one at a time onto the primitives: lights → fan → AC → air purifier. After each, the room screen still works.
4. **Quick-controls strip**: build `QuickControlTile` + the room strip on the descriptor; wire into `room_detail_screen.dart` (sidebar on wide, row on compact). Repoint `sectionStatusLine` at the descriptor.
5. **Cleanup**: remove the now-dead per-widget glow/dim/status code and the duplicated arc painters.

Rollback: revert the PR — no persisted state, schema, or service-contract changes, so revert is clean.

## Open Questions

All initial open questions are resolved and folded into the Decisions above:
- **AC power-on mode** → fixed to `cool` (fallback to first non-`off` mode if the entity lacks `cool`). See Decision 3 / Risks.
- **Wide-layout quick-controls placement** → augment the sidebar with a per-device quick-controls block (does not replace bookmark status lines). See Decision 4.
- **Severity scale scope** → a generic three-level model (`nominal / warning / critical`) usable for any numeric reading — PM2.5, battery, critical temperatures, machine-health indicators — not limited to environment sensors. See Decision 7.
