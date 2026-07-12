## Context

The repository already treats `AGENTS.md`, OpenSpec artifacts, and installed skills as durable agent context, but it has no path from an ordinary correction or repeated difficulty to a reviewed repository lesson. The tracked `validate` skill also lives under the nonstandard `skill/` directory and is absent from `skills-lock.json`; current setup restores only locked external skills and generated OpenSpec skills, so repository-owned skill source is not reliably materialised for agents. In `skills` 1.5.10, adding a local source resolves `.` to an absolute path before writing `skills-lock.json`, so raw local lock entries are not portable between checkouts.

The change spans policy, two reusable skills, learning-record storage, both platform setup scripts, and lockfile verification. Generated agent directories remain ignored outputs. The design must work for agents with different metadata exposure and must not let the learning mechanism silently grant itself authority.

## Goals / Non-Goals

**Goals:**

- Surface plausible durable lessons from natural agent interactions using narrow, concrete triggers.
- Require independent causal and generalisation analysis before a learning is drafted.
- Keep every repository write human-reviewed while preserving inconclusive observations for future evidence.
- Make repository-owned and external skills reproducibly available through the existing setup entry points.
- Correct and register the existing `validate` skill as the first acceptance case.
- Keep the detailed procedures out of globally loaded `AGENTS.md` and in focused, testable skills.

**Non-Goals:**

- Automatically change `AGENTS.md`, skills, specs, or application code based on an agent observation.
- Replace OpenSpec decision logs or use learning records for change-specific decisions.
- Add a database, background service, telemetry system, or scheduled learning process.
- Change Flutter application behavior.
- Guarantee learning on an agent host that cannot spawn an independent subagent.
- Install arbitrary external skills solely from setup arguments; external sources must first be deliberately registered in the lockfile.

## Decisions

### 1. Split the policy trigger from the learning procedure

`AGENTS.md` will contain only the concrete trigger signals, the prohibition on immediate learning writes, the independent-subagent and review requirements, and the setup fallback. `skills/learn-from-interaction/SKILL.md` will hold the operational workflow. This follows D2, D3, and D9 and avoids loading a long RCA procedure into unrelated tasks.

The expected flow is:

```text
interaction exposes a concrete signal
              |
              v
invoke learn-from-interaction
              |
              v
spawn independent critical subagent
              |
              v
five-whys + evidence + generalisation + counterexamples
              |
              v
primary agent classifies and previews a candidate
              |
              v
human review before any file write
       | approved                 | rejected
       v                          v
create candidate record       create nothing
       |
       v
separate human review before promotion
```

If subagents are unavailable, the skill reports that learning cannot proceed and returns control to the original task. It does not emulate independence with another self-review pass.

### 2. Keep learning records non-normative and individually addressable

Following D5-D8 and D17, `learn-from-interaction` will include an `assets/learning-record.md` output template. After review, the primary agent instantiates it at:

```text
agent-learnings/YYYY-MM-DD-HHmmssZ-short-slug.md
```

The template frontmatter contains:

```yaml
---
status: candidate
observed_at: 2026-07-11T14:30:52Z
coding_agent: codex
model: exact-surfaced-model-or-unavailable
session_id: exact-session-id-or-unavailable
---
```

For Pi, `model` is omitted. The body contains the observation, source evidence, five-whys attempt, root-cause confidence and unknowns, proposed generalisation, counterexamples, existing-guidance check, recommendation, human review outcome, and links to related occurrences or promoted guidance.

A candidate does not alter agent behavior. Promotion into `AGENTS.md` or a skill is a separate reviewed change. The review-before-record rule launches as a provisional constraint; D8 defines the evidence for reconsidering it if interruptions outweigh its filtering value.

### 3. Use two focused repository skills

Following D14-D17, create:

```text
skills/
  learn-from-interaction/
    SKILL.md
    assets/learning-record.md
  install-project-skill/
    SKILL.md
  validate/
    SKILL.md
    evals/...
```

`learn-from-interaction` triggers on the four learning signals and uses low-freedom guardrails around delegation, evidence, and writes. `install-project-skill` triggers when a repository-owned or external skill is added or updated and branches by source type:

- Repository-owned: create or update `skills/<name>`, then run the platform setup script.
- External: inspect the source, run `npx skills add <source> --skill <name>` to install and update `skills-lock.json`, review the lockfile diff, then run setup. Because `skills add` has no lock-only mode, its immediate materialisation is accepted, but adoption is incomplete until setup reconciles and verifies the declared state.

Both new skills are initialised with the locked `npx skills init` command and validated by the tracked local-skill validator plus CLI discovery. Forward tests use raw scenarios in Codex, Claude Code, and Pi sessions: corrections that should and should not trigger learning, inconclusive RCA, unavailable metadata or subagents, clean local-skill installation, repeat setup, and external lockfile registration. The existing `validate` skill is moved intact rather than regenerated.

### 4. Make setup authoritatively reconcile and verify the declared skill set

Following D10-D13, D18, and D21-D23, setup is the authoritative reconciliation and verification entry point. External registration may materialise a skill before setup, but no installation workflow reports success until this phase completes:

```text
npm tooling available
        |
        v
npx skills install
restore skills-lock.json entries
        |
        v
enumerate immediate skills/<name> directories
        |
        v
for each name: npx skills add . --skill <name> --yes
        |
        v
normalize tracked local lock sources to "."
        |
        v
continue OpenSpec generation and configuration checks
        |
        v
verify every lockfile and tracked local skill exists in the canonical installed directory
```

The scripts derive names from the tracked directory layout and require the directory name to match the SKILL.md `name`. They never hard-code `validate`, `learn-from-interaction`, or future skill names. Explicit names are passed one at a time because `--skill '*'` could rediscover ignored generated agent skills during a repeat setup and incorrectly record them as local source.

Because the CLI writes an absolute local source, both setup paths call one cross-platform Node helper after reconciliation. The helper limits normalization to local lock entries that correspond exactly to the tracked `skills/<name>/SKILL.md` inventory, rewrites each matching absolute `source` to `.`, and then fails if an unexpected local entry or absolute local source remains. The helper also returns the complete expected skill-name set from the lockfile plus tracked local sources so setup can fail when any canonical installed file is absent. This makes the committed lock portable while preserving the root-source `npx skills` workflow and compensates for per-source restore failures that the CLI only logs.

`skills-lock.json` remains the reproducible manifest for external skills and records local skills after root-source installation with portable `source: "."` entries. A repeat setup with unchanged tracked sources is expected to leave tracked files unchanged. Generated `.agents/`, `.codex/`, and tool-specific directories remain ignored.

### 5. Verify behavior at both structural and workflow levels

Structural verification covers:

- OpenSpec schema and change validation.
- Skill frontmatter and directory names through the tracked validator and `npx skills` discovery.
- Exact equality between immediate `skills/<name>` directories and repository-owned skills registered by setup.
- Portable `source: "."` values and expected `skillPath` values for every local lock entry, with no absolute checkout path committed.
- Presence of every lockfile and tracked local skill at `.agents/skills/<name>/SKILL.md` after setup.
- A clean `skills-lock.json` diff after a repeated setup with no source changes.

Workflow verification covers:

- `/validate` is discoverable after a clean setup.
- A newly added local skill is installed without editing either setup script.
- External skills remain restorable from the lockfile.
- The learning skill does not write before review, does not promote inconclusive analysis, and stops its learning branch when no independent subagent is available.

## Risks / Trade-offs

- **[Learning prompts interrupt normal work]** → Keep triggers narrow, require a candidate preview rather than an immediate write, and use D8's explicit reevaluation criteria after real usage.
- **[The critic fabricates a neat root cause]** → Require evidence at every why, allow unknowns, and preserve inconclusive observations without promotion.
- **[Subagents are unsupported by an agent host]** → Stop only the learning workflow, report the limitation, and allow the original task to continue.
- **[Root discovery captures generated skills]** → Enumerate tracked local names and pass each name explicitly instead of using a wildcard.
- **[Setup rewrites the lockfile on every run]** → Verify idempotence and treat unexplained lockfile churn as a setup failure.
- **[The CLI emits machine-specific local lock sources]** → Normalize only verified tracked local entries to `.` after reconciliation and reject unexpected local entries.
- **[The CLI logs an external restore failure but exits successfully]** → Verify canonical output for every declared lockfile entry after restore and fail setup on any absence.
- **[Windows symlink or PowerShell differences cause divergence]** → Verify the canonical `.agents/skills` copy, use the existing platform-native scripts, and test both script paths where their toolchains are available.
- **[External skill instructions introduce unsafe authority]** → Keep external registration deliberate, review the source and lockfile diff, and rely on setup only after the source is tracked.
- **[Skill instructions overfit the examples used to build them]** → Forward-test with raw positive, negative, and ambiguous scenarios without leaking the expected answer.

## Migration Plan

1. Move `skill/validate` to `skills/validate`, preserving `SKILL.md` and eval assets.
2. Initialise `learn-from-interaction` and `install-project-skill` under `skills/` with `npx skills init`; author them, add the learning-record asset, and validate all tracked skills with repository-available tooling.
3. Add the concise learning trigger and project-skill conventions to `AGENTS.md`.
4. Add the local-lock validator/normalizer and update both setup scripts to use `npx skills install`, enumerate repository-owned skill names, install each from the repository root, normalize local lock sources, and verify canonical output for every declared skill.
5. Run setup to register repository-owned skills and refresh `skills-lock.json`; review the resulting lockfile changes.
6. Run structural checks, repeated-setup idempotence checks, clean-install checks, Git Bash checks, and independent Codex/Claude Code/Pi forward tests.

Rollback consists of reverting the tracked source move, skills, guidance, setup changes, and lockfile entries. Ignored generated agent directories can then be regenerated by the prior setup workflow; no Flutter application data is migrated.

## Open Questions

- There are no blocking design questions. After real usage, revisit D8 if the frequency of review prompts or rejected candidates shows that review should move to an end-of-task checkpoint while remaining mandatory.
