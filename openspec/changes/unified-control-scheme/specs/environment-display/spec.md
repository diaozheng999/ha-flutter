## ADDED Requirements

### Requirement: Shared reading presentation
Environment readings (temperature, humidity, illuminance, PM2.5) SHALL be rendered via the shared `ReadingPill` primitive wherever they appear (room headers, room sidebar, home summary row). Readings without a severity mapping SHALL render in the neutral muted colour; severity-mapped readings SHALL use the shared severity tokens.

#### Scenario: Readings share one presentation
- **WHEN** the Living Room header shows temperature, humidity, and illuminance
- **THEN** all three SHALL render as `ReadingPill`s in the neutral muted colour

#### Scenario: Severity applies only where mapped
- **WHEN** temperature and PM2.5 render together in the Bedroom header
- **THEN** the temperature pill SHALL be neutral while the PM2.5 pill uses its severity colour

## MODIFIED Requirements

### Requirement: PM2.5 air quality display
The app SHALL display PM2.5 concentration from `sensor.zhimi_sg_433492230_mb4_pm2_5_density_p_3_4` (unit: µg/m³) in the Bedroom room header. The value SHALL be rendered by the shared `ReadingPill` and colour-coded via the shared severity scale: `severityNominal` for < 12, `severityWarning` for 12–35, `severityCritical` for > 35 (WHO 24-hour guideline thresholds).

#### Scenario: Good air quality renders nominal
- **WHEN** PM2.5 is 8 µg/m³
- **THEN** the Bedroom header SHALL display "8 µg/m³" in the `severityNominal` colour

#### Scenario: Moderate air quality renders warning
- **WHEN** PM2.5 is 20 µg/m³
- **THEN** the Bedroom header SHALL display "20 µg/m³" in the `severityWarning` colour

#### Scenario: Poor air quality renders critical
- **WHEN** PM2.5 is 45 µg/m³
- **THEN** the Bedroom header SHALL display "45 µg/m³" in the `severityCritical` colour
