# Step-by-step Broadlink button verification

Read [decisions.md](decisions.md) first. D71 corrects the sweep to the updated Broadlink values only. Physical remotes remain accepted. Existing codes come from [rf-codebook.md](rf-codebook.md); no captures, RF logs or relearning are involved.

## Current step

**Sweep closed under D87.** All 13 Study commands and Bedroom FAN OFF/SPEED 1 are verified or explicitly accepted (15/26). The other 11 Bedroom checks are skipped on user instruction. Proceed to Home Assistant integration; no further sweep commands are pending. Calibration remains separate.

Only one command is tested at a time: Study Broadlink (1–13), then Bedroom Broadlink (14–26). The assistant sends each command when that step is reached. Do not ask the user to operate the physical remotes. D84 separates later calibration from this button sweep; do not insert calibration trials between its remaining commands.

For each single send, request one new logical OLED event with the expected room/button and `BL` source. Tell the user to reply with its E-number if that expected result is present, or describe a mismatch. Under this explicit response contract an E-number confirms the stated expected event; do not ask those same details again. Record appliance observations separately when reported, especially brightness changes. An already-off fan/light or a brightness endpoint can make an action visibly unchanged. RAW and matched-frame counts are not press counts. Wait for the event page; do not resend because the diagnostic page is currently visible.

## All-button matrix

Each cell records the step result and OLED event ID. All 26 values are already updated in HA; live storage was rechecked under D71/D72. Pending below means physical verification of that Broadlink command, not a missing code update. Earlier accepted evidence remains in the decision log.

| Order | Stored command | Expected OLED button | Study Broadlink | Bedroom Broadlink |
| --- | --- | --- | --- | --- |
| 1 | `fan_off` | FAN OFF | Pass — E031 / BL | Pass — user verified |
| 2 | `speed_1` | SPEED 1 | Pass — user verified / BL; E-number not supplied | Pass — user verified / BL |
| 3 | `speed_2` | SPEED 2 | Pass — user verified / BL | Skipped — user instruction |
| 4 | `speed_3` | SPEED 3 | Pass — user verified / BL | Skipped — user instruction |
| 5 | `speed_4` | SPEED 4 | Pass — user verified / BL | Skipped — user instruction |
| 6 | `speed_5` | SPEED 5 | Pass — user verified / BL | Skipped — user instruction |
| 7 | `fan_fr` | DIRECTION | Pass — user verified / BL | Skipped — user instruction |
| 8 | `light_off` | LIGHT OFF | Pass — user verified / BL | Skipped — user instruction |
| 9 | `light_warm` | LIGHT WARM | Pass — user verified / BL | Skipped — user instruction |
| 10 | `light_neutral` | LIGHT NEUTRAL | Pass — user verified / BL | Skipped — user instruction |
| 11 | `light_cool` | LIGHT COOL | Pass — user verified / BL | Skipped — user instruction |
| 12 | `light_brightness_up` | BRIGHTNESS UP | Pass — user accepted light + OLED reception | Skipped — user instruction |
| 13 | `light_brightness_down` | BRIGHTNESS DOWN | Pass — user verified / BL | Skipped — user instruction |

## Brightness calibration

The user selected calibrated tracking. D84 accepts light/OLED reception as sufficient for the button checks and leaves calibration for integration. D89 confirms the existing HA brightness helper range is 1–7; script level 0 means light off. D94–D97 confirm both visible maxima and record each as level 7 with tracking enabled. Full effective step and echo behavior remain pending. Calibration is separate from the closed reception sweep. Broadlink echoes must not be added again to the script's own brightness change.

| Evidence | Study | Bedroom |
| --- | --- | --- |
| Visible starting endpoint | Maximum confirmed: user "max brightness set" (D94) | Maximum confirmed: user "Bedroom is set to max brightness" (D96) |
| Effective upward steps across full range | Pending | Pending |
| Effective downward steps across full range | Pending | Pending |
| One logical BL event per Broadlink step | Pending | Pending |
| Endpoint behavior / clamping | Pending | Pending |
| Confirmed calibration endpoint and initial HA value | Confirmed maximum mapped to 7; full step range not yet verified | Confirmed maximum mapped to 7; full step range not yet verified |
| HA calibration write | Level 7 and flag on verified at 22:25:40 +0800 (D95) | Level 7 and flag on verified at 22:27:55 +0800 (D97) |
| Subsequent live correction | Existing HA script sent three DOWN commands for 7→4; all three BL echoes caused no duplicate helper writes (D98) | One unmarked DOWN event decremented 7→6; calibration flag stayed on (D98) |
| Current HA brightness at D98 readback | 4; from the independent HA script | 6; from the unmarked step |

Calibration establishes a known starting point. This record does not claim recovery of missed transmissions or appliance acknowledgement from OLED reception.

## Observations

| Step | User report | Recorded evidence | Status |
| --- | --- | --- | --- |
| Retired mistaken physical FAN OFF step | `E017` | OLED event ID E017 was reported in response to the physical-remote instruction; no Broadlink send was made for that step | Closed under D71; no further details requested, not a Broadlink result |
| 1 — Study Broadlink FAN OFF | `E031` | Under the stated response contract, one new STUDY / FAN OFF / BL event was confirmed. No unexpected fan behavior was reported; independent fan-state observation was not supplied. | OLED pass |
| 2 — Study Broadlink SPEED 1 | `Try again`, then `verified. next` | Initial send and one requested resend completed. The user verified the latest expected STUDY / SPEED 1 / BL result; E-number not supplied. The resend request alone does not establish failure of the first send. | OLED pass |
| 3 — Study Broadlink SPEED 2 | `verified. next` | User confirmed the expected new STUDY / SPEED 2 / BL event. E-number not supplied. | OLED pass |
| 4 — Study Broadlink SPEED 3 | `yes, next` | User confirmed the expected new STUDY / SPEED 3 / BL event. E-number not supplied. | OLED pass |
| 5 — Study Broadlink SPEED 4 | `yes, next` | User confirmed the expected new STUDY / SPEED 4 / BL event. E-number not supplied. | OLED pass |
| 6 — Study Broadlink SPEED 5 | `yes, next` | User confirmed the expected new STUDY / SPEED 5 / BL event. E-number not supplied. | OLED pass |
| 7 — Study Broadlink DIRECTION | `yes, next` | User confirmed the expected new STUDY / DIRECTION / BL event. E-number not supplied. | OLED pass |
| 8 — Study Broadlink LIGHT OFF | `yes, next` | User confirmed the expected new STUDY / LIGHT OFF / BL event. E-number not supplied. | OLED pass |
| 9 — Study Broadlink LIGHT WARM | `yes, next` | User confirmed the expected new STUDY / LIGHT WARM / BL event. E-number not supplied. | OLED pass |
| 10 — Study Broadlink LIGHT NEUTRAL | `yes, next` | User confirmed the expected new STUDY / LIGHT NEUTRAL / BL event. E-number not supplied. | OLED pass |
| 11 — Study Broadlink LIGHT COOL | `yes, next` | User confirmed the expected new STUDY / LIGHT COOL / BL event. E-number not supplied. | OLED pass |
| 12 — Study Broadlink BRIGHTNESS UP | `yes. Light received the event. That's good enough. OLED shows event received.` | User confirmed light and OLED reception and explicitly accepted this button check. No brightness delta, endpoint or calibrated level was supplied; do not request those again as a gate for this pass. | User-accepted pass |
| 13 — Study Broadlink BRIGHTNESS DOWN | `yes, next` | User confirmed the expected STUDY / BRIGHTNESS DOWN / BL result before the interrupted turn. No calibration anchor inferred. | OLED pass |
| 14 — Bedroom Broadlink FAN OFF | `Received both. Continue` | User accepted the Bedroom FAN OFF result after the requested resend. No E-number supplied; no repeat confirmation required. The preceding interrupted attempt has no completed tool result. | User-verified pass |
| 15 — Bedroom Broadlink SPEED 1 | `Yes -- skip the rest and continue to the next step` | User verified the expected BEDROOM / SPEED 1 / BL result and explicitly skipped the remaining sweep. | OLED pass |

The sweep is closed under D87. Preserve these results without sending skipped commands. D91's publication firmware is now installed; the D66 full footer-only code rollout remains unchanged.
