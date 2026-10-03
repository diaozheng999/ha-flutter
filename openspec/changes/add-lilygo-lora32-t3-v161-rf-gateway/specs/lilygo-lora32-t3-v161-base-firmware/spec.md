## MODIFIED Requirements

### Requirement: Radio-neutral peripheral scope
The base firmware MUST NOT initialize or assign pins for the SD card, user LED, or battery ADC, and MUST NOT include RF transmit behavior. SX1276 reception, its frequency, modulation, and receive decoding, and the on-board OLED SHALL be governed by the `lilygo-lora32-t3-v161-rf-receiver` capability instead of being prohibited by the baseline.

#### Scenario: Compile the base with permitted receive and display support
- **GIVEN** the single base device configuration extended with SX1276 reception and OLED support
- **WHEN** ESPHome validates and compiles it
- **THEN** the generated firmware retains the connectivity and maintenance baseline with the receive and display support, without SD, user LED, battery ADC, or RF transmit behavior

#### Scenario: Bring up the display before adding reception
- **GIVEN** the base device configuration extended with OLED support while the receiver has not yet been added
- **WHEN** ESPHome validates and compiles the display-first configuration
- **THEN** the OLED extension is permitted without requiring radio initialization or adding any excluded peripheral or RF transmit behavior
