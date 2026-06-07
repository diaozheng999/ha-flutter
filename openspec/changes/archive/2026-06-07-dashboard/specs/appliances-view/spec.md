## ADDED Requirements

### Requirement: Appliances section on home screen
The home screen SHALL display an appliances section containing cards for: Shiny (vacuum), the washing machine, and the water heater. The section SHALL appear between the room grid and the now-playing widget. Each card SHALL use the `GlassCard` surface and SHALL NOT display a glow effect regardless of state (appliances are not ambient-light sources).

#### Scenario: Appliance section renders on home screen
- **WHEN** the home screen is displayed
- **THEN** the appliances section SHALL show Shiny, washing machine, and water heater cards in a horizontal scroll row

---

### Requirement: Vacuum (Shiny) card
The vacuum card SHALL display: Shiny's current state (`docked`, `cleaning`, `returning`, `paused`, `idle`, `error`), a start button (calls `vacuum.start` on `vacuum.roborock_qr_798`) visible when docked or idle, and a return-to-base button (calls `vacuum.return_to_base`) visible when cleaning or paused. The card icon SHALL animate (spin) when Shiny is in `cleaning` state.

#### Scenario: Start button visible when docked
- **WHEN** `vacuum.roborock_qr_798` state is `docked`
- **THEN** the Shiny card SHALL show "Start" button and SHALL NOT show "Return to base"

#### Scenario: Return to base visible when cleaning
- **WHEN** `vacuum.roborock_qr_798` state is `cleaning`
- **THEN** the Shiny card SHALL show "Return" button, SHALL NOT show "Start", and the icon SHALL spin

#### Scenario: Start calls vacuum.start
- **WHEN** the user taps "Start" on the Shiny card
- **THEN** the app SHALL call `vacuum.start` with `entity_id: vacuum.roborock_qr_798`

#### Scenario: Error state shown prominently
- **WHEN** `vacuum.roborock_qr_798` state is `error`
- **THEN** the card SHALL display "Error" in red with a warning icon and neither action button

---

### Requirement: Washing machine card
The washing machine card SHALL display: the current status from `sensor.mibx5_sg_2047340869_f35th_status_p_2_2` (friendly state string), and the remaining time from `sensor.mibx5_sg_2047340869_f35th_left_time_p_2_10` (shown only when non-zero, formatted as "Xm remaining"). The card SHALL be display-only (no control actions) in v1.

#### Scenario: Status and time render during cycle
- **WHEN** the washing machine status is "Washing" and remaining time is 42 minutes
- **THEN** the card SHALL display "Washing" and "42m remaining"

#### Scenario: Remaining time hidden when zero
- **WHEN** remaining time sensor value is 0
- **THEN** the "remaining" label SHALL NOT render

#### Scenario: Idle state
- **WHEN** the status sensor reads "Standby" or equivalent idle value
- **THEN** the card SHALL display the status string with muted foreground colour

---

### Requirement: Water heater card
The water heater card SHALL display: the current temperature from `climate.l10wfe`'s `current_temperature` attribute and the state (`on` / `off` / `unknown`). The card SHALL be display-only in v1.

#### Scenario: Water heater temperature shown
- **WHEN** `climate.l10wfe` `current_temperature` is 55.0
- **THEN** the card SHALL display "55.0°C"

#### Scenario: Unknown state shown gracefully
- **WHEN** `climate.l10wfe` state is `unknown`
- **THEN** the card SHALL display "—" for temperature and "Unknown" for state in muted foreground colour
