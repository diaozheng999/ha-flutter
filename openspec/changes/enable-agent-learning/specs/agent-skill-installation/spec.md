## ADDED Requirements

### Requirement: Repository-owned skills use the conventional source layout
Every repository-owned skill MUST live at `skills/<name>/SKILL.md`, and the immediate directory name MUST match the skill's frontmatter `name`. The repository root MUST be the local source passed to `npx skills`.

#### Scenario: Valid repository-owned skill is discovered
- **GIVEN** `skills/example-skill/SKILL.md` declares `name: example-skill`
- **WHEN** setup reconciles repository-owned skills
- **THEN** it installs the skill using `npx skills add . --skill example-skill --yes`

#### Scenario: Directory and frontmatter names disagree
- **GIVEN** an immediate skill directory name differs from the `name` in its SKILL.md frontmatter
- **WHEN** setup validates repository-owned skills
- **THEN** setup fails with an error that identifies the mismatched directory and declared name

### Requirement: Setup is the authoritative reconciliation and verification entry point
The Windows and Linux/macOS setup scripts MUST perform skill restoration, repository-owned skill reconciliation, and installed-output verification. External registration MAY materialise a skill before setup, but a skill-installation workflow MUST NOT report successful repository adoption until the applicable platform setup script completes successfully.

#### Scenario: Repository-owned skill is added
- **GIVEN** a reviewed skill source has been added under `skills/`
- **WHEN** the applicable setup script runs
- **THEN** it installs and verifies that skill without requiring a hard-coded per-skill setup command

#### Scenario: Setup fails during verification
- **GIVEN** a skill cannot be restored or found at its canonical installed path
- **WHEN** setup reaches verification
- **THEN** setup exits unsuccessfully and the installer workflow reports the skill as not installed

### Requirement: Setup restores the lockfile through the stable command
Both setup scripts MUST run `npx skills install` to restore skills declared by `skills-lock.json`. They MUST NOT depend on `experimental_install` for the supported restore path.

#### Scenario: Fresh checkout restores external skills
- **GIVEN** a fresh checkout contains `skills-lock.json` and no generated agent directories
- **WHEN** setup runs the skill restore phase
- **THEN** every restorable locked external skill is materialised through `npx skills install`

### Requirement: Setup reconciles tracked local skills without wildcard discovery
After lockfile restoration, setup MUST enumerate immediate directories under `skills/` and invoke `npx skills add . --skill <name> --yes` once for each valid name. It MUST NOT use root-source `--skill '*'` and MUST NOT contain a hard-coded list of repository-owned skill names.

#### Scenario: New local skill requires no setup edit
- **GIVEN** a valid new directory is added under `skills/`
- **WHEN** setup runs without any script modification
- **THEN** the new directory name is discovered and passed explicitly to the root-source add command

#### Scenario: Generated skills already exist
- **GIVEN** ignored `.agents/skills` contains generated or external skills from an earlier setup
- **WHEN** setup reconciles repository-owned skills
- **THEN** it selects only names enumerated from the tracked `skills/` directory and does not relock generated skills as local sources

### Requirement: Local lock entries are portable between checkouts
After reconciliation, setup MUST normalize every verified repository-owned lock entry to `source: "."` and MUST preserve its expected `skills/<name>/SKILL.md` path and computed hash. Setup MUST fail if a local lock entry does not correspond to an immediate tracked skill or if an absolute local source remains.

#### Scenario: Local source is normalized
- **GIVEN** `npx skills add . --skill example-skill --yes` writes the current checkout's absolute path
- **WHEN** setup normalizes the project lock
- **THEN** the `example-skill` entry records `source: "."`, retains its expected skill path and hash, and contains no machine-specific checkout path

#### Scenario: Unexpected local lock entry is present
- **GIVEN** `skills-lock.json` contains a local entry with no matching immediate directory under `skills/`
- **WHEN** setup validates and normalizes the project lock
- **THEN** setup fails and identifies the unexpected local entry instead of silently preserving or deleting it

#### Scenario: Another checkout restores local skills
- **GIVEN** a fresh checkout contains portable local entries with `source: "."`
- **WHEN** `npx skills install` runs from that checkout root
- **THEN** it resolves the current checkout and restores the declared local skills without referring to the path of the machine that committed the lockfile

### Requirement: External skills are deliberately registered before setup
The `install-project-skill` workflow MUST use `npx skills add <source> --skill <name>` to install and register a reviewed external source, present the resulting `skills-lock.json` diff for review, and then run setup. Setup MUST reproduce tracked external state rather than accept arbitrary external source arguments, and the workflow MUST treat any immediate CLI materialisation as incomplete until setup verifies it.

#### Scenario: External skill is approved and registered
- **GIVEN** the user has selected an external skill source and name
- **WHEN** the installer workflow registers it
- **THEN** the lockfile records the source, the user is shown the lockfile change, and setup runs before completion is reported

#### Scenario: External lockfile change is not accepted
- **GIVEN** `npx skills add` produces an unexpected or rejected lockfile change
- **WHEN** the user declines that change
- **THEN** the installer workflow does not report the external skill as successfully adopted by the repository

### Requirement: Every declared skill is verified canonically
After reconciliation, setup MUST verify that every skill named by `skills-lock.json` and every valid immediate `skills/<name>` source has a corresponding `.agents/skills/<name>/SKILL.md`. Missing canonical output for a local or external skill MUST fail setup even when `npx skills install` returned success.

#### Scenario: All declared skills are present
- **GIVEN** setup has reconciled every lockfile and repository-owned skill
- **WHEN** canonical verification runs
- **THEN** setup succeeds only if each expected `.agents/skills/<name>/SKILL.md` exists

#### Scenario: One external skill is missing after a logged restore failure
- **GIVEN** one locked external skill did not materialise in `.agents/skills` even though the restore command completed
- **WHEN** canonical verification runs
- **THEN** setup fails and names the missing skill

### Requirement: Repeated setup is idempotent for tracked skill state
Running setup repeatedly without changing `skills/`, external skill selections, or their locked versions MUST leave `skills-lock.json` unchanged.

#### Scenario: Setup runs twice with unchanged sources
- **GIVEN** setup completed successfully and no tracked skill source or selection changed
- **WHEN** setup runs again
- **THEN** the second run produces no `skills-lock.json` diff

### Requirement: Generated agent directories remain reproducible outputs
Generated directories such as `.agents/`, `.codex/`, `.claude/`, and other tool-specific skill locations MUST remain ignored and MUST NOT become the durable source for repository-owned skills.

#### Scenario: Generated directories are removed
- **GIVEN** all ignored generated agent directories have been deleted
- **WHEN** setup runs from the tracked repository state
- **THEN** it restores the declared skills without requiring generated files to be committed

### Requirement: Validate is installed through the generic path
The existing `validate` skill MUST be moved intact to `skills/validate`, registered through root-source reconciliation, and available after clean setup without a `validate`-specific setup branch.

#### Scenario: Clean setup exposes validate
- **GIVEN** a checkout contains `skills/validate` and no generated agent directories
- **WHEN** either platform setup script completes successfully
- **THEN** `.agents/skills/validate/SKILL.md` exists and the setup script contains no hard-coded `validate` installation command

### Requirement: New skills are reproducibly validated and forward-tested
New repository-owned skills MUST be initialised with the locked `npx skills init` command, pass the tracked local-skill validator and CLI discovery checks, and be forward-tested with realistic positive, negative, and ambiguous prompts in every planned agent host before the change is considered complete.

#### Scenario: Skill structure is invalid
- **GIVEN** a new skill has invalid frontmatter or a nonconforming name
- **WHEN** skill validation runs
- **THEN** implementation verification fails before setup adoption is considered complete

#### Scenario: Skill passes structural checks but violates workflow boundaries
- **GIVEN** a structurally valid skill writes without review, over-triggers, or bypasses setup in a forward test
- **WHEN** the forward-test result is evaluated
- **THEN** the skill is revised and retested before completion

#### Scenario: A planned agent host is unavailable
- **GIVEN** Codex, Claude Code, or Pi is included in the planned support matrix but cannot run the forward-test scenarios
- **WHEN** implementation readiness is evaluated
- **THEN** the missing host is reported as a blocker and its result is not simulated by another model
