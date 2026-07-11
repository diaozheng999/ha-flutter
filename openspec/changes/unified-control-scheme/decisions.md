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

### D19 - Resolve validation findings from the coherence audit (2026-07-11)

- **Decision:** Applied the audit's fixes: (1) the compact quick-controls strip renders **above the section selector**, not "above the section content" — design.md is corrected to match the spec and tasks, because the strip is a section-independent at-a-glance layer that must stay put as sections switch; (2) added a `Glassmorphic card surface` MODIFIED delta to `device-controls` that re-expresses blur/fill/border/radius as the shared glass tokens (values retained), so after archive it no longer contradicts the new `Single glass surface recipe` requirement; (3) purged the pre-D12 "good / elevated / high" wording and the pre-D2 flat state enum from proposal.md and design.md; (4) enumerated the verified `0xFF66BB6A` occurrences in task 7.2 for retrievable context.
- **Why:** A `/validate` audit flagged one design↔spec contradiction (S1) and several stale-vocabulary and cross-spec-consistency nits; resolving them keeps every artifact telling the same story before implementation.
- **Alternatives considered:** Superseding the strip-placement contradiction with a new decision that picked "above the section content" was rejected — the selector-adjacent placement is the better UX and the spec/tasks already committed to it, so aligning design.md is the smaller, correct move. Leaving the glass-surface contradiction for archive-time was rejected because it would ship two specs mandating different blur handling.
- **Status:** Implemented
- **Handoff note:** The strip-placement wording is now consistent across design/spec/tasks; the glass-surface delta means task 1.2's blur token also satisfies the `device-controls` surface requirement.

### D20 - Severity token hex values (2026-07-11)

- **Decision:** Implemented the severity triple as `severityNominal` `#66BB6A` (green), `severityWarning` `#FFA726` (orange), `severityCritical` `#EF5350` (red). Added `glassBlurSigma` = 20 as a token and routed `GlassCard` through it. Added a single `ChipThemeData` (glass fill, `onAccent` selected tint, no checkmark) so all chips derive one style.
- **Why:** D12 fixed the vocabulary and the distinguishability constraint but left hexes as an implementation choice. Nominal reuses the prior confirm/PM2.5 green (`#66BB6A`, the value task 7.2 names). Warning moved from the old amber `#FFB300` to the oranger `#FFA726` so it no longer collides with the amber `onAccent` `#FFD27D`. Critical keeps the prior PM2.5 red `#EF5350`.
- **Alternatives considered:** Keeping `#FFB300` for warning was rejected under D12 (too close to `onAccent`). A deeper red-orange was rejected as too close to `severityCritical`.
- **Status:** Implemented
- **Handoff note:** Group 1 complete and compiling. PM2.5 / battery / temperature severity mappings and the confirm-glow token migration (tasks 5.2, 6.2, 7.2) all read these three tokens.

### D21 - Primitive API shapes (2026-07-11)

- **Decision:** Group 2 primitives landed with these APIs: `ArcGauge` fixes geometry as static constants (`startAngle` 135°, `sweep` 270°, `strokeWidth` 14, `inset` 16) and always draws the sweep-gradient fill (previously only the fan dial did) so ring and dial are pixel-identical; `ReadingSpec` carries `SeverityMapping` closures built by `risingBad` / `fallingBad` factories with a `pm25` preset (nominal < 12, warning 12–35 inclusive, critical > 35); `DeviceControlDescriptor.describe(ref, device, {roomLights})` dispatches on `DeviceRole` and centralises the `hvacModeLabel` and `climateGlowFor` formatters (cool/dry → cold `#4FC3F7`, heat/heat_cool/auto → warm `#FF8A65`, else no glow); climate power-on prefers `cool` then the first non-`off` mode. Availability treats HA `unknown` as unavailable alongside `unavailable`.
- **Why:** Fixing the arc geometry as shared constants is what guarantees "one dial style"; closures for severity keep direction (rising/falling) in one place per D8; a single `describe` switch is the D4 single-source-of-truth. Treating `unknown` as unavailable matches the design's "HA unavailable / unknown" gate.
- **Alternatives considered:** A polymorphic controller hierarchy (rejected in D4) and per-widget arc painters (rejected in D7) — both superseded here. Passing full `RoomConfig` into `describe` was rejected in favour of a narrow `roomLights` param so the descriptor stays decoupled from room config.
- **Status:** Implemented
- **Handoff note:** 14 descriptor/severity tests pass. Group 3 refits each device widget onto these primitives; the purifier card (3.6) should consume `descriptor.sensors` rather than re-deriving PM2.5/filter.

### D22 - Device widgets take a RoomDevice; climate section no longer double-wraps (2026-07-11)

- **Decision:** `AcThermostatWidget` and `FanSpeedDial` now take a `RoomDevice` (matching `AirPurifierWidget`) instead of a bare `entityId`, because the `ControlCard` header needs the device name and the descriptor keys on the role. All three device widgets now render their own `ControlCard` (which includes `GlassCard`), so `room_climate_section` stopped wrapping them in an outer `GlassCard`. `LightToggleWidget` keeps its `entityId` + optional `name` API but gained an `individualLights` param so the group card's status matches the "N on" grammar. Light tap/toggle (tile and group) resolves to explicit `turn_on`/`turn_off` (not `toggle`) to satisfy the group-toggle spec scenario. Fan oscillation uses `fan.oscillate` and renders only when the entity exposes `oscillating`.
- **Why:** The old climate section wrapped each widget in a `GlassCard`; since the widgets are now `ControlCard`s that double-wrapped the glass. Passing `RoomDevice` is the smallest change that gives the header its name and keeps the descriptor as the single source of truth (all three widgets read `describe(...)` for icon/name/status/isOn/glow/toggle).
- **Alternatives considered:** Keeping `entityId` + a separate `name` param on AC/fan was rejected as more args than just passing the `RoomDevice` the caller already holds. Leaving the outer `GlassCard` was rejected — it would double the blur/border.
- **Status:** Implemented
- **Handoff note:** These widgets are only consumed by `room_climate_section` / `room_lights_section`, so the constructor change has no other call sites. Group 4 (quick controls + room screen) is next; `sectionStatusLine` still uses its own logic and must be repointed at descriptors (task 4.4).

### D23 - Compact room layout has no section selector; strip sits above the sections (2026-07-11)

- **Decision:** The compact room detail layout stacks all sections in a scroll view — there is no compact section selector widget in the current code (the wide sidebar's bookmark nav is the only section selector). So task 4.3's "strip above the section selector" is realised as the quick-controls strip rendered at the top of the compact scroll, above the first section (after the header + alert strip). Quick-tile chevrons scroll to the relevant section via the existing `_sectionKeys` (now also attached in the compact layout). Task 6.3's "compact section selector" clause is therefore not applicable; only the dashboard config selector was migrated to the shared `ModeSelector` treatment.
- **Why:** The plan (design/spec/D19) repeatedly names a "compact section selector", but it does not exist — the compact layout was built to stack sections, not switch between them, and reworking that is explicitly out of scope ("No change to the room navigation model"). Placing the strip at the top keeps it the section-independent at-a-glance layer the design intends.
- **Alternatives considered:** Adding a compact section selector to satisfy the wording was rejected as out-of-scope navigation redesign. Restyling a nonexistent widget for 6.3 was impossible, so 6.3 covers the config selector only.
- **Status:** Implemented
- **Handoff note:** The dashboard config selector now uses `ModeSelector` (shared chip theme). If a compact section selector is ever added, it should also use `ModeSelector` to stay conformant. The room-view spec's "above the section selector" wording reads as "above the sections" for the compact layout.

### D24 - Colour-literal sweep scope; pre-existing broken tests left as-is (2026-07-11)

- **Decision:** Migrated every severity-mappable status literal to the new tokens: `severityNominal` (maintenance up-to-date, security disarmed, presence home, scene confirm), `severityWarning` (security armed-home, presence unknown, room-alert maintenance/battery, reconnecting chip), `severityCritical` (security armed-away/triggered, appliance error, room-alert safety). Two literals are deliberately kept: the room-alert **activity** blue `#64B5F6` (informational — no severity token maps to it) and the presence **not_home** grey `#78909C` (neutral away state). The three-level scale can't represent the alert palette's 5 levels without losing the maintenance/battery vs activity/offline distinctions, so only the clean mappings were made.
- **Why:** Task 7.2 mandated mapping `#66BB6A` to `severityNominal` everywhere and sweeping remaining accent literals. The severity tokens exist precisely for nominal/warning/critical state colour, so status palettes that fit the scale were migrated; colours with no matching token stayed literal (and are commented as such) rather than being forced onto a wrong token.
- **Pre-existing broken tests:** `test/room_sections_test.dart`, `test/widget_test.dart`, and `test/room_alerts_test.dart` fail to compile because they reference a removed static-rooms API (`HaEntities.roomById`, `HaEntities.rooms`, and the old `RoomConfig(lightGroup/individualLights/fan)` constructor). Verified identical failures on the clean baseline (git stash) — they broke in an earlier change when rooms became registry-driven, not in this one. Left unfixed: rewriting them requires mocking the dynamic HA registry, which is unrelated to this presentation change. `flutter analyze` is clean (only 3 pre-existing `directives_ordering` infos in untouched files); the 16 tests in the two compiling files (`device_control_descriptor_test`, `light_tile_test`) pass.
- **Alternatives considered:** Forcing the alert palette onto the 3 tokens was rejected (loses information). Rewriting the obsolete tests here was rejected as out-of-scope for a presentation change.
- **Status:** Implemented
- **Handoff note:** The obsolete tests are worth a dedicated cleanup change against the registry-driven room API. Group 7 verification (7.4/7.5) is a Windows build + run of home/security/scenes/maintenance and the room screen at both breakpoints.

### D25 - Verification: build + widget tests done; live breakpoint walkthrough deferred (2026-07-11)

- **Decision:** Task 7.4 is verified: `flutter build windows --debug` succeeds, so all five screens (home, rooms/room-detail, security, scenes, maintenance) compile against the changed shared-widget APIs — the compile-time compatibility risk the design named is resolved. Render/interaction is covered by new deterministic widget tests (`control_scheme_render_test.dart`, 5 tests) plus the descriptor/severity suite (`device_control_descriptor_test.dart`, 14) and `light_tile_test.dart` (2) — 21 passing tests asserting status-line grammar, power routing (incl. climate cool fallback), the purifier rendering a `PowerToggle` and no Material `Switch`, readings persisting while off with severity colour, and the quick-tile body-toggle vs chevron-open split. Task 7.5's literal on-Windows manual walkthrough at both breakpoints with **live** HA devices is left for the user: the Flutter app authenticates to Home Assistant via its own OAuth flow, and no authenticated session is available in this environment, so the running app reaches the login screen rather than a populated room. The automated tests are the reproducible substitute for the manual clicking they describe.
- **Why:** Faithful reporting — the build and widget tests are real, complete verification of the code paths; the one step that genuinely needs a live backend (7.5) is flagged rather than claimed.
- **Status:** Implemented (7.4); 7.5 deferred to a user-run live walkthrough.
- **Handoff note:** To finish 7.5, run `flutter run -d windows` against a logged-in HA instance and resize across the 840 dp breakpoint, checking quick toggles, refit controls, status lines, and glow behaviour.
