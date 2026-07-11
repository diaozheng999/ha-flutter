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

### D10 - Ration the radial glow to colour-bearing state (2026-07-11)

- **Decision:** The radial card glow renders only where colour carries information: lights glow in their `hs_color`, climate cards glow in a hue derived from the active HVAC mode (cool → cold, heat → warm); fan and air purifier cards signal "on" via the accent treatment (accent icon, lit arc, selected chips) with no radial glow. Quick-control tiles follow the same rule.
- **Why:** The glow is the app's visual signature; the design left glow colour undefined for non-lights, and defaulting every on-card to the same amber bloom would dilute the signature into noise. A design review before specs surfaced this.
- **Alternatives considered:** Glowing every on-device in `onAccent` amber was rejected as undifferentiated; tinting the purifier glow by air-quality severity was rejected because it conflates power state with sensor severity.
- **Status:** Decided
- **Handoff note:** `GlassCard`'s API is unchanged; `ControlCard` resolves a nullable glow colour from the descriptor.

### D11 - PowerToggle is a glass power button, not a Material Switch (2026-07-11)

- **Decision:** `PowerToggle` renders as a circular glass icon button with a power glyph — `offMuted` glyph on the glass fill when off, `onAccent` fill when on, hit target at least 48 dp.
- **Why:** A restyled Material `Switch` would reimport the stock-Material vocabulary the change removes (the purifier's `Switch` is one of the named inconsistencies); a power glyph is domain-neutral and compact enough for headers and tiles.
- **Alternatives considered:** A themed Material `Switch` was rejected as clashing with the glass language; an On/Off text pill was rejected as wider and localisation-sensitive.
- **Status:** Decided
- **Handoff note:** Headers and quick tiles both route through the descriptor's `togglePower`.

### D12 - Severity vocabulary is nominal/warning/critical with hues distinct from onAccent (2026-07-11)

- **Decision:** The severity scale is named `nominal / warning / critical` everywhere, superseding the proposal's good/elevated/high wording, and its hues must stay distinguishable from the amber `onAccent` (warning reads orange, nominal a desaturated green, critical red).
- **Why:** `onAccent` is amber (#FFD27D); an amber warning pill next to amber on-state icons would be unreadable, and two vocabularies would drift between artifacts.
- **Alternatives considered:** Keeping good/elevated/high for environment readings only was rejected because the scale is generic (battery, temperature, filter life).
- **Status:** Decided
- **Handoff note:** Exact hex values are an implementation choice; the distinguishability constraint is normative.

### D13 - One status-line grammar for all devices (2026-07-11)

- **Decision:** Descriptor status lines follow a single grammar: `Unavailable` when unavailable, `Off` when off, otherwise `<primary value> · <secondary>` (AC `24.5° · Cool`, fan `75%`, purifier `Auto · PM2.5 8`, lights `2 on` / `On`), with mode labels from one shared formatter.
- **Why:** Words are part of the control language; today each widget words its own state and the wording drifts.
- **Alternatives considered:** Leaving wording per-widget was rejected — that inconsistency is part of the bug this change fixes.
- **Status:** Decided
- **Handoff note:** `sectionStatusLine` and quick tiles must render the same string for the same device.

### D14 - Air purifier stays in Climate & Air as a first-class ControlCard (2026-07-11)

- **Decision:** The conformed air purifier control continues to render inside the Climate & Air section, as a `ControlCard` peer of the AC and fan.
- **Why:** It already renders there (`room_climate_section.dart`) and is an air device; "promotion" means conforming its shell, not relocating it.
- **Alternatives considered:** A separate air-quality section was rejected as navigation overhead for one device.
- **Status:** Decided
- **Handoff note:** Reflected in the `room-view` delta spec.

### D15 - Slider behaviour is unchanged; unification is styling-only (2026-07-11)

- **Decision:** The brightness and colour-temperature slider requirements get no spec delta; "one slider style" is delivered through shared theming.
- **Why:** Their service-call and debounce behaviour is already consistent; MODIFIED deltas restating unchanged behaviour add archive risk without information.
- **Alternatives considered:** Restating the slider requirements as MODIFIED was rejected as noise.
- **Status:** Decided
- **Handoff note:** If slider styling needs a token, extend `AppTokens` without a spec delta.

### D16 - Defer the RGB colour control (2026-07-11)

- **Decision:** The "colour control if RGB-capable" row in the design's standard-control table is deferred out of this change.
- **Why:** The proposal's scope is interaction coherence for existing controls; no colour picker exists today, so adding one is a new feature, not a refit.
- **Alternatives considered:** Speccing a colour picker now was rejected as scope creep that would delay the refit.
- **Status:** Decided
- **Handoff note:** Revisit as its own change; the `ControlCard` body accommodates it later.

### D17 - Extend scope to app-wide surface and accent consistency (2026-07-11)

- **Decision:** The design language applies to every surface, not only room controls: (1) one glass recipe — every blurred translucent surface, including the floating navigation dock, derives blur, fill, border, and radius from the shared glass tokens instead of hand-rolling them; (2) no inline accent colour literals — feature widgets resolve accents from `AppTokens`/`ColorScheme` (the scene-launch confirm green becomes a token); (3) mutually-exclusive selectors outside the room screen (dashboard config selector, compact section selector) adopt the shared selector treatment.
- **Why:** A user review asked for a cohesive app-wide feel. An audit found the background engine already global and `GlassCard` used on all five tabs, but the dock uses blur sigma 24 vs the cards' 20, the scene confirm glow is a hard-coded `0xFF66BB6A`, and the config selector hand-rolls its selected-pill styling — the same class of drift this change exists to remove.
- **Alternatives considered:** A separate follow-up change was rejected: the fixes ride on the tokens and primitives this change already introduces, and deferring them would ship a "unified" language with visible exceptions on the home screen and dock. A full redesign of non-room screens remains out of scope — this is surface/token conformance only, no layout changes.
- **Status:** Decided
- **Handoff note:** Proposal, design, and the `control-design-language` spec are updated; the room-view/device-controls deltas are unaffected.

### D18 - Task sequencing follows the migration plan, conformance before cleanup (2026-07-11)

- **Decision:** tasks.md follows the design's migration order (tokens → primitives → per-device refit lights/fan/AC/purifier → quick controls → environment displays), with the D17 app-wide conformance group inserted after the room work and before cleanup, and descriptor/severity tests placed with the primitives rather than at the end.
- **Why:** Every group leaves the app compiling and runnable; conformance work depends on tokens and selector primitives existing, and testing the descriptor early protects all downstream refit tasks.
- **Alternatives considered:** Doing dock/scene/selector conformance first was rejected because the blur token and selector treatment do not exist yet; a single trailing test task was rejected as too late to catch descriptor mistakes.
- **Status:** Decided
- **Handoff note:** Implement groups in order; within group 3, one device per session is a natural checkpoint.
