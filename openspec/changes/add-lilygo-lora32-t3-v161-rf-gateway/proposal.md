## Why

Home Assistant's Study and Bedroom Mistral fan/light entities are purely optimistic. Their state lives in `input_boolean`, `input_number`, and `input_select` helpers that the control scripts write themselves, so nothing observes the hardware: using a physical remote silently desynchronises Home Assistant, and a Broadlink transmission that never reaches the unit leaves Home Assistant reporting a state the room does not have.

The LilyGo LoRa32 T3 v1.6.1 now runs a verified ESPHome baseline and carries an idle SX1276 and OLED on already-adopted hardware. Listening on the same 433 MHz band the Broadlink transmits on closes both gaps at once.

## What Changes

Delivered in four phases, each building on the last.

- **Phase 1 — Reliable receiver.** Add SX1276 reception to the existing device configuration: the SPI bus, the `sx127x` component in OOK continuous mode, and `remote_receiver` fed from the radio's demodulated data line. Confirm the operating frequency against the hardware rather than assuming it, and prove the node hears both Mistral remotes and the Broadlink.
- **Phase 2 — Receive status.** Recognise the individual fan and light codes already learned by the Broadlink as `rf.study_fan` and `rf.bedroom_fan`, and track whether an expected transmission was actually observed on air, giving Broadlink commands a delivery confirmation they do not have today.
- **Phase 3 — Local status display.** Enable the on-board SSD1306 OLED to show receive status at the device, independent of Home Assistant or Wi-Fi.
- **Phase 4 — Home Assistant integration.** Publish received remote activity to Home Assistant so the existing fan and light helpers can be corrected when someone uses a physical remote.
- Narrow the base firmware's radio-neutral scope. The SX1276 and OLED move into this capability; SD card, user LED, battery ADC, and RF transmit stay out.
- Keep transmission on the Broadlink. This change adds no RF transmit path, superseding the half-duplex transmitter anticipated in the base change's decision log.

Telling a Broadlink-originated burst apart from a human pressing the remote is explicitly deferred. The two are indistinguishable on air today because the Broadlink replays the waveform it learned from that remote; the intended future answer is to give the Broadlink signal a Home Assistant origin signature, decided when Phase 4 requires it.

## Capabilities

### New Capabilities

- `lilygo-lora32-t3-v161-rf-receiver`: Defines 433 MHz OOK reception on the LilyGo node, recognition of the Mistral fan and light remote codes, receive-status tracking as delivery confirmation for Broadlink transmissions, local OLED status display, and publication of received remote activity to Home Assistant.

### Modified Capabilities

- `lilygo-lora32-t3-v161-base-firmware`: The "Radio-neutral peripheral scope" requirement forbids initialising or assigning pins for the SX1276, OLED, and RF configuration. Both firmwares are the same file on the same board, so that prohibition must be narrowed to the peripherals that genuinely remain out of scope: SD card, user LED, battery ADC, and RF transmit.

## Impact

- Extends `esphome/lilygo-lora32-t3-v161.yaml`, which remains the single configuration for this board. No second device file and no ESPHome packages.
- Uses ESPHome 2026.7.0's native `sx127x`, `remote_receiver`, `ssd1306_i2c`, and `event` components. No new project dependency, no Arduino framework, no external radio library.
- Adds no secrets. The existing Wi-Fi, API encryption, and OTA secret contract is unchanged.
- Deploys over the authenticated OTA path proven by the base change. USB plus the retained pre-ESPHome full-flash backup remain the rollback route.
- Leaves the Broadlink control path untouched throughout. Phase 4 adds Home Assistant automations that write the existing `input_boolean.*_state`, `input_number.*_speed`, `input_number.*_brightness`, and `input_select.*_temp` helpers; those automations live in the Home Assistant instance's storage, not in this repository.
- Does not change the Flutter application, its Home Assistant REST/WebSocket client, or any existing Home Assistant client capability.
