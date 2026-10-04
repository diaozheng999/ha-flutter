"""Exercise the production JSON action tree; optionally compare templates on HA.

The small runner models service feedback, not HA's scheduler or physical bulbs.
--export writes read-only ha_eval_template arguments containing these exact
production expressions and fixture snapshots. --compare verifies its response.
"""

import argparse
import ast
import copy
from datetime import datetime
import json
import math
from pathlib import Path
import unittest

from jinja2.nativetypes import NativeEnvironment

CONFIG = json.loads((Path(__file__).parents[1] / "automations/bedroom_rf_ambient.json").read_text())
EVENT = CONFIG["triggers"][0]["entity_id"]
GROUP = "light.bedroom_ambient"
PROFILE = "switch.bedroom_ambient_adaptive_lighting_bedroom_ambient"
MEMBERS = CONFIG["actions"][1]["variables"]["ambient_members"]
RENDERS = {}


def timestamp(value, default=0):
    try:
        return datetime.fromisoformat(value).timestamp()
    except (TypeError, ValueError):
        return default


def is_number(value):
    try:
        return math.isfinite(float(value))
    except (TypeError, ValueError):
        return False


def occurrence(command, source="unmarked", when="2026-10-04T11:00:01+08:00"):
    return {
        "entity_id": EVENT,
        "from_state": {"state": "2026-10-04T11:00:00+08:00", "last_changed": "2026-10-04T11:00:00+08:00"},
        "to_state": {"state": when, "attributes": {"event_type": f"{command}_{source}"}},
    }


class ConditionFailed(Exception):
    """HA ends only the sequence containing a failed condition."""


class StopAutomation(Exception):
    pass


class Runner:
    def __init__(self, state="on", brightness=128, adaptive="on"):
        self.states = {
            EVENT: {"state": "2026-10-04T11:00:01+08:00", "attributes": {"event_type": "fan_off_broadlink"}},
            PROFILE: {"state": adaptive, "attributes": {}},
            GROUP: {"state": state, "attributes": {"brightness": brightness}},
            **{member: {"state": state, "attributes": {"brightness": brightness, "color_temp_kelvin": 4000}} for member in MEMBERS},
        }
        self.calls = []
        self.variables = {}
        self.feedback = True
        self.env = NativeEnvironment()
        self.env.globals.update(
            states=lambda entity: self.states.get(entity, {}).get("state", "unknown"),
            state_attr=lambda entity, attr: self.states.get(entity, {}).get("attributes", {}).get(attr),
            is_state=lambda entity, state: self.states.get(entity, {}).get("state") == state,
            is_number=is_number,
            as_timestamp=timestamp,
        )

    def render(self, value):
        if isinstance(value, str) and ("{{" in value or "{%" in value):
            result = self.env.from_string(value).render(**self.variables)
            fixture = {"states": self.states, "variables": self.variables}
            key = json.dumps([value, fixture], sort_keys=True)
            RENDERS[key] = {"source": value, "fixture": copy.deepcopy(fixture), "expected": result}
            return result
        if isinstance(value, dict):
            return {key: self.render(item) for key, item in value.items()}
        if isinstance(value, list):
            return [self.render(item) for item in value]
        return value

    def condition(self, condition):
        if isinstance(condition, list):
            return all(self.condition(item) for item in condition)
        if isinstance(condition, str):
            return bool(self.render(condition))
        if condition["condition"] == "template":
            return bool(self.render(condition["value_template"]))
        if condition["condition"] == "state":
            allowed = condition["state"] if isinstance(condition["state"], list) else [condition["state"]]
            return self.states[condition["entity_id"]]["state"] in allowed
        raise AssertionError(f"Unsupported condition: {condition}")

    def execute(self, sequence):
        for step in sequence:
            if "condition" in step:
                if not self.condition(step):
                    raise ConditionFailed()
            elif "variables" in step:
                for name, value in step["variables"].items():
                    self.variables[name] = self.render(value)
            elif "if" in step:
                self.execute_child(step.get("then", []) if self.condition(step["if"]) else step.get("else", []))
            elif "choose" in step:
                for choice in step["choose"]:
                    if self.condition(choice["conditions"]):
                        self.execute_child(choice["sequence"])
                        break
                else:
                    self.execute_child(step.get("default", []))
            elif "stop" in step:
                raise StopAutomation()
            elif "action" in step:
                data = self.render(step.get("data", {}))
                target = self.render(step.get("target", {}))
                self.calls.append((step["action"], target, data))
                if step["action"].startswith("light."):
                    assert target == {"entity_id": GROUP}
                    on = step["action"] == "light.turn_on"
                    # Partial feedback intentionally updates one member only.
                    for member in MEMBERS if self.feedback else MEMBERS[:1]:
                        self.states[member]["state"] = "on" if on else "off"
                        attrs = self.states[member]["attributes"]
                        if "brightness_pct" in data:
                            attrs["brightness"] = int(data["brightness_pct"] * 255 / 100)
                        if "color_temp_kelvin" in data:
                            attrs["color_temp_kelvin"] = data["color_temp_kelvin"]
                    self.states[GROUP]["state"] = "on" if on else "off"
                    self.states[GROUP]["attributes"]["brightness"] = sum(self.states[m]["attributes"]["brightness"] for m in MEMBERS) / 2
            else:
                raise AssertionError(f"Unsupported step: {step}")

    def execute_child(self, sequence):
        try:
            self.execute(sequence)
        except ConditionFailed:
            pass

    def run(self, trigger):
        self.variables = {} if trigger is None else {"trigger": copy.deepcopy(trigger)}
        try:
            if not self.condition(CONFIG["conditions"]):
                return self.calls
            self.execute(CONFIG["actions"])
        except (ConditionFailed, StopAutomation):
            pass
        return self.calls


class AmbientTests(unittest.TestCase):
    def test_power_and_temperature(self):
        for command, kelvin in [("light_off", None), ("light_warm", 2700), ("light_neutral", 4000), ("light_cool", 6500)]:
            with self.subTest(command=command):
                runner = Runner()
                runner.run(occurrence(command))
                light_calls = [call for call in runner.calls if call[0].startswith("light.")]
                self.assertEqual(len(light_calls), 1)
                if kelvin:
                    self.assertEqual(light_calls[0][2], {"color_temp_kelvin": kelvin, "transition": 0})
                    self.assertEqual(runner.states[GROUP]["attributes"]["brightness"], 128)
                else:
                    self.assertEqual(runner.calls[0][0], "light.turn_off")
                    self.assertEqual(len(runner.calls), 1)

    def test_temperature_from_off(self):
        runner = Runner(state="off")
        runner.run(occurrence("light_warm"))
        self.assertEqual(runner.states[GROUP]["state"], "on")
        self.assertNotIn("brightness_pct", runner.calls[-1][2])

    def test_all_other_sources_and_fan_commands(self):
        for command in ["light_off", "light_warm", "light_neutral", "light_cool", "light_brightness_up", "light_brightness_down"]:
            for source in ["broadlink", "mixed", "unknown"]:
                self.assertEqual(Runner().run(occurrence(command, source)), [])
        for command in ["fan_off", "fan_fr", "speed_1", "speed_2", "speed_3", "speed_4", "speed_5", "invalid"]:
            self.assertEqual(Runner().run(occurrence(command)), [])

    def test_input_boundary_and_restoration(self):
        self.assertEqual(Runner().run(None), [])
        for field in ["from_state", "to_state"]:
            trigger = occurrence("light_warm")
            trigger[field] = None
            self.assertEqual(Runner().run(trigger), [])
        for value in ["unknown", "unavailable", "2026-10-04T10:59:59+08:00", "2026-10-04T11:00:00+08:00"]:
            self.assertEqual(Runner().run(occurrence("light_warm", when=value)), [])
        trigger = occurrence("light_warm")
        trigger["entity_id"] = "event.study_lilygo_lora32_t3_v1_6_1_study_rf_command"
        self.assertEqual(Runner().run(trigger), [])
        trigger = occurrence("light_warm")
        trigger["from_state"]["state"] = "unavailable"
        self.assertEqual(len(Runner().run(trigger)), 2)

    def test_unavailable_receiver_or_target(self):
        for entity in [EVENT, GROUP]:
            for state in ["unknown", "unavailable"]:
                runner = Runner()
                runner.states[entity]["state"] = state
                self.assertEqual(runner.run(occurrence("light_warm")), [])

    def test_relative_steps_and_clamping(self):
        for brightness, command, expected in [(128, "light_brightness_up", 60), (128, "light_brightness_down", 40), (242, "light_brightness_up", 100), (13, "light_brightness_down", 1), (255, "light_brightness_up", 100), (2, "light_brightness_down", 1)]:
            with self.subTest(brightness=brightness, command=command):
                runner = Runner(brightness=brightness)
                runner.run(occurrence(command))
                self.assertEqual(runner.calls[-1][2]["brightness_pct"], expected)

    def test_off_or_missing_brightness_does_not_turn_on_or_pause(self):
        for state, brightness in [("off", None), ("off", 128), ("on", None), ("on", "invalid"), ("on", "nan")]:
            self.assertEqual(Runner(state=state, brightness=brightness).run(occurrence("light_brightness_up")), [])

    def test_repeated_presses_use_occurrence_snapshot_and_new_brightness(self):
        runner = Runner()
        runner.run(occurrence("light_brightness_up"))
        runner.run(occurrence("light_brightness_up", when="2026-10-04T11:00:02+08:00"))
        self.assertEqual([call[2]["brightness_pct"] for call in runner.calls if call[0] == "light.turn_on"], [60, 70])
        # Current EVENT attributes intentionally name a different, marked command.
        self.assertEqual(runner.states[EVENT]["attributes"]["event_type"], "fan_off_broadlink")

    def test_no_confirmation_waits_with_partial_feedback(self):
        runner = Runner()
        runner.feedback = False
        runner.run(occurrence("light_brightness_up"))
        self.assertEqual(len([call for call in runner.calls if call[0] == "light.turn_on"]), 1)
        for forbidden in ["wait_template", "wait_for_trigger", '"delay"', '"timeout"']:
            self.assertNotIn(forbidden, json.dumps(CONFIG))

    def test_nested_condition_does_not_abort_parent_but_stop_does(self):
        # Live trace 3df2f5cc... continued after the old nested on-condition failed.
        for branch in [
            {"if": "{{ true }}", "then": [{"condition": "template", "value_template": "{{ false }}"}]},
            {"choose": [{"conditions": "{{ true }}", "sequence": [{"condition": "template", "value_template": "{{ false }}"}]}]},
        ]:
            runner = Runner()
            runner.execute([branch, {"variables": {"parent_continued": True}}])
            self.assertTrue(runner.variables["parent_continued"])
        with self.assertRaises(StopAutomation):
            Runner().execute([{"if": "{{ true }}", "then": [{"stop": "End automation"}]}])

    def test_brightness_calculation_uses_guarded_snapshot(self):
        runner = Runner()
        original_render = runner.render

        def change_live_state_after_snapshot(value):
            if isinstance(value, str) and "set current =" in value:
                runner.states[GROUP]["state"] = "off"
                runner.states[GROUP]["attributes"]["brightness"] = None
            return original_render(value)

        runner.render = change_live_state_after_snapshot
        runner.run(occurrence("light_brightness_up"))
        self.assertEqual(runner.calls[-1][2]["brightness_pct"], 60)

    def test_manual_takeover_targets_and_disabled_profile(self):
        runner = Runner()
        runner.run(occurrence("light_cool"))
        self.assertEqual(runner.calls[0], ("adaptive_lighting.set_manual_control", {}, {"entity_id": PROFILE, "lights": MEMBERS, "manual_control": True}))
        runner = Runner(adaptive="off")
        runner.run(occurrence("light_cool"))
        self.assertEqual(len(runner.calls), 1)
        self.assertEqual(runner.calls[0][0], "light.turn_on")

    def test_queue_and_allowed_actions(self):
        self.assertEqual((CONFIG["mode"], CONFIG["max"], CONFIG["trace"]["stored_traces"]), ("queued", 50, 10))
        serialized = json.dumps(CONFIG)
        for forbidden in ["light.bedroom_spotlight", "light.bedroom_light", "remote.send_command", "light.toggle", "input_number", "automation.toggle_bedroom_light"]:
            self.assertNotIn(forbidden, serialized)


def export_cases(path):
    cases = list(RENDERS.values())
    blocks = ["["]
    for index, case in enumerate(cases):
        fixture_json = json.dumps(case["fixture"])
        blocks.append("{% with %}{% set fixture = " + repr(fixture_json) + " | from_json %}")
        for key in case["fixture"]["variables"]:
            blocks.append("{% set " + key + " = fixture.variables." + key + " %}")
        blocks.append("{% macro fake_states(entity, returns) %}{% do returns(fixture.states.get(entity, {}).get('state', 'unknown')) %}{% endmacro %}{% set states = fake_states | as_function %}")
        blocks.append("{% macro fake_attr(entity, attr, returns) %}{% do returns(fixture.states.get(entity, {}).get('attributes', {}).get(attr)) %}{% endmacro %}{% set state_attr = fake_attr | as_function %}")
        blocks.append("{% macro fake_is_state(entity, state, returns) %}{% do returns(fixture.states.get(entity, {}).get('state') == state) %}{% endmacro %}{% set is_state = fake_is_state | as_function %}")
        blocks.append("{% set actual %}" + case["source"] + "{% endset %}" + ("," if index else "") + '{"id":' + str(index) + ',"actual":{{ actual | trim | to_json }}}{% endwith %}')
    blocks.append("]")
    Path(path).write_text(json.dumps({"template": "".join(blocks), "timeout": 30}), encoding="utf-8")
    Path(str(path) + ".expected.json").write_text(json.dumps(cases), encoding="utf-8")
    print(f"Exported {len(cases)} production template fixture evaluations")


def compare(path, response):
    expected = json.loads(Path(str(path) + ".expected.json").read_text())
    wrapper = json.loads(Path(response).read_text(encoding="utf-8-sig"))
    result = wrapper.get("result")
    if isinstance(result, str):
        result = json.loads(result)
    assert isinstance(result, list), wrapper
    assert len(result) == len(expected)
    for item in result:
        actual = item["actual"]
        try:
            actual = ast.literal_eval(actual)
        except (ValueError, SyntaxError):
            pass
        assert actual == expected[item["id"]]["expected"], (item, expected[item["id"]])
    print(f"Home Assistant renderer passed all {len(result)} production template evaluations")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--export")
    parser.add_argument("--compare", nargs=2)
    args = parser.parse_args()
    if args.compare:
        compare(*args.compare)
    else:
        result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(AmbientTests))
        if not result.wasSuccessful():
            raise SystemExit(1)
        if args.export:
            export_cases(args.export)
