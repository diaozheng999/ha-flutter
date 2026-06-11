# Environment Display

## Purpose

Defines how environmental sensor readings (temperature, humidity, illuminance, PM2.5) are displayed in room headers and on the home screen summary row.

## Requirements

### Requirement: Temperature display
The app SHALL display the current room temperature sourced from the `current_temperature` attribute of the room's `climate.*` entity. Temperature SHALL be displayed as a numeric value with one decimal place and a °C suffix. The value SHALL update within one WebSocket event of an attribute change.

#### Scenario: Temperature renders in room header
- **WHEN** `climate.living_room_ac` `current_temperature` is 26.5
- **THEN** the Living Room room header and room card SHALL display "26.5°C"

#### Scenario: Temperature missing when AC unavailable
- **WHEN** `climate.living_room_ac` is `unavailable`
- **THEN** the temperature field SHALL display "—" rather than a stale value

---

### Requirement: Humidity display
The app SHALL display relative humidity from `sensor.shellywalldisplay_00a90b9db957_humidity` (unit: %) in the Living Room room header only. The value SHALL be shown with zero decimal places and a % suffix.

#### Scenario: Humidity shown in Living Room header
- **WHEN** the humidity sensor reads 72
- **THEN** the Living Room header SHALL display "72%"

#### Scenario: Humidity not shown in other rooms
- **WHEN** the Bedroom or Kitchen room header is displayed
- **THEN** no humidity field SHALL appear (the ShellyWallDisplay is only in the Living Room)

---

### Requirement: Illuminance display
The app SHALL display illuminance from `sensor.shellywalldisplay_00a90b9db957_illuminance` (unit: lx) in the Living Room room header only. The value SHALL be displayed as an integer with an "lx" suffix.

#### Scenario: Illuminance shown in Living Room header
- **WHEN** the illuminance sensor reads 420
- **THEN** the Living Room header SHALL display "420 lx"

---

### Requirement: PM2.5 air quality display
The app SHALL display PM2.5 concentration from `sensor.zhimi_sg_433492230_mb4_pm2_5_density_p_3_4` (unit: µg/m³) in the Bedroom room header. The value SHALL be colour-coded: green for < 12, amber for 12–35, red for > 35 (WHO 24-hour guideline thresholds).

#### Scenario: Good air quality renders green
- **WHEN** PM2.5 is 8 µg/m³
- **THEN** the Bedroom header SHALL display "8 µg/m³" in green

#### Scenario: Moderate air quality renders amber
- **WHEN** PM2.5 is 20 µg/m³
- **THEN** the Bedroom header SHALL display "20 µg/m³" in amber

#### Scenario: Poor air quality renders red
- **WHEN** PM2.5 is 45 µg/m³
- **THEN** the Bedroom header SHALL display "45 µg/m³" in red

---

### Requirement: Environment readings on home screen
The home screen SHALL display a compact environment summary row beneath the greeting header showing: Living Room temperature, Living Room humidity, and Bedroom PM2.5. Each reading SHALL be a small chip with an icon and value. Tapping a chip SHALL scroll to or navigate to the relevant room.

#### Scenario: Environment row displays three readings
- **WHEN** all three sensors are available
- **THEN** the home screen SHALL show a living room thermometer chip, a humidity drop chip, and a PM2.5 leaf chip with their current values

#### Scenario: Chip hidden when sensor unavailable
- **WHEN** `sensor.shellywalldisplay_00a90b9db957_humidity` is `unavailable`
- **THEN** the humidity chip SHALL NOT render; the remaining chips SHALL reflow
