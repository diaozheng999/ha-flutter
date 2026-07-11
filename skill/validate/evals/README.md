# Evals for /validate

Three scenarios testing the skill's core failure modes. There is no built-in runner:
run each by setting up the fixture, invoking `/validate` on it in a fresh session,
and checking the report against `expected_behavior`. A run passes only if the verdict
line, the severity assignments, and the finding locations all match.

- `01-seeded-contradiction.json` — detects a cross-artifact contradiction as a Blocker
- `02-unimplementable-task.json` — detects a task failing the mid-level test as a Major
- `03-clean-change.json` — gives an explicit positive verdict with no invented findings
