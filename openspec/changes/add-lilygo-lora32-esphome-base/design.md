## Context

The repository currently contains a Flutter Home Assistant client but no ESPHome registry, device configuration, credential contract, or firmware verification workflow. The target device is a USB-connected LilyGo LoRa32 T3 v1.6.1 built around an ESP32-PICO-D4 with 4 MB flash. LilyGo recommends the generic ESP32 Dev Module target, while ESPHome 2026.7.0 and esptool 5.3.1 are already installed on the Windows development machine.

This change establishes the smallest secure ESPHome baseline that can be proven on the physical board. It deliberately separates board bring-up from the later RF gateway: the future firmware may receive LoRa, FSK, or OOK packets, publish decoded values as Home Assistant entities, and transmit by temporarily switching the SX1276 from RX to TX, but none of that radio behavior belongs in this baseline.

The board's serial port was not visible to the ESPHome CLI during planning. USB enumeration and driver availability therefore remain implementation preconditions rather than reasons to weaken the hardware acceptance criteria.

## Goals / Non-Goals

**Goals:**

- Add one clearly named, device-specific YAML configuration under `esphome/`.
- Target the LilyGo board reproducibly with the ESP32 Dev Module definition, native ESP-IDF toolchain, and ESP-IDF framework.
- Provide Wi-Fi recovery, logging, encrypted Home Assistant API access, and authenticated ESPHome OTA updates.
- Define a safe local-secrets contract without committing credentials, generated build state, firmware binaries, or device backups.
- Preserve the pre-existing device flash before overwriting it.
- Validate, compile, flash, boot, connect, expose the API, and complete a network OTA cycle on the physical board.
- Leave a clean extension point for a later native ESPHome SX127x gateway.

**Non-Goals:**

- Configure the SX1276 radio, choose an RF frequency or modulation, decode packets, or transmit RF.
- Configure the OLED, SD card, user LED, battery ADC, or any other board peripheral.
- Add MQTT, the general-purpose top-level `web_server:` component, ESPHome packages, or reusable multi-device abstractions. The captive portal's implicit recovery interface remains in scope.
- Modify the Flutter application or its existing Home Assistant REST/WebSocket behavior.
- Automate the final user-controlled Home Assistant adoption UI.

## Decisions

### Source layout and identity

The registry will contain `esphome/lilygo-lora32-t3-v161.yaml` as the sole device configuration, using `lilygo-lora32-t3-v161` as the ESPHome node name and `LilyGo LoRa32 T3 v1.6.1` as its friendly name. A single file is preferred until another node or firmware variant creates real reuse. The corresponding capability remains board- and purpose-specific: `lilygo-lora32-t3-v161-base-firmware`. This distills D5 and D9.

Only source inputs are versioned. `esphome/secrets.example.yaml` documents required secret keys with inert placeholders, while the real `esphome/secrets.yaml`, ESPHome's local `.esphome/` state, generated outputs, and raw flash backups are ignored with narrow `/esphome/` patterns. This distills D6 and D11.

### Hardware and build platform

The YAML will explicitly select the generic `esp32dev` board, the native ESP-IDF toolchain, and the `esp-idf` framework. It will not enable PSRAM or copy peripheral settings from unrelated LilyGo revisions. The installed ESPHome CLI is the single interface for configuration validation, compilation, USB upload, logging, discovery, and OTA; no Docker image, project dependency, or custom PlatformIO board definition is introduced. This distills D2 and D12.

### Connectivity and security boundary

The device will use secret-backed Wi-Fi credentials plus a password-protected fallback access point and captive portal. It will enable the logger, native API encryption, and the ESPHome OTA platform with a password. The secret contract will cover `wifi_ssid`, `wifi_password`, `fallback_ap_password`, `api_encryption_key`, and `ota_password`.

The native API is the only Home Assistant state transport. MQTT and the general-purpose top-level `web_server:` component are omitted because they add duplicate paths and services without a present requirement. ESPHome's captive portal implicitly provides a recovery-only web interface and `web_server` OTA platform on the password-protected fallback access point; that scoped recovery behavior is allowed and is not a second state transport. Future RF decoders will publish ESPHome entities over this same API rather than changing the base transport architecture. This distills D6, D7, and D14.

### Radio-neutral baseline with a native future path

No SPI bus, SX127x component, RF pin, frequency, modulation, packet trigger, or transmit action will appear in the initial YAML. This keeps basic boot and connectivity failures independent from radio configuration. A later change can extend the same node with ESPHome's native SX127x component, using received packets to update entities and switching between RX and TX for half-duplex transmission. Arduino remains a fallback only if a future protocol has no viable native implementation. This distills D1, D3, and D4.

### Physical verification and rollback

The implementation is not complete when the YAML merely validates or compiles. Before the first upload, esptool will read the board's full 4 MB flash into an ignored local backup. ESPHome will then perform the USB upload and serial-log verification. After Wi-Fi and API availability are confirmed, the same configuration will be uploaded over the authenticated ESPHome OTA path to prove network updates work. This distills D8 and D10.

## Risks / Trade-offs

- **The USB serial port is not currently visible** → Recheck Windows device enumeration, the USB data cable, the LilyGo CH9102 driver, SD-card removal, and whether another process owns the port before any flash operation.
- **The first upload destroys the current firmware image** → Capture and verify a full 4 MB flash backup before upload; retain USB/esptool as the recovery path.
- **A generic board target could expose a revision mismatch** → Use LilyGo's documented ESP32 Dev Module target, avoid unverified peripherals, and inspect early boot/flash-size logs before proceeding to OTA.
- **Secrets or device data could enter Git history** → Add narrow ignore rules first, use only placeholders in the example file, verify with `git check-ignore`, and avoid echoing secret values in terminal output.
- **The fallback access point adds a recovery network** → Require a secret-backed password and rely on it only when normal Wi-Fi cannot connect.
- **mDNS discovery may be unreliable on the local network** → Permit an explicit device IP for logs and OTA verification without changing the YAML identity.
- **The native toolchain may need downloads on its first compile** → Perform configuration validation first, then allow the ESPHome-managed toolchain setup before connecting the deployment workflow to the board.
- **A later RF protocol may require Arduino-only code** → Keep this change radio-neutral so switching frameworks later remains a contained, explicitly logged follow-on decision.

## Migration Plan

1. Add the narrow `/esphome/` ignore rules before creating secrets, build state, or backups.
2. Add the device YAML and safe secrets example, then create the ignored local secrets file with Wi-Fi, fallback AP, API encryption, and OTA values.
3. Run `esphome config` against the device file, followed by `esphome compile` using the native ESP-IDF toolchain.
4. Resolve the board's Windows serial port and any CH9102 driver or cable issue; remove an inserted SD card before flashing as advised by LilyGo.
5. Back up the complete 4 MB flash with esptool and confirm the backup file exists outside version control.
6. Upload over USB with ESPHome and inspect serial logs for a clean boot, correct flash recognition, Wi-Fi connection, and native API startup.
7. Confirm Home Assistant can reach the encrypted API; user-controlled adoption may be completed manually if required.
8. Perform a second upload through ESPHome OTA using mDNS or an explicit IP, then confirm the device returns online.

Rollback uses the USB serial connection and esptool to restore the preserved full-flash image. If only networking or OTA fails while the ESPHome image still boots, USB upload of the last validated ESPHome build is the first recovery option.

## Open Questions

- Which Windows COM port will the board expose once the USB/driver issue is resolved?
- What local Wi-Fi and generated API/OTA secret values will be used during implementation?
- Will Home Assistant adoption require a manual confirmation in the user's instance after API reachability is verified?
- Which RF band, modulation, packet source, and entity mapping will the later RF gateway change support?
