# Handoff: Agent tooling rework (setup lockfile, /opsx-* rename, decisions schema, grill-me)

**Started:** 2026-07-11
**Status:** In progress — Phase 1 of 2 committed. Phase 2 (setup scripts + AGENTS.md) pending.
**Branch:** `feat/agent-tooling-rework` (to be created)

## Context

Multi-part rework of the ha-flutter agent tooling, requested by the user:

1. Update setup script: global openspec install, inject openspec skills/commands into `.agents/skills` with Claude Code as default, rename `/opsx:xxxx` → `/opsx-xxxx`, install all skills from `skills-lock.json`.
2. Add skills: `frontend-design` (anthropics/skills), `grill-me` (mattpocock/skills).
3. Wire `grill-me` into OpenSpec explore.
4. Enforce a decision log via the openspec schema (fork + `decisions.md` artifact), plus AGENTS.md guidance on schema customization.

Mid-implementation the user refined the approach (see D4 below), which changed how `/opsx-*` renaming and explore customization are delivered.

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
- **Status:** Decided. Confirm again at implementation time in case openspec
  init output changes.

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

## Next steps (in order)

1. Create `feat/agent-tooling-rework` branch, commit the three completed items
   (already staged) + this handoff doc.
2. Implement setup.sh + setup.ps1 rewrite per PENDING section 1.
3. Implement AGENTS.md rewrite per PENDING section 2.
4. Verify per PENDING section 3.
