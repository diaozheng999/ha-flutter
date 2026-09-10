## 1. Repository Safety and Local Secrets

- [x] 1.1 Add narrow `.gitignore` entries for `esphome/secrets.yaml`, `esphome/.esphome/`, generated firmware outputs, and `esphome/backups/`.
- [x] 1.2 Create `esphome/secrets.example.yaml` with inert placeholders for `wifi_ssid`, `wifi_password`, `fallback_ap_password`, `api_encryption_key`, and `ota_password`.
- [x] 1.3 Create the ignored local `esphome/secrets.yaml` with the user's Wi-Fi values and securely generated API, OTA, and fallback access-point credentials without printing them to logs.
- [x] 1.4 Verify with `git check-ignore` and `git status` that real secrets, build state, generated binaries, and backups are ignored while the device YAML and secrets example remain trackable.

## 2. Base Firmware Configuration

- [x] 2.1 Create `esphome/lilygo-lora32-t3-v161.yaml` with node name `lilygo-lora32-t3-v161` and friendly name `LilyGo LoRa32 T3 v1.6.1` in one self-contained file.
- [x] 2.2 Configure the `esp32dev` board with the native `esp-idf` toolchain and `esp-idf` framework, without enabling PSRAM or importing another board revision's settings.
- [x] 2.3 Configure secret-backed Wi-Fi, a password-protected fallback access point, the captive portal, and runtime logging.
- [x] 2.4 Configure the encrypted native Home Assistant API and password-protected ESPHome OTA platform using the declared secret keys.
- [x] 2.5 Confirm by source inspection that the base YAML contains no packages, MQTT, top-level `web_server:` component, SX127x/SPI setup, RF settings, OLED, SD, LED, or battery configuration; permit only the captive portal's implicit recovery interface.

## 3. Configuration and Build Verification

- [x] 3.1 Recheck the installed ESPHome and esptool versions and append a decision-log entry before using syntax or tooling that differs from D12.
- [x] 3.2 Run `esphome config esphome/lilygo-lora32-t3-v161.yaml` with the complete local secrets file and resolve every validation error.
- [x] 3.3 Verify in an isolated temporary configuration that omitting each required secret causes validation to fail before compilation or deployment.
- [x] 3.4 Run `esphome compile esphome/lilygo-lora32-t3-v161.yaml` and confirm a native ESP-IDF firmware image is produced for the ESP32 Dev Module target without PSRAM.
- [x] 3.5 Inspect the resolved configuration and build output to confirm MQTT, the top-level `web_server:` component, radio, display, SD, LED, and battery components are absent; confirm only the captive portal's expected `web_server` OTA recovery platform is present and all generated files remain ignored.

## 4. USB Preflight and Firmware Backup

- [x] 4.1 Enumerate Windows serial ports, resolve any USB data-cable or CH9102 driver issue, ensure no other process owns the port, and remove any inserted SD card before flashing.
- [x] 4.2 Use esptool to identify the connected ESP32 and verify the detected flash capacity is 4 MB before reading or writing flash.
- [x] 4.3 Read the complete `0x400000`-byte existing flash image into `esphome/backups/` and verify the backup file size and readability.
- [x] 4.4 Confirm the backup is ignored and record the exact local restore command and backup path without exposing or committing device data; stop deployment if any backup check fails.

## 5. USB Bring-up and Network Recovery

- [x] 5.1 Upload the compiled base firmware over the verified USB serial port with ESPHome.
- [x] 5.2 Monitor serial logs through first boot and confirm correct flash recognition, no reset loop, active logging, and a successful connection to the configured Wi-Fi network.
- [x] 5.3 Temporarily make the configured Wi-Fi network unavailable, confirm through serial evidence that the password-configured fallback access point starts after its timeout, accept the configured captive portal without a client reachability test per the user's decision, then restore normal Wi-Fi connectivity.
- [x] 5.4 Verify a client with the configured API encryption key establishes the native API session and a client without the correct key cannot obtain an authenticated session.
- [x] 5.5 Confirm the running device exposes neither MQTT nor a general-purpose web server, limits its web recovery interface to the captive portal on the password-protected fallback access point, and is available for Home Assistant adoption through the native API.

## 6. OTA and Final Acceptance

- [x] 6.1 Attempt an OTA upload with an incorrect password and verify it is rejected while the USB-flashed firmware remains online.
- [x] 6.2 Upload the validated firmware through authenticated ESPHome OTA using mDNS or an explicit device IP.
- [x] 6.3 Confirm the device reboots, reconnects to Wi-Fi, resumes logging, and restores encrypted native API availability after OTA.
- [x] 6.4 Confirm Home Assistant can reach the node and complete any user-controlled adoption confirmation required by the instance.
- [x] 6.5 Review `git status` for leaked secrets, backups, build outputs, or unrelated edits; append any implementation deviations or new considerations to `decisions.md` before marking the change complete.
