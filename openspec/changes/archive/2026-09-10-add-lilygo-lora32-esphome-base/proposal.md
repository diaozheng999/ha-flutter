## Why

The repository has no reproducible ESPHome baseline for the connected LilyGo LoRa32 T3 v1.6.1, so hardware targeting, flashing, networking, and Home Assistant connectivity remain unverified. Establishing a minimal, working node now provides a dependable foundation for a later RF receiver and half-duplex transmitter without mixing radio-protocol complexity into the initial bring-up.

## What Changes

- Add one device-specific ESPHome configuration for the LilyGo LoRa32 T3 v1.6.1 using the ESP32 Dev Module target and ESP-IDF framework.
- Configure secrets-backed Wi-Fi with captive-portal fallback, logging, the encrypted native Home Assistant API, and password-protected OTA updates.
- Add a safe example secrets file and ensure the real local secrets file cannot be committed.
- Validate and compile the configuration, flash it over USB, and verify boot, Wi-Fi connectivity, Home Assistant API availability, and OTA operation on the physical board.
- Keep RF reception/transmission, packet decoding, OLED, SD card, LED, and battery support outside this first change while preserving a path to ESPHome's native SX127x support later.

## Capabilities

### New Capabilities

- `lilygo-lora32-t3-v161-base-firmware`: Defines the secure, buildable, flashable, and hardware-verified ESPHome baseline for the LilyGo LoRa32 T3 v1.6.1.

### Modified Capabilities

None.

## Impact

- Adds a new top-level `esphome/` registry containing the device configuration and safe credential template.
- Updates repository ignore rules for local ESPHome secrets and generated artifacts as needed.
- Uses the locally installed ESPHome CLI, the USB-connected LilyGo board, the local Wi-Fi network, and the Home Assistant native API during verification.
- Does not change the Flutter application, its Home Assistant client APIs, or any existing OpenSpec capability.
