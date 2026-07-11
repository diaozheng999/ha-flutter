## 1. Tokens & theme

- [ ] 1.1 Add `severityNominal` / `severityWarning` / `severityCritical` to `AppTokens` (hues distinguishable from `onAccent` per D12); update `copyWith` and `lerp`
- [ ] 1.2 Add a shared glass blur sigma token and route `GlassCard`'s `BackdropFilter` through it (D17)
- [ ] 1.3 Add a `ChipThemeData` to `AppTheme.dark` so all chips derive one style

## 2. Primitives (no consumers yet; app still compiles after each)

- [ ] 2.1 Add `ArcGauge`: single 270° arc painter (start 135°, shared stroke width, rounded caps, track + fill) with caller-supplied fraction and centre content
- [ ] 2.2 Add `ReadingSpec` + `ReadingPill`: icon + formatted value, optional severity mapping (rising-bad / falling-bad) resolving to the severity tokens, neutral `offMuted` fallback
- [ ] 2.3 Add `PowerToggle`: circular glass power-glyph button (`offMuted` glyph on glass when off, `onAccent` fill when on), hit target ≥ 48 dp (D11)
- [ ] 2.4 Add `ModeSelector` (mutually-exclusive) and `OptionChip` (independent binary) on the shared chip theme
- [ ] 2.5 Add `ControlCard`: `GlassCard` + compact header (icon, name, status line, trailing slot) + optional body; availability → 40% dim + disable; nullable glow colour input (rationed glow, D10)
- [ ] 2.6 Add `DeviceControlDescriptor` resolved per `DeviceRole` (icon, name, availability, isOn, sensor specs, status line, `togglePower`); climate powers on with `cool` falling back to first non-`off` mode; include the shared status-line formatter (D13) and the shared HVAC/mode label formatter
- [ ] 2.7 Unit/widget tests: descriptor power semantics (incl. climate cool fallback), status-line grammar, and severity mapping directions

## 3. Refit detailed controls (one device at a time; room screen works after each)

- [ ] 3.1 Lights: rebuild `LightToggleWidget` as a `ControlCard` with header `PowerToggle` (keep `hs_color` glow, warm-white fallback, 300 ms glow animation, unavailable treatment)
- [ ] 3.2 `LightTile`: align header row and status line to the shared grammar; keep whole-tile tap-to-toggle, glow, 200 ms debounce, drag-to-0 → `light.turn_off`
- [ ] 3.3 Lights section: adaptive-lighting chip becomes an `OptionChip`
- [ ] 3.4 Fan: wrap `FanSpeedDial` in a `ControlCard` (status per grammar, header `PowerToggle` → `fan.turn_on`/`fan.turn_off`); draw the dial with `ArcGauge`; oscillation `OptionChip` only when the entity exposes `oscillating`
- [ ] 3.5 AC: wrap `AcThermostatWidget` in a `ControlCard` (status per grammar, header `PowerToggle` with cool fallback); ring via `ArcGauge`; mode row via `ModeSelector`; mode-derived glow hue (cool → cold, heat → warm); keep 16–30 °C range, ±0.5 steps, off = dim ring + disabled steps + active modes
- [ ] 3.6 Air purifier: replace the bespoke `Switch`/header layout with a `ControlCard` (header `PowerToggle` on the power switch entity, `ModeSelector` from the select options — disabled while off, `ReadingPill`s for PM2.5 with WHO severity mapping and filter life, readings visible while off)

## 4. Quick controls & room screen

- [ ] 4.1 Add `QuickControlTile`: own `ConsumerWidget` per device (isolated rebuilds), whole-tile tap = `togglePower`, chevron/long-press opens the detailed control, on-state per rationed glow rule
- [ ] 4.2 Wide layout: quick-controls block in the room sidebar (order: icon+name, environment readings, alert strip, quick controls, section nav)
- [ ] 4.3 Compact layout: horizontal quick-controls strip above the section selector
- [ ] 4.4 Repoint `sectionStatusLine` at the descriptors so nav items and quick tiles render identical strings
- [ ] 4.5 Climate & Air section: purifier renders as a `ControlCard` peer of AC and fan (side by side wide, stacked compact)

## 5. Environment displays

- [ ] 5.1 Render environment readings (room header/sidebar, home summary row) via `ReadingPill`; unmapped readings neutral
- [ ] 5.2 PM2.5 colour-coding reads the severity tokens via its `ReadingSpec` mapping (remove the inline green/amber/red literals)

## 6. App-wide surface conformance (D17)

- [ ] 6.1 Floating dock adopts the shared glass recipe (shared blur sigma, fill, border) instead of its hand-rolled blur-24 surface
- [ ] 6.2 Scene-launch confirm glow uses the severity-nominal token instead of inline `0xFF66BB6A`
- [ ] 6.3 Dashboard config selector and compact section selector derive selected/unselected styling from the shared selector treatment

## 7. Cleanup & verification

- [ ] 7.1 Remove dead code: per-widget glow/dim/status wiring, duplicated `_RingPainter`/`_DialPainter`, purifier `Switch` remnants
- [ ] 7.2 Sweep `lib/features/` for remaining hard-coded accent colour literals; migrate to tokens
- [ ] 7.3 Run `flutter analyze` and the test suite; fix regressions
- [ ] 7.4 Verify home, security, scenes, and maintenance screens still build and render (shared-widget API compatibility risk from design)
- [ ] 7.5 Verify the room screen end-to-end at compact (< 840 dp) and wide (≥ 840 dp) breakpoints on Windows: quick toggles, refit controls, status lines, glow behaviour
