# Decisions

> **This is a living document.** Append a new entry the moment a decision or
> important consideration arises — at ANY phase (planning, explore, design,
> implementation). Do not batch. Do not edit past entries; supersede them with
> a new dated entry. The next agent reads this file FIRST.

## Context

- **Change:** Add 433 MHz OOK reception to the existing LilyGo node so Broadlink transmissions gain a delivery confirmation and physical Mistral remote presses sync back into Home Assistant.
- **Started:** 2026-09-12
- **Related:** [Proposal](proposal.md); archived predecessor [`2026-09-10-add-lilygo-lora32-esphome-base`](../archive/2026-09-10-add-lilygo-lora32-esphome-base/decisions.md), whose D1, D3, and D4 anticipated this work; [`openspec/specs/lilygo-lora32-t3-v161-base-firmware/spec.md`](../../specs/lilygo-lora32-t3-v161-base-firmware/spec.md); [ESPHome SX127x component](https://esphome.io/components/sx127x/); [LilyGo T3 v1.6.1 hardware](https://github.com/Xinyuan-LilyGO/LilyGo-LoRa-Series/blob/master/docs/en/t3_v161_sx1276/t3_v161_sx1276_hw.md).

### Facts established during grilling (do not re-derive)

**Board pinout.** SX1276 on SPI: SCK 5, MISO 19, MOSI 27, CS 18, RST 23, DIO0 26, DIO1 33, DIO2 32. OLED (SSD1306) on I2C: SDA 21, SCL 22. SD card on a separate bus: CS 13, MOSI 15, MISO 2, SCK 14. LED 25, battery ADC 35. LilyGo's hardware page omits DIO0; GPIO26 is confirmed from ESPHome's own documented example. No pin conflict between the radio, the OLED, and the SD card.

**Installed ESPHome is 2026.7.0.** Its native `sx127x` supports `LORA`/`FSK`/`OOK`, `frequency` 137–1020 MHz, an `on_packet` trigger exposing `x` (`std::vector<uint8_t>`), `rssi`, and `snr`, and the actions `send_packet`, `set_mode_tx`, `set_mode_rx`, `set_mode_sleep`, `set_mode_standby`, `run_image_cal`. `remote_receiver` accepts `pin`, `dump`, `tolerance`, `filter`, `idle`. An `event` platform `template` exists with a required `event_types:` list and an `event.trigger` action. An `sx127x/packet_transport` sub-component exists for ESPHome-to-ESPHome links and is not relevant here.

**Home Assistant side.** The two target units are Mistral fan/light combos, named in `script.rf_light_toggle`. Control runs through `remote.send_command` on `remote.universal_remote` (Broadlink) with `device: rf.study_fan` / `rf.bedroom_fan`. Commands are `fan_off`, `speed_1`–`speed_5`, `light_off`, `light_warm`, `light_neutral`, `light_cool`, `light_brightness_up`, `light_brightness_down`. Every send uses `num_repeats: 1`, `delay_secs: 0.4`, `hold_secs: 0` — relevant to any Phase 2 acknowledgement window. Driving scripts are `script.study_fan_set_speed` (used by both rooms), `script.rf_light_toggle`, `script.rf_light_temp`, and `script.1779206777245` ("RF Light Brightness V2").

The Broadlink device prefix is load-bearing: `rf.` devices are radio, `ir.` devices are infrared. A third fan exists — `living_room_fan` — but `script.living_room_set_fan_speed` drives it through `device: ir.living_room_fan` plus a Zigbee switch (`switch.0xa4c1388aecbb45dd_l4`) for power, so it is infrared and correctly outside this change. It is also the only fan with `speed_count: 3` and a shared `input_number.fan_speed` helper rather than a room-prefixed one.

`script.rf_light_temp` maps Kelvin to a name (≤3500 warm, ≤4500 neutral, else cool), transmits `light_<name>` **only if the light is already on**, but writes `input_select.<room>_light_temp` unconditionally. So Home Assistant's recorded temperature can already diverge from the fan's actual state today, independently of anything this change does. Its mode is `parallel` (max 10) where the other scripts are `queued`.

**Broadlink interfaces checked for frequency metadata (negative result).** The instance exposes `remote.universal_remote`, `infrared.universal_remote_ir_emitter`, and `radio_frequency.universal_remote`. None carries a frequency attribute — `radio_frequency.universal_remote` has state `unknown` and only `friendly_name`. The integration offers no diagnostics platform and no options. The learned codes, whose leading type byte distinguishes IR (`0x26`) from 433 MHz (`0xb2`) from 315 MHz (`0xd7`), live in the Home Assistant instance's `.storage` and are not reachable through any available interface. Do not repeat this search.

State is held entirely in helpers the scripts themselves write: `input_boolean.{study,bedroom}_{fan,light}_state`, `input_number.{study,bedroom}_fan_speed` (0–5), `input_number.{study,bedroom}_light_brightness` (0–7), `input_select.{study,bedroom}_light_temp` (`warm`/`neutral`/`cool`, mapped to 370/250/153 mireds). Nothing observes the hardware. The instance has no `rtl_433`, no RFXtrx, and no RF bridge — the Broadlink is the only existing RF path, and it can only transmit.

## Decision Log

### D1 - Scope this change to reception only (2026-09-12)

- **Decision:** The LilyGo receives; it does not transmit. Home Assistant keeps driving both units through the Broadlink for the whole life of this change.
- **Why:** Reception is the actual gap — the Broadlink already transmits reliably enough to be in daily use, and nothing in the house listens. Keeping transmit out means the working control path is never at risk behind unproven firmware. Decisively, a transmit design cannot be specified before the codes have been captured and decoded, and capturing them *is* the receive work.
- **Alternatives considered:** Receive and transmit, retiring the Broadlink for these two units; rejected because it puts a daily-use control path behind new firmware and adds half-duplex mode discipline (`set_mode_tx` → transmit → `set_mode_rx`, racing an inbound burst) in the same change as first light. Build the transmit path but leave it uncalled; rejected as speculative surface of exactly the kind the base change refused to carry. Drop transmit from the roadmap permanently; rejected as premature closure while no evidence demands it.
- **Status:** Decided
- **Handoff note:** This supersedes the half-duplex transmitter direction recorded as D4 in the archived base change. That entry stays valid as history; treat this one as current. A future transmit change remains possible and is not foreclosed.

### D2 - Target the Study and Bedroom Mistral units concretely (2026-09-12)

- **Decision:** The change is scoped to the two Mistral fan/light combos already modelled as `rf.study_fan` and `rf.bedroom_fan`, not to a general-purpose 433 MHz sniffer.
- **Why:** A named, finite set of codes gives the change a testable finish line and lets acceptance be stated against real hardware. The archived base change's open question ("which RF band, modulation, packet source, and entity mapping") is answered by these two devices.
- **Alternatives considered:** A generic sniffer that dumps whatever it hears and decides later; rejected because it has no completion criterion and defers every meaningful decision. Cover every 433 MHz device in the house; rejected because no others are known to exist and none are modelled in Home Assistant.
- **Status:** Decided
- **Handoff note:** The two remotes must emit distinguishable codes, since the Broadlink holds separately learned code sets per device. Confirm this early in Phase 1 — if the units share a factory code, the per-room state model collapses and needs rethinking.

### D3 - Deliver in four phases (2026-09-12)

- **Decision:** Phase 1 reliable receiver, Phase 2 receive status, Phase 3 OLED status display, Phase 4 Home Assistant integration. `tasks.md` carries these as sections within this single change.
- **Why:** Each phase is independently verifiable on hardware, and the earlier ones de-risk the later ones — there is no point designing an entity model before knowing the node can hear a remote at all. Matches how the base change ran six sequential sections to completion.
- **Alternatives considered:** Split device-side (1–3) and Home Assistant integration (4) into separate changes; rejected because it fragments one coherent arc, though it remains the fallback if Phase 4 stalls on D9. Scope the change to Phase 1 alone; rejected because a receiver that does nothing with what it hears is not shippable value.
- **Status:** Decided
- **Handoff note:** Do not design later phases in detail while an earlier one is unproven. This was explicit user direction during grilling, twice.

### D4 - Presume 433.92 MHz and confirm on hardware (2026-09-12)

- **Decision:** Configure for 433.92 MHz, and verify against the physical board and remotes during Phase 1 before treating any other result as a fault.
- **Why:** The Broadlink already transmits these codes successfully, and its RF learning covers 433/315 MHz, so 433.92 is the strong prior. But the SX1276's matching network and antenna are band-specific, so a wrong guess yields firmware that validates, compiles, flashes, and then hears nothing — a failure mode that looks like a software bug.
- **Alternatives considered:** Read the band out of the Broadlink's learned codes, whose leading type byte distinguishes 433 from 315; rejected as the codes live in the Home Assistant instance's `.storage` and are not reachable through the available interfaces. Ask the user to read the module silkscreen; deferred because the receiver itself can settle it faster once Phase 1 is up.
- **Status:** Proposed
- **Handoff note:** If nothing is heard at 433.92, retry at 315 MHz before suspecting wiring, mode, or pin configuration. LilyGo's hardware page quotes an 830–945 MHz RF range for this board, which matches neither — treat that figure as unreliable for this unit rather than as evidence.

### D5 - Receive through OOK continuous mode into `remote_receiver` (2026-09-12)

- **Decision:** Run the `sx127x` in OOK continuous mode (`bitsync` disabled, packet mode off) and feed the demodulated data line on DIO2 (GPIO32) into ESPHome's `remote_receiver`.
- **Why:** Cheap fan remotes emit unframed PWM-encoded OOK bursts with no sync word and no length field. `sx127x` packet mode and its `on_packet` trigger require framing these remotes do not have, so that path cannot hear them at all. ESPHome documents the continuous-mode-into-`remote_receiver` pairing explicitly, including the caveat that mode must be switched manually around any transmit.
- **Alternatives considered:** Packet mode with `on_packet`; rejected as structurally unable to receive unframed bursts. An Arduino radio library with a custom decoder; rejected because the native components cover the need and the base change's D12 established the native ESP-IDF toolchain as the target.
- **Status:** Decided
- **Handoff note:** This choice costs per-burst RSSI, which is only exposed by `on_packet` in packet mode. That forecloses RSSI-based transmitter discrimination — see D9.

### D6 - Narrow the base capability's radio-neutral scope (2026-09-12)

- **Decision:** Modify the `lilygo-lora32-t3-v161-base-firmware` requirement "Radio-neutral peripheral scope" so it forbids only the SD card, user LED, battery ADC, and RF transmit. SX1276 receive and the OLED move into the new capability.
- **Why:** That requirement currently states the base firmware MUST NOT initialize or assign pins for the SX1276 or OLED. There is one board and therefore one YAML, so adding reception to it would violate a published requirement rather than extend it. The requirement must change explicitly, through a delta spec, not by drift.
- **Alternatives considered:** A second device YAML for the RF build; rejected because one board cannot run two firmwares and it would fork the connectivity baseline. Leave the base requirement untouched and let the conflict stand; rejected as knowingly shipping a spec the implementation contradicts.
- **Status:** Decided
- **Handoff note:** This makes `lilygo-lora32-t3-v161-base-firmware` a Modified Capability needing a `## MODIFIED Requirements` delta, alongside the new capability's `## ADDED Requirements`. Do not forget the delta — `openspec validate` currently fails this change for having no deltas at all.

### D7 - Bring the OLED into scope (2026-09-12)

- **Decision:** Enable the on-board SSD1306 over I2C (SDA 21, SCL 22) to display receive status locally, as Phase 3.
- **Why:** The value is a status surface that does not depend on Wi-Fi, Home Assistant, or the API being up — which is exactly when knowing whether the radio is hearing anything matters most. It also makes Phase 1 and 2 debuggable at the device instead of through logs.
- **Alternatives considered:** Leave the OLED out and rely on Home Assistant and ESPHome logs; rejected on user direction and because it makes local diagnosis harder. Give the OLED its own capability; rejected because it currently has exactly one consumer, so the boundary would be invented ahead of any second use.
- **Status:** Decided
- **Handoff note:** The OLED was an explicit non-goal of the base change. D6 covers the spec consequence.

### D8 - Home Assistant helpers stay the source of truth (2026-09-12)

- **Decision:** The existing `input_boolean`/`input_number`/`input_select` helpers keep owning state. The node becomes a second writer that corrects them; it does not hold state itself, and the template fan and light entities are not restructured.
- **Why:** The node cannot know state at boot, cannot observe the remote while it is offline, and would fight the Broadlink path if it tried to own state. Keeping the current architecture also avoids colliding with the in-flight `unified-control-scheme` and `seamless-room-lighting` changes.
- **Alternatives considered:** Make the ESPHome node the state holder and repoint the template entities at it; rejected for the boot and offline gaps above. Replace the template entities with native ESPHome fan and light entities; rejected as a much larger blast radius for no gain while transmit stays on the Broadlink.
- **Status:** Decided
- **Handoff note:** Because the Broadlink path also writes these helpers, both writers must be idempotent for the absolute commands. See D10 for where that breaks.

### D9 - Defer telling a Broadlink burst from a human press (2026-09-12)

- **Decision:** Do not attempt to distinguish a Home Assistant-originated transmission from someone using the physical remote in this change. The intended future answer is to give the Broadlink signal a Home Assistant origin signature.
- **Why:** The two are indistinguishable on air by construction — the Broadlink replays the waveform it learned from that same remote, so the RF carries nothing to separate them. Solving it properly means changing what the Broadlink transmits, which is its own piece of work and is not needed until Phase 4.
- **Alternatives considered:** Time-window correlation, classifying a burst as an acknowledgement if it lands within N ms of Home Assistant firing the Broadlink; viable but needs a tuning parameter that is wrong in both directions at the edges, and was deferred rather than rejected. Firmware-side gating where Home Assistant signals the node before transmitting; rejected as putting Home Assistant on the critical path of firmware behaviour with a race it can lose. RSSI discrimination; foreclosed by D5.
- **Status:** Proposed
- **Handoff note:** Phase 4 cannot be fully specified until this is decided. If it stalls, fall back to splitting Phase 4 into its own change per D3's alternative.

### D10 - Record relative brightness as an unresolved constraint (2026-09-12)

- **Decision:** Log the problem now; do not design brightness reconciliation before Phase 4.
- **Why:** `script.1779206777245` computes `delta = target − current` and sends `light_brightness_up`/`down` repeated `|delta|` times, so brightness is the one relative quantity among otherwise absolute commands. Two consequences follow. Observing a single step tells you only ±1 and requires already knowing the current value, so a missed burst desynchronises silently. Worse, the node will hear Home Assistant's own Broadlink transmissions: the script writes +3 to the helper and the receiver then hears three `up` bursts and adds +3 again, double-counting. The absolute commands (`fan_off`, `speed_1`–`speed_5`, `light_off`, `light_warm`/`neutral`/`cold`) have no such problem — both writers converge on the same value.
- **Alternatives considered:** Suppress the echo in firmware; rejected for now because the echo is the mechanism Phase 2 depends on for delivery confirmation, so it must not be discarded. Exclude brightness from state sync entirely; a live option for Phase 4, not yet chosen. Rework the Home Assistant script to absolute levels; out of scope here and may not be possible if the remote has no absolute brightness command.
- **Status:** Proposed
- **Handoff note:** Note that `light_warm`/`neutral`/`cold` serve double duty — `script.rf_light_toggle` turns the light on by sending the current temperature code, so hearing one means both "on" and "temperature is X".

### D11 - One change, one new capability, one modified capability (2026-09-12)

- **Decision:** Keep `add-lilygo-lora32-t3-v161-rf-gateway` as a single change introducing `lilygo-lora32-t3-v161-rf-receiver` and modifying `lilygo-lora32-t3-v161-base-firmware`.
- **Why:** All four phases serve one coherent capability, and the base change set the precedent that a long phased change runs to completion here. Naming the capability `-rf-receiver` rather than `-rf-gateway` keeps it honest about D1's receive-only scope; the change directory name differing from the capability name already has precedent in the base change.
- **Alternatives considered:** Split device-side from Home Assistant integration, and scope to Phase 1 only; both covered and rejected under D3. A separate capability for the OLED; rejected under D7.
- **Status:** Decided
- **Handoff note:** Phase 4's deliverables — the correcting automations — live in the Home Assistant instance's storage, not in this repository. Only the ESPHome YAML is version-controlled, so acceptance for that phase must be stated against observed behaviour rather than committed files.

### D12 - Defer the node's Home Assistant-facing entity surface (2026-09-12)

- **Decision:** Do not fix now whether received buttons surface as `event` entities, per-button binary sensors, text sensors, or raw Home Assistant events. Decide it when Phase 4 is reached.
- **Why:** The choice only binds at integration time, and Phases 1 to 3 need the node to recognise codes regardless of how it later publishes them. Committing early would mean designing an entity model against codes not yet captured.
- **Alternatives considered:** Settle on one `event` entity per remote with an `event_types` list now — the strongest candidate, since `event` is Home Assistant's purpose-built domain for stateless button presses, repeated identical presses still fire, and the platform is confirmed present in the installed ESPHome; deferred rather than rejected. Per-button binary sensors; weaker, around 28 entities of registry sprawl and awkward momentary semantics. A text sensor per remote; rejected on merit, since pressing `speed_3` twice leaves state unchanged and fires no trigger.
- **Status:** Proposed
- **Handoff note:** If Phase 4 proceeds, start from the `event`-entity option above; the analysis is done and only needs confirming against captured codes.

### D13 - Correct the light temperature command name and close the fact audit (2026-09-12)

- **Decision:** The third colour-temperature command is `light_cool`, not `light_cold`. D10's body and handoff note say `cold` and are left unedited per append-only discipline; this entry is authoritative. The Context facts block has been corrected in place, since it is reference material rather than decision history and a known-wrong command name there would actively mislead.
- **Why:** `light_cold` was never observed — it was inferred from the Study and Bedroom light templates, which name only `warm` and `neutral` explicitly and leave the third as an unnamed `else` branch. Reading `script.rf_light_temp` at handoff showed it derives `"warm" if ≤3500K else "neutral" if ≤4500K else "cool"` and transmits `light_{{ target }}`. A wrong command name would have propagated into the specs as a code to recognise, and failed on hardware for a reason that looks like a radio fault.
- **Alternatives considered:** Edit D10 in place; rejected because the log is append-only and the mistake is itself worth preserving — it shows exactly which facts were inferred rather than observed. Leave the Context block wrong and rely on this entry; rejected because Context is explicitly the "do not re-derive" section, so an error there has the longest reach.
- **Status:** Decided
- **Handoff note:** Three findings closed the audit alongside this correction, all now in Context: the `rf.`/`ir.` Broadlink device-prefix convention, which confirms the third fan (`living_room_fan`) is infrared and correctly out of scope; the Broadlink send parameters (`num_repeats: 1`, `delay_secs: 0.4`), which bound any Phase 2 acknowledgement window; and a negative result — none of the three Broadlink entities exposes frequency metadata, so D4 must be settled on hardware. Note also that `script.rf_light_temp` writes the temperature helper even when it transmits nothing, so a Home Assistant/device temperature divergence already exists independently of this change. Generalisation for whoever picks this up: command names in this system come from the scripts, not the template entities — the templates only read helpers.
