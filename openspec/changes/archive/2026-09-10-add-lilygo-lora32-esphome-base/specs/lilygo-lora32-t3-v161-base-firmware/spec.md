## ADDED Requirements

### Requirement: Device-specific registry entry
The repository SHALL provide exactly one self-contained base firmware configuration at `esphome/lilygo-lora32-t3-v161.yaml`. The configuration SHALL declare the node name `lilygo-lora32-t3-v161` and friendly name `LilyGo LoRa32 T3 v1.6.1`, and it MUST NOT depend on an ESPHome package hierarchy.

#### Scenario: Load the registered node configuration
- **GIVEN** a checkout containing the required local secrets
- **WHEN** ESPHome loads `esphome/lilygo-lora32-t3-v161.yaml`
- **THEN** it resolves one node named `lilygo-lora32-t3-v161` with friendly name `LilyGo LoRa32 T3 v1.6.1` without loading another firmware configuration or package

### Requirement: LilyGo hardware and ESP-IDF target
The firmware configuration SHALL target the generic `esp32dev` board with the native `esp-idf` toolchain and `esp-idf` framework. It MUST NOT enable PSRAM or copy unverified peripheral settings from another LilyGo revision.

#### Scenario: Validate and compile the hardware target
- **GIVEN** ESPHome 2026.7.0 and a complete local secrets file
- **WHEN** the device configuration is validated and compiled
- **THEN** ESPHome produces firmware for the ESP32 Dev Module target using the native ESP-IDF toolchain and framework without requiring PSRAM

### Requirement: Secret and generated-artifact isolation
The device configuration MUST obtain `wifi_ssid`, `wifi_password`, `fallback_ap_password`, `api_encryption_key`, and `ota_password` from `esphome/secrets.yaml`. The repository SHALL provide `esphome/secrets.example.yaml` with inert placeholders for those exact keys, and it MUST ignore the real secrets file, ESPHome's `.esphome/` working state, generated firmware outputs, and raw device flash backups.

#### Scenario: Use a complete local secret contract
- **GIVEN** an ignored `esphome/secrets.yaml` containing all five required keys
- **WHEN** ESPHome validates the device configuration
- **THEN** every credential reference resolves without any credential being embedded in the tracked device YAML

#### Scenario: Detect an incomplete local secret contract
- **GIVEN** a local secrets file missing one required key
- **WHEN** ESPHome validates the device configuration
- **THEN** validation fails and identifies the unresolved secret before compilation or deployment

#### Scenario: Keep local ESPHome data out of Git
- **GIVEN** local secrets, build state, generated firmware, or a raw flash backup under `esphome/`
- **WHEN** repository ignore behavior is checked
- **THEN** each sensitive or generated path is ignored while the device YAML and secrets example remain trackable

### Requirement: Wi-Fi recovery and logging
The firmware SHALL connect to the secret-configured Wi-Fi network, SHALL expose serial/runtime logging, and SHALL start a password-protected fallback access point with a captive portal when normal Wi-Fi cannot be established.

#### Scenario: Join the configured Wi-Fi network
- **GIVEN** valid Wi-Fi credentials and an available configured network
- **WHEN** the device boots
- **THEN** it connects to that network, makes runtime logs available, and does not require the fallback access point for recovery

#### Scenario: Recover from unavailable Wi-Fi
- **GIVEN** the configured Wi-Fi network is unavailable or its credentials are invalid
- **WHEN** the normal connection attempt reaches ESPHome's fallback condition
- **THEN** the device exposes the password-protected fallback access point and captive portal

### Requirement: Encrypted native Home Assistant API
The firmware SHALL expose ESPHome's native Home Assistant API using `api_encryption_key`. The base firmware MUST NOT configure MQTT or the general-purpose top-level `web_server:` component. The captive portal's implicit recovery web interface and `web_server` OTA platform MAY be present only as part of the password-protected fallback access-point recovery path.

#### Scenario: Connect with the API encryption key
- **GIVEN** the device is connected to Wi-Fi and a Home Assistant client has the configured encryption key
- **WHEN** the client opens the ESPHome native API connection
- **THEN** the encrypted connection succeeds and the node is available for Home Assistant adoption

#### Scenario: Reject a client without the API encryption key
- **GIVEN** the device is connected to Wi-Fi and a client lacks the configured encryption key
- **WHEN** the client attempts to open the native API connection
- **THEN** the client does not obtain an authenticated API session

#### Scenario: Expose no duplicate state transport
- **GIVEN** the base firmware configuration
- **WHEN** its enabled network services are inspected
- **THEN** the native API is present, MQTT and a top-level `web_server:` component are absent, and any web-accessible firmware recovery surface is limited to the captive portal on the password-protected fallback access point

### Requirement: Authenticated ESPHome OTA
The firmware SHALL configure the ESPHome OTA platform using `ota_password`. A standard ESPHome OTA upload over the configured network MUST require successful OTA authentication. Captive-portal recovery upload MAY be available only to a client that has joined the password-protected fallback access point.

#### Scenario: Complete an authenticated OTA update
- **GIVEN** the device has booted the USB-flashed firmware, joined Wi-Fi, and is reachable by mDNS or IP
- **WHEN** ESPHome uploads the validated firmware using the configured OTA password
- **THEN** the device accepts the update, reboots, and returns online with the native API available

#### Scenario: Reject an unauthenticated OTA update
- **GIVEN** a running device with password-protected ESPHome OTA enabled
- **WHEN** an uploader supplies an incorrect OTA password
- **THEN** the update is rejected and the running firmware remains available

### Requirement: Radio-neutral peripheral scope
The base firmware MUST NOT initialize or assign pins for the SX1276 radio, OLED, SD card, user LED, battery ADC, RF frequency, RF modulation, packet decoder, or RF transmit behavior.

#### Scenario: Compile the base without board peripherals
- **GIVEN** the base device configuration
- **WHEN** ESPHome validates and compiles it
- **THEN** the generated firmware contains the connectivity and maintenance baseline without SX127x, display, SD, LED, battery, or RF protocol configuration

### Requirement: Reversible first USB flash
Before the first ESPHome upload, the deployment process MUST read the board's complete 4 MB flash into an ignored local backup and MUST verify that the backup file exists. The first upload MUST NOT proceed if the backup operation fails or produces an incomplete image.

#### Scenario: Preserve the existing firmware before upload
- **GIVEN** the board exposes a usable serial port and contains its pre-existing firmware
- **WHEN** the first ESPHome deployment is prepared
- **THEN** esptool reads a complete `0x400000`-byte flash image to an ignored local path before ESPHome writes the board

#### Scenario: Stop when backup cannot be completed
- **GIVEN** the flash read fails or the resulting backup is incomplete
- **WHEN** the deployment workflow evaluates the backup result
- **THEN** it stops before the first ESPHome upload and leaves the pre-existing device firmware untouched

### Requirement: Physical-device acceptance
The capability SHALL be considered implemented only after the configuration validates, compiles, uploads over USB, boots successfully on the LilyGo board, connects to Wi-Fi, exposes the encrypted native API, and completes an authenticated network OTA update.

#### Scenario: Complete end-to-end base firmware verification
- **GIVEN** the required secrets, working USB serial connection, and preserved flash backup
- **WHEN** the implementation follows the validation, compilation, USB upload, runtime verification, and OTA sequence
- **THEN** all stages succeed on the physical LilyGo LoRa32 T3 v1.6.1 and the device returns online after OTA with logging and the encrypted native API available
