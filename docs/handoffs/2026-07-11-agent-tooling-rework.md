# Handoff: Agent tooling rework (setup lockfile, /opsx-* bridge, decisions schema, grill-me)

**Started:** 2026-07-11
**Last updated:** 2026-07-11 (session 2)
**Status:** In progress — bridge script, setup scripts, and decisions/grill wiring
DONE (uncommitted). AGENTS.md rewrite + end-to-end verify + commit PENDING.
**Branch:** `feat/agent-tooling-rework` (checked out)

> **Session 2 note:** The approach shifted from the original plan. The
> `/opsx:*` → `/opsx-*` rename is now done by a dedicated, committed,
> idempotent Node script (`scripts/generate-opsx-skills.mjs`) rather than
> inline sed/heredoc in the setup script (see D6). decisions.md is now wired
> through all three OpenSpec customization hooks, not just config rules (D7).
> Read the "Session 2: what changed" section below before the older PENDING
> list — parts of that list are now superseded.

## Context

Multi-part rework of the ha-flutter agent tooling, requested by the user:

1. Update setup script: global openspec install, inject openspec skills/commands into `.agents/skills` with Claude Code as default, rename `/opsx:xxxx` → `/opsx-xxxx`, install all skills from `skills-lock.json`.
2. Add skills: `frontend-design` (anthropics/skills), `grill-me` (mattpocock/skills).
3. Wire `grill-me` into OpenSpec explore.
4. Enforce a decision log via the openspec schema (fork + `decisions.md` artifact), plus AGENTS.md guidance on schema customization.

Mid-implementation the user refined the approach (see D4 below), which changed how `/opsx-*` renaming and explore customization are delivered.

The session-2 user framing added three explicit challenges:
1. **Respect the existing OpenSpec workflow.** For agents *unsupported by
   OpenSpec*, produce skills via a script that moves Claude Code's
   `.claude/commands/opsx/xxx` → `.agents/skills/opsx-xxx` and renames
   `/opsx:xxx` → `/opsx-xxx`. Emphasis: understand the difference between
   agent support in `openspec init` vs. the `skills` CLI.
2. **Wire decisions.md sustainably** — grounded in
   https://github.com/Fission-AI/OpenSpec/blob/main/docs/customization.md
3. **Wire `/grill-me`** into the OpenSpec planning phase (explore + change creation).

## Session 2: what changed (READ THIS FIRST)

### The openspec-vs-skills support difference (challenge 1, now grounded)

Empirically verified from the installed package sources:

- **`openspec init --tools <list>`** supports ~30 tools (`node_modules/@fission-ai/openspec/dist/core/config.js`,
  `AI_TOOLS`). Each writes to its OWN dir (`.claude`, `.cursor`, `.codex`,
  `.opencode`, `.pi`, `.gemini`, …). Only **Claude Code** gets nested
  slash-command files at `.claude/commands/opsx/<id>.md` — the `opsx:` colon
  is an artifact of that directory nesting.
- **The `skills` CLI** knows ~70 agents (`node_modules/skills/dist/cli.mjs`,
  the `agents` map). Most of them (amp, warp, zed, cursor, codex, opencode,
  replit, github-copilot, gemini-cli, zcode-via-universal, …) resolve skills
  from the shared **`.agents/skills/`** dir. `getUniversalAgents()` =
  every agent whose `skillsDir === ".agents/skills"`.
- **Gap:** the ~40 universal-dir agents that OpenSpec does NOT emit for get
  nothing. The bridge fills the gap by MOVING the Claude commands into
  `.agents/skills/opsx-<id>/SKILL.md` (renaming `opsx:` → `opsx-`), which is
  read by all universal-dir agents *including Claude Code itself*.

### `scripts/generate-opsx-skills.mjs` (NEW, committed, idempotent)

Does the move+rename+prune. Verified working: 10 commands → 10 `opsx-*`
skills, 0 residual `opsx:` refs, second run is a clean no-op. Also prunes
legacy `openspec-*` skill dirs that older OpenSpec versions wrote into
`.agents/skills/` (current versions write those per-tool, e.g.
`.claude/skills/`, so universal copies would double up).

### decisions.md wired through all three customization hooks (challenge 2)

Per the customization doc, three levers exist; this uses all three so the
discipline can't be skipped:
1. **Schema dependency graph** — `specs` and `design` now `requires:
   [proposal, decisions]`, so `openspec status` BLOCKS them until
   decisions.md exists. (`apply.requires` already included `decisions`.)
   Verified order: `proposal → decisions → {specs, design} → tasks`.
2. **Per-artifact `instruction:` appends** in `schema.yaml` — every artifact
   (proposal, specs, design, tasks, apply) now tells the agent to append to
   decisions.md *the moment* a decision arises, and apply tells it to read
   decisions.md FIRST.
3. **`config.yaml` `rules:`** — runtime-injected `<rules>` block per artifact
   (verified they appear in `openspec instructions <id>` output).

### grill-me wired into planning (challenge 3)

- Proposal `instruction:` now opens with a "grill FIRST" step (run the
  `grilling` skill / `/grill-me` unless already grilled in explore mode).
- `config.yaml` `rules.proposal` carries the same as an injected rule.
- Explore-mode wiring: the OpenSpec explore command/skill customization from
  the original plan is still PENDING (see below) — decide whether to patch
  the generated explore skill in the bridge script or document it in AGENTS.md.

## What's DONE (committed on this branch)

- **`skills-lock.json`** — added `frontend-design`, `grill-me`, and `grilling`
  (grilling is grill-me's required companion: grill-me's body is just
  "Run a `/grilling` session"). Lockfile now has 14 skills across 4 sources.
- **`openspec/schemas/spec-driven-decisions/`** — forked `spec-driven` via
  `openspec schema fork`. Edited `schema.yaml` to insert a `decisions` artifact
  (generates `decisions.md`) right after `proposal`, with `requires: [proposal]`,
  and added `decisions` to `apply.requires`. New `templates/decisions.md`
  (append-only dated entries: Decision / Why / Alternatives / Status / Handoff
  note + a `## Context` block). Validated: `openspec schema validate
  spec-driven-decisions` passes. Resulting artifact order:
  `proposal → decisions → specs → design → tasks`.
- **`openspec/config.yaml`** — `schema: spec-driven-decisions` (was
  `spec-driven`); added `rules.decisions` (append immediately, always include
  Why + Alternatives, supersede don't edit).

## What's PENDING (the rest of this work)

### 1. Rewrite `scripts/setup.sh` and `scripts/setup.ps1` (keep in lockstep)

New flow:

1. `npm install` (local devDeps).
2. **`npm install -g @fission-ai/openspec@latest`** (req 1a — global CLI).
3. **`openspec init`** — default to Claude Code (req 1b). Guard: only run if
   `.claude/commands/opsx` is missing, to avoid clobbering `openspec/config.yaml`
   on re-runs.
4. **`npx skills experimental_install -y`** — restore all skills from
   `skills-lock.json` (req 1c). This replaces the old `npx skills add ...`
   calls that regenerated the lockfile non-reproducibly.
5. **Flatten `/opsx:*` → `/opsx-*` for `.claude` only** (see D4). Programmatic
   in the script: move `.claude/commands/opsx/*.md` → `.claude/commands/opsx-*.md`,
   remove the `opsx/` dir, sed `opsx:` → `opsx-` across the command files, and
   normalize the frontmatter `name` field.
6. **Patch explore command/skill in-place** (see D4) to add grilling mode +
   decision-log routing. Do this with sed/heredoc inside the setup script,
   applied to the regenerated `.claude/commands/opsx-explore.md` and
   `.agents/skills/openspec-explore/SKILL.md`. Keep the patch text in the script
   so it's self-contained.
7. Assert `openspec/config.yaml` uses `schema: spec-driven-decisions` (warn if
   init overwrote it).
8. `flutter doctor`.

Keep the existing optional `[tools]`/`$Tools` arg, defaulting to `claude`.

### 2. Rewrite `AGENTS.md`

- **Decision Log & Handoff section (prominent, near top)** — the "immediately
  and studiously" discipline: every agent, at every planning stage, appends to
  `decisions.md` the moment a decision or key consideration arises. Location,
  format, schema-required, doubles as handoff doc.
- **Development Setup** — global openspec install, claude default, the flatten
  step, `/opsx-*` (dash) convention.
- **Skill & Tool Management** — lockfile-driven install via
  `experimental_install`; updated "add a skill" recipe (`npx skills add …` then
  commit `skills-lock.json`).
- **OpenSpec** — `/opsx-*` command list, `spec-driven-decisions` schema,
  artifact sequence, **Workflows** subsection linking
  https://github.com/Fission-AI/OpenSpec/blob/main/docs/workflows.md,
  **Customizing the schema** subsection: 3 levels (project config / custom
  schemas / global), commands (`schema fork`, `schema init`, `schema validate`,
  `schema which`), link
  https://github.com/Fission-AI/OpenSpec/blob/main/docs/customization.md,
  `spec-driven-decisions` as the worked example. Tell future agents they ARE
  allowed to modify the schema and how.

### 3. Verify end-to-end

On a clean `.claude/`/`.agents/` (delete them, run setup), confirm: 14 skills
installed, `.claude/commands/opsx-*.md` flat (no `opsx/` dir), no `opsx:`
references remain, `openspec schema which spec-driven-decisions` resolves from
project, explore command/skill contains the grilling + decisions sections.

## Decision log

### D1 - Lockfile-driven skill install (2026-07-11)

- **Decision:** Use `npx skills experimental_install` to restore from
  `skills-lock.json`, replacing the per-source `npx skills add` calls.
- **Why:** Reproducibility — `add` regenerated the lockfile from latest and two
  devs could get different skill versions.
- **Alternatives considered:** Pin versions in package.json (skills come from
  GitHub repos, not npm, so not applicable).
- **Status:** Decided. Implementation pending in setup script.

### D2 - Add `grilling` alongside `grill-me` (2026-07-11)

- **Decision:** Install both `grill-me` and `grilling` from mattpocock/skills.
- **Why:** grill-me is a thin trigger ("Run a `/grilling` session"); the actual
  prompt lives in the companion `grilling` skill. Without it, grill-me is inert.
- **Alternatives considered:** Install only grill-me and inline its prompt
  (duplicates upstream, drifts).
- **Status:** Decided & done (in lockfile).

### D3 - Enforce decision log via schema fork, not convention (2026-07-11)

- **Decision:** Fork `spec-driven` → `spec-driven-decisions`, add a `decisions`
  artifact, require it in `apply.requires`. User chose the "required" variant
  and emphasized `decisions.md` should be created as early as possible.
- **Why:** Schema enforcement means `/opsx-apply` won't proceed without it;
  ordering it second (after proposal) makes it available through every later
  phase. Also serves as the worked example for the schema-customization docs
  the user asked for.
- **Alternatives considered:** Optional artifact (lighter, no hard block);
  convention-only (not schema-aware, doesn't teach customization).
- **Status:** Decided & done. Config points at the new schema.

### D4 - Deliver /opsx-* rename + explore customization via script, not new skill files (2026-07-11)

- **Decision:** Do the `/opsx:*` → `/opsx-*` rename and the explore
  customization (grilling mode + decision-log routing) **programmatically inside
  the setup script**, NOT via hand-maintained files under a new
  `scripts/agent-overlay/` directory.
- **Why:** User steered away from creating new skill files ("You don't need to
  create new skills. Simply use a script to reorganize"). Doing it in-script
  keeps the source of truth in one place (the setup script) and avoids a
  parallel tree of hand-maintained agent files that must be mirrored to two
  destinations.
- **Alternatives considered:** The overlay approach originally planned
  (committed files in `scripts/agent-overlay/` that setup copies over regenerated
  dirs). Explored and abandoned after user feedback; the `scripts/agent-overlay/`
  directory was deleted before commit.
- **Status:** Decided. Implementation pending in setup script.

### D5 - Scope the /opsx-* flatten to .claude only (2026-07-11)

- **Decision:** Only `.claude/commands/opsx/*.md` needs flattening. All other
  generated agent dirs (`.agent/workflows/`, `.cursor/commands/`,
  `.opencode/command(s)/`, `.pi/prompts/`) already use flat `opsx-*` names.
- **Why:** Empirically verified — only Claude Code uses the nested-dir `opsx:`
  convention; the colon comes from the directory nesting.
- **Status:** Decided. SUPERSEDED by D6 — the flatten is now a MOVE into
  `.agents/skills/`, not an in-place rename under `.claude`.

### D6 - Deliver the bridge as a committed Node script, not inline setup sed (2026-07-11, session 2)

- **Decision:** The `/opsx:*` → `/opsx-*` transformation lives in a committed,
  standalone `scripts/generate-opsx-skills.mjs` that MOVES
  `.claude/commands/opsx/<id>.md` → `.agents/skills/opsx-<id>/SKILL.md`,
  rewrites `opsx:` → `opsx-` in bodies, and converts command frontmatter to
  skill frontmatter. setup.ps1/setup.sh just call it.
- **Why:** (a) It targets the *universal* `.agents/skills/` dir, which is what
  makes unsupported agents (challenge 1) actually get the workflow — an
  in-place `.claude` rename would only help Claude Code. (b) A real script is
  testable and idempotent; verified 10/10 move + no-op re-run. Inline sed
  across two shells (D4) is duplicated and unverifiable. (c) The user's
  session-2 wording explicitly asked for "a script" that moves
  `.claude/commands/xxxx` → `.agents/skills/xxxx`.
- **Alternatives considered:** Inline sed/heredoc per D4 (rejected: not
  testable, shell-duplicated, wrong target dir). Hand-maintained overlay files
  per the pre-D4 plan (already rejected in D4).
- **Status:** Decided & DONE (script written, tested, idempotent).

### D7 - Wire decisions.md through all three OpenSpec customization hooks (2026-07-11, session 2)

- **Decision:** Enforce decisions.md via (1) the schema dependency graph
  (`specs`/`design` require `decisions`), (2) per-artifact `instruction:`
  appends, and (3) `config.yaml` `rules:`. Use all three, not just one.
- **Why:** The customization doc exposes exactly these three levers. The graph
  makes it a hard block in `openspec status`; the instructions/rules make the
  "append immediately" discipline show up in the prompt for every artifact.
  Belt and suspenders because the whole point is the log can't be skipped.
- **Alternatives considered:** config `rules` only (original plan — soft, easy
  to ignore, no hard block). Graph only (blocks creation but doesn't teach the
  append-immediately discipline mid-artifact).
- **Status:** Decided & DONE. `openspec schema validate spec-driven-decisions`
  passes; instruction output verified to contain the rules + grill step.

### D8 - grill-me at the proposal gate; explore wiring still open (2026-07-11, session 2)

- **Decision:** Wire `/grill-me` (the `grilling` skill) as the FIRST step of
  the proposal artifact, via both the schema `instruction:` and
  `config.yaml rules.proposal`, with an "unless already grilled in explore
  mode" escape hatch.
- **Why:** The proposal is the narrowest gate every change must pass through,
  so it's the reliable place to force a stress-test. Explore mode is optional
  and freeform, so it can't be the only hook.
- **Alternatives considered:** Only patching the explore skill (misses changes
  created via `/opsx-new`/`/opsx-propose` without exploring first).
- **Status:** Proposal gate DONE. Explore-mode reinforcement (patching the
  generated explore skill vs. documenting in AGENTS.md) still PENDING — needs
  a call in the next session.

## Key facts for the next agent

- `.agents/`, `.claude/`, and all other agent dirs are **gitignored and
  regenerated** by setup (`.gitignore` lines 41-58). `openspec/schemas/` is NOT
  gitignored — that's why the schema fork is durable there without any overlay.
- The `openspec` CLI is currently invoked via `npx`; the setup rewrite moves it
  to a global install (`npm install -g @fission-ai/openspec@latest`).
- Internal `/opsx:` cross-references appear in 9 of 10 `.claude/commands/opsx/`
  files (bulk-archive has none). Unique tokens to rewrite: `opsx:apply`,
  `opsx:archive`, `opsx:continue`, `opsx:explore`, `opsx:ff`, `opsx:new`,
  `opsx:propose`, `opsx:sync`, `opsx:verify`.
- OpenSpec workflows doc: https://github.com/Fission-AI/OpenSpec/blob/main/docs/workflows.md
- OpenSpec customization doc: https://github.com/Fission-AI/OpenSpec/blob/main/docs/customization.md
- The grill-me/grilling skill content (fetched during research): grilling =
  relentless one-question-at-a-time interview walking the decision tree; for
  each question give a recommended answer but wait; facts looked up in
  codebase, decisions put to user; don't enact until shared understanding.
- The existing `openspec/changes/unified-control-scheme/` change predates this
  schema fork (it uses `spec-driven`); do not retroactively convert it. New
  changes use `spec-driven-decisions`.

## Current working-tree state (session 2, UNCOMMITTED)

`git status --short` at handoff:

```
 M openspec/config.yaml                                  # rules: proposal/specs/design/tasks/decisions
 M openspec/schemas/spec-driven-decisions/schema.yaml    # grill step + decisions deps/instructions
 M scripts/setup.ps1                                      # 7-step rewrite
 M scripts/setup.sh                                       # 7-step rewrite
?? scripts/generate-opsx-skills.mjs                       # NEW bridge script
```

Regenerated agent dirs (`.claude/`, `.agents/`) are gitignored — the bridge's
output is NOT part of the commit; it's reproduced by running setup. Nothing is
staged or committed yet this session.

## Next steps (in order)

1. **AGENTS.md rewrite** (task #5, still PENDING) — per "What's PENDING §2"
   above, but updated for session-2 reality: document the openspec-vs-skills
   support difference and the bridge script; the `/opsx-*` (dash) convention;
   the decision-log discipline + three-hook enforcement; the schema
   customization levels with the two doc links; grill-me at the proposal gate.
2. **Decide explore-mode grill wiring** (D8 open question) — either extend
   `generate-opsx-skills.mjs` to inject a grill section into the generated
   `opsx-explore` skill, or just document the expectation in AGENTS.md.
3. **End-to-end verify** (task #6) — `rm -rf .claude .agents`, run
   `scripts/setup.ps1`, confirm: skills restored from lockfile, `opsx-*` skills
   present in `.agents/skills/` with no `opsx:` residue and no `.claude/commands/opsx/`
   dir, `openspec schema which spec-driven-decisions` = project, proposal
   instructions contain grill + decisions rules.
4. **Commit** — one commit for the tooling rework. Remember the trailer:
   this session is `(claude-code, opus-4.8)` (model switched to opus mid-session).

## Verified this session (so you don't re-check)

- `scripts/generate-opsx-skills.mjs`: 10/10 move, 0 `opsx:` residue, idempotent
  no-op on re-run, prunes 10 legacy `openspec-*` dirs.
- `openspec schema validate spec-driven-decisions` → valid.
- `openspec schema which spec-driven-decisions` → source: project.
- Fresh `openspec new change` → schema `spec-driven-decisions`, artifact graph
  `proposal → decisions → {specs,design} → tasks`, decisions blocks specs/design.
- `openspec instructions proposal` → `<rules>` block has the grill rule; body
  opens with the grill-FIRST step.

## Prior next-steps (session 1, now DONE or superseded)

1. ~~Create branch + commit completed items~~ — branch exists; commit still pending.
2. ~~setup.sh/ps1 rewrite~~ — DONE (7-step, lockfile install, bridge call, schema assert).
3. AGENTS.md rewrite — still pending (step 1 above).
4. Verify — still pending (step 3 above).
