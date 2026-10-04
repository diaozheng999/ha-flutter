## Why

The bedroom Mistral RF remote already controls its fan/light and publishes recognized commands to Home Assistant, but its light buttons do not control the room's ambient lighting. Extend those familiar buttons to the bedroom ambient group so one physical remote operates both lights together.

## What Changes

- React to fresh, finalized unmarked bedroom light commands using the existing LilyGo event entity.
- Target only `light.bedroom_ambient`: OFF turns it off; warm, neutral and cool turn it on at 2700, 4000 and 6500 K.
- Apply brightness up/down as +/-10 percentage points from ambient's current brightness while on, clamped to 1–100%.
- Give explicit remote selections precedence over Adaptive Lighting for ambient only, retaining the existing reset policy.
- Preserve Mistral helper correction, direct physical-remote behavior, app/Broadlink controls, wall-button behavior and spotlight controls. Do not retransmit received RF commands.

## Capabilities

### New Capabilities

- `bedroom-rf-ambient-control`: Source-filtered bedroom RF light-button actions for the ambient group, including power, color temperature, bounded relative brightness and scoped Adaptive Lighting takeover.

### Modified Capabilities

None. Existing RF publication and helper-correction requirements remain unchanged; the new capability consumes their established events.

## Impact

- Home Assistant: one new queued automation and ambient-scoped Adaptive Lighting service calls through the configuration API. Existing event entity: `event.study_lilygo_lora32_t3_v1_6_1_bedroom_rf_command`.
- Configuration and validation artifacts should be kept in the repository so the live automation remains reviewable and reproducible; private sessions/backups remain ignored.
- No Flutter feature changes, new hardware, RF acquisition, learned-code edits or firmware changes are required.
- Physical-only filtering uses absence of the Broadlink footer (`unmarked`); a lost marker can misclassify a Broadlink send. Preserve that evidence boundary and do not claim guaranteed transmitter identification.
