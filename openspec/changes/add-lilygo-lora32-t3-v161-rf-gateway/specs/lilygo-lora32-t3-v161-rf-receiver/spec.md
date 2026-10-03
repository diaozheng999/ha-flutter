## ADDED Requirements

### Requirement: Receive-only extension of the existing node
The capability SHALL extend `esphome/lilygo-lora32-t3-v161.yaml` as the single self-contained configuration for the existing LilyGo node. It SHALL preserve the base capability's device identity, native ESP-IDF target, secret contract, connectivity, logging, encrypted native API, authenticated OTA, and recovery behavior. It MUST NOT introduce RF transmission from the LilyGo. Home Assistant SHALL continue controlling the Study and Bedroom Mistral units through the existing Broadlink path using `rf.study_fan` and `rf.bedroom_fan`; the infrared living-room fan SHALL remain outside this capability.

#### Scenario: Load the extended configuration
- **GIVEN** the existing node configuration with display and receiver support and the required local secrets
- **WHEN** ESPHome validates and compiles it
- **THEN** it produces firmware for the same node and native ESP-IDF target without a second device configuration, package hierarchy, or RF transmit path, retaining the base capability's security and maintenance services

#### Scenario: Continue controlling the units without the receiver
- **GIVEN** the LilyGo is unavailable and the existing Home Assistant and Broadlink control path is operational
- **WHEN** a user commands either target unit through Home Assistant
- **THEN** control continues through the existing Broadlink scripts without requiring the LilyGo to authorize or transmit the command

### Requirement: Display-first phased delivery
Delivery SHALL retain four phases: local display, reliable receiver, separate events and marked Broadlink bursts, and Home Assistant integration. Phase 1 is accepted under D25, and D38–D41 establish basic reception for both physical remotes and Broadlink. D48 retires repeated Wi-Fi-outage/basic reception checks and the expected-command acknowledgement workflow. Fresh capture sessions and acquisition requests MUST NOT be used. Phase 3 SHALL focus on command-event separation and D63's coded burst footer added to the existing HA Broadlink codes. D15's event-grouping contract and D9's marker attribution rules SHALL be recorded before their dependent behavior is accepted. D10 and D12 remain integration decisions. Resulting contracts SHALL be reflected in specs and design.

#### Scenario: Begin receiver bring-up with a proven display
- **GIVEN** Phase 1 has demonstrated visible startup/status output on the physical OLED independently of the radio and network
- **WHEN** Phase 2 adds reception
- **THEN** raw capture feedback is connected to that working display before RF acceptance trials begin

#### Scenario: Reach an unresolved later-phase contract
- **GIVEN** a phase's required decision remains Proposed
- **WHEN** implementation reaches behavior dependent on that decision
- **THEN** the decision and concrete contract are resolved and recorded before implementing and accepting that dependent behavior, while completed earlier-phase evidence remains valid

### Requirement: Local display independent of reception and network availability
The firmware SHALL enable the on-board SSD1306 over I2C using SDA GPIO21 and SCL GPIO22. It SHALL provide visible startup/status output before reception is implemented and without requiring Wi-Fi, Home Assistant, or command recognition. The display SHALL show a heartbeat marker toggling once per second, uptime in seconds, and actual Wi-Fi and native API client connected/disconnected states. Heartbeat and uptime updates SHALL continue independently of those connections, with uptime restarting on reboot. The display SHALL distinguish a receiver that has not started from a running receiver that has observed no captures. The heartbeat MUST NOT be presented as RF activity, and the API connection label MUST NOT be presented as independent verification of encryption or unique identification of Home Assistant.

#### Scenario: Verify the display before the radio exists
- **GIVEN** Phase 1 firmware with OLED support, no initialized receiver, and no available Wi-Fi or Home Assistant connection
- **WHEN** the physical board boots
- **THEN** the OLED presents a ticking heartbeat and advancing uptime, shows the disconnected Wi-Fi/API states, and indicates that reception has not started rather than reporting an RF observation

#### Scenario: Observe reboot and connection recovery
- **GIVEN** the display firmware has been deployed and the OLED is being observed
- **WHEN** the node reboots and Wi-Fi and a native API client subsequently reconnect
- **THEN** uptime restarts, the heartbeat resumes, and each connection label reflects its actual recovered state while encrypted API recovery is checked independently

#### Scenario: Keep the indication live during a network outage
- **GIVEN** the OLED is displaying the heartbeat, uptime, and connected Wi-Fi/API states
- **WHEN** Wi-Fi and the API client disconnect and later reconnect
- **THEN** the labels reflect the disconnected and recovered states while the heartbeat and uptime continue updating during runtime without needing incoming radio traffic

#### Scenario: Show a running receiver with no observations
- **GIVEN** the receiver is running and has made no captures since boot
- **WHEN** the display renders receive diagnostics
- **THEN** it distinguishes the running receiver from the not-started state and shows zero captures with no last capture observed

### Requirement: Local input diagnostics independent of recognition
Once reception is added, the OLED SHALL show receiver/decode status and the number of raw inputs since boot. Before the first exact match it SHALL show last-input age or NONE; after a match it SHALL show the age of the retained room/button result. Raw input counting SHALL update independently of recognition and network connectivity. RAW SHALL count input batches and OK SHALL count complete matched frames, neither representing physical presses or confirmed deliveries. Live timing data SHALL be decoded in memory without raw timing dumps or recording sessions; existing stored codes SHALL supply the protocol reference.

#### Scenario: Observe an undecoded capture
- **GIVEN** the receiver and OLED are running without command recognition or network access
- **WHEN** the receiver records a raw capture
- **THEN** the display increments RAW and reports the rejection on RX; before any match ROOM/BTN show UNKNOWN, while a previous exact match remains visible with BTN AGE, without recording or dumping timings

#### Scenario: Observe silence after a capture
- **GIVEN** a raw capture has been recorded and no subsequent capture occurs
- **WHEN** time passes and the display refreshes
- **THEN** RAW stays unchanged while the displayed last-input age or retained-button age increases

#### Scenario: Restart diagnostic counters
- **GIVEN** the board previously recorded captures
- **WHEN** it reboots
- **THEN** the since-boot count starts at zero and the display reports no last capture until a new one occurs, without implying that appliance state was reset

### Requirement: Native continuous OOK receive path
The firmware SHALL receive through the native ESPHome `sx127x` component in OOK continuous mode with bit synchronization disabled and packet mode off, feeding demodulated DIO2 on GPIO32 into `remote_receiver`. It SHALL use the board's radio connections: SPI SCK GPIO5, MISO GPIO19, MOSI GPIO27, CS GPIO18, and reset GPIO23. Reception and raw local diagnostics MUST NOT depend on Home Assistant being connected or preparing the node before a transmission.

#### Scenario: Capture an unframed transmission locally
- **GIVEN** the radio is configured at the hardware-verified frequency and the node has no Home Assistant connection
- **WHEN** a target remote emits a receivable unframed OOK burst
- **THEN** `remote_receiver` captures the demodulated signal and the OLED shows capture activity without requiring packet-mode framing, an `on_packet` callback, or a Home Assistant handshake

### Requirement: Hardware-verified reception for both target rooms
Receiver acceptance SHALL establish repeatable reception in two ordered verification steps: first activate each physical Mistral remote and ensure its transmissions register, then activate Broadlink replays for both target devices and ensure they register. Registration SHALL be demonstrated by recognized room/button names on the physical OLED. The working frequency SHALL be 433.92 MHz, established by D38's user-confirmed decoding from both physical remotes. Evidence SHALL record actual trial conditions, the codebook reference, and separate visible results for each source. Home Assistant publication, raw timing dumps and recording sessions SHALL NOT be prerequisites. A successful build, service call or changing raw counter alone MUST NOT be accepted as proof of target reception.

#### Scenario: Activate each physical remote and verify registration
- **GIVEN** the working OLED, receiver firmware, and the Study and Bedroom physical remotes
- **WHEN** each remote is activated separately through repeated controlled command trials and compared with idle behavior
- **THEN** each remote's transmissions register as the corresponding room/button names on the OLED, with separate recorded visual results for the subsequent Broadlink checks

#### Scenario: Activate the Broadlink and verify registration
- **GIVEN** both physical remotes have registered successfully on the OLED and the existing codebook is available
- **WHEN** the Broadlink sends repeated controlled commands for `rf.study_fan` and then `rf.bedroom_fan`, with idle comparisons
- **THEN** each device code set's transmissions register as the corresponding room/button names on the OLED, with replay results recorded separately from physical-remote results

#### Scenario: Fail to establish target reception
- **GIVEN** firmware validates and compiles but trials yield silence or activity that cannot be associated with the target transmissions
- **WHEN** Phase 2 acceptance is evaluated
- **THEN** reception remains unverified and frequency or receiver investigation continues without accepting generic activity as target reception

#### Scenario: Reject an unknown room code
- **GIVEN** stored Study and Bedroom unit IDs are respectively `0x21` and `0xCB`
- **WHEN** a received frame has another unit ID, even with a known command payload
- **THEN** RX reports the unrecognized code and no new room/button match is assigned; any retained result remains explicitly associated with its earlier BTN AGE

### Requirement: Recognition of the existing Mistral command set
The firmware SHALL recognize room and command from the existing stored codes for `rf.study_fan` and `rf.bedroom_fan`, using the complete mapping in `rf-codebook.md`. Each room's set SHALL include `fan_off`, `speed_1` through `speed_5`, `fan_fr`, `light_off`, `light_warm`, `light_neutral`, `light_cool`, `light_brightness_up`, and `light_brightness_down`. It SHALL normalize either input polarity and match a complete 29-bit word containing a known unit ID and exact command, with alternating levels, valid short/long timings, a terminal mark and frame boundaries under D36. Unknown or malformed input MUST NOT create a known room/button match. The OLED SHALL show actual room/button names and retain recognized events across subsequent unmatched callbacks, without presenting old observations as fresh events. Passive decoding SHALL continue independently of network connectivity. D15 governs repeated-frame versus separate-event behavior. Direction recognition SHALL NOT introduce a direction helper; brightness recognition SHALL NOT settle D10.

#### Scenario: Recognize each room and command
- **GIVEN** the existing stored-code mappings for both rooms and every command in the required set
- **WHEN** each mapped command is exercised through its physical remote and corresponding Broadlink replay
- **THEN** the receiver identifies the mapped room and displays its actual button name alongside local input diagnostics

#### Scenario: Validate the decoder without RF acquisition
- **GIVEN** the 101 complete existing reference frames and all 26 mapped room/command combinations
- **WHEN** the native C++ test builds the actual YAML decoder and exercises complete stored transmissions, both polarities, receiver-sized input batches, timing variation, truncation, inconsistent levels and unknown words
- **THEN** valid references produce the expected room/button and invalid input produces no match, without accessing a radio or recording new data

#### Scenario: Retain a recognized button through a later fragment
- **GIVEN** a complete known frame matched before the next one-second display refresh
- **WHEN** a trailing short or unmatched input arrives before that refresh
- **THEN** the OLED still shows the real matched room/button with BTN AGE, RX reports the latest rejection, and OK does not increment for the unmatched input

#### Scenario: Keep unknown activity unclassified
- **GIVEN** a capture does not match the established target command mappings
- **WHEN** the receiver processes it
- **THEN** raw diagnostics show the activity without presenting it as a recognized Mistral command or applying a room-specific helper correction

#### Scenario: Preserve separate identical commands
- **GIVEN** captured repetition behavior and the resolved D15 contract distinguish repeated frames from distinct command observations
- **WHEN** two separate presses issue the same command
- **THEN** recognition preserves both logical command observations rather than suppressing the second solely because its room and command equal the first

### Requirement: Preserve separate and interleaved command events
Phase 3 SHALL preserve distinct decoded room/button events in a bounded history independent of the OLED refresh. Repeat suppression SHALL be scoped to the relevant room/button and burst, rather than a global quiet period that suppresses unrelated commands. Each separate event SHALL have a local event identity, room/button and source-marker evidence. At least two recent events SHALL be inspectable on the physical OLED. The implementation SHALL document its limits for repeated identical unmarked presses and physical RF collisions; it MUST NOT infer lost events from corrupted signals or present frame counts as proven physical press counts.

#### Scenario: Decode two events before the display refreshes
- **GIVEN** intact frames for two different room/button combinations arrive within one callback or successive callbacks before a redraw
- **WHEN** the receiver decodes them
- **THEN** both event records survive with distinct identities and both can be inspected on the OLED

#### Scenario: Interleave repeated frames from two commands
- **GIVEN** intact frames interleave as Study A, Bedroom B, Study A, Bedroom B within their bursts
- **WHEN** repeated-frame grouping runs
- **THEN** it preserves both commands while grouping repeats independently, without one command suppressing the other

#### Scenario: Receive physically colliding transmissions
- **GIVEN** overlapping RF transmissions corrupt one or both frames
- **WHEN** only part of the input satisfies the complete decoder contract
- **THEN** only intact valid commands produce event records, and verification does not claim that software recovered two events from undecodable data

#### Scenario: Accept the observed interference limit
- **GIVEN** D68 records the user's interference observation, lack of fan reaction during overlapping presses, and acceptance of this unlikely operating case
- **WHEN** Phase 3 acceptance is evaluated
- **THEN** the accepted limitation permits progression without further forced-overlap trials, while unreported OLED rows and physical cross-source separation remain explicitly unverified rather than claimed successful

### Requirement: Mark Broadlink bursts in the existing learned codes
The implementation SHALL use D63's `original command burst | 5A footer` with D57's corrected B1 C0 transport boundary. Waveform parsing SHALL begin at byte 8; bytes 0–1 and 4–7 SHALL remain identical to the original and only length bytes 2–3 SHALL change. All original appliance frame timings, repetitions and spacing SHALL be preserved with no command-start or total-duration increase. The 172-tick footer SHALL occupy the original final quiet space with at least 160 quiet ticks before and after; insufficient space SHALL be rejected. Exact reversal SHALL restore the original byte packet. Source attribution SHALL require a complete valid footer after a candidate group containing one distinct recognized command word; different recognized words in a group SHALL retain separate events with ambiguous attribution. A group SHALL expire after 300 ms without a recognized command, checked on receive callbacks and the 50 ms publication tick. Each valid footer SHALL close the group so consecutive identical marked bursts create separate local events. Static markers SHALL NOT be described as globally unique transmission IDs; absent/damaged markers or indistinguishable same-word overlap SHALL NOT establish human origin or guaranteed transmitter identity.

#### Scenario: Separate consecutive identical marked sends
- **GIVEN** two consecutive Broadlink packets contain the same appliance command and valid footer
- **WHEN** the receiver decodes both complete marked bursts
- **THEN** it produces separate local event identities rather than suppressing the second because the command or static marker is unchanged

#### Scenario: Reject damaged or unrelated source markers
- **GIVEN** malformed/truncated 5A timing, a missing boundary/quiet guard, or different recognized command words inside one candidate group
- **WHEN** marker association runs
- **THEN** it does not assign confirmed Broadlink source to the unrelated command; intact unmarked appliance frames remain decodable with source uncertainty preserved

#### Scenario: Reject an orphan or stale footer
- **GIVEN** a valid footer with no recognized command in a current candidate group, including a group expired after 300 ms without a recognized command
- **WHEN** footer association runs
- **THEN** it creates no command event and does not label earlier events BL

#### Scenario: Present unambiguous marker status
- **GIVEN** marker status is being checked on the physical OLED
- **WHEN** its diagnostic page is shown
- **THEN** FOOTER uses an explicit YES/NO label, the latest source is visible, and decoded bits use NONE/FULL at the extremes, with larger text and a separate page retaining both recent events

#### Scenario: Update HA's learned codes reversibly
- **GIVEN** an immutable fresh backup of the existing storage and validated transformed packets for all 26 target commands
- **WHEN** the implementation applies the migration with a compare-before-write guard and targeted integration reload
- **THEN** the same command names send footer-marked packets, unrelated codes remain unchanged, and restoring the backup recovers the exact original packets

### Requirement: RF observation evidence boundary
All local and Home Assistant receive-status surfaces SHALL distinguish raw input activity, matched frames and separate command events. They MUST NOT present reception at the LilyGo as proof that a Mistral unit received or executed the command. Broadlink attribution SHALL depend on the validated marker contract selected under D48; unmarked or ambiguous traffic MUST NOT be asserted to have human origin merely because no valid marker was decoded.

#### Scenario: Observe a command without appliance feedback
- **GIVEN** a recognized command is captured at the LilyGo and no appliance acknowledgement or independent action observation exists
- **WHEN** receive status is displayed or published
- **THEN** it reports the RF observation without asserting verified appliance execution

#### Scenario: Hear an indistinguishable replay
- **GIVEN** a physical remote and the Broadlink can emit the same captured waveform and no resolved origin evidence distinguishes this observation
- **WHEN** that waveform is recognized
- **THEN** its room/command can be reported without claiming which transmitter emitted it

### Requirement: Home Assistant publication preserves command occurrences
Phase 4 SHALL publish through two native template event entities named Study RF Command and Bedroom RF Command, firmware IDs `study_rf_command` and `bedroom_rf_command`. Each SHALL support the 13 existing stored command names suffixed `_unmarked`, `_broadlink` or `_mixed`, preserving command/source atomically and room through the entity. HA registry IDs SHALL be discovered after deployment before automation creation. Each retained logical occurrence SHALL publish once only after source finalization: on a valid footer or after 300 ms without a recognized command, checked by a 50 ms tick. The bounded eight-record publication buffer SHALL retain occurrence order and count overwritten pending records. Offline or disconnected pending events SHALL NOT replay on reconnect; boot SHALL NOT publish an assumed command.

#### Scenario: Publish repeated identical presses
- **GIVEN** an available encrypted Home Assistant connection and the resolved publication and command-observation contracts
- **WHEN** two separate recognized presses issue the same room/command
- **THEN** Home Assistant can react to both occurrences even though their room and command values are identical

### Requirement: Correct existing Home Assistant helpers without moving state ownership
Phase 4 SHALL correct the existing room-specific helpers through Home Assistant while retaining the existing template fan/light entities and Broadlink scripts. The node MUST NOT become the owner of appliance state or initialize helpers from an assumed boot state. Absolute-command corrections SHALL be idempotent with the existing script writes. Commands `light_warm`, `light_neutral`, and `light_cool` SHALL represent both light-on and the corresponding temperature selection. D70 selects calibrated brightness tracking. Before brightness writes are enabled, the implementation SHALL establish physical calibration anchors/range, verify logical step counting and record the concrete reconciliation contract under D9/D10. It SHALL avoid adding received Broadlink echoes to the existing script's delta a second time. Calibration SHALL NOT be presented as a guarantee that future RF steps cannot be missed.

The existing state holders are `input_boolean.<room>_fan_state`, `input_number.<room>_fan_speed` (live range 1–5), `input_boolean.<room>_light_state`, `input_number.<room>_light_brightness` (live range 1–7), and `input_select.<room>_light_temp` (`warm`, `neutral`, `cool`), for each of `study` and `bedroom`. Off commands SHALL change the corresponding boolean while preserving the remembered speed/brightness/temperature. Room-specific queued automations SHALL apply absolute recognized commands idempotently for each finalized source. DIRECTION SHALL remain observable without adding a direction helper.

Brightness corrections SHALL apply only to unmarked events while that room's calibration flag is enabled, using the existing brightness helper's bounds. Broadlink-marked and mixed brightness observations SHALL NOT modify that helper. Calibration flags SHALL start off and reset off on HA restart or receiver-event unavailability. Queued automation processing SHALL use the triggering occurrence rather than current entity attributes; old restored timestamps and non-event states SHALL NOT cause helper corrections. Explicit calibration actions SHALL record a user-confirmed physical level within the live helper range and enable its flag; they SHALL NOT transmit RF or claim that a helper write establishes a physical anchor.

#### Scenario: Correct absolute fan and light commands
- **GIVEN** the Phase 4 decisions and integration contract are resolved and a target room's helpers disagree with a recognized absolute command
- **WHEN** Home Assistant handles that observation
- **THEN** `speed_1` through `speed_5` set the room's fan state on and speed to the indicated level, `fan_off` sets its fan state off, or `light_off` sets its light state off as applicable, and the existing template entity reflects the correction without changing the other room

#### Scenario: Share virtual appliance state with wall controls
- **GIVEN** Study and Bedroom wall-button automations operate `fan.<room>_fan` and `light.<room>_light`, whose template states derive from the existing helpers
- **WHEN** a finalized RF event corrects the same room's fan power/speed or light power/temperature/eligible brightness helper
- **THEN** the virtual entities and their dashboard/app controls reflect that helper state, so the next wall-button toggle acts on the current virtual state without an RF-triggered retransmission or any write to the physical Zigbee relay entities

#### Scenario: Correct light-on and temperature together
- **GIVEN** a recognized `light_warm`, `light_neutral`, or `light_cool` command for one target room
- **WHEN** the resolved integration handles it
- **THEN** the room's light-state helper is on and its temperature helper is respectively `warm`, `neutral`, or `cool`, including when the helpers previously recorded the light as off

#### Scenario: Converge after an absolute Broadlink command
- **GIVEN** an existing script has already written the absolute state associated with a Broadlink transmission
- **WHEN** the receiver observes that same command and Home Assistant applies its absolute correction
- **THEN** the affected helpers remain at the same command-derived values rather than toggling or applying an additional relative change

#### Scenario: Verify calibrated brightness tracking
- **GIVEN** D70's calibrated tracking direction and the verified anchors/range and source-handling contract have been incorporated into D9/D10 and the integration
- **WHEN** physical brightness presses and Home Assistant brightness sends with received echoes are exercised
- **THEN** effective steps update the calibrated value within the verified range without adding the script's own brightness delta a second time, and endpoint behavior and any unobserved/missed steps remain explicit

#### Scenario: Close the Broadlink sweep under the user's revised acceptance
- **GIVEN** all 26 updated values are installed and D87 records 15 verified/accepted commands plus the user's instruction to skip the remaining 11 Bedroom checks
- **WHEN** integration begins
- **THEN** the physical results and skipped cases remain distinct, skipped commands are not sent again, and brightness calibration proceeds separately from button reception acceptance

#### Scenario: Restart without knowing appliance state
- **GIVEN** a unit could have changed while the LilyGo was offline
- **WHEN** the node restarts and reconnects to Home Assistant
- **THEN** startup does not overwrite the existing appliance helpers with assumed values or claim to reconstruct missed commands

### Requirement: Physical acceptance across all four phases
Completion SHALL retain the accepted display and basic reception evidence and add verification of separate command events, marked Broadlink packets and live Home Assistant correction under D48. The extended firmware SHALL validate, compile, deploy through authenticated OTA and recover its baseline services. Previously accepted Wi-Fi-unavailable or basic recognition checks SHALL NOT be repeated as gates. Phase 4 acceptance SHALL use observed behavior in Home Assistant; committed firmware or planning files alone SHALL NOT establish it. All dependent decision contracts SHALL be reflected in specs and design before the whole change is accepted.

#### Scenario: Complete the phased capability
- **GIVEN** the phase decisions are resolved, their concrete contracts are recorded, and the required local hardware and live Home Assistant instance are available
- **WHEN** the four phases' acceptance scenarios and an authenticated OTA deployment are exercised
- **THEN** the evidence combines the accepted display/receiver results with separate-event preservation, updated Broadlink codes and source-marker behavior, live helper correction under the resolved policy, and normal deployment recovery

#### Scenario: Evaluate build-only or partial completion
- **GIVEN** firmware builds or earlier phases pass but a later phase or its required decision contract remains unverified
- **WHEN** overall completion is evaluated
- **THEN** the verified evidence is retained and the capability remains incomplete until all four phases are accepted
