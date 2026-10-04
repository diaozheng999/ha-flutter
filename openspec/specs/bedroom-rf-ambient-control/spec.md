# Bedroom RF Ambient Control

## Purpose

Extend the bedroom physical Mistral RF remote's light buttons to the ambient light group through the existing received-command event, preserving source filtering, scoped Adaptive Lighting takeover and existing controls.

## Requirements

### Requirement: Consume fresh bedroom physical-remote light observations

The system SHALL consume `event.study_lilygo_lora32_t3_v1_6_1_bedroom_rf_command` using the immutable triggering occurrence and SHALL accept only `light_off_unmarked`, `light_warm_unmarked`, `light_neutral_unmarked`, `light_cool_unmarked`, `light_brightness_up_unmarked` and `light_brightness_down_unmarked`. It MUST reject non-timestamp states, initial creation without prior state, and timestamps not newer than the preceding state's `last_changed`. Broadlink/mixed sources, fan commands and other rooms MUST NOT cause ambient actions. Unmarked SHALL mean no valid marker was received; it MUST NOT be presented as guaranteed physical-transmitter identity.

#### Scenario: Accept a fresh physical light command

- **GIVEN** an existing bedroom event entity with a prior state
- **WHEN** a fresh `light_warm_unmarked` occurrence arrives
- **THEN** the system processes that occurrence's warm command for ambient control

#### Scenario: Exclude other traffic

- **GIVEN** the ambient consumer is enabled
- **WHEN** a marked/mixed bedroom command, a bedroom fan command or a Study command occurs
- **THEN** this consumer performs no ambient, spotlight or RF action

#### Scenario: Reject restored events

- **GIVEN** the bedroom event entity is initialized or restored after an availability transition
- **WHEN** its state is non-timestamp, has no prior state, or carries an old occurrence timestamp
- **THEN** no ambient action is performed

### Requirement: Map power and temperature to the ambient group

The added control SHALL target `light.bedroom_ambient` only. `light_off_unmarked` SHALL call an explicit ambient turn-off; warm, neutral and cool SHALL turn the ambient group on at respectively 2700, 4000 and 6500 Kelvin. Temperature selections SHALL retain ambient's current or normally remembered turn-on brightness without copying a Mistral helper. The system MUST NOT call the virtual Mistral light, Broadlink transmitter, wall automation, spotlight group or physical relay as an added action.

#### Scenario: Turn ambient off idempotently

- **GIVEN** the ambient group is on or already off
- **WHEN** one or more fresh `light_off_unmarked` occurrences are processed
- **THEN** ambient is requested off without toggling it on or changing other fixtures

#### Scenario: Select each white temperature

- **GIVEN** the ambient group is available
- **WHEN** a fresh warm, neutral or cool unmarked command is processed
- **THEN** ambient is requested on at 2700, 4000 or 6500 K respectively, without assigning Mistral brightness

### Requirement: Apply bounded relative ambient brightness

Brightness up/down SHALL apply +/-10 percentage points from the ambient group's reported current brightness, independently of Mistral brightness helpers and calibration flags. Calculations SHALL clamp to 1–100% and account for HA's byte brightness representation. A relative step SHALL require the ambient group to be on with numeric brightness, checked from one snapshot at the parent execution boundary; off, unknown/unavailable and missing/non-numeric brightness SHALL cause no relative light action or manual takeover. Separate responsive occurrences SHALL execute in order and accumulate from the latest reported brightness. The automation SHALL bound queue size and call native group services directly without added confirmation waits, delays or retries. Failed or unobserved changes MUST NOT be recorded as successful physical steps.

#### Scenario: Apply relative up and down

- **GIVEN** ambient is on at reported 50% brightness and Mistral calibration is off
- **WHEN** a fresh unmarked brightness up or down command is processed
- **THEN** ambient is requested at 60% or 40% respectively, within HA byte rounding, without modifying the calibration flag or adding a Mistral action

#### Scenario: Clamp brightness endpoints

- **GIVEN** ambient is on at 95% or 5%
- **WHEN** brightness up at 95% or down at 5% is processed
- **THEN** ambient is requested at 100% or 1% respectively and brightness down does not turn it off

#### Scenario: Ignore brightness while off or unreadable

- **GIVEN** ambient is off, unknown/unavailable or has no numeric brightness
- **WHEN** a fresh brightness command arrives
- **THEN** no brightness action or manual takeover occurs and the group is not turned on

#### Scenario: Preserve repeated identical presses

- **GIVEN** ambient is on at 50% and reports requested updates promptly
- **WHEN** two distinct brightness-up occurrences arrive before the first action finishes
- **THEN** their queued snapshots produce two steps ending at 70%, within byte rounding, rather than both calculating from 50%

### Requirement: Preserve explicit ambient choices under Adaptive Lighting

Before applying manual temperature/on or an eligible brightness action, the system SHALL mark only ambient or its resolved tracked members as manually controlled in the applicable Adaptive Lighting profile. It MUST NOT pause the entire profile or mark spotlight/other-room lights. It SHALL retain the installed profile's existing reset/timeout policy and SHALL perform normal light actions when adaptation is disabled. Installed group expansion and service support SHALL be verified before deployment.

#### Scenario: Override adaptation only for ambient

- **GIVEN** an enabled Adaptive Lighting profile manages ambient and other fixtures
- **WHEN** an eligible remote temperature or brightness action is processed
- **THEN** only ambient's tracked targets receive manual takeover and the selected setting is not immediately replaced by adaptation; other fixtures keep their existing policy

#### Scenario: Preserve normal adaptation reset

- **GIVEN** ambient was marked manually controlled by the remote action
- **WHEN** the installed profile's usual off/reset/timeout behavior applies
- **THEN** adaptation resumes according to that existing policy without a new room-wide timer or setting change

### Requirement: Keep existing control and acceptance boundaries

The added automation SHALL leave existing RF publication, Mistral helper correction, fan commands, app/Broadlink control and wall-button automations intact. It MUST NOT alter firmware or stored learned codes, acquire new codes, replay old events on startup/reconnect, or require renewed predecessor acceptance. Validation SHALL distinguish service/trace evidence from physically observed outcomes and SHALL restrict new physical checks to ambient behavior and spotlight isolation.

#### Scenario: Keep helper correction independent

- **GIVEN** the accepted bedroom helper-correction automation and the new ambient consumer are enabled
- **WHEN** a bedroom Mistral command arrives while ambient is unavailable
- **THEN** existing Mistral helper correction remains able to process the command and no ambient retry is deferred to reconnection

#### Scenario: Preserve spotlight isolation

- **GIVEN** spotlight state and settings are recorded before an ambient remote action
- **WHEN** each eligible remote light-button mapping is exercised
- **THEN** the added automation targets only ambient and its scoped takeover targets, with no spotlight action
