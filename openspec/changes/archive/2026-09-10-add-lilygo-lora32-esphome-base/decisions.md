# Decisions

> **This is a living document.** Append a new entry the moment a decision or
> important consideration arises — at ANY phase (planning, explore, design,
> implementation). Do not batch. Do not edit past entries; supersede them with
> a new dated entry. The next agent reads this file FIRST.

## Context

- **Change:** Establish a secure, hardware-verified ESPHome baseline for a LilyGo LoRa32 T3 v1.6.1 before implementing RF behavior.
- **Started:** 2026-07-19
- **Related:** [Proposal](proposal.md); [LilyGo T3 v1.6.1 hardware documentation](https://github.com/Xinyuan-LilyGO/LilyGo-LoRa-Series/blob/master/docs/en/t3_v161_sx1276/t3_v161_sx1276_hw.md); [ESPHome ESP32 platform](https://esphome.io/components/esp32/); [ESPHome SX127x component](https://esphome.io/components/sx127x/)
- **Environment:** ESPHome 2026.7.0 is installed locally on Windows. The user reports the board connected over USB, but the ESPHome CLI did not see a serial port during planning; implementation must recheck USB enumeration before flashing.

## Decision Log

### D1 - Establish a verified base before RF features (2026-07-19)

- **Decision:** Create and verify a minimal ESPHome node as a separate first change before adding RF receive, transmit, decoding, display, storage, LED, or battery behavior.
- **Why:** Separating board bring-up from radio behavior isolates hardware-targeting, flashing, networking, and Home Assistant integration risks and provides a known-good foundation for later firmware.
- **Alternatives considered:** Implement the RF gateway immediately; rejected because radio configuration and protocol decoding would obscure failures in the basic device setup. Create only an untested YAML; rejected because it would not prove the target works on the physical board.
- **Status:** Decided
- **Handoff note:** Keep the implementation deliberately small; later RF work should be proposed as a follow-on change.

### D2 - Target ESP32 Dev Module with ESP-IDF (2026-07-19)

- **Decision:** Configure the LilyGo LoRa32 T3 v1.6.1 as an ESP32 Dev Module using ESPHome's ESP-IDF framework.
- **Why:** LilyGo identifies the board as an ESP32-PICO-D4 with 4 MB flash and recommends the generic ESP32 Dev Module target. ESP-IDF is ESPHome's current default and recommended ESP32 framework and supports the native SX127x component planned for later.
- **Alternatives considered:** Use the Arduino framework to maximize compatibility with LilyGo examples; retained only as a fallback if a future protocol requires an Arduino-only library. Add a custom PlatformIO board definition; rejected because the manufacturer-recommended generic target is sufficient for the base node.
- **Status:** Decided
- **Handoff note:** Use an explicit framework selection for reproducibility. Do not enable PSRAM or assume unverified peripheral settings in the base configuration.

### D3 - Keep the first firmware radio-neutral (2026-07-19)

- **Decision:** Do not initialize the SX1276, OLED, SD card, user LED, battery ADC, or RF protocol in the base firmware.
- **Why:** None of these peripherals is required to validate ESPHome, USB flashing, Wi-Fi, the Home Assistant API, or OTA, and their inclusion would expand the first change beyond its bring-up purpose.
- **Alternatives considered:** Configure the complete LilyGo pin map now; rejected because unused peripheral configuration adds failure modes. Add placeholder RF settings; rejected because frequency, modulation, and protocol have not been selected.
- **Status:** Decided
- **Handoff note:** RF band, modulation, packet format, and decoded entities remain explicit follow-on decisions.

### D4 - Plan a native SX127x half-duplex gateway (2026-07-19)

- **Decision:** Design future RF work around ESPHome's native SX127x component, with reception driving ESPHome entity states and optional transmission temporarily switching the radio to TX before returning it to RX.
- **Why:** The native component exposes received packets, RSSI/SNR for LoRa, packet transmission, and raw OOK receive/transmit paths without requiring an Arduino-only dependency. The SX1276 uses exclusive RX and TX modes, so bidirectional half-duplex operation is feasible while simultaneous full-duplex operation is not.
- **Alternatives considered:** Use ESPHome packet transport only; insufficient for arbitrary third-party RF packets. Start with an Arduino radio library; unnecessary while the native component covers the intended receive/transmit primitives. Build a full-duplex design; rejected because the single SX1276 cannot receive while transmitting.
- **Status:** Decided
- **Handoff note:** Determine whether transmitters are ESPHome nodes or third-party devices before specifying the later decoder and state model.

### D5 - Use one device-specific YAML (2026-07-19)

- **Decision:** Place the initial node in `esphome/lilygo-lora32-t3-v161.yaml` with node ID `lilygo-lora32-t3-v161` and friendly name `LilyGo LoRa32 T3 v1.6.1`.
- **Why:** There is only one board and one firmware variant, so a single file is easier to compile, flash, and evolve than a package hierarchy.
- **Alternatives considered:** Introduce reusable ESPHome packages immediately; rejected until a second node or shared configuration creates real reuse. Name the node after a future RF role; rejected because the hardware-specific identity remains accurate as behavior evolves.
- **Status:** Decided
- **Handoff note:** Extract packages later only when duplication or multiple firmware variants justify them.

### D6 - Keep credentials out of version control (2026-07-19)

- **Decision:** Read Wi-Fi, fallback access-point, API encryption, and OTA credentials from `esphome/secrets.yaml`, ignore that file in Git, and commit only `esphome/secrets.example.yaml` with non-secret placeholders.
- **Why:** The configuration must be reproducible without exposing operational credentials or cryptographic keys in repository history.
- **Alternatives considered:** Inline credentials in the device YAML; rejected as unsafe. Commit real secrets for convenience; rejected because repository history is durable. Use only interactive provisioning; rejected because automated validation, flashing, and OTA need a documented credential contract.
- **Status:** Decided
- **Handoff note:** Verify ignore behavior before creating the real secrets file and never print secret values in command output or logs.

### D7 - Use only the encrypted native Home Assistant API (2026-07-19)

- **Decision:** Enable ESPHome's encrypted native API as the sole Home Assistant state transport in the base firmware, with Wi-Fi captive-portal fallback, logging, and password-protected OTA; omit MQTT and the embedded web server.
- **Why:** The native API directly exposes future decoded RF entities to Home Assistant while avoiding duplicate state paths, unnecessary services, and extra attack surface.
- **Alternatives considered:** Add MQTT; rejected because there is no broker-specific requirement. Add the web server for diagnostics; rejected because logs and the native API are sufficient for initial bring-up. Use an unencrypted API or unauthenticated OTA; rejected as an avoidable security weakness.
- **Status:** Decided
- **Handoff note:** If a future integration genuinely requires MQTT or a web UI, add it through a new logged decision rather than silently expanding this baseline.

### D8 - Require physical-device acceptance (2026-07-19)

- **Decision:** Completion requires configuration validation, compilation, USB flashing, successful boot, Wi-Fi connection, native API availability, and a working OTA update path on the physical LilyGo board.
- **Why:** Build-only validation cannot detect USB-driver, flash-layout, boot, network, or runtime integration failures on the actual hardware.
- **Alternatives considered:** Stop after `esphome config`; rejected as too weak. Stop after compilation; rejected because it does not exercise the board. Require automated Home Assistant adoption; rejected because the final adoption confirmation may require a user-controlled UI or credentials, but API availability must still be verified.
- **Status:** Decided
- **Handoff note:** The CLI currently reports no serial ports. Recheck the cable, CH9102 driver, Windows device enumeration, and whether another process holds the port before attempting upload.

### D9 - Use a board-specific capability name (2026-07-19)

- **Decision:** Name the new capability `lilygo-lora32-t3-v161-base-firmware`.
- **Why:** The repository is expected to contain additional firmware capabilities later, so the capability identifier must distinguish this board revision and its baseline role without relying on surrounding change context.
- **Alternatives considered:** Keep `esphome-node-firmware`; rejected because it is too generic once multiple device firmwares exist. Use the change name as the capability; rejected because `add-` describes an action rather than a durable capability. Use a future RF-gateway name; rejected because RF behavior is intentionally outside this change.
- **Status:** Decided
- **Handoff note:** Create the corresponding delta spec at `specs/lilygo-lora32-t3-v161-base-firmware/spec.md`; future firmware capabilities should use similarly device- and purpose-specific identifiers.

### D10 - Back up the existing flash before first upload (2026-07-19)

- **Decision:** Read and preserve the board's existing 4 MB flash image before the first ESPHome USB upload, storing the backup outside version control.
- **Why:** The initial upload overwrites the device's current firmware. A raw flash backup provides the most reliable rollback even if the exact factory image or board variant cannot later be reconstructed.
- **Alternatives considered:** Flash without a backup; rejected because it makes rollback dependent on finding a matching external binary. Rely only on LilyGo's published firmware; rejected because it may not match the exact image currently installed on this board.
- **Status:** Decided
- **Handoff note:** Use the detected serial port and local esptool 5.3.1 to read the full 0x400000-byte image before upload. Never commit the binary or expose it through logs or artifacts.

### D11 - Commit source configuration only (2026-07-19)

- **Decision:** Ignore the local `esphome/secrets.yaml`, ESPHome's `.esphome/` working directory, generated firmware/build outputs, and device flash backups; commit only the device YAML and safe secrets example.
- **Why:** Generated outputs are reproducible, machine-specific, potentially large, and may contain operational metadata, while backups may contain sensitive device data.
- **Alternatives considered:** Commit compiled firmware for convenience; rejected because it creates stale binary artifacts and bypasses source review. Commit flash backups; rejected because they are device-specific and may contain credentials.
- **Status:** Decided
- **Handoff note:** Add narrow repository ignore patterns under `/esphome/` and verify them with `git check-ignore` before generating local state.

### D12 - Use the installed ESPHome CLI and native ESP-IDF toolchain (2026-07-19)

- **Decision:** Use the locally installed ESPHome 2026.7.0 CLI for validation, compilation, USB upload, logs, and OTA, with the ESP32 configuration explicitly selecting the native ESP-IDF toolchain and framework.
- **Why:** The local CLI and esptool are already available on Windows, provide direct serial-port access, and match ESPHome's recommended ESP32 path without adding repository dependencies or a container layer.
- **Alternatives considered:** Use Docker; rejected because Docker is not installed and Windows USB forwarding adds unnecessary complexity. Use a Home Assistant-hosted Device Builder for the initial flash; rejected because the board is attached to this development machine. Use PlatformIO as the toolchain; rejected because the native ESP-IDF toolchain is sufficient for the base firmware and future native SX127x integration.
- **Status:** Decided
- **Handoff note:** Do not add ESPHome as a project package. Recheck `esphome version` and the selected toolchain during implementation, and document any version-driven syntax change as a new decision.

### D13 - Permit validation-only local secrets before deployment (2026-07-19)

- **Decision:** Use an ignored `esphome/secrets.yaml` containing clearly marked, non-operational placeholder values for static configuration validation and compilation until the user supplies real Wi-Fi values and replaces all generated credentials locally.
- **Why:** Static ESPHome validation and compilation require every `!secret` key to resolve, but collecting or exposing operational credentials through the task transcript is unnecessary and unsafe. Placeholder values unblock source verification without authorizing a device upload.
- **Alternatives considered:** Pause all implementation until real credentials are provided; rejected because tracked configuration and build correctness can be verified independently. Ask the user to paste credentials into chat; rejected because it exposes secrets. Treat placeholders as deployment values; rejected because predictable credentials and an invalid SSID are unsafe and non-operational.
- **Status:** Decided
- **Handoff note:** Task 1.3 remains incomplete. Do not back up, flash, or attempt OTA until the validation-only file is replaced locally and the user confirms it contains operational values.

### D14 - Allow only the captive portal's recovery web interface (2026-07-19)

- **Decision:** Permit the fallback captive portal's implicit recovery web interface and `web_server` OTA platform, while continuing to omit MQTT and the general-purpose top-level `web_server:` component. The encrypted native API remains the only Home Assistant state transport.
- **Why:** ESPHome 2026.7 automatically includes firmware upload in the captive portal and resolves it as a `web_server` OTA platform. This behavior is inseparable from the already selected captive-portal recovery path and does not require enabling the persistent general-purpose web server component.
- **Alternatives considered:** Remove `captive_portal`; rejected because it would discard the agreed Wi-Fi recovery path. Enable the general-purpose web server; rejected because it adds an unnecessary runtime service and attack surface. Keep a blanket prohibition on any resolved web-server presence; rejected because it contradicts ESPHome's documented captive-portal behavior.
- **Status:** Decided
- **Handoff note:** Static and physical acceptance must distinguish the permitted captive-portal recovery interface from a top-level `web_server:` service. Standard ESPHome OTA remains password-protected; captive recovery firmware upload is protected by access to the password-protected fallback AP.

### D15 - Pause for operational secrets and USB serial (2026-07-30)

- **Decision:** Keep the ignored `esphome/secrets.yaml` as validation-only until the user replaces it locally with operational Wi-Fi values and confirms readiness; do not collect credentials through chat. Defer flash backup and USB upload until a usable ESP32 serial port is available.
- **Why:** Task 1.3 and D13 forbid deploying with placeholder credentials. The current secrets file still carries the validation-only marker. Physical acceptance also requires a working USB serial path; this session sees no CH9102 LilyGo adapter and only an unavailable Silicon Labs CP210x COM3 entry with empty `Win32_SerialPort` enumeration.
- **Alternatives considered:** Paste Wi-Fi credentials into the agent transcript; rejected because it exposes secrets. Proceed to flash with validation-only values; rejected as unsafe and non-operational. Treat the CP210x COM3 entry as the LilyGo port without further checks; rejected because the board is documented for CH9102 and the port is not currently usable.
- **Status:** Blocking
- **Handoff note:** After the user updates `esphome/secrets.yaml` locally and confirms it is operational, regenerate API/OTA/fallback secrets if still placeholders, re-enumerate serial ports, then resume at task 4.1. Do not print secret values.

### D16 - Generate non-Wi-Fi secrets locally; user supplies Wi-Fi (2026-07-30)

- **Decision:** Replace the validation-only secrets file by generating `fallback_ap_password`, `api_encryption_key`, and `ota_password` locally into the ignored `esphome/secrets.yaml`, while leaving `wifi_ssid` and `wifi_password` as explicit `REPLACE_ME_*` placeholders for the user to edit outside chat.
- **Why:** The user chose option 2 from the pause: agent-generated device credentials with self-supplied Wi-Fi. This avoids pasting credentials into the transcript while unblocking credential readiness for everything except the network join values.
- **Alternatives considered:** Keep the full validation-only file until the user writes every key; slower and leaves weak predictable device credentials if forgotten. Ask for Wi-Fi values in chat; rejected per D13/D15.
- **Status:** In progress
- **Handoff note:** Task 1.3 stays incomplete until the user replaces both Wi-Fi placeholders and confirms the file is operational. Do not start flash backup or upload while Wi-Fi placeholders remain. Never print secret values.

### D17 - Resume physical deployment on the CH9102 serial port (2026-09-06)

- **Decision:** Resume the backup-first deployment workflow using the LilyGo board enumerated as `USB-Enhanced-SERIAL CH9102` on `COM3` after the user confirmed the microSD card is removed and the local secrets are operational.
- **Why:** The ignored secrets file now contains all five non-placeholder values, its API key decodes to 32 bytes, ESPHome configuration validation succeeds, and the expected CH9102 bridge is available on a concrete serial port.
- **Alternatives considered:** Continue waiting despite resolved prerequisites; rejected because it provides no additional safety. Flash immediately without inspecting and backing up the existing device; rejected by D10 and the reversible-first-flash requirement.
- **Status:** Decided
- **Handoff note:** Identify the ESP32 and confirm 4 MB flash on `COM3`, then read and validate the entire `0x400000`-byte image before any upload. Stop if identification or backup validation fails.

### D18 - Preserve and verify the pre-ESPHome full-flash image (2026-09-06)

- **Decision:** Retain the verified 4 MiB pre-ESPHome backup at `esphome/backups/lilygo-lora32-t3-v161-pre-esphome-20260906.bin` and use `python -m esptool --port COM3 write-flash 0x0 "esphome\backups\lilygo-lora32-t3-v161-pre-esphome-20260906.bin"` as the local full-flash restore command if rollback is required.
- **Why:** Esptool read all 4,194,304 bytes successfully, a complete SHA-256 was computed, and Git confirms the backup is ignored. This satisfies the reversible-first-flash boundary before any overwrite.
- **Alternatives considered:** Rely on a partial application backup; rejected because bootloader, partition table, configuration, and factory data may also be needed. Commit the backup or its contents; rejected because the image is device-specific and may contain sensitive data.
- **Status:** Decided
- **Handoff note:** Keep the backup local and ignored. Do not run the restore command unless rollback is intentionally required.

### D19 - Recompile with operational secrets before first upload (2026-09-06)

- **Decision:** Recompile the unchanged source configuration after operational secrets validation and immediately before the first USB upload.
- **Why:** The previously successful build was intentionally produced with validation-only placeholders under D13. Uploading that cached image would prevent the node from joining the real network and would deploy weak placeholder credentials.
- **Alternatives considered:** Upload the earlier build and provision through the captive portal; rejected because it would temporarily deploy predictable credentials and diverge from the secret-backed source of truth. Assume `esphome upload` recompiles; rejected because upload can use existing build output.
- **Status:** Decided
- **Handoff note:** Confirm the new compile succeeds before invoking USB upload, and never print the resolved secret values.

### D20 - Regenerate the ignored build after ESP-IDF cache relocation (2026-09-06)

- **Decision:** Run ESPHome's node-scoped clean operation and regenerate the ignored build before retrying the operational compile.
- **Why:** The existing generated project records the earlier ESP-IDF Python environment under `C:\Users\Simon\AppData\Local\esphome\Cache`, while the current tool environment activates the same ESP-IDF 5.5.4 under `F:\Caches\esphome-Cache`. ESP-IDF refuses to reuse a build configured with a different interpreter path and explicitly requires a full clean.
- **Alternatives considered:** Edit generated CMake metadata; rejected because it is brittle and outside the source of truth. Force the old cache path; rejected because the active ESPHome environment now owns the toolchain location. Upload the stale binary; rejected by D19 because it contains validation-only credentials.
- **Status:** Decided
- **Handoff note:** Clean only `lilygo-lora32-t3-v161` through ESPHome, retain the source YAML and full-flash backup, then require a successful fresh compile before upload.

### D21 - Complete the first ESPHome upload over USB (2026-09-06)

- **Decision:** Install the freshly rebuilt operational ESPHome factory image on the LilyGo through the verified CH9102 bridge on `COM3`.
- **Why:** The pre-flash backup is complete and verified, the build uses operational local secrets, and esptool identified the expected ESP32-PICO-D4 with 4 MB flash. The upload wrote 925,168 bytes, verified the written hash, and reset the board successfully.
- **Alternatives considered:** Continue using the board's previous firmware; rejected because it would not establish the requested ESPHome base. Upload the stale validation-only image; rejected by D19. Use OTA for the initial installation; rejected because the existing firmware was not yet an authenticated ESPHome node.
- **Status:** Decided
- **Handoff note:** Treat the ignored full-flash image in D18 as the rollback point. Validate the first boot through serial before relying on network or OTA access.

### D22 - Validate first boot and encrypted API independently (2026-09-06)

- **Decision:** Accept the first boot after combining redacted serial observation, mDNS reachability, and direct native API authentication tests rather than relying on unredacted ESPHome log output.
- **Why:** The serial trace showed exactly one boot, active ESPHome logging, and no crash signature; the node resolved and responded at its `.local` hostname. A client using the configured Noise key authenticated and matched the expected node name, a randomly generated incorrect key was rejected, and a subsequent correct-key session proved the node remained online.
- **Alternatives considered:** Print the full serial log; rejected because Wi-Fi metadata would be exposed in the transcript. Infer encryption only from the YAML; rejected because it would not verify the running firmware. Treat the initial log-filter wording mismatch as a network failure; rejected after independent mDNS and API checks proved connectivity.
- **Status:** Decided
- **Handoff note:** Runtime network and API bring-up are confirmed. Keep future diagnostics redacted and use direct protocol checks where practical.

### D23 - Delegate portal and Home Assistant UI confirmation after restoring the canonical image (2026-09-06)

- **Decision:** Keep fallback-portal and Home Assistant adoption confirmation user-controlled on another device, while retaining automated protocol checks for the portions that do not require those interfaces. Restore the canonical operational image over USB before continuing OTA acceptance.
- **Why:** An ignored acceptance-only image targeting a deliberately nonexistent SSID produced a clean boot and logged `Starting fallback AP` after ESPHome's 90-second fallback timeout. The development PC's spare Wi-Fi adapter had its software radio disabled, so it could not join the AP to verify the portal; the user offered to verify through another device or the Home Assistant UI. The canonical image was subsequently re-uploaded, its written hash verified, and its encrypted API authenticated successfully after Wi-Fi reconnection.
- **Alternatives considered:** Change Windows radio or privacy settings; rejected after UI automation was stopped and because another client can perform the confirmation without modifying the workstation. Mark the portal fully verified from the startup log alone; rejected because reachability and password admission still need user observation. Leave the acceptance-only image installed; rejected because it intentionally cannot join the operational network.
- **Status:** Decided
- **Handoff note:** Task 5.3 remains open until the user confirms the password-protected fallback AP and captive portal are reachable. Task 6.4 remains open until the user confirms Home Assistant discovery/adoption. The board is currently running the canonical source configuration with a healthy encrypted API.

### D24 - Confirm the normal-network service boundary (2026-09-06)

- **Decision:** Accept the deployed service boundary from the combination of source/build inspection and a runtime TCP probe on the normal Wi-Fi network.
- **Why:** The running node accepts the encrypted native API on port 6053 and ESPHome OTA on port 3232, while ports 80, 443, and 1883 are closed. The tracked configuration and generated component audit already show no MQTT or top-level `web_server:` component, and the API session proves the node is available for Home Assistant adoption.
- **Alternatives considered:** Infer the deployed surface from source alone; rejected because a runtime check provides independent evidence. Treat ESP-IDF's compiled MQTT library as an enabled MQTT client; rejected because framework library presence does not instantiate the ESPHome MQTT component or establish a broker connection.
- **Status:** Decided
- **Handoff note:** The recovery-only web surface remains tied to fallback AP activation. Task 5.3 separately requires the user's external-client portal reachability confirmation.

### D25 - Verify OTA rejects an incorrect password without disruption (2026-09-06)

- **Decision:** Exercise the running ESPHome OTA protocol directly with a newly generated incorrect password and the canonical OTA image, then verify the encrypted native API remains available.
- **Why:** The OTA server rejected the authentication attempt before accepting firmware data, and a subsequent correct-key API session matched the expected node name. This proves unauthenticated OTA does not replace or take the running firmware offline.
- **Alternatives considered:** Infer rejection from the configured YAML; rejected because it would not exercise the deployed server. Build or flash an alternate wrong-password firmware; rejected because the OTA client can test authentication without changing the device.
- **Status:** Decided
- **Handoff note:** Proceed with one authenticated OTA upload of the canonical image, then verify reboot, Wi-Fi reconnection, logging, and encrypted API recovery.

### D26 - Complete authenticated OTA and post-reboot acceptance (2026-09-06)

- **Decision:** Use the canonical source build for an authenticated ESPHome OTA upload through the node's mDNS hostname, then validate the recovered runtime through the encrypted API and a redacted log subscription.
- **Why:** The OTA server accepted the configured password and 859,632-byte application image, reported a successful update, and rebooted. Afterward the mDNS hostname resolved, the correct Noise key authenticated to the expected node name, and the API delivered configuration-level runtime logs without exposing their contents.
- **Alternatives considered:** Treat the USB restore as sufficient; rejected because physical acceptance explicitly requires network OTA. Validate only with ping; rejected because it would not prove the native API or logger recovered. Print the full post-OTA logs; rejected to avoid exposing Wi-Fi metadata.
- **Status:** Decided
- **Handoff note:** OTA rejection, authenticated upload, reboot recovery, Wi-Fi, API, and logging are complete. Remaining external confirmations are the fallback captive portal in task 5.3 and Home Assistant discovery/adoption in task 6.4, followed by the final Git leak review.

### D27 - Confirm Home Assistant adoption (2026-09-06)

- **Decision:** Accept the user's confirmation that the LilyGo node was added to the Home Assistant instance as completion of the user-controlled adoption step.
- **Why:** Automated checks had already authenticated the deployed encrypted native API and verified the expected node identity; successful addition in Home Assistant supplies the remaining instance-side confirmation that the node is reachable and adoptable.
- **Alternatives considered:** Attempt to automate the user's Home Assistant UI; rejected because the design explicitly keeps final adoption user-controlled and the user has directly confirmed completion.
- **Status:** Decided
- **Handoff note:** Home Assistant adoption is complete. Keep the canonical ESPHome image running until the user explicitly agrees to the remaining temporary fallback-portal test.

### D28 - Waive client-side captive portal reachability testing (2026-09-06)

- **Decision:** Complete fallback recovery acceptance using the observed physical-device AP activation plus configuration/build evidence, without disrupting the working Home Assistant node again for a client-side captive portal reachability test.
- **Why:** The ignored unavailable-network image already proved on the physical LilyGo that ESPHome starts the fallback AP after its 90-second timeout. The validated configuration supplies a secret-backed AP password and includes the captive portal and its recovery web stack. The user explicitly decided that joining and opening the portal is unnecessary for this baseline, while USB recovery remains available.
- **Alternatives considered:** Reflash the unavailable-network acceptance image and join the AP from another device; declined because it adds another outage without materially advancing the RF firmware foundation. Claim that the portal was client-tested; rejected because that did not occur. Remove fallback recovery from the firmware; rejected because retaining the standard recovery mechanism remains useful and low-cost.
- **Status:** Decided
- **Handoff note:** Task 5.3 records the reduced acceptance evidence explicitly. The canonical image remains installed, online through the encrypted API, adopted in Home Assistant, and verified for authenticated OTA.

### D29 - Complete the final repository and secret-leak audit (2026-09-06)

- **Decision:** Treat the implementation as repository-clean after scanning every tracked and unignored commit candidate for the exact operational secret values, verifying the sensitive/generated paths remain ignored, and separating unrelated working-tree changes from this change.
- **Why:** None of the five operational secret values appears in 316 tracked or unignored candidate files. `esphome/secrets.yaml` is untracked and ignored, and the ESPHome build state, diagnostic scripts, generated firmware, and full-flash backup are ignored. The only visible ESPHome additions are the device YAML and inert secrets example. `git diff --check` reports no whitespace error. The pre-existing `skills-lock.json` modification and `_probe_skill_copy/` files are unrelated and were preserved untouched.
- **Alternatives considered:** Delete or rewrite unrelated working-tree changes; rejected because they belong to the user or another task. Commit a redundant ESPHome-generated nested `.gitignore`; rejected because the root repository ignore rules already cover the exact sensitive/generated paths, so the redundant untracked file was removed from the commit surface.
- **Status:** Decided
- **Handoff note:** All 28 implementation tasks are complete. Keep the ignored factory backup locally for rollback and retain the canonical ESPHome image currently running on the adopted Home Assistant node.
