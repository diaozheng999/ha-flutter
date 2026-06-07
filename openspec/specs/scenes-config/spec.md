# Scenes Config

## Purpose

Defines the Scenes & Config screen: scene tile grid, configuration mode selector, and adaptive lighting controls.

## Requirements

### Requirement: Scenes and config screen layout
The app SHALL provide a `ScenesConfigScreen` as the fourth bottom-navigation destination (icon: `Icons.auto_awesome_outlined`). The screen SHALL contain, in order: a scene tile grid, a configuration mode selector, and a per-room adaptive lighting section.

#### Scenario: Scenes tab navigates to scenes screen
- **WHEN** the user taps the Scenes tab
- **THEN** `ScenesConfigScreen` SHALL render with all three sections visible

---

### Requirement: Scene tile grid
The scenes screen SHALL display a 2-column grid of scene tiles, one per `scene.*` entity. Each tile SHALL show the scene's `friendly_name` and a fixed icon (no icon customisation in v1). Tapping a tile SHALL call `scene.turn_on` with the scene's `entity_id`. A brief ripple and a green checkmark animation SHALL confirm the activation. No deactivation action is available (scenes are one-shot). The grid SHALL display all `scene.*` entities: `scene.daylight`, `scene.all_off`, `scene.living_room_fan_spd_3`, and any additional scenes present in the HA instance.

#### Scenario: Scene tile calls turn_on
- **WHEN** the user taps the "Daylight" tile
- **THEN** the app SHALL call `scene.turn_on` with `entity_id: scene.daylight` and display a green checkmark for 1.5 s

#### Scenario: All scenes rendered
- **WHEN** the scenes screen is displayed and HA has 5 scene entities
- **THEN** 5 tiles SHALL be rendered in the grid (not hardcoded — read from subscribed `scene.*` states)

---

### Requirement: Configuration mode selector
The scenes screen SHALL display a selector for `input_select.configuration` showing the current option and allowing the user to choose from the available options list. The selector SHALL use a segmented-button-style control (for ≤ 4 options) or a bottom-sheet picker (for > 4 options). Selecting an option SHALL call `input_select.select_option`.

#### Scenario: Current option highlighted
- **WHEN** `input_select.configuration` state is "Home"
- **THEN** the "Home" option SHALL be highlighted in the selector

#### Scenario: Selecting an option calls select_option
- **WHEN** the user selects a different option from the selector
- **THEN** the app SHALL call `input_select.select_option` with the chosen option value

---

### Requirement: Adaptive lighting controls
The scenes screen SHALL display an adaptive lighting section with one row per room that has an adaptive lighting switch. Each row SHALL show: room name, an on/off toggle for the adaptive lighting switch, and a "Pause 1h" button. Toggling SHALL call `switch.turn_on` or `switch.turn_off` on the corresponding switch entity. "Pause 1h" SHALL call `adaptive_lighting.set_manual_control` with `manual_control: true`. The "Pause 1h" button SHALL only be active when the switch is on; it SHALL be disabled (40% opacity) when the switch is off.

Adaptive lighting entities by room:
- Living Room: `switch.living_room_kitchen_adaptive_lighting_main`
- Kitchen: `switch.adaptive_lighting_kitchen_lights`
- Bedroom: `switch.bedrooms_adaptive_lighting_bedrooms`
- Study: `switch.study_lights_adaptive_lighting_study_lights`

#### Scenario: Toggle adaptive lighting off
- **WHEN** the user toggles the Living Room adaptive lighting row to off
- **THEN** the app SHALL call `switch.turn_off` with `entity_id: switch.living_room_kitchen_adaptive_lighting_main`

#### Scenario: Pause 1h calls set_manual_control
- **WHEN** the user taps "Pause 1h" on the Bedroom row (and the switch is on)
- **THEN** the app SHALL call `adaptive_lighting.set_manual_control` with `entity_id: switch.bedrooms_adaptive_lighting_bedrooms` and `manual_control: true`

#### Scenario: Pause button disabled when switch is off
- **WHEN** the Kitchen adaptive lighting switch is off
- **THEN** the "Pause 1h" button for Kitchen SHALL be rendered at 40% opacity and SHALL NOT be tappable
