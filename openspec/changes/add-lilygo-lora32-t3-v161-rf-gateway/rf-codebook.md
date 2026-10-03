# Existing Mistral RF codebook

Read [decisions.md](decisions.md) first. D29–D33 require reuse of these existing codes and verification on the physical OLED. Do not acquire or relearn RF codes, run timed recording sessions, or ask the user where this data lives.

## Provenance

- Existing Home Assistant storage: `root@homeassistant.local:/config/.storage/broadlink_remote_348e892deef9_codes`, under `data["rf.study_fan"]` and `data["rf.bedroom_fan"]`. Access is read-only SSH using the established host key and credentials.
- Predecessor task: **Add ESPHome node configuration**, `019f7914-88b9-7ba0-8839-cd1d3823337c`, final turn `01a0759f-bc2f-7111-a18f-750379c09f92` on 2026-09-06. It already decoded the complete command table.
- The same storage was read again on 2026-09-12, and all 26 commands reproduced that table across 101 complete repeated frames. This was offline processing of existing data, with no RF acquisition.
- Ignored local references: `esphome/.esphome/existing-broadlink-rf-codes.json`, `existing-rf-codebook.json`, and `existing-rf-frames.json` in that directory. The table below preserves the reusable result independently of those local files.

## Frame and matching contract

**D57 transport correction:** Every retained packet starts `B1 C0`, followed by a two-byte little-endian length counting from byte 4. Bytes 4–7 are transport metadata and MUST be preserved verbatim; the waveform begins at byte 8. Those four-byte little-endian values are 433700–433980, consistent with carrier frequency in kHz, but this interpretation is inferred from the original data. `C0` is preserved, not treated as 192 repeats. The earlier four-byte-header interpretation consumed metadata and the first waveform pair as fictitious timing values and caused the failed D55 marker packet. It must not be reused.

Actual waveform timings use one byte or a zero prefix followed by a two-byte big-endian value. The [generic Broadlink protocol reference](https://github.com/mjg59/python-broadlink/blob/master/protocol.md) gives ticks near 30.5 microseconds; offline validation uses `ticks * 8192 / 269`. Its generic four-byte header does not describe the retained B1 C0 subformat. D38 separately establishes successful live reception at 433.92 MHz.

Each complete reference frame supplies 29 alternating mark/space pairs followed by a terminal positive mark. Short-mark/long-space is zero; long-mark/short-space is one. The resulting word contains an 8-bit unit ID and a 21-bit command. Study is `0x21`, Bedroom is `0xCB`; corresponding commands share the same payload. There are 2–8 complete repeated frames per stored command. This does not establish how many physical presses occurred.

Across the 101 frames, short timings occupy 6–14 ticks and long timings 34–43 ticks. The terminal mark may be short or long: 52 are 11–13 ticks and 49 are 34–36 ticks. It is not an additional complete pulse-pair bit.

The firmware accepts short timings of 150–600 microseconds and long timings of 800–1500 microseconds. D36 normalizes either input polarity while requiring alternating levels, the terminal mark, and boundaries at the input edge or a normalized negative gap of at least 3 ms. The receiver ends input at 4 ms of unchanged level, separating the original stored frame gaps (approximately 4.75–6.52 ms). It matches the full known unit and command, rejecting incomplete frames, malformed timing and unknown words. These initial tolerances cover the stored data; physical OLED verification remains necessary for live reception.

## Room and button mapping

| Existing command | OLED button | 21-bit payload | Study 29-bit word | Bedroom 29-bit word |
| --- | --- | --- | --- | --- |
| `fan_off` | FAN OFF | `16E50B` | `0436E50B` | `1976E50B` |
| `speed_1` | SPEED 1 | `16E5A9` | `0436E5A9` | `1976E5A9` |
| `speed_2` | SPEED 2 | `16E589` | `0436E589` | `1976E589` |
| `speed_3` | SPEED 3 | `16E56A` | `0436E56A` | `1976E56A` |
| `speed_4` | SPEED 4 | `16E54A` | `0436E54A` | `1976E54A` |
| `speed_5` | SPEED 5 | `16E5E8` | `0436E5E8` | `1976E5E8` |
| `fan_fr` | DIRECTION | `16E5C8` | `0436E5C8` | `1976E5C8` |
| `light_off` | LIGHT OFF | `16E591` | `0436E591` | `1976E591` |
| `light_warm` | LIGHT WARM | `16E572` | `0436E572` | `1976E572` |
| `light_neutral` | LIGHT NEUTRAL | `16E5B1` | `0436E5B1` | `1976E5B1` |
| `light_cool` | LIGHT COOL | `16E5D0` | `0436E5D0` | `1976E5D0` |
| `light_brightness_up` | BRIGHTNESS UP | `16E533` | `0436E533` | `1976E533` |
| `light_brightness_down` | BRIGHTNESS DOWN | `16E4F4` | `0436E4F4` | `1976E4F4` |

`fan_fr` is recognized locally without introducing a Home Assistant direction helper. Brightness recognition does not resolve D10's correction policy.

## OLED behavior and verification

The screen shows ROOM, BTN, receiver/decode status, RAW input count, OK matched-frame count, age, uptime/heartbeat, and Wi-Fi/API states. Startup labels are NONE. Until the first match, unmatched input shows UNKNOWN. A complete known frame stores its actual mapped room/button; D36 preserves that last match across subsequent unmatched input and shows BTN AGE so an older result is explicit. Before any match, LAST reports input age. OK counts complete matched frames, not presses. This prevents a trailing fragment from erasing a recognized button before the one-second redraw.

RX reports MATCH with the decoded bit count, SHORT with input length, TIMING with the furthest decoded bit count, FRAMING, NO FRAME, or CODE followed by an unrecognized 29-bit word in hexadecimal. Hardware ERROR/STARTING takes precedence. These concise on-screen results support direct OLED diagnosis without raw timing dumps, recording sessions, or network-dependent verification.

Verify physical remotes first, followed by Broadlink replays for both rooms. D38 records the user's confirmation that both physical remotes decode correctly, establishing 433.92 MHz for this receiver. D40–D41 confirm separate Broadlink checks for Study SPEED 1 and Bedroom FAN OFF. Record visible room/button results and actual conditions; offline decoding, deployment and service-call success do not themselves establish reception. D9/D10/D12/D15 remain open. Display-lag tuning is deferred at the user's request; the current refresh interval is one second.

## Offline validation

On 2026-09-12, the actual `on_raw` C++ lambda was extracted from the canonical YAML, compiled with MSVC C++17, and passed 437 checks. These cover all 101 existing frames and all 26 room/command combinations at nominal timing and ±10%, input-edge and gap framing, repeated frames, startup labels, counter/timestamp updates, every truncated prefix, invalid timings and polarity, and unknown unit/command words. Unknown input after a match correctly replaces the previous labels.

The native regression test is `esphome/tests/mistral_decoder_test.cpp` with 101 existing valid reference frames in `mistral_existing_frames.h`. D57 corrects `mistral_existing_packets.h` to retain all 26 exact original byte packets and independently decoded waveforms from byte 8, excluding transport metadata. D63 packet tests compare immutable metadata directly with those original bytes and assert exact restoration, unchanged native pulse boundaries and zero added command-start or total duration for the footer-only format. From `esphome/tests` in an x64 Visual Studio developer command prompt, run `nmake /f Makefile test`. The Makefile extracts the actual YAML lambda into an ignored include, compiles the C++ tests and runs them directly. No device, network or Python test wrapper is used.

After the user reported UNKNOWN for multiple buttons with RAW increasing only around presses, D36 expanded validation to 977 passing checks: both polarities, complete stored transmissions, input batches delimited at the configured 4 ms idle, retained names after later unmatched callbacks, and short-input/unknown-word diagnostics. The earlier 437 checks covered normalized reference frames and did not establish hardware recognition. D38 subsequently confirmed that the revised decoder works for both physical remotes; D40–D41 confirmed separate Broadlink replays on the OLED.

## Physical verification recorded on 2026-09-13

| Source | User-confirmed OLED result | Evidence |
| --- | --- | --- |
| Study physical remote | Decoding works | D38; user's confirmation covers both remotes, without an exhaustive per-button matrix |
| Bedroom physical remote | Decoding works | D38 |
| Broadlink `rf.study_fan` | STUDY / SPEED 1 with fresh match feedback | D40 |
| Broadlink `rf.bedroom_fan` | BEDROOM / FAN OFF with fresh match feedback | D41 |
| Historical node-only Wi-Fi outage trial | Further verification retired by user direction | D42–D43 record the trial/restoration; D48 removes it as a progression gate without inventing an OLED observation |

Both ordered source-registration checks pass at 433.92 MHz with D37's firmware. D48 directs new verification to separate/interleaved events and an on-air Broadlink prefix. Basic reception and Wi-Fi-outage checks are not to be repeated. These existing samples do not establish appliance execution or source attribution; the prefix's new behavior requires its own evidence. D49 preserves the fresh original HA storage snapshot for reversible code transformation.
