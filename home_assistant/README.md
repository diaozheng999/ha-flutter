# Home Assistant configuration

`automations/bedroom_rf_ambient.json` is the reviewable configuration for
**Bedroom RF Remote Ambient Control**. Deploy it through the Home Assistant
configuration API; do not copy it into `.storage` or edit the live files by hand.

The automation consumes fresh bedroom LilyGo `_unmarked` light occurrences.
It targets `light.bedroom_ambient`: OFF, 2700/4000/6500 K selections, and relative
brightness steps of ten percentage points while on, bounded to 1–100%.
Marked/mixed observations and fan commands do not add ambient actions.
Unmarked means no valid Broadlink marker was received, not proven human origin.

Manual takeover explicitly targets the ambient bulbs on
`switch.bedroom_ambient_adaptive_lighting_bedroom_ambient`. Its existing one-hour
reset policy is preserved. Each accepted event directly calls the group's light
service, with no confirmation waits, delays or retries. Calls execute in order;
relative brightness uses a guarded snapshot of the latest reported group value.
The installed bulb integration can still delay a service call or time out; the
automation does not fix that transport or guarantee physical response timing.
Existing Mistral helper correction runs independently.

## Validation

With Python and Jinja2 available:

```powershell
python home_assistant/tests/test_bedroom_rf_ambient.py
```

The runner executes the actual JSON action tree against state/feedback fixtures.
It models native nested-condition continuation and fixture service feedback,
not HA scheduling or physical bulb execution. For
the exact production templates, export read-only HA renderer cases:

```powershell
python home_assistant/tests/test_bedroom_rf_ambient.py --export esphome/.esphome/ambient-control/template-tests.json
```

Send that JSON as the arguments to the configured `ha_eval_template` tool. Save
its response privately, then compare:

```powershell
python home_assistant/tests/test_bedroom_rf_ambient.py --compare esphome/.esphome/ambient-control/template-tests.json esphome/.esphome/ambient-control/template-tests-result.json
```

Validate `triggers`, `conditions` and `actions` through the read-only HA
WebSocket `validate_config` command, exposed by the configured MCP's
`ha_call_service(ws_command="validate_config", data=...)`.

## Deployment and rollback

Read the change's `decisions.md` first. Resolve the current group members and
Adaptive Lighting profile, check for an existing automation with the same alias,
read the server's current best-practices guide/receipt, and create through
`ha_config_set_automation(config=..., BestPracticeKey=...)`. For an update, pass
the existing identifier and its freshly read `config_hash`; never create a
duplicate. Read the deployed config and enabled state back and compare the
configuration to this file, allowing only the server-generated `id`.

Private HA connections, snapshots and validation responses stay in ignored
staging. No credentials belong in these repository files. Concrete deployment
identity, acceptance and rollback evidence live in
`openspec/changes/archive/2026-10-04-bedroom-rf-remote-ambient/decisions.md`.

To roll back, call `automation.turn_off` for the added automation with
`stop_actions: true`, or remove it through `ha_config_remove_automation`.
Clear only ambient member manual flags introduced by this automation, preserving
pre-existing manual control. Clearing manual control while the profile is on
can immediately adapt the ambient bulbs; leave existing room profiles, the
Mistral correction automation, wall automations and firmware unchanged.
