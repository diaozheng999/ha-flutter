# Decisions

> Append entries as decisions arise. Never rewrite history. Read this file first when taking over.

## Context

- **Change:** Extend the bedroom physical Mistral RF remote's light controls to the bedroom ambient light group.
- **Started:** 2026-10-04 (Asia/Singapore).
- **Phase:** Complete by explicit user acceptance and archived on 2026-10-04; all twelve tasks closed and main specs synchronized. Simplified automation remains deployed and enabled, exact readback confirmed. Unmeasured physical timing and earlier bulb-integration timeouts are historical limitations, not active blockers.
- **Related:** [RF gateway handoff](../2026-10-03-add-lilygo-lora32-t3-v161-rf-gateway/decisions.md), especially D88-D90 and D100-D102; [receiver spec](../../../specs/lilygo-lora32-t3-v161-rf-receiver/spec.md).
- **Access:** The existing ignored helper `esphome/.esphome/Invoke-RfHaTool.ps1` and its session file provide read-only Home Assistant access with network escalation. Do not print/commit the private session URL or headers. Tool schemas are retained in `esphome/.esphome/ha-tools-schema.json`.
- **Live evidence, Oct 4:** `ha_config_get_automation` returned `automation.lilygo_bedroom_rf_helper_correction` (ID `1789394931180`, hash `5a7f1c29976a4f7f`), queued/max 50, triggered by `event.study_lilygo_lora32_t3_v1_6_1_bedroom_rf_command`. It preserves per-occurrence snapshots and rejects stale/restored timestamps. `automation.toggle_bedroom_light` (ID `1779184799892`, hash `0115cc473079a098`) calls the virtual Mistral light and turns ambient on; its off branch targets ambient and spotlight plus a switch. Reusing that wall action would broaden the requested target.
- **Prior acceptance:** The RF gateway is complete by explicit acceptance (D102). Its unmeasured physical brightness limits and skipped checks are historical limitations, not blockers for this change.

## Decision Log

### D1 - Couple the remote's light controls (2026-10-04)

- **Decision:** User selected light buttons controlling the Mistral light and the added lighting target together, then selected all light controls rather than power only. Added lighting brightness changes from its own level.
- **Why:** The physical remote already directly drives the Mistral; HA can add room lighting actions on reception.
- **Alternatives considered:** Independent gestures or power-only coupling; user selected the full existing light-button mapping.
- **Status:** Decided; original spotlight target superseded by D3.
- **Handoff note:** Preserve native Mistral behavior. Do not send its received commands back through the virtual light or Broadlink.

### D2 - Restrict added actions to physical-remote observations (2026-10-04)

- **Decision:** User selected physical remote only, excluding app/Broadlink commands from the added lighting behavior.
- **Why:** App controls retain their current individual-appliance scope and marked RF echoes must not add ambient actions.
- **Alternatives considered:** Extend the coupling to app/Broadlink traffic; user rejected that option.
- **Status:** Decided.
- **Handoff note:** Use finalized `_unmarked` occurrences only. Unmarked is evidence of no received marker, not proof of human origin; missing footer evidence remains a source-classification limitation.

### D3 - Correct the target to the ambient group (2026-10-04)

- **Decision:** Apply the user's correction: "the control should only be about the ambient light group; NOT the spotlights". Target `light.bedroom_ambient`; rename the new scaffold to `bedroom-rf-remote-ambient` and retire all spotlight work from this change.
- **Why:** The latest explicit user scope overrides the original request and earlier target assumptions.
- **Alternatives considered:** Include both groups or continue spotlight controls; both conflict with the correction.
- **Status:** Decided; supersedes D1's target only.
- **Handoff note:** Inspect ambient members/capabilities next. Preserve prior answers on full light controls and physical-remote-only source. No spotlight service calls or wall-automation reuse. This is a user redirection, not evidence of a failed RF path.

### D4 - Ground the corrected target and preserve adaptive-lighting scope (2026-10-04)

- **Decision:** Use the verified ambient group. Pending user confirmation, propose 2700/4000/6500 K selections, relative 10-percentage-point brightness steps while on, a 1–100% floor/ceiling, and ambient-only manual takeover of Adaptive Lighting.
- **Why:** `ha_get_state` on Oct 4 returned `light.bedroom_ambient` with members `light.yeelink_sg_457031179_colorc_s_2` and `light.yeelink_sg_457037035_colorc_s_2`, `color_temp`/`rgb` support and Kelvin bounds 2700–6500. The group was off with null brightness/temperature attributes. `switch.bedrooms_adaptive_lighting_bedrooms` was on with no manually controlled lights, so explicit controls may otherwise compete with adaptation. Group brightness is independent of the calibrated 1–7 Mistral helper.
- **Alternatives considered:** Copy the Mistral helper level or gate ambient changes on its calibration flag; neither describes the Yeelight group's reported state. Pause the entire Adaptive Lighting profile; this would affect lighting outside the corrected scope. Let brightness down turn the group off; reserve power-off for the OFF button instead.
- **Status:** Proposed; waiting for the final mapping answer.
- **Handoff note:** Verify the installed Adaptive Lighting profile's membership, group expansion and service schema before implementation; mark only ambient or its resolved tracked members. The public [manual-control documentation](https://github.com/basnijholt/adaptive-lighting#regain-manual-control) says scoped light targets can be marked and normal reset behavior applies; installed behavior must be checked. Native [light actions](https://www.home-assistant.io/actions/light.turn_on/) support brightness and color-temperature requests. No manual takeover or light action has been executed.

### D5 - Confirm the complete ambient mapping (2026-10-04)

- **Decision:** User confirmed D4's mapping and shared understanding: OFF turns ambient off; warm/neutral/cool turn it on at 2700/4000/6500 K; brightness buttons apply +/-10 percentage points from ambient's own current level while on, clamped to 1–100%; explicit manual choices override Adaptive Lighting only for ambient.
- **Why:** This resolves the final interaction choices without changing native remote behavior or introducing new gestures.
- **Alternatives considered:** Power-only control, helper-level mirroring, app/Broadlink coupling, brightness-triggered turn-on and room-wide adaptation pause; excluded by the agreed scope.
- **Status:** Decided; confirms D4's proposed behavior.
- **Handoff note:** Draft all planning artifacts now. Ignore brightness when ambient is off, unknown/unavailable or has no numeric brightness. Temperature selections preserve ambient brightness (including normal remembered turn-on brightness) rather than assigning the Mistral helper's level. Shared understanding authorizes the proposal; this turn does not deploy it.

### D6 - Add an independent queued consumer of native events (2026-10-04)

- **Decision:** Add one new queued ambient-control automation, leaving the existing helper-correction and wall automations untouched. Snapshot `event_type` from each `trigger.to_state`; reproduce the established fresh-timestamp guard and allow exactly the six `_unmarked` light command types. Use native light actions with explicit entity targets, and ambient-only Adaptive Lighting manual control before on/brightness actions. Treat OFF as idempotent. Read ambient brightness at action execution; serialize relative steps and use a bounded state-report wait where needed for distinct rapid presses.
- **Why:** Added fixture side effects must not block or change the accepted Mistral state-correction path. Trigger snapshots preserve queued occurrences; current mutable event attributes can point to a later press. Queueing avoids concurrent relative reads; reported state must catch up before another calculation.
- **Alternatives considered:** Extend the existing correction automation (couples failures), invoke the wall action (also targets spotlights and a switch), react to helper-state changes (misses repeated commands and admits app writes), or use toggles (unsafe on repeated OFF). Rework firmware/source classification; unnecessary for this scoped capability.
- **Status:** Decided.
- **Handoff note:** Use `mode: queued`, bounded max 50 and stored traces 10, consistent with the existing event consumer. Skip unavailable target states; no retries or deferred replay when HA/receiver reconnects. A group action controls its members together, including bringing an off member on when the group is on. Successful brightness requests require current numeric state; do not invent a remembered level. Use byte-aware comparisons and zero transition for relative-step readback; timeout is recorded as uncertain action execution, never a pass. Prove distinct steps with responsive-state fixtures and live traces during apply.

### D7 - Stage configuration and validate this scope before deployment (2026-10-04)

- **Decision:** During implementation, keep reviewable automation JSON plus meaningful event/action tests in a repository `home_assistant/` area. Discover current consumers/profile membership/service schemas, back up affected live configuration locally, validate the proposed automation, then create it through HA's config API, read it back and check narrowly scoped live results. Rollback disables/removes only the added automation and restores only takeover state it changed.
- **Why:** Live HA is outside the Git working tree; repository artifacts and readback make the deployed behavior reproducible. The new automation has a small rollback boundary.
- **Alternatives considered:** Keep the only implementation in ignored staging (unreviewable), write HA `.storage`/raw configuration files (bypasses supported APIs), or rerun the predecessor's full RF sweep (already closed and unrelated).
- **Status:** Decided.
- **Handoff note:** Automated checks cover all six mappings, excluded sources/rooms/fan commands, restored events, numeric guards/clamping, successive same-command occurrences and ambient-only takeover targets. Physical acceptance covers only the new ambient behavior and spotlight isolation; reuse existing receiver acceptance. Record traces, user acceptance and unobserved outcomes separately. Proposal work stops before live deployment.

### D8 - Complete the proposal stage (2026-10-04)

- **Decision:** Mark the planning handoff ready for implementation after all five artifacts were recognized as complete and `openspec validate bedroom-rf-remote-ambient --strict` passed.
- **Why:** The corrected scope and confirmed mapping are represented consistently in proposal, specs, design and tasks, with concrete live facts retained here.
- **Alternatives considered:** Deploy as part of proposal generation; outside this skill's requested stage. Leave the original spotlight change active; corrected scaffold was renamed and no spotlight implementation exists.
- **Status:** Decided; planning complete, implementation pending.
- **Handoff note:** Continue with `/opsx-apply bedroom-rf-remote-ambient` or an explicit implementation request. Twelve implementation tasks remain unchecked. HA reads succeeded through the retained connection; no RF sends, appliance actions, HA config writes, firmware edits or commits were performed in this proposal turn.

### D9 - Resolve the installed ambient-specific adaptation profile (2026-10-04)

- **Decision:** Use `switch.bedroom_ambient_adaptive_lighting_bedroom_ambient` and explicitly list ambient's two tracked bulbs for manual takeover. The generic Bedrooms profile is Mistral-only and must not be used for this feature.
- **Why:** Read-only SSH of `/config/.storage/core.config_entries` shows the Bedroom Ambient profile tracking only `light.yeelink_sg_457031179_colorc_s_2` and `light.yeelink_sg_457037035_colorc_s_2`, with `take_over_control: true`, `pause_changed`, `autoreset_control_seconds: 3600`, interval 86 s. Adaptive Lighting 1.31.0's installed `handle_set_manual_control` expands explicit light lists and marks those members. The profile was on with no manual-control entries; the separate spotlight profile tracks the other two bulbs. Ambient consumers are the wall-light automation, `automation.bedroom_button_2` (ambient toggle), its group helper and dashboard references. Neither member has an additional automation/script consumer in the search; partial member-search warnings describe the verified group reference, not an inaccessible unknown target.
- **Alternatives considered:** Use `switch.bedrooms_adaptive_lighting_bedrooms` based on the room override, or pause an entire profile; both would target the wrong scope. Change profile membership/settings; unnecessary.
- **Status:** Decided; supersedes D4's generic-profile consideration with verified configuration.
- **Handoff note:** Live evidence is retained in ignored `esphome/.esphome/ambient-control/` (`adaptive-profiles.json`, `ambient-profile-state.json`, consumer searches, service schemas and before-states). Both existing automation hashes still match D8's proposal reads. Member friendly names contain “Spotlight” but their explicit membership is the ambient group; do not substitute the separate spotlight group's bulbs based on friendly names. The server write receipt was read from its skill guide; retain it only in private staging.

### D10 - Guard execution and wait for member feedback (2026-10-04)

- **Decision:** Keep freshness/source guards inside the queued action sequence so every queued occurrence is checked at execution. Skip actions when the receiver or ambient group is unavailable. Calculate a rounded integer percentage from the group's current byte brightness, add/subtract 10, and clamp 1–100. Set zero transition and wait at most five seconds for both ambient members to report the requested brightness within two byte units before processing another step. Use the same bounded member feedback for temperature selections. Timeouts stop the current occurrence without retry and are recorded as uncertain.
- **Why:** Group aggregate state can reflect only the first bulb's update; waiting on both members avoids calculating the next press from a half-updated average. HA/Miio byte/percentage conversion requires small rounding tolerance. A readiness template can already be true when a service returns; a change-only wait would miss that case.
- **Alternatives considered:** Concurrent steps, fixed delays, or waiting only for any group update; these can lose relative steps or depend on timing. Persistent brightness helpers would create a second state owner. A new recovery workflow for unavailable bulbs is outside scope.
- **Status:** Decided.
- **Handoff note:** Tests must evaluate the production templates using Home Assistant's actual template renderer and cover both-member readback, timeout, stale events and two consecutive responsive presses. The confirmed mapping remains unchanged. Execution guards reference the current receiver only for availability, never to replace the triggering event type.

### D11 - Validate the production configuration without live fixture events (2026-10-04)

- **Decision:** Use a local generic action-tree runner against the production JSON and compare every recorded template evaluation with the live HA renderer using fixture-only function bindings. Validate native configuration separately through WebSocket `validate_config`; do not emit synthetic occurrences on the live receiver.
- **Why:** Installed HA is **2026.8.3** (verified through `get_config`). The local SSH shell has neither Python nor Docker, but the supported MCP template and WebSocket paths work. Eleven tests passed; all **312 exact production-template fixture evaluations** matched HA's renderer. Native triggers, conditions and actions each returned `valid: true`. Coverage includes all six mappings, excluded source/fan/room traffic, manual invocation, restored timestamps, availability, null/non-numeric brightness, clamps, both-member feedback, scoped takeover and two responsive relative steps.
- **Alternatives considered:** Install HA locally, use a different HA version, or inject events into the live state entity; unnecessary and less faithful to the available API. Treat the fixture runner as actual HA scheduler or hardware verification; expressly rejected.
- **Status:** Implemented; configuration/template validation passed, physical behavior still pending.
- **Handoff note:** Reusable test is `home_assistant/tests/test_bedroom_rf_ambient.py`; production config is `home_assistant/automations/bedroom_rf_ambient.json`. Private validation requests/results, initial states and existing automation backups are in ignored `esphome/.esphome/ambient-control/`. Public core source confirms the read-only [validate_config contract](https://github.com/home-assistant/core/blob/2026.8.3/homeassistant/components/websocket_api/commands.py). No live light service or state mutation has occurred. Deployment and enabled/config readback are next.

### D12 - Create the validated ambient consumer (2026-10-04)

- **Decision:** Deploy through `ha_config_set_automation` using the server's current guide receipt. Creation succeeded as `automation.bedroom_rf_remote_ambient_control`, unique ID `1791081797176`.
- **Why:** The user explicitly invoked implementation, including the rollout task, and validation passed. Pre-create search returned no matching automation, so this is one new consumer rather than a duplicate.
- **Alternatives considered:** Stop after writing local JSON or request approval again; neither completes the authorized implementation. Modify the existing correction automation; retained the independent consumer boundary.
- **Status:** Implemented; saved configuration/state readback in progress.
- **Handoff note:** The write returned advisory template/wait warnings, not a rejection. Readiness waits deliberately pass if already true; a change-only trigger would differ. Replace the native-expressible ambient availability list with a native state condition before finalizing, retaining the receiver's missing-state-safe check. No assistant RF send or physical light test was performed. Readback and scoped physical acceptance remain required.

### D13 - Verify enabled deployment and native-condition refinement (2026-10-04)

- **Decision:** Replace the ambient availability template clause with a native state condition allowing on/off. Re-run all eleven tests, all 312 production-template fixture comparisons and HA `validate_config`; all pass. Update the existing new automation with optimistic locking rather than creating another.
- **Why:** The server's advisory correctly identified a native-expressible state list. Receiver freshness/source/numeric checks and immediate-ready member waits still require their contextual templates.
- **Alternatives considered:** Ignore the native state warning or replace readiness waits with change-only triggers; the former misses a routine improvement, the latter changes behavior when reports arrive before the service returns.
- **Status:** Implemented. `automation.bedroom_rf_remote_ambient_control` is on; final config hash `6fd761284223f81c`, unique ID `1791081797176`.
- **Handoff note:** Parsed deployed config equals repository JSON exactly after removing only generated `id`. Existing correction hash remains `5a7f1c29976a4f7f`; wall-light hash remains `0115cc473079a098`. Rollback is `automation.turn_off` on the added entity with `stop_actions: true`, or `ha_config_remove_automation` for that entity. Initial ambient manual-control list was empty; clear only the two ambient flags introduced by this automation if rolling back, noting that clearing can adapt bulbs immediately. The user has been asked once for the new six-button ambient mapping and spotlight isolation; await that scoped response, not predecessor RF checks.

### D14 - Reject pacing as acceptance and investigate latency (2026-10-04)

- **Decision:** Apply the user's correction: "The 2 seconds is a serious flaw -- the spotlights do NOT react fast enough." Retire the paced six-button acceptance request. Prioritize responsive ambient command handling and fix the discovered off-brightness guard before claiming acceptance. The previously corrected target remains the ambient group; member friendly names themselves contain “Spotlight”.
- **Why:** Actual traces show queued actions delayed behind bulb service errors, including an ambient member's color-temperature/on execution timeout. A brightness run then failed rendering `float(None)` after the group was off. The local runner incorrectly propagated a condition failure from inside an `if` to the entire automation, so it failed to expose HA's actual nested-sequence continuation behavior. Fixture/renderer success did not verify the native script control-flow boundary.
- **Alternatives considered:** Ask the user to press more slowly, repeat the same acceptance sequence, infer a failed physical command from an error alone, or claim all controls work; rejected. Reopen remote capture/receiver acceptance; unrelated.
- **Status:** Decided; latency and native control-flow fix in progress, physical acceptance not complete.
- **Handoff note:** Latest stored traces include `3df2f5cc130fc87dbf6e04d06f5ff0f0` (float(None)) and member service timeout `fb2bf027e229ada841af5722b002a24a`. Read details immediately while retained; earlier traces rotated out of the ten-record live store, but list summaries are saved locally. Inspect the bulb integration/service path and replace nested guard with a top-level snapshot guard. Add a prevention rule and production-config regression covering real nested condition semantics during this task. Do not schedule or request another paced sweep.

### D15 - Simplify to direct event-to-group actions (2026-10-04)

- **Decision:** Follow the user's direction: "an automation that listens to the event and make an input change to the other light group. That's all." Remove all added member-confirmation waits. Retain one automation, the confirmed mappings/source filter, ambient-only manual takeover and ordered native light calls. Fix brightness eligibility at the parent sequence boundary and calculate from one state snapshot. Do not introduce workers, persistent helpers or a replacement bulb integration.
- **Why:** The confirmation waits add latency and complexity beyond the requested event mapping. Read-only inspection of installed `xiaomi_home/light.py` shows power-on then brightness/temperature are separate awaited property writes; actual member timeouts delayed subsequent queued actions. This is distinct from automation-added waits and must not be presented as fixed by removing them.
- **Alternatives considered:** Additional worker scripts, changing the Xiaomi connection globally, parallel relative writes or a new local bulb integration; outside the requested simple mapping or liable to lose ordered steps. Slower button pacing; explicitly rejected.
- **Status:** Decided; supersedes D6/D10's member-feedback waits. Revalidation and update in progress.
- **Handoff note:** The queue preserves command order but native service timeouts can still block it. Relative steps read the latest reported ambient value without maintaining a second brightness owner. Do not claim responsiveness or physical acceptance without observed evidence, or ask for the retired paced sweep. Correct the local runner to distinguish nested condition abort from global stop; use live traces as the native control-flow evidence.

### D16 - Validate the simplified mapping and corrected guards (2026-10-04)

- **Decision:** Keep source/freshness filtering before queue admission and at the execution boundary. Place brightness eligibility in the parent sequence, using one state/brightness snapshot. Remove both OFF and on/setting member waits. Correct the fixture runner's nested-condition semantics and cover the actual off/null failure, mutable state after snapshot, global stop and absence of waits.
- **Why:** This addresses the concrete native control-flow failure and follows the user's simple event-to-group direction without expanding live integration scope. Thirteen local checks pass; all 292 exact production-template fixture evaluations match HA's renderer; native trigger/condition/action validation and strict OpenSpec validation pass.
- **Alternatives considered:** Leave the old fixture runner unchanged, only add a float default, or report fixture checks as physical responsiveness; none establishes the intended guard boundary or observed physical behavior.
- **Status:** Validated; update of existing automation next.
- **Handoff note:** Evidence is in ignored ambient-control staging (`simplified-template-tests*.json`, `simplified-native-validation.json`, `pre-simplification-config.json`). Removing waits does not resolve the previously observed Xiaomi property timeouts. No new live light/RF command or synthetic receiver event was sent for these checks.

### D17 - Record simplified deployment and remaining physical limitation (2026-10-04)

- **Decision:** Update the existing `automation.bedroom_rf_remote_ambient_control` (ID `1791081797176`) rather than creating a duplicate. Saved config hash is `c844fffe76c75539`; enabled state is on, and readback exactly matches repository JSON after removing only generated `id`. Keep physical acceptance task 3.2 open; the rejected paced test does not establish that all mappings or response timing work.
- **Why:** The user's latest scope is a simple event-to-ambient group mapping. Supported config update succeeded. Existing helper-correction hash remains `5a7f1c29976a4f7f` and wall-light hash remains `0115cc473079a098`. No bulb connection/profile settings, firmware or codes changed. The cause of excess automation complexity was treating member feedback as an extra acknowledgement barrier; its corrective rule is now recorded in AGENTS.md alongside the guard-semantics rule.
- **Alternatives considered:** Claim all twelve tasks complete, request another paced sweep, or expand into transport reconfiguration; rejected. Native integration timeouts remain a limitation of ordered service calls, not a proven failure of the revised event mapping.
- **Status:** Implementation/configuration validation complete; physical responsiveness and all-six-button acceptance unconfirmed. Eleven of twelve tasks complete. Do not archive yet.
- **Handoff note:** Thirteen production-tree fixture checks and 292 live-renderer comparisons passed; native HA validation and strict OpenSpec validation passed. Repeated responsive steps are fixture evidence (60 then 70%), not measured hardware timing. Existing live marked OFF trace `36a9085f67d3790c8243926d6343976a` ends at the source guard before any service. Installed Adaptive Lighting off-reset code plus `post-test-states.json` show ambient off, manual_control empty and autoreset timers empty, matching the initially empty flags; the timeout path is source-verified, not physically waited out. Rollback: disable only this added automation with `automation.turn_off` and `stop_actions: true`, or remove it through the config API; clear only ambient manual flags it introduced if necessary (clearing may immediately adapt bulbs). Revised deployment evidence is `simplified-deployment.json`, `simplified-readback.json`, `simplified-live-states.json` and unchanged automation readbacks in ignored staging. No assistant light/RF sends, synthetic receiver events or commits occurred. Do not repeat predecessor acceptance or the retired paced request.

### D18 - Accept, close and archive the change (2026-10-04)

- **Decision:** Apply the user's explicit acceptance: "Yeah it's fine. Mark it as done, archive, and commit." Close task 3.2 by user-directed acceptance, synchronize the new ambient-control capability to main specs, archive as `2026-10-04-bedroom-rf-remote-ambient`, and commit this change plus its two prevention rules.
- **Why:** The user accepted the simplified deployed behavior and explicitly requested closure. Additional physical sweeps or latency investigations are no longer active work. All twelve tasks are closed.
- **Alternatives considered:** Keep physical acceptance open, request another sweep, or commit unrelated predecessor archive changes; rejected as contrary to acceptance or outside this change's scope.
- **Status:** Complete by user acceptance; authorized archive and commit.
- **Handoff note:** D18 supersedes D17's open acceptance/blocker status. Retain prior observed timeouts and unmeasured per-button physical timing as historical limitations; do not claim fresh physical measurements or reopen those checks without a new request. Deployed ID/hash and rollback remain as in D17. Main capability requirements are synchronized; private HA staging stays ignored. Preserve unrelated working-tree changes outside the commit.

### D19 - Finish spec synchronization and archival (2026-10-04)

- **Decision:** Create `openspec/specs/bedroom-rf-ambient-control/spec.md` with all five added requirements and archive the complete change at `openspec/changes/archive/2026-10-04-bedroom-rf-remote-ambient/`, retaining its schema metadata. Update repository documentation and current handoff links for the archived location.
- **Why:** The main capability did not exist, so synchronization adds requirements without changing another capability. Strict validation passed for both the main spec and complete change before the directory move.
- **Alternatives considered:** Archive without synchronizing requirements or include unrelated working-tree edits in the commit; rejected.
- **Status:** Archived; twelve of twelve tasks complete. Scoped commit follows.
- **Handoff note:** Commit the archived change, new main capability, ambient automation/tests/docs and only the two HA prevention rules added in this session. Preserve the pre-existing AGENTS acceptance rule and unrelated predecessor changes in the working tree. Acceptance is final; no new physical checks are required by this closed change.
