# Decisions

> **This is a living document.** Append a new entry the moment a decision or
> important consideration arises — at ANY phase (planning, explore, design,
> implementation). Do not batch. Do not edit past entries; supersede them with
> a new dated entry. The next agent reads this file FIRST.

## Context

- **Change:** Add a governed repository-learning loop and make repository-owned skills reliably installable through setup.
- **Started:** 2026-07-11
- **Related:** Existing agent-tooling conventions in `AGENTS.md`, `scripts/setup.ps1`, `scripts/setup.sh`, `skills-lock.json`, and the tracked `skill/validate` source. The decisions below were established during `/openspec-explore` before this change was scaffolded.

## Decision Log

### D1 - Use a governed learning loop (2026-07-11)

- **Decision:** Allow ordinary agent interactions to produce durable repository learning through a defined candidate, review, and promotion workflow.
- **Why:** Corrections, repeated friction, and repository discoveries currently disappear with the session unless someone deliberately converts them into guidance.
- **Alternatives considered:** Leave learning entirely ad hoc; rejected because it does not make improvement natural or repeatable. Allow agents to amend guidance directly; rejected because self-modifying instructions need independent scrutiny and human control.
- **Status:** Decided
- **Handoff note:** The learning loop is a repository-agent capability, not Flutter application behavior.

### D2 - Trigger only on concrete learning signals (2026-07-11)

- **Decision:** Trigger learning consideration for explicit user corrections, repeated friction, newly discovered repository invariants, or workflows repeated enough to be reusable.
- **Why:** Concrete signals allow useful lessons to surface without launching the workflow for every preference or one-off workaround.
- **Alternatives considered:** Evaluate every completed task; rejected as too noisy and interruptive. Trigger only when the user explicitly asks to record a lesson; rejected because it would not support natural improvement.
- **Status:** Decided
- **Handoff note:** The skill description and `AGENTS.md` trigger must cover these signals without treating ordinary implementation detail as a learning candidate.

### D3 - Require an independent critical subagent (2026-07-11)

- **Decision:** Before drafting or recording a learning, the primary agent must ask an independent subagent to assess whether the observation is durable, evidence-based, reusable, and absent from existing guidance.
- **Why:** A second context reduces the chance that the agent which made or encountered the issue immediately canonises a shallow interpretation.
- **Alternatives considered:** Let the primary agent assess its own observation; rejected because it lacks an independent challenge. Spawn a subagent only after drafting; rejected because wording the candidate first anchors the review.
- **Status:** Decided
- **Handoff note:** If the active agent host cannot spawn a subagent, the learning workflow stops and reports the limitation; the original task may continue.

### D4 - Attempt evidence-backed five-whys and generalisation (2026-07-11)

- **Decision:** The critical subagent must attempt a five-whys root-cause analysis, tie each answer to evidence or mark it unknown, attempt to generalise the root cause, and test the generalisation against counterexamples and existing guidance.
- **Why:** Recording symptoms creates brittle rules; durable learning needs a defensible cause and a principle that survives beyond the triggering incident.
- **Alternatives considered:** Record the observed correction verbatim; rejected because it may encode a local symptom. Require exactly five causal answers even without evidence; rejected because it encourages fabrication.
- **Status:** Decided
- **Handoff note:** “Attempt” is intentional: the analysis may remain inconclusive, but unknowns must never be invented.

### D5 - Preserve inconclusive observations as candidates (2026-07-11)

- **Decision:** An inconclusive root-cause analysis may still produce a reviewed, non-normative candidate record containing the evidence, attempted analysis, uncertainties, and possible generalisation.
- **Why:** Weak evidence should not change agent behavior, but discarding it prevents later occurrences from strengthening or disproving the pattern.
- **Alternatives considered:** Discard every inconclusive analysis; rejected because recurrence cannot accumulate evidence. Promote the best available explanation despite uncertainty; rejected because speculative guidance would become normative.
- **Status:** Decided
- **Handoff note:** Candidate records do not establish repository rules; future occurrences may link to and re-evaluate them.

### D6 - Use individual timestamped learning files (2026-07-11)

- **Decision:** Store each reviewed learning under `agent-learnings/{date}-{time}-{slug}.md` using a UTC, second-resolution timestamp and a concise slug.
- **Why:** Individual files are independently reviewable, linkable, and less prone to merge conflicts than one append-only global log.
- **Alternatives considered:** Use one append-only `learnings.md`; rejected because unrelated observations would contend for the same file and become difficult to track. Store candidates only in session transcripts; rejected because they are not a durable repository artifact.
- **Status:** Decided
- **Handoff note:** A representative filename is `agent-learnings/2026-07-11-143052Z-missing-skill-bootstrap.md`.

### D7 - Record agent provenance without fabrication (2026-07-11)

- **Decision:** Each learning file records status, observation time, coding agent, session ID, and exact surfaced model identifier. Use `unavailable` when exposed metadata cannot be obtained; omit the model field for Pi.
- **Why:** Provenance makes later review and pattern analysis possible while respecting environments that do not expose every identifier.
- **Alternatives considered:** Require all fields and block recording when one is unavailable; rejected because metadata availability varies by host. Infer missing model or session identifiers; rejected because fabricated provenance is worse than an explicit unknown.
- **Status:** Decided
- **Handoff note:** Do not replace exact model variants with broad family names.

### D8 - Review every repository write, provisionally (2026-07-11)

- **Decision:** Require human review before creating a candidate learning file and again before promoting a candidate into `AGENTS.md` or a skill.
- **Why:** Even non-normative tracked files affect the repository and may accumulate noise; review keeps the learning corpus intentional.
- **Alternatives considered:** Review only promotion into normative guidance; deferred because it is less interruptive but allows unreviewed candidate accumulation. Permit autonomous writes with later Git review; rejected for the initial rollout because the repository should not be silently modified.
- **Status:** Decided
- **Handoff note:** This policy is explicitly provisional. Revisit it if learning prompts become too frequent, candidates are routinely rejected, or ordinary task flow is noticeably disrupted; a likely alternative is end-of-task batched review while retaining mandatory approval.

### D9 - Keep policy concise and procedure in a skill (2026-07-11)

- **Decision:** Put only the learning triggers, safety boundary, and bootstrap fallback in `AGENTS.md`; put the full analysis and recording workflow in `skills/learn-from-interaction/SKILL.md`.
- **Why:** `AGENTS.md` is loaded broadly and should remain concise, while a triggered skill can carry detailed procedural guidance without consuming context on unrelated tasks.
- **Alternatives considered:** Put the entire workflow in `AGENTS.md`; rejected because it would burden every interaction. Put everything only in a skill; rejected because agents need an authoritative trigger and fallback when the skill is missing.
- **Status:** Decided
- **Handoff note:** If the skill is unavailable, guidance should direct the agent to setup when authorised and prevent ad hoc learning writes.

### D10 - Standardise repository-owned skills under skills (2026-07-11)

- **Decision:** Use `skills/<name>/SKILL.md` as the mandatory tracked location and use the repository root as the local `npx skills` source.
- **Why:** `npx skills add . --skill <name>` discovers the conventional `skills/` container reliably, whereas the existing singular `skill/` directory can be skipped when other standard skill directories are present.
- **Alternatives considered:** Keep `skill/` and install from that subdirectory; rejected because it breaks the desired root-source workflow and relies on fragile recursive discovery. Introduce a new `agent-skills/` directory; rejected because `skills/` is already the CLI convention.
- **Status:** Decided
- **Handoff note:** Move the existing `skill/validate` tree to `skills/validate` without losing its eval assets.

### D11 - Make setup the installation entry point (2026-07-11)

- **Decision:** Both platform setup scripts automatically discover and install every repository-owned skill from the repository root with `npx skills`, restore locked external skills, and verify availability.
- **Why:** Contributors and agents should run one documented setup command rather than remember separate per-skill installation commands.
- **Alternatives considered:** Require `npx skills add . --skill <name>` manually for each local skill; rejected because the existing `validate` omission demonstrates that it is easy to forget. Add one hard-coded setup command per skill; rejected because it duplicates the tracked skill inventory and violates current repository conventions.
- **Status:** Decided
- **Handoff note:** Setup remains cross-platform and lockfile-driven for external sources; local skill discovery must be generic rather than naming `validate` or `learn-from-interaction` directly.

### D12 - Register validate through the shared path (2026-07-11)

- **Decision:** Install and verify the existing `validate` skill through the same root-source setup and lockfile lifecycle as future repository-owned skills.
- **Why:** A repository-owned skill already exists but is absent from `skills-lock.json` and therefore is not restored by current setup, providing a concrete acceptance case for the new installation capability.
- **Alternatives considered:** Special-case `/validate` in setup; rejected because it would not prevent recurrence for the next local skill. Leave it source-only and rely on agents to find it directly; rejected because generated agent runtimes do not consistently scan arbitrary tracked paths.
- **Status:** Decided
- **Handoff note:** Clean-setup verification must demonstrate that `/validate` is discoverable after the source directory correction.

### D13 - Enumerate tracked local skill names during setup (2026-07-11)

- **Decision:** Each setup script enumerates the immediate `skills/<name>` directories and invokes `npx skills add . --skill <name> --yes` for each discovered name.
- **Why:** Root-source installation preserves the intended lockfile source, while explicit discovered names prevent repeat setup runs from selecting generated skills under ignored agent directories.
- **Alternatives considered:** Run `npx skills add . --skill '*'`; rejected because root discovery may include generated `.agents/skills` and relock them as local sources. Install from `./skills`; rejected because the agreed canonical source is the repository root. Hard-code names; rejected because future local skills would again require setup edits.
- **Status:** Decided
- **Handoff note:** Directory names and SKILL.md frontmatter names must match; setup should fail clearly when they do not.

### D14 - Separate learning and installation skills (2026-07-11)

- **Decision:** Create `learn-from-interaction` for governed learning and `install-project-skill` for adding or updating project skills.
- **Why:** Learning analysis and skill installation have different triggers, permissions, and failure modes; separate metadata lets agents load only the relevant procedure.
- **Alternatives considered:** Combine both workflows into one maintenance skill; rejected because its trigger description would be broad and its body would mix unrelated authority. Put installation only in `AGENTS.md`; rejected because the multi-step local/external workflow benefits from a reusable procedure.
- **Status:** Decided
- **Handoff note:** `install-project-skill` delegates final materialisation and verification to the current platform setup script.

### D15 - Branch skill installation by source type (2026-07-11)

- **Decision:** For repository-owned skills, place the source under `skills/` and run setup; for external skills, use `npx skills add <source> --skill <name>` to register the source in `skills-lock.json`, then run setup to restore and verify the complete set.
- **Why:** Setup can discover tracked local source automatically, but an external source must be supplied once before the lockfile can reproduce it.
- **Alternatives considered:** Teach setup to accept arbitrary external source parameters; rejected because setup should reproduce tracked state rather than become an ad hoc package-selection interface. Let the installer skill materialise agent directories without setup; rejected because setup is the agreed single installation entry point.
- **Status:** Decided
- **Handoff note:** The installer skill must show and verify the lockfile diff for external additions before treating the workflow as complete.

### D16 - Initialise, validate, and forward-test new skills (2026-07-11)

- **Decision:** Create new skill folders with the skill-creator initializer, validate them with its frontmatter/naming validator, and forward-test both skills on realistic prompts before implementation is considered complete.
- **Why:** The learning skill has subtle trigger and authority boundaries, while the installer must work across clean and repeated setup runs; structural validation alone cannot demonstrate those behaviours.
- **Alternatives considered:** Hand-author only `SKILL.md` files; rejected because it skips deterministic scaffolding and metadata validation. Rely only on reading the skill text; rejected because forward tests expose over-triggering, anchoring, and installation-path mistakes.
- **Status:** Decided
- **Handoff note:** Forward-test agents receive the skill and raw scenario, not the expected diagnosis; the existing `validate` skill is moved intact rather than reinitialised.

### D17 - Package the learning-record template with the skill (2026-07-11)

- **Decision:** Keep the reusable learning-record skeleton as an asset of `learn-from-interaction`, with the skill body defining when and how to fill it.
- **Why:** A bundled output template makes filenames, frontmatter, analysis sections, and disposition consistent without bloating the always-loaded skill description.
- **Alternatives considered:** Repeat the full template inline in `AGENTS.md`; rejected because it adds global context cost. Let each agent invent its own record structure; rejected because later comparison and re-evaluation would be unreliable.
- **Status:** Decided
- **Handoff note:** The asset is source material for a reviewed repository file; the skill must not write it before human approval.

### D18 - Use the stable lockfile restore command (2026-07-11)

- **Decision:** Replace `npx skills experimental_install` with the stable `npx skills install` command in setup, then reconcile tracked repository-owned skills as a distinct phase.
- **Why:** The installed `skills` CLI supports `install` as the lockfile restore interface, while a separate reconciliation phase keeps local discovery explicit and safe.
- **Alternatives considered:** Retain `experimental_install`; rejected because the stable alias now expresses the intended contract. Use only root-source local installation and stop restoring the lockfile; rejected because external skills still require reproducible restoration.
- **Status:** Decided
- **Handoff note:** Verify the command against the lockfile-pinned CLI version on both PowerShell and Bash paths.

### D19 - Normalize local lock sources to the repository root (2026-07-11)

- **Decision:** After local-skill reconciliation, a cross-platform Node helper rewrites tracked local `skills-lock.json` entries from the absolute path emitted by `skills` 1.5.10 to the portable source `.` and validates their expected `skills/<name>/SKILL.md` paths.
- **Why:** `npx skills add .` resolves `.` before writing the project lock, so committing its raw output would embed one machine's absolute checkout path and break restoration in other clones. `npx skills install` can resolve a committed `.` against the current checkout.
- **Alternatives considered:** Commit the absolute source; rejected as non-portable. Exclude all local skills from `skills-lock.json`; rejected because they would not participate in the requested `npx skills install` lifecycle. Install from `./skills`; rejected because the agreed package source is the repository root and the CLI still resolves local paths absolutely. Patch the third-party CLI; rejected because a small repository normalizer is lower risk and remains under project control.
- **Status:** Decided
- **Handoff note:** Setup must finish with `source: "."` for every tracked local skill and fail if a local lock entry points outside the current tracked `skills/` inventory.

### D20 - Use repository-available skill tooling (2026-07-11)

- **Decision:** Supersede D16's dependency on the unavailable `skill-creator` scripts. Initialise new skills with `npx skills init` from the tracked `skills/` directory, validate them with the repository's local-skill validator and `npx skills add . --list`, and retain independent forward testing.
- **Why:** `skill-creator`, its initializer, and its validator are not tracked, locked, or installed by repository setup, so another supported agent cannot execute the original tasks. The locked `skills` CLI and the new tracked validator are reproducible project dependencies.
- **Alternatives considered:** Add the runtime-specific system skill as an implicit prerequisite; rejected because it is unavailable to other agents and has no tracked source. Vendor its scripts; rejected because the CLI already provides initialization and the repository needs only a small validation surface.
- **Status:** Decided; supersedes D16
- **Handoff note:** New project skills contain portable Agent Skills files only; `agents/openai.yaml` is no longer required by this change.

### D21 - Setup is authoritative reconciliation and verification (2026-07-11)

- **Decision:** Clarify D11: setup is the authoritative reconciliation and verification entry point, not the only command that can materialise files. External adoption may run `npx skills add` first because that CLI has no lock-only registration mode, but the workflow is incomplete until setup succeeds.
- **Why:** `npx skills add` immediately installs the selected skill while updating the lockfile, so describing setup as the sole materializer contradicts the required external workflow.
- **Alternatives considered:** Keep the single-materializer wording; rejected as factually false. Build a separate lock-only package editor; rejected because it would duplicate third-party lock semantics and bypass the supported CLI.
- **Status:** Decided; clarifies D11 and D15
- **Handoff note:** Proposal, design, specs, tasks, and `AGENTS.md` wording must consistently use “authoritative reconciliation and verification.”

### D22 - Verify every declared skill after restore (2026-07-11)

- **Decision:** Setup validates canonical `.agents/skills/<name>/SKILL.md` output for every entry in `skills-lock.json` as well as every tracked local skill, and fails if any declared skill is absent.
- **Why:** `skills` 1.5.10 catches and logs per-source restore failures without reliably making the command fail, so checking only local skills can produce a false-successful setup with missing external skills.
- **Alternatives considered:** Trust the `npx skills install` exit code; rejected because the current implementation handles source failures internally. Verify only external command output text; rejected because filesystem state is the actual postcondition.
- **Status:** Decided
- **Handoff note:** The same cross-platform helper can expose the complete expected skill-name set to both setup scripts.

### D23 - Normalize matching absolute entries before rejecting leftovers (2026-07-11)

- **Decision:** For a local entry that matches a tracked `skills/<name>/SKILL.md`, rewrite an absolute source to `.` first. Fail only when an unmatched local entry exists or an absolute local source remains after normalization.
- **Why:** The previous task wording could be read as rejecting the exact absolute entry that D19 requires the helper to repair.
- **Alternatives considered:** Fail on every absolute entry before rewriting; rejected because normal `npx skills add .` always produces that intermediate state. Silently delete unmatched entries; rejected because unexpected lock state requires review.
- **Status:** Decided; clarifies D19
- **Handoff note:** Helper tests must assert both successful repair and post-normalization rejection behavior.

### D24 - Forward-test the planned agent matrix (2026-07-11)

- **Decision:** Forward-test the learning and installation skills in Codex, Claude Code, and Pi sessions, using exact surfaced models when available; a missing planned host is reported as an implementation blocker rather than simulated as a successful model test.
- **Why:** The skills are deliberately distributed across agent hosts and include Pi-specific provenance behavior. Testing only same-model subagents would not validate actual discovery or instruction following across the planned hosts.
- **Alternatives considered:** Test only Codex and infer portability; rejected because the endorsed authoring guidance calls for testing every planned model. Pretend a Codex subagent is Pi; rejected because simulated metadata does not exercise Pi behavior.
- **Status:** Decided
- **Handoff note:** Raw scenarios and expected invariants are shared across hosts; expected answers are not included in the prompts.

### D25 - Use the installed Git Bash for Bash-path verification (2026-07-11)

- **Decision:** On this Windows workspace, run Bash syntax and functional setup checks with `C:\Program Files\Git\bin\bash.exe` in a disposable checkout instead of requiring an unspecified Linux/macOS machine.
- **Why:** Git Bash is installed and retrievable locally, while no WSL distribution, container runtime, CI job, or native Linux/macOS environment is defined by the repository.
- **Alternatives considered:** Require an unspecified native host; rejected as an unretrievable task prerequisite. Add a new CI workflow solely for this change; rejected as unnecessary scope while the existing Bash implementation can be exercised locally.
- **Status:** Decided
- **Handoff note:** This validates the Bash path and POSIX script behavior available in the current development environment without claiming a Flutter macOS build.

### D26 - Split forward testing by actual host (2026-07-11)

- **Decision:** Give each Codex, Claude Code, and Pi installer-skill forward test its own task and disposable checkout rather than grouping the three hosts into one task.
- **Why:** A cross-host task cannot be completed in one focused agent session and obscures which host and surfaced model produced each result.
- **Alternatives considered:** Keep one matrix task; rejected because it fails the mid-level task-size test. Test only one host; rejected because D24 and the endorsed authoring guidance require every planned host and model to be exercised.
- **Status:** Decided
- **Handoff note:** Shared scenarios stay identical, but results and reruns are recorded per actual host.

### D27 - Use a deterministic external-restore failure fixture (2026-07-11)

- **Decision:** Test swallowed external restore failures in a disposable checkout by adding a fixture lock entry whose external source is deliberately unresolvable and whose canonical installed output is absent, then assert setup exits non-zero and names that skill.
- **Why:** Merely deleting a generated external skill usually lets setup restore it successfully and does not prove that canonical verification catches a restore failure hidden by the CLI's successful exit code.
- **Alternatives considered:** Rely on an incidental network outage; rejected because the result is nondeterministic. Mock the entire `skills` CLI; rejected because it would not exercise the pinned CLI's actual per-source error handling.
- **Status:** Decided
- **Handoff note:** Keep the fixture isolated to a disposable checkout and use a clearly nonexistent source and skill name so tracked lock state is never polluted.
