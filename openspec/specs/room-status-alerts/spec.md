# Room Status Alerts

## Purpose

Defines the room alert subsystem: severity taxonomy, autodiscovery of alert sensors from HA registries, declarative alert rules for semantic events, activity alert lifetimes, offline device detection, low battery alerts, and alert presentation on the room screen.

## Requirements

### Requirement: Alert severity taxonomy
The app SHALL classify room alerts into five severity tiers, ordered highest to lowest: **safety** (leak/gas/smoke/CO sensors triggered), **activity** (time-sensitive notices such as doorbell rang, laundry done, dishwasher done), **offline** (room devices unavailable), **maintenance** (filter lifespan low, appliance/AC service due, `problem`-class sensors triggered), and **battery** (battery level low).

#### Scenario: Severity ordering
- **GIVEN** a room with one device offline, a leak sensor `on`, and a low battery
- **WHEN** the room's alerts are computed
- **THEN** the list SHALL be ordered safety, then offline, then battery

---

### Requirement: Alert sensor autodiscovery by area
The app SHALL discover alert sensors from the HA entity and device registries (fetched via WebSocket `config/entity_registry/list` and `config/device_registry/list`). Each entity's area SHALL resolve as the entity's own `area_id`, falling back to its device's `area_id`, and SHALL be matched to the room whose id equals the HA area id. Discovered entities SHALL be selected by device class: `moisture`, `gas`, `smoke`, `carbon_monoxide`, `safety` → safety alerts when `on`; `battery` → battery alerts; `problem` → maintenance alerts when `on`. Entities without an area assignment SHALL be ignored.

#### Scenario: Area-assigned leak sensor is discovered
- **GIVEN** the HA registry contains `binary_sensor.kitchen_leak` with device class `moisture` assigned to area `kitchen`
- **WHEN** registries are fetched after connection
- **THEN** the Kitchen room SHALL monitor that sensor for safety alerts without any app config change

#### Scenario: Sensor without area is ignored
- **GIVEN** a moisture binary sensor with no `area_id` on the entity or its device
- **WHEN** discovery runs
- **THEN** the sensor SHALL NOT be attached to any room

---

### Requirement: Configured alert rules for semantic events
`RoomConfig` SHALL support a list of declarative alert rules, each defining: a trigger entity, a match condition on its state, a severity tier, and a display label. Rules SHALL cover semantics autodiscovery cannot infer — activity notices (e.g. washer status sensor reporting a finished state → "Laundry done", doorbell ring → "Doorbell"), and maintenance conditions (e.g. purifier filter-life sensor below 10% → "Replace filter", service-interval sensors). The rule set SHALL be hardcoded (not user-configurable) in v1.

#### Scenario: Laundry-done rule fires
- **GIVEN** a rule mapping the washer status sensor's finished state to an activity alert "Laundry done"
- **WHEN** the washer status sensor enters the finished state
- **THEN** the owning room SHALL surface an activity alert labelled "Laundry done"

#### Scenario: Filter lifespan rule fires
- **GIVEN** a rule mapping a purifier filter-life sensor below 10% to a maintenance alert
- **WHEN** the sensor reports 8
- **THEN** the room SHALL surface a maintenance alert naming the filter

---

### Requirement: Activity alert lifetime
Activity alerts from stateful sources SHALL remain visible while the triggering state holds and clear when it changes. Activity alerts from momentary triggers (e.g. a doorbell ring) SHALL remain visible for 10 minutes after the triggering state change, then clear automatically.

#### Scenario: Stateful activity alert clears with state
- **GIVEN** a "Laundry done" alert is showing
- **WHEN** the washer status sensor leaves the finished state
- **THEN** the alert SHALL be removed

#### Scenario: Momentary activity alert expires
- **WHEN** a doorbell-ring rule triggers
- **THEN** the "Doorbell" activity alert SHALL display for 10 minutes and then clear without user action

---

### Requirement: Offline device detection
The app SHALL derive an offline alert for each room entity (light group, individual lights, fan, climate, media player) whose state is `unavailable`. Detection SHALL be a pure derivation from already-subscribed entity states with no polling.

#### Scenario: Unavailable light produces an offline alert
- **GIVEN** the Living Room detail screen is open
- **WHEN** `light.0x001788010d9450aa` reports state `unavailable`
- **THEN** the room SHALL surface an offline alert naming the affected device

#### Scenario: Alert clears when device returns
- **GIVEN** an offline alert is shown for a room device
- **WHEN** that entity's state changes from `unavailable` to any available state
- **THEN** the offline alert SHALL be removed without user action

---

### Requirement: Low battery alerts
The app SHALL surface a battery alert when any discovered battery-class sensor in the room reports a numeric level below 20%.

#### Scenario: Battery below threshold
- **GIVEN** a discovered battery sensor in the room
- **WHEN** the sensor reports 12
- **THEN** the room SHALL surface a low-battery alert naming the device and its level

#### Scenario: Battery at or above threshold produces no alert
- **WHEN** a discovered battery sensor reports 20 or higher
- **THEN** no battery alert SHALL be surfaced for that sensor

---

### Requirement: Alert presentation on the room screen
Room alerts SHALL render on the room detail screen ordered by severity tier (safety, activity, offline, maintenance, battery). In the wide layout they SHALL render as an alert strip inside the room sidebar; in the compact layout as a banner between the header row and the section selector. Each alert SHALL show an icon, the device or event name, and a short condition label. When the room has no alerts, no alert UI (including empty containers or "all clear" placeholders) SHALL render.

#### Scenario: Healthy room shows no alert UI
- **WHEN** all room entities are available and no safety, activity, maintenance, or battery conditions exist
- **THEN** the sidebar and compact layouts SHALL render no alert strip, banner, or placeholder

#### Scenario: Multiple alerts ordered by severity
- **GIVEN** a room with one device offline and one leak sensor `on`
- **WHEN** the alert strip renders
- **THEN** the leak alert SHALL appear above the offline alert
