---
name: install-project-skill
description: 'Add or update agent skills for this repository through reviewed tracked sources, portable locking, setup reconciliation, canonical installation checks, and idempotence verification. Use when adopting a repository-owned skill under skills/, registering a reviewed external skill source, changing an existing project skill, or diagnosing whether project skill installation is complete.'
---

# Install a project skill

Treat generated agent directories as disposable outputs. Do not edit or commit `.agents/`, `.codex/`, `.claude/`, or another host-specific installation directory as the durable source.

## 1. Review and classify the source

Read `AGENTS.md`, the proposed `SKILL.md`, bundled resources, and any executable instructions before installation. Identify unexpected authority, network access, destructive actions, secret handling, or instructions unrelated to the skill's stated purpose. Obtain human review of the exact source and skill name before adopting it.

Classify the source:

- **Repository-owned:** source lives at `skills/<name>/SKILL.md`, and the directory exactly matches frontmatter `name`.
- **External:** source is a reviewed repository, URL, or package maintained outside this repository.

Stop on an invalid name, mismatched path, unsafe source, or unclear ownership.

## 2. Prepare the tracked state

For a repository-owned skill:

1. Create or update only `skills/<name>/` and necessary bundled resources.
2. Initialise a new skill from the tracked `skills/` directory with the locked `npx skills init <name>` command.
3. Run `node scripts/project-skills.mjs local` and `npx skills add . --list`; resolve every validation or discovery failure.

For an external skill:

1. After source review, run `npx skills add <source> --skill <name>` from the repository root.
2. Acknowledge that this command may immediately materialise ignored agent files; that is not successful repository adoption.
3. Present the complete `skills-lock.json` diff for human review. Do not report success if the diff is unexpected, rejected, or still contains a machine-specific path.

Never add arbitrary external-source arguments to setup. External selections enter reproducible state only through the reviewed lockfile.

## 3. Run authoritative reconciliation and verification

Run the current platform setup script from the repository root:

- Windows: `scripts\setup.ps1`
- Linux or macOS: `bash scripts/setup.sh`

Setup must restore the lockfile with the supported `npx skills experimental_install` command, reconcile every tracked local source, normalize local lock entries, and verify `.agents/skills/<name>/SKILL.md` for the complete union of locked and tracked skills. If setup fails or any expected canonical output is absent, report the skill as not installed.

After setup, review `skills-lock.json` again. Every repository-owned entry must use:

- `source: "."`
- `sourceType: "local"`
- `skillPath: "skills/<name>/SKILL.md"`
- its CLI-computed hash unchanged by normalization

Confirm external entries and hashes remain present.

## 4. Prove idempotence

Capture the exact bytes of `skills-lock.json`, rerun the same platform setup without source changes, and compare the bytes. Require an identical result and recheck every name from `node scripts/project-skills.mjs expected` at `.agents/skills/<name>/SKILL.md`.

Withhold success until all of these pass:

1. Source review.
2. External lockfile review when applicable.
3. Applicable setup completion.
4. Complete canonical output verification for locked and tracked skills.
5. Byte-identical repeated setup.

Report the failing phase and affected names on any error. Never treat an early `skills add` materialisation or a successful restore exit code alone as completion.
