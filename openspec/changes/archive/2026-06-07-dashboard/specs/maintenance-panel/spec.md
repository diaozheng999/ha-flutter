## ADDED Requirements

### Requirement: Maintenance screen layout
The app SHALL provide a `MaintenanceScreen` as the fifth bottom-navigation destination (icon: `Icons.build_outlined`). The screen SHALL contain, in order: an HA updates badge section, the power-cycling switch grid, the DB cabinet monitor, and the Shiny vacuum map.

#### Scenario: Maintenance tab navigates to maintenance screen
- **WHEN** the user taps the Maintenance tab
- **THEN** `MaintenanceScreen` SHALL render with all four sections visible

---

### Requirement: HA updates badge
The maintenance screen SHALL display the count of `update.*` entities currently in `on` state (i.e., update available). The count SHALL be shown as a prominent badge number alongside a label "Updates available". If the count is zero the section SHALL display "Up to date" in green. Tapping the section SHALL do nothing in v1 (no in-app update management). The bottom navigation Maintenance tab icon SHALL also display a badge dot (not a count) when the update count is > 0.

#### Scenario: Badge shows count when updates pending
- **WHEN** 4 `update.*` entities are in `on` state
- **THEN** the updates section SHALL display "4 updates available" and the Maintenance tab icon SHALL show a badge dot

#### Scenario: Up to date state
- **WHEN** all `update.*` entities are in `off` state
- **THEN** the section SHALL display "Up to date" in green and the tab icon badge SHALL NOT appear

---

### Requirement: Power-cycling switch grid
The maintenance screen SHALL display a grid of power-cycling switches. Each switch SHALL render as a `GlassCard` with the switch's label and an on/off state indicator. Activating a switch SHALL require a **long-press** of at least 600 ms; a tap alone SHALL produce a tooltip "Hold to toggle" and SHALL NOT trigger any service call. After a long-press, the app SHALL call `switch.turn_on` or `switch.turn_off` (toggling current state) and display a brief confirmation snackbar with the switch name.

Power-cycling switches and their labels:

| Label | Entity |
|---|---|
| Entry Light | `switch.entry_switch_l1` |
| LR Hanging 1 | `switch.0xa4c1388aecbb45dd_l1` |
| LR Hanging 2 | `switch.0xa4c1388aecbb45dd_l2` |
| LR Spotlight | `switch.0xa4c1388aecbb45dd_l3` |
| LR Fan | `switch.0xa4c1388aecbb45dd_l4` |
| Walkway Spot | `switch.shellywalldisplay_00a90b9db957` |
| Bedroom Light/Fan | `switch.bedroom_switch_l2` |
| Bedroom Spotlight | `switch.bedroom_switch_l1` |
| Study Light/Fan | `switch.study_switch_l1` |

#### Scenario: Tap shows tooltip, no toggle
- **WHEN** the user taps (short press) a power-cycling switch card
- **THEN** the app SHALL display "Hold to toggle" as a tooltip and SHALL NOT call any service

#### Scenario: Long-press toggles switch
- **WHEN** the user long-presses a power-cycling switch card for ≥ 600 ms
- **THEN** the app SHALL call `switch.turn_on` or `switch.turn_off` (opposite of current state) and display a snackbar "Entry Light toggled"

#### Scenario: Switch state shown accurately
- **WHEN** a power-cycling switch is in `on` state
- **THEN** its card SHALL display an "On" indicator; when `off`, an "Off" indicator

---

### Requirement: DB cabinet monitor
The maintenance screen SHALL display a DB cabinet section showing: current temperature from `sensor.w02_001af7_temperature` with a °C suffix, current fan speed from `sensor.w02_001af7_fan_speed` with a "RPM" suffix, and a 24-hour temperature history mini-graph rendered as a `CustomPainter` line chart (no external chart library). The graph SHALL use data points fetched via the HA REST history API (`GET /api/history/period`) on screen open and SHALL NOT update in real time (manual refresh only via a refresh icon button).

#### Scenario: Current readings shown
- **WHEN** the maintenance screen is displayed
- **THEN** the DB cabinet section SHALL show the current temperature and fan speed from the entity attributes

#### Scenario: Temperature graph renders on open
- **WHEN** the maintenance screen first renders
- **THEN** the app SHALL fetch 24-hour temperature history and render a line graph

#### Scenario: Refresh button re-fetches history
- **WHEN** the user taps the refresh icon on the DB cabinet section
- **THEN** the app SHALL re-fetch the 24-hour history and redraw the graph

---

### Requirement: Vacuum map display
The maintenance screen SHALL display the Shiny vacuum's last-known floor map using the image entity `image.shiny_map_0`. The image SHALL be loaded via the HA image proxy URL (authenticated). A "Refresh map" button SHALL reload the image. Below the map, Shiny's current state (`docked`, `cleaning`, etc.) from `vacuum.roborock_qr_798` SHALL be shown as a text label.

#### Scenario: Map image renders
- **WHEN** the maintenance screen is displayed and `image.shiny_map_0` has a valid image timestamp
- **THEN** the map image SHALL load and display within the section

#### Scenario: Refresh map button reloads image
- **WHEN** the user taps "Refresh map"
- **THEN** the image SHALL reload from the HA proxy URL with cache-busting

#### Scenario: Shiny state shown below map
- **WHEN** `vacuum.roborock_qr_798` state is `docked`
- **THEN** "Docked" SHALL be displayed as a label beneath the map image
