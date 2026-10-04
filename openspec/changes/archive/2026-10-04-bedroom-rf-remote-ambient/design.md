## Context

The existing LilyGo receiver publishes finalized bedroom RF occurrences on `event.study_lilygo_lora32_t3_v1_6_1_bedroom_rf_command`. The accepted `automation.lilygo_bedroom_rf_helper_correction` consumes those occurrences and updates helpers behind `light.bedroom_light` and `fan.bedroom_fan`. Physical RF already reaches the Mistral directly, so calling its virtual light again would retransmit.

The corrected target is `light.bedroom_ambient`, verified on 2026-10-04 as a two-bulb Yeelight group with brightness and 2700–6500 K support. Its members and concrete HA access path are retained in [decisions.md](decisions.md). The existing wall-light automation has broader effects, including spotlights and a switch. D9 resolves adaptation to `switch.bedroom_ambient_adaptive_lighting_bedroom_ambient`, whose two tracked members are precisely the ambient bulbs and whose manual reset is one hour. The generic Bedrooms profile targets only the Mistral light.

## Goals / Non-Goals

**Goals:** Add ambient power, white-temperature and relative-brightness actions for physical bedroom remote observations; honor explicit selections under Adaptive Lighting; preserve ordered occurrences and the accepted Mistral path.

**Non-Goals:** Spotlight controls, other rooms, ambient actions from marked/mixed app/Broadlink traffic, new gestures, firmware changes, RF transmission/acquisition, Mistral recalibration or predecessor re-verification.

## Decisions

### Independent event consumer (D2, D3, D6)

Create a separate automation with `mode: queued`, max 50 and ten stored traces. Trigger on the existing bedroom event state. Validate freshness with the predecessor's established guard: both state objects exist and the new state's parsed timestamp exceeds `trigger.from_state.last_changed`. Extract `event_type` from `trigger.to_state` for that occurrence, and allow exactly the six eligible `_unmarked` types.

This retains identical distinct presses without reading later mutable event attributes. A separate consumer keeps ambient failures independent of helper correction. Helper-state triggers would admit app writes and miss commands that leave helpers unchanged; wall-automation reuse would exceed the corrected scope. No synthetic events are generated for testing on the live receiver entity.

### Ambient light mapping (D1, D4, D5)

| Received unmarked command | Added ambient action |
|---|---|
| `light_off` | Explicit `light.turn_off` |
| `light_warm` | `light.turn_on`, `color_temp_kelvin: 2700` |
| `light_neutral` | `light.turn_on`, `color_temp_kelvin: 4000` |
| `light_cool` | `light.turn_on`, `color_temp_kelvin: 6500` |
| `light_brightness_up` | Current ambient percentage +10, clamp 1–100 |
| `light_brightness_down` | Current ambient percentage -10, clamp 1–100 |

Use the explicit `light.bedroom_ambient` entity target. Temperature actions omit brightness so normal current/remembered brightness applies. Relative steps require the group to be on with numeric brightness, using HA's 0–255 representation to calculate a rounded bounded request. Read that value at execution time, independently of the Mistral calibration flag. A group action treats the member bulbs as one control unit; it is not a per-bulb delta.

Brightness actions use zero transition and one guarded state/brightness snapshot. The eligibility condition is in the parent action sequence, because a failed condition inside an if/choose branch does not stop the parent. D15 removes all added state-confirmation waits following the user's direction to keep event-to-group mapping simple. Native service calls remain ordered; subsequent relative steps use the latest reported group brightness. No retries, workers or persistent brightness helpers are introduced. OFF is idempotent; brightness down never substitutes for OFF.

### Scoped manual takeover (D4–D6, D9)

Before temperature/on and eligible brightness actions, call the installed `adaptive_lighting.set_manual_control` service with `entity_id: switch.bedroom_ambient_adaptive_lighting_bedroom_ambient`, the explicit two ambient member IDs and `manual_control: true`. D9 verified installed service fields and member tracking. Do not copy the Flutter room-wide pause action, which omits a light list, or disable the whole profile.

Retain the profile's usual reset and timeout settings. If adaptation is disabled, light actions still work. OFF does not establish a new manual hold; existing off/reset behavior applies. [Adaptive Lighting's own documentation](https://github.com/basnijholt/adaptive-lighting#regain-manual-control) describes scoped takeover and normal resets; installed behavior, rather than the latest upstream version, determines the actual API contract.

### Reviewable configuration and scoped rollout (D7)

Store automation JSON and meaningful mapping/event tests under a repository `home_assistant/` directory during apply. Use the existing configured HA tool connection and configuration API to validate/create the automation. Keep private connection data, live backups and raw staging ignored. No dependency or Flutter build change is needed.

## Risks / Trade-offs

- A lost Broadlink footer can leave an app send unmarked → filter finalized source types, preserve the existing uncertainty contract and do not promise perfect physical-origin detection.
- HA state reports may lag relative requests → serialize native calls and read a guarded current snapshot; distinguish a requested value from physical acceptance. Do not invent current brightness when reports are absent. No additional member-report waits are used (D15).
- Installed Xiaomi bulb property writes can time out → this can delay queued native calls even without added waits. Do not claim the transport or physical responsiveness is fixed by simplifying the automation.
- Adaptive Lighting may track group members or have different takeover/reset behavior → inspect the installed profile, verify ambient-only takeover and check that temperature selections survive adaptation without affecting spotlights.
- RF/HA delivery remains dependent on reception and connectivity → use existing availability/stale-state guards; do not queue offline work for reconnect or claim simultaneous physical execution.

## Migration Plan

1. Re-read this log and current event/target/profile schemas; search consumers of ambient and its members for interactions. Preserve existing correction/wall-automation configurations as evidence of the boundary.
2. Prepare repository configuration and automated checks, including fresh/restored events, all six commands, excluded traffic, bounds, repeated presses and scoped takeover.
3. Validate and create the new automation through HA's configuration API. Record the returned ID and read back the actual configuration and enabled state.
4. Validate only this added ambient behavior using existing reception, service/trace evidence and narrowly scoped user observations. Check spotlight isolation and Adaptive Lighting behavior. Record observed, user-accepted and unobserved results separately.
5. Roll back by disabling/removing the new automation and clearing only manual takeover state it introduced. Existing Mistral/wall controls and firmware remain available throughout.

## Open Questions

No product decisions remain open. D9 resolved adaptation targets and fields; D15 supersedes D10's confirmation waits with direct native group calls. The paced physical sweep is retired. Actual response timing remains unaccepted; do not request slower presses, relearn codes or repeat old receiver acceptance.
