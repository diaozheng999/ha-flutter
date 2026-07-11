## Why

Repository knowledge currently improves only when someone deliberately edits agent guidance, so corrections and reusable discoveries from ordinary agent interactions are easily lost. Repository-owned skills are also not reliably restored by setup, which prevents durable workflows such as `/validate` and the proposed learning process from being available consistently across agents.

## What Changes

- Add a review-gated learning workflow that detects durable lessons during ordinary work without allowing agents to silently amend repository guidance.
- Add a `learn-from-interaction` skill that delegates critical analysis to an independent subagent, requires an evidence-backed five-whys root-cause attempt, attempts to generalise the lesson, and tests the generalisation before proposing a repository learning.
- Store reviewed learning candidates as individual `agent-learnings/{date}-{time}-{slug}.md` files containing the observation, evidence, analysis, disposition, coding agent, session ID, and model metadata when available; Pi intentionally omits model metadata.
- Require human review before creating a candidate learning file or promoting a learning into `AGENTS.md` or a skill. Treat candidate-file review as a provisional policy to revisit if it proves too interruptive.
- Keep `AGENTS.md` limited to the learning triggers, mandatory safety boundary, and bootstrap fallback while placing the detailed workflow in the reusable skill.
- Standardise tracked repository-owned skills under `skills/`, including correcting the existing `skill/validate` location.
- Add a project skill-installation workflow that uses `npx skills` and treats the platform setup scripts as the authoritative reconciliation and verification entry point.
- Make both setup scripts discover and install all repository-owned skills from the repository root, restore locked external skills, and verify that expected skills are available without adding per-skill setup commands.
- Register and restore the existing `validate` skill through the same lockfile-driven setup path.

## Capabilities

### New Capabilities

- `agent-learning`: Detect, critically assess, record, review, and promote durable lessons arising from natural agent interactions.
- `agent-skill-installation`: Discover, install, lock, restore, and verify repository-owned and external agent skills through the cross-platform setup workflow.

### Modified Capabilities

None.

## Impact

- Agent policy and handoff guidance in `AGENTS.md`.
- New tracked learning records under `agent-learnings/` and repository-owned skills under `skills/`.
- Existing `validate` skill source path and its evaluation assets.
- Windows and Linux/macOS setup scripts, `skills-lock.json`, and the `npx skills` installation lifecycle.
- Generated agent skill directories remain ignored and reproducible from tracked sources and setup.
