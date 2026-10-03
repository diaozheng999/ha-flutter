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

### D28 - Preserve validate wording while repairing YAML syntax (2026-07-12)

- **Decision:** Quote the existing `validate` frontmatter description without changing its text or procedural body.
- **Why:** After relocation, `npx skills add . --list` skipped `validate` because the current CLI's YAML parser rejects the unquoted `Read-only:` substring. Quoting the scalar makes the existing metadata valid while preserving behavior.
- **Alternatives considered:** Rewrite or shorten the description; rejected because task 1.3 requires preserving validated behavior. Leave it invalid and special-case discovery; rejected because every repository-owned skill must pass the shared CLI path.
- **Status:** Decided
- **Handoff note:** Treat this as a syntax repair only; the skill's triggers and read-only contract remain unchanged.

### D29 - Give setup one validated skill-inventory interface (2026-07-12)

- **Decision:** Implement the Node helper with `local`, `normalize`, and `expected` commands. `local` emits validated tracked names, `normalize` repairs and validates local lock entries, and `expected` emits the union of locked and tracked names.
- **Why:** Both setup scripts need the same three boundaries at different phases. A shared command interface prevents PowerShell and Bash from independently parsing skill frontmatter or inferring lock semantics.
- **Alternatives considered:** Emit one compound JSON document and make each shell parse it; rejected because native JSON handling differs substantially between the two shells. Duplicate enumeration in each setup script; rejected because it would create divergent validation behavior.
- **Status:** Decided
- **Handoff note:** Successful list commands write one skill name per stdout line; diagnostics go to stderr so shell capture remains deterministic.

### D30 - The locked skills CLI has no stable install command (2026-07-12)

- **Decision:** Pause setup implementation rather than silently substitute `experimental_install` for the required `skills install` command.
- **Why:** The functional Windows setup run with locked `skills` 1.5.10 failed at `npx skills install`; the CLI parsed it as an add invocation and reported a missing source. Its own help lists only `experimental_install` for lockfile restoration. This directly contradicts D18 and the stable-restore requirements.
- **Alternatives considered:** Revert both scripts to `experimental_install`; technically compatible but violates the current spec, tasks, design, and D18, so it requires an artifact decision first. Add a repository wrapper while continuing to say `npx skills install`; rejected because it would not make that third-party command real. Change or fork the dependency; possible but materially expands scope and needs an explicit choice.
- **Status:** Blocked pending artifact direction
- **Handoff note:** Tasks 4.1 and 4.3 were reopened. The first functional setup attempt stopped before local reconciliation and tasks 6.1-6.5 remain unverified.

### D31 - Use the supported experimental lockfile restore command (2026-07-12)

- **Decision:** Use `npx skills experimental_install` in both setup scripts and update the change artifacts to describe it as the supported restore command for locked `skills` 1.5.10.
- **Why:** The user explicitly selected this resolution after D30 demonstrated that `skills install` does not exist in the locked CLI. Reproducible restoration is more important than retaining an unavailable command name.
- **Alternatives considered:** Change or fork the CLI to add `install`; rejected by the user choice and unnecessary for the learning capability. Omit lockfile restoration; rejected because external skills must remain reproducible.
- **Status:** Decided; supersedes D18 and resolves D30
- **Handoff note:** Keep canonical output verification because `experimental_install` may log a per-source failure without returning a failing exit code.

### D32 - Populate omitted local skill paths during normalization (2026-07-12)

- **Decision:** When a matching `sourceType: "local"` lock entry omits `skillPath`, have the shared helper populate the validated inventory path `skills/<name>/SKILL.md`; continue rejecting any conflicting path.
- **Why:** Locked `skills` 1.5.10 does not write `skillPath` for local sources because its path mapping is only built for cloned sources. Setup nevertheless requires portable local entries with an explicit expected path, and the validated tracked inventory makes that value deterministic.
- **Alternatives considered:** Relax the path requirement and leave it absent; rejected because it weakens portable lock validation and contradicts the required postcondition. Patch the third-party CLI; rejected because the repository helper already owns normalization of its local lock output.
- **Status:** Decided
- **Handoff note:** Preserve `computedHash` byte-for-byte while adding the path and normalizing the absolute source to `.`.

### D33 - Use a missing node_modules skill for the false-success fixture (2026-07-12)

- **Decision:** Implement D27's disposable missing-output fixture as a clearly nonexistent external `node_modules` skill entry rather than a missing Git repository.
- **Why:** In `skills` 1.5.10, Git clone and source-parse failures terminate `experimental_install` with exit code 1 before setup can reach canonical verification. The node_modules restore branch catches missing sync inputs and returns success, allowing the required verification failure to be exercised deterministically.
- **Alternatives considered:** Keep a missing GitHub repository; rejected because it only tests restore exit propagation. Mock the CLI; rejected by D27 because it would not exercise the real locked implementation.
- **Status:** Decided; refines D27
- **Handoff note:** The fixture remains disposable and must be absent from both tracked lock state and canonical output.

### D34 - Claude Code and Pi forward-test hosts are unavailable (2026-07-12)

- **Decision:** Run the available Codex forward tests in fresh Codex subagent sessions, but treat the Claude Code and Pi matrix rows as unrun blockers.
- **Why:** Host discovery finds the Codex application but no `claude` or `pi` executable. D24 and task 7.7 prohibit substituting Codex subagents or simulated labels for those actual hosts.
- **Alternatives considered:** Simulate Claude Code and Pi with Codex prompts; rejected by D24. Install new host tooling without an explicit repository or user installation workflow; rejected as an unauthorized scope expansion.
- **Status:** Blocked for Claude Code and Pi host rows; Codex testing continues
- **Handoff note:** Unrun scenarios are learning cases 7.2-7.3 and installer cases 7.5-7.6. Record exact surfaced metadata for Codex when available; otherwise report it as unavailable rather than infer it.

### D35 - Codex learning forward test passes (2026-07-12)

- **Decision:** Accept the Codex `learn-from-interaction` forward-test result without revising the skill.
- **Why:** Fresh Codex handling of all seven raw scenarios respected trigger boundaries, performed unanchored independent assessment where warranted, deduplicated existing guidance, avoided promoting inconclusive or conflicting evidence, used unavailable metadata without inference, stopped when delegation was unavailable, and made no repository writes.
- **Alternatives considered:** Add more prescriptive classification wording; rejected because the observed behavior already matched the specification without anchoring the agent. Treat unavailable model/session metadata as a failure; rejected because the provenance requirement explicitly permits `unavailable` when the host does not expose values.
- **Status:** Passed on Codex; coding agent `codex`, surfaced model `unavailable`, session ID `unavailable`
- **Handoff note:** Claude Code and Pi learning rows remain unrun under D34.

### D36 - Align forward-test task metadata with unavailable provenance (2026-07-12)

- **Decision:** Clarify the Codex and Claude Code forward-test tasks to record the exact surfaced model when available and `unavailable` otherwise.
- **Why:** The repository `validate` audit found that the task wording required an exact model unconditionally, while the agent-learning spec, D7, D24, and D34 explicitly prohibit inference and permit unavailable exposed values.
- **Alternatives considered:** Treat the Codex result as failed because its model was not exposed; rejected because that would contradict the normative provenance behavior. Infer a model family from the host; rejected by D7.
- **Status:** Decided
- **Handoff note:** The wording correction resolves the artifact contradiction; actual Claude Code and Pi host absence remains the implementation blocker.

### D37 - Codex installer forward test passes (2026-07-12)

- **Decision:** Accept the Codex `install-project-skill` forward-test result without revising the skill.
- **Why:** In a clean disposable checkout, a new local skill used the root source, normalized to `source: "."` with its expected path and hash, survived two byte-identical setup runs, and appeared canonically. A reviewed external re-registration produced no lock diff, and the missing node_modules fixture reached canonical verification and failed naming the absent skill. The workflow correctly withheld external adoption pending exact-source human acceptance.
- **Alternatives considered:** Treat source-selection approval as approval of the exact reviewed external contents; rejected because the skill intentionally separates source review from selection. Revise around the PowerShell `npx.ps1` policy failure; rejected because repository setup and the successful test use the platform-compatible command path.
- **Status:** Passed on Codex; coding agent `codex`, exact model variant unavailable, thread `019f55a5-2fb6-7dd0-b401-90a3fe495381`
- **Handoff note:** The disposable checkout and all its artifacts were safely removed. Claude Code and Pi installer rows remain unrun under D34.

### D38 - Claude Code learning forward test passes (2026-07-12)

- **Decision:** Accept the Claude Code `learn-from-interaction` forward-test result without revising the skill; unblocks the Claude Code learning row (task 7.2) previously blocked under D34.
- **Why:** A real Claude Code session ran all seven raw learning scenarios. The primary host delegated each triggering observation to a fresh, unanchored subagent that never received an expected diagnosis. Every specified gate and classification held: durable-but-documented signals were deduplicated (S1 skill-source correction, S5 disproved `.mjs` generalisation, S6 setup-root authority), an ungrounded repeated-friction observation was refused rather than canonised (S2 nonexistent `previews.dart`), the inconclusive case stopped the five-whys at the evidence boundary and marked the next cause `unknown` without fabrication (S4 transient linker), the one-off detail never started the workflow (S3 single-build env var), and the constructed no-delegation case halted the learning branch, wrote nothing, and allowed the original task to continue (S7). No repository writes occurred. Fully-exposed provenance recorded exact values (coding agent `claude-code`, model `claude-opus-4-8`, session `87d7cb1f-a792-4ee6-aa87-d2a5eac9675f`); the unavailable-metadata branch was confirmed to write `unavailable` without inference.
- **Alternatives considered:** Add more prescriptive classification wording; rejected because observed behavior already matched the spec without anchoring the agent. Force a constructed scenario to a promotable candidate to exercise the review gate; rejected because the honest unanchored assessments correctly declined, and the review gate was instead exercised by a genuinely emergent non-normative candidate (a discoverability/timing gap surfaced independently by the S1 and S6 assessors), previewed to the user with no write pending approval.
- **Status:** Passed on Claude Code; coding agent `claude-code`, model `claude-opus-4-8`, session `87d7cb1f-a792-4ee6-aa87-d2a5eac9675f`. Pi learning row (7.3) remains unrun under D34.
- **Handoff note:** S3 and S7 are structural gate checks decided at the primary level; S7's no-subagent condition is a legitimate constructed environment constraint, matching how the Pi/Codex hosts must construct that branch. The emergent candidate preview was not written; it awaits the human review gate.

### D39 - Final validation passes (2026-07-19)

- **Decision:** All final validation checks pass; the change is implementation-ready.
- **Why:**
  - `npx openspec validate enable-agent-learning` passes (task 8.1).
  - Tracked local-skill validator (`npx skills add . --list`) discovers all three local skills.
  - Node helper tests (`project-skills.test.mjs`) all 7 pass.
  - Both setup scripts pass syntax checks (PowerShell runs, Bash `bash -n` clean).
  - Setup runs successfully on Windows, produces portable `skills-lock.json` with `source: "."` for all local skills, and verifies all 20 canonical skill outputs.
  - Second setup run leaves `skills-lock.json` byte-identical (idempotent).
  - `git diff --check` passes (only CRLF warnings on Windows).
  - `git status` shows only intended tracked changes: `AGENTS.md`, OpenSpec artifacts, setup scripts, `skills-lock.json`, new `scripts/project-skills.mjs`, `scripts/project-skills.test.mjs`, new `skills/` directory, and removal of legacy `skill/validate/`.
  - Generated agent directories (`.agents/`, `.codex/`, etc.) and `node_modules/` remain ignored.
- **Alternatives considered:** None; all validation criteria met.
- **Status:** Decided
- **Handoff note:** Tasks 7.3, 7.5, 7.6, 7.8 remain blocked on Pi and Claude Code host availability per D34/D38. The change is complete for the available host (Codex).

### D40 - Pi runtime identity is host-visible but not prompt-visible by default (2026-07-19)

- **Decision:** Treat the unconditional Pi model-omission assumption as unsupported and reopen the change's Pi provenance design. A real Pi 0.80.6 session exposes exact provider, model, and session values in host event metadata, and an allowlisted per-turn extension can make those values available to the model. Keep the extension disposable until its permanent repository placement and the affected artifact supersessions are reviewed.
- **Why:** Without an extension, Pi's NVIDIA-backed assistant said its provider and model were unavailable even though the same JSON event identified `provider: "nvidia"`, `model: "nvidia/nemotron-3-ultra-550b-a55b"`, and session `019f7933-3d3b-7570-8deb-0c457fe04b54`. An ignored `.pi/extensions/runtime-context.ts` prototype then read `ctx.model`, `ctx.sessionManager.getSessionId()`, `ctx.mode`, and `ctx.cwd` in `before_agent_start`. Explicit loading and trusted project-local auto-discovery each produced a fresh session whose self-report exactly matched the authoritative host metadata. Independent unanchored assessment classified the correction as change-specific and confirmed the result at high confidence.
- **Alternatives considered:** Preserve Pi's unconditional omission; rejected because it now contradicts direct host and end-to-end evidence. Parse JSON events only outside Pi; rejected because that verifies provenance but does not let Pi use it. Install a global user extension; rejected for now because it is not repository-scoped or reproducible. Track the conventional `.pi/extensions/` source directly or track it elsewhere and have setup reconcile generated output; both remain viable pending a scoped implementation decision.
- **Status:** Evidence confirmed; permanent artifact and implementation direction pending
- **Handoff note:** The prototype is ignored evidence, not durable source. Any adopted extension must inject only explicitly allowlisted non-secret fields, retain `unavailable` when `ctx.model` is absent, run per turn so model changes do not go stale, account for Pi project trust, supersede D7's Pi exception, and reconcile the current mismatch where task 7.3 is checked while D39 still calls it blocked.

### D41 - Track a project-local Pi runtime identity extension (2026-07-19)

- **Decision:** Track the validated extension directly at Pi's conventional `.pi/extensions/runtime-context.ts` path, with narrow `.gitignore` exceptions for that file only. On every `before_agent_start`, inject an authoritative, JSON-encoded allowlist containing `coding_agent`, `provider`, `model`, `session_id`, `mode`, `working_directory`, and `observed_at`; use `unavailable` for an absent model or provider and never expose credentials or registry state. Require exact surfaced model metadata for Pi under the same fallback rule as other agents.
- **Why:** The user approved the direct tracked-path recommendation after D40's explicit-load and trusted auto-discovery tests succeeded. Direct conventional placement gives Pi automatic, project-scoped discovery without a global user installation, setup copy, duplicate source, or stale generated output. Per-turn calculation follows model/session changes, JSON encoding constrains dynamic values, and the allowlist contains the provenance needed by learning records while excluding secrets.
- **Alternatives considered:** Track the source elsewhere and copy it into ignored `.pi/` from setup; rejected because it duplicates source and adds reconciliation machinery for a file Pi can load directly. Install globally; rejected because it escapes repository scope. Keep the model field optional only for Pi; rejected because the host now exposes an exact identifier and the existing unavailable fallback already covers missing values.
- **Status:** Decided by explicit user approval; supersedes D7's Pi omission and resolves D40's pending direction
- **Handoff note:** Update the proposal, agent-learning spec, design, tasks, learning skill/template, `.gitignore`, and `AGENTS.md` provenance/commit guidance. Reopen and rerun Pi learning provenance plus final validation from the durable tracked state; Pi project trust remains an explicit runtime precondition for automatic project-local loading.

### D42 - Tracked Pi runtime identity passes host-metadata verification (2026-07-19)

- **Decision:** Accept the tracked `.pi/extensions/runtime-context.ts` implementation and its exact-model provenance behavior without revision.
- **Why:** Three Node tests pass for the allowlisted exact values, absent-model fallback, and per-turn `before_agent_start` injection. In a fresh trusted Pi 0.80.6 JSON session, automatic project-local discovery produced coding agent `pi`, provider `nvidia`, model `nvidia/nemotron-3-ultra-550b-a55b`, session `019f7944-1d99-7269-962d-f8a1005c6f48`, mode `json`, the exact working directory, and UTC observation time `2026-07-19T07:25:35.137Z`; strict assertions matched every self-reported value to Pi's authoritative session or assistant event metadata. A matching `--no-extensions` control retained the same host provider/model while the assistant reported both as unavailable, proving the extension supplies otherwise absent prompt context rather than eliciting a guess.
- **Alternatives considered:** Trust the assistant's self-report without event comparison; rejected because the original failure showed those evidence channels differ. Keep the prototype list format; rejected in favor of JSON encoding and an explicitly testable field allowlist. Add provider secrets or registry details; rejected as unnecessary and unsafe.
- **Status:** Passed on Pi; exact model and session surfaced
- **Handoff note:** Automatic discovery requires project trust. The identity extension itself is complete; remaining Pi forward-test work concerns the learning and installer skill scenarios, not runtime provenance transport.

### D43 - Repository-bearing Pi forward tests require explicit disclosure approval (2026-07-19)

- **Decision:** Pause the Pi learning and installer workflow rows rather than work around the environment's data-loss safeguard. Continue only local validation and setup checks until the user explicitly approves sending repository instructions and disposable-checkout contents to the configured external NVIDIA endpoint.
- **Why:** The first two fresh Pi installer attempts made no changes because Nemotron emitted textual multi-tool JSON instead of native calls, although a repository-free single-command smoke test proved native tool execution works. The proposed safer rerun decomposed the workflow into atomic native-tool turns, but the environment rejected the first repository read because it would transmit private `skills/install-project-skill/SKILL.md` content to Pi's external NVIDIA-backed model. The rejection explicitly prohibits indirect execution or policy circumvention without informed user approval.
- **Alternatives considered:** Simulate Pi with Codex or another host; rejected by D24. Drive the repository actions locally and label them Pi results; rejected because that would not test Pi instruction following. Switch models silently; rejected because it would not test the user's configured model and would still disclose repository content. Circumvent the safeguard through shell indirection; prohibited and rejected.
- **Status:** Blocked pending explicit informed approval for repository disclosure to Pi/NVIDIA
- **Handoff note:** The runtime identity extension remains accepted because its strict tests used only the explicit test prompt and allowlisted metadata. Tasks 7.3, 7.6, and therefore 7.8 cannot complete until disclosure is approved; task 7.5 separately remains blocked because `claude` is absent from the current PowerShell host.

### D44 - Tenant policy blocks repository-bearing Pi verification (2026-07-19)

- **Decision:** Do not retry or indirectly reproduce repository-bearing Pi forward tests in this environment. Keep the Pi learning and installer rows blocked unless a materially safer test is designed or the tenant policy changes.
- **Why:** After the user agreed to try the informed verification, the first fresh trusted Pi learning run was rejected before execution. The safeguard states that tenant policy forbids sending private repository instructions and workspace contents to the external NVIDIA-backed endpoint even with explicit user approval, and explicitly prohibits workarounds, indirect execution, or policy circumvention. No repository content reached Pi during the rejected attempt.
- **Alternatives considered:** Retry with different quoting, inline the private skill text, or have a local wrapper feed repository files to Pi; all are equivalent disclosure attempts and explicitly prohibited. Label local Codex execution as Pi verification; rejected by D24. Use only repository-free synthetic metadata prompts; safe but insufficient for tasks 7.3 and 7.6 because it would not test Pi against the tracked skills or disposable repository workflow.
- **Status:** Blocked by tenant data-loss policy
- **Handoff note:** The tracked runtime identity result in D42 remains valid because it exposed only the reviewed allowlisted metadata. Tasks 7.3, 7.6, 7.8, 8.2, and 8.3 remain incomplete; task 7.5 remains separately blocked by the absent `claude` executable.

### D45 - Identity-only Pi verification passes under the safe boundary (2026-07-19)

- **Decision:** Accept a fresh identity-only verification as additional confirmation of the tracked runtime extension, without treating it as completion of the repository-bearing Pi skill tests.
- **Why:** Pi ran in a newly created empty temp directory with context files, skills, prompt templates, themes, built-in tools, and session persistence disabled. The tracked extension was loaded explicitly and supplied only its reviewed runtime allowlist. Pi's authoritative JSON assistant event and its self-report matched exactly on provider `nvidia`, model `nvidia/nemotron-3-ultra-550b-a55b`, session `019f79e8-ddbb-754a-8125-f24722f597bb`, JSON mode, and the temporary working directory; the reported observation time was `2026-07-19T10:25:32.157Z`. The scratch directory was removed after the successful run.
- **Alternatives considered:** Omit the safe rerun because D42 already passed; rejected because the user explicitly asked to verify the behavior again. Treat the metadata-only result as completing tasks 7.3 or 7.6; rejected because those tasks require the tracked learning and installer skills plus repository workflow context that tenant policy blocks.
- **Status:** Passed for identity transport only; repository-bearing Pi rows remain blocked
- **Handoff note:** The exact Pi commit trailer may use `(pi, nvidia/nemotron-3-ultra-550b-a55b)`. Tasks 7.3, 7.6, 7.8, 8.2, and 8.3 remain incomplete under D44.
