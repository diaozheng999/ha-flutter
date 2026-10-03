## Why

Home Assistant's Study and Bedroom Mistral fan/light entities are purely optimistic. Their state lives in `input_boolean`, `input_number`, and `input_select` helpers that the control scripts write themselves, so nothing observes the hardware: using a physical remote silently desynchronises Home Assistant, and a Broadlink transmission that never reaches the unit leaves Home Assistant reporting a state the room does not have.

The LilyGo LoRa32 T3 v1.6.1 now runs a verified ESPHome baseline and carries an idle SX1276 and OLED on already-adopted hardware. Listening on the same 433 MHz band the Broadlink transmits on closes both gaps at once.

## What Changes

Delivered in four phases, with the display established first as the local instrument for receiver testing (D16).

- **Phase 1 — Local display.** Enable and verify the on-board SSD1306 OLED with visible startup/status output, independent of Home Assistant or Wi-Fi, before adding reception.
- **Phase 2 — Reliable receiver.** Add SX1276 reception to the existing device configuration: the SPI bus, the `sx127x` component in OOK continuous mode, and `remote_receiver` fed from the radio's demodulated data line. Show raw capture activity on the working OLED without waiting for command recognition. Confirm the operating frequency against the hardware rather than assuming it. Verify reception in two steps: activate each physical Mistral remote and ensure it registers, then activate Broadlink replays for both target devices and ensure they register (D20).
- **Phase 3 — Separate events and marked Broadlink bursts.** Preserve distinct closely spaced/interleaved room/button events instead of only the latest decoded value. Prepend a coded burst identifier to Broadlink transmissions by updating the existing learned codes for `rf.study_fan` and `rf.bedroom_fan`, preserving their appliance waveforms. Show at least two recent events and their marked/unmarked source evidence on the OLED. Expected-command acknowledgement and repeated Wi-Fi/basic reception checks are removed under D48.
- **Phase 4 — Home Assistant integration.** Publish received remote activity to Home Assistant so the existing fan and light helpers can be corrected when someone uses a physical remote.
- Narrow the base firmware's radio-neutral scope. The SX1276 and OLED move into this capability; SD card, user LED, battery ADC, and RF transmit stay out.
- Keep transmission on the Broadlink. This change adds no RF transmit path, superseding the half-duplex transmitter anticipated in the base change's decision log.

D48 brings the Broadlink origin signature into this change now. A validated, command-bound prefix identifies a marked Broadlink burst, while an absent or damaged marker does not prove human origin. The LilyGo assigns separate local event identities; a static learned prefix is not a globally unique transmission sequence. One receiver cannot guarantee recovery of physically colliding transmissions.

## Capabilities

### New Capabilities

- `lilygo-lora32-t3-v161-rf-receiver`: Defines 433 MHz OOK reception, recognition of Mistral fan/light codes and Broadlink burst prefixes, preservation of separate decoded command events, local OLED history and publication of received activity to Home Assistant.

### Modified Capabilities

- `lilygo-lora32-t3-v161-base-firmware`: The "Radio-neutral peripheral scope" requirement forbids initialising or assigning pins for the SX1276, OLED, and RF configuration. Both firmwares are the same file on the same board, so that prohibition must be narrowed to the peripherals that genuinely remain out of scope: SD card, user LED, battery ADC, and RF transmit.

## Impact

- Extends `esphome/lilygo-lora32-t3-v161.yaml`, which remains the single configuration for this board. No second device file and no ESPHome packages.
- Uses ESPHome 2026.7.0's native `sx127x`, `remote_receiver`, `ssd1306_i2c`, and `event` components. No new project dependency, no Arduino framework, no external radio library.
- Adds no secrets. The existing Wi-Fi, API encryption, and OTA secret contract is unchanged.
- Deploys over the authenticated OTA path proven by the base change. USB plus the retained pre-ESPHome full-flash backup remain the rollback route.
- Updates the two target learned Broadlink code sets with backed-up, validated prefixed packets while retaining command names and existing control scripts. Phase 4 adds Home Assistant automations that write the existing helpers; those automations live in the Home Assistant instance's storage, not in this repository.
- Does not change the Flutter application, its Home Assistant REST/WebSocket client, or any existing Home Assistant client capability.
