# Decision Log: Unified Control Scheme

## Context

- The room screen currently uses inconsistent control layouts and interactions
  for AC, fans, air purifiers, and lights.
- This change remains presentation-only: Home Assistant service-call contracts,
  data-layer code, and entity/room models are unchanged.
- This log was added when the change migrated to the `spec-driven-decisions`
  workflow on 2026-07-11. It records the decisions already present in
  `proposal.md` and `design.md`; future decisions are appended below.

### D1 - Establish a shared control language (2026-06-13)

- **Decision:** Standardise control cards, power affordances, selectors, sliders, dials, and status treatment across room devices.
- **Why:** The existing controls read as disconnected mini-apps and use inconsistent interaction patterns.
- **Alternatives considered:** Token-only styling was rejected because it would not resolve the incompatible card anatomy and power affordances.
- **Status:** Decided
- **Handoff note:** The shared primitives must preserve existing HA service-call behavior.

### D2 - Model device state in five layers (2026-06-13)

- **Decision:** Render availability, power, sensors, control surface, and category controls as distinct layers; pending remains an overlay.
- **Why:** Availability and on/off have different meanings, particularly when a powered-off purifier continues reporting PM2.5.
- **Alternatives considered:** A flat on/off/unavailable/pending enum was rejected because it cannot represent available, off devices with live sensors.
- **Status:** Decided
- **Handoff note:** Unavailable devices dim and disable controls; sensor readings use a placeholder instead of stale values.

### D3 - Use ControlCard as the common shell (2026-06-13)

- **Decision:** Add a `ControlCard` over the existing `GlassCard` with a fixed header and optional detailed body.
- **Why:** AC and fan lack headers while purifier and lights each use bespoke ones; a common shell provides structural consistency.
- **Alternatives considered:** A `ThemeExtension`-only approach was rejected because it harmonises colours without reconciling layout.
- **Status:** Decided
- **Handoff note:** Category-specific bodies implement the final control layer while the shell owns availability, glow, and header treatment.

### D4 - Centralise device descriptors (2026-06-13)

- **Decision:** Resolve one `DeviceControlDescriptor` per `DeviceRole` for icon, name, availability, power state, sensors, status, and toggle action.
- **Why:** Quick controls and section summaries otherwise duplicate role-specific logic.
- **Alternatives considered:** A polymorphic controller hierarchy was rejected as unnecessary for four current roles.
- **Status:** Decided
- **Handoff note:** The descriptor is the single source of truth for both the quick-controls strip and section status lines.

### D5 - Use one power component in two contexts (2026-06-13)

- **Decision:** Use `PowerToggle` in detailed card headers and whole-tile `QuickControlTile` toggles in the room-level strip.
- **Why:** This gives all domains the same power semantics while retaining quick at-a-glance access.
- **Alternatives considered:** Retaining card taps for lights and Material switches for purifiers was rejected as inconsistent.
- **Status:** Decided
- **Handoff note:** Climate powers on with `cool`, falling back to the first non-off HVAC mode when needed.

### D6 - Separate mutually exclusive and binary chip semantics (2026-06-13)

- **Decision:** Theme chips once and provide `ModeSelector` for exclusive choices and `OptionChip` for independent binary options.
- **Why:** Existing ChoiceChip and FilterChip usage is inconsistent despite different meanings.
- **Alternatives considered:** `SegmentedButton` was rejected because it does not wrap well in compact cards.
- **Status:** Decided
- **Handoff note:** HVAC and purifier use mode selectors; adaptive lighting and fan oscillation use option chips.

### D7 - Share the AC and fan arc implementation (2026-06-13)

- **Decision:** Extract a shared 270-degree `ArcGauge` for thermostat rings and speed dials.
- **Why:** The existing custom painters duplicate the same geometry and visual language.
- **Alternatives considered:** Keeping separate painters was rejected because they would inevitably drift.
- **Status:** Decided
- **Handoff note:** Centre content and value mapping stay category-specific.

### D8 - Generalise reading severity (2026-06-13)

- **Decision:** Replace PM2.5-specific display logic with `ReadingPill`, a generic severity mapping, and shared nominal/warning/critical tokens.
- **Why:** The same visual vocabulary should work for environmental, battery, temperature, and diagnostic readings.
- **Alternatives considered:** Retaining inline PM2.5 thresholds and colours was rejected because it cannot be reused coherently.
- **Status:** Decided
- **Handoff note:** Each reading supplies its own rising-bad or falling-bad severity mapping; readings without one stay neutral.

### D9 - Migrate this change to the decision-log schema (2026-07-11)

- **Decision:** Adopt `spec-driven-decisions` for this still-planning change and seed its decision log from existing artifacts.
- **Why:** The change has proposal and design but no specs or tasks, so migration preserves work while making future planning and implementation auditable.
- **Alternatives considered:** Leaving the change on the legacy schema was rejected at the user's request; recreating artifacts was rejected because it would discard valid planning work.
- **Status:** Implemented
- **Handoff note:** Continue with specs, then tasks. Append new decisions immediately rather than editing these historical entries.
