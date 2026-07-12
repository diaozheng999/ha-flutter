## 1. Standardise Repository Skill Sources

- [ ] 1.1 Move the complete `skill/validate` tree to `skills/validate` and verify Git recognises `SKILL.md` and every eval asset as preserved content rather than deletion.
- [ ] 1.2 Update tracked references that still identify repository-owned skills under singular `skill/`, then use `rg` to confirm no stale source-layout reference remains outside historical OpenSpec decision entries.
- [ ] 1.3 Run `npx skills add . --list` and confirm `validate` is discovered from `skills/validate/SKILL.md` without changing the skill's validated behavior.

## 2. Build the Portable Local-Skill Validator

- [ ] 2.1 Implement a cross-platform Node helper under `scripts/` that inventories immediate `skills/<name>/SKILL.md` sources, parses their required frontmatter, and fails when a directory name, frontmatter name, or expected path does not agree.
- [ ] 2.2 Extend the helper to find each tracked local skill's lock entry, rewrite a matching machine-specific absolute local source to `.`, preserve hashes and external entries, and fail only when a local entry is unmatched or an absolute local source remains after normalization.
- [ ] 2.3 Make the helper expose the complete expected installed skill-name set formed by the union of lockfile entries and valid tracked local sources, so setup can verify external and repository-owned outputs independently of the `skills` CLI exit code.
- [ ] 2.4 Add Node built-in tests for portable normalization, preserved hashes and external entries, directory/frontmatter/path mismatch, unmatched local entries, leftover absolute sources, union inventory, and an already-normalized byte-identical no-op run.
- [ ] 2.5 Run the helper tests with `node --test` and confirm a second normalization of every successful fixture is byte-identical.

## 3. Create and Validate the Project Skills

- [ ] 3.1 From the tracked `skills/` directory, initialise `learn-from-interaction` with the locked `npx skills init` command and add `assets/learning-record.md`; do not add host-specific metadata files that repository setup cannot reproduce.
- [ ] 3.2 Author the learning-record asset with the UTC filename convention, required provenance frontmatter, Pi model omission, RCA and generalisation sections, review outcome, disposition, and related-learning links from the `agent-learning` spec.
- [ ] 3.3 Author `skills/learn-from-interaction/SKILL.md` with the four concrete triggers, independent unanchored subagent delegation, evidence-backed five-whys and generalisation attempt, classification outcomes, unavailable-subagent stop, and two human review gates.
- [ ] 3.4 Ensure the learning skill treats review-before-record as provisional, identifies the interruption signals from D8, and forbids autonomous relaxation of the review gate.
- [ ] 3.5 From the tracked `skills/` directory, initialise `install-project-skill` with `npx skills init`, then author its `SKILL.md` for repository-owned sources under `skills/` and reviewed external sources registered with `npx skills add <source> --skill <name>`.
- [ ] 3.6 Make the installer withhold success until source review, lockfile review, setup reconciliation, complete canonical installation verification, and idempotence verification pass, while acknowledging that external `skills add` may materialise files before setup.
- [ ] 3.7 Run the tracked local-skill validator and `npx skills add . --list`; resolve every structural or discovery failure and confirm `validate`, `learn-from-interaction`, and `install-project-skill` are listed.

## 4. Reconcile and Verify Skills Through Setup

- [ ] 4.1 Update `scripts/setup.ps1` to run stable `npx skills install`, enumerate valid immediate local skill names without a wildcard or hard-coded inventory, run `npx skills add . --skill <name> --yes` for each, and invoke portable lock normalization.
- [ ] 4.2 After reconciliation, make `scripts/setup.ps1` verify `.agents/skills/<name>/SKILL.md` for every name returned by the union inventory and fail for any missing external or local canonical output even when `npx skills install` returned success.
- [ ] 4.3 Give `scripts/setup.sh` behavior equivalent to the PowerShell path: stable restore, explicit root-source additions, normalization, complete union verification, non-zero failure on missing output, and corrected progress numbering.
- [ ] 4.4 Verify neither setup script names `validate`, `learn-from-interaction`, or `install-project-skill` in its installation logic and neither uses root-source `--skill '*'` or `experimental_install`.
- [ ] 4.5 Update `AGENTS.md` skill-management guidance to declare `skills/` as the tracked source, setup as the authoritative reconciliation and verification entry point, `npx skills add . --skill <name>` as the repository-root source operation, and generated agent directories as ignored outputs.

## 5. Add the Repository Learning Policy

- [ ] 5.1 Add a concise `AGENTS.md` learning section containing only the concrete triggers, prohibition on immediate writes, independent-subagent requirement, mandatory candidate and promotion reviews, provisional-review note, and missing-skill setup fallback.
- [ ] 5.2 Cross-check the `AGENTS.md` policy against `learn-from-interaction` so every normative trigger and safety boundary agrees while detailed RCA, template, and classification instructions remain only in the skill.
- [ ] 5.3 Confirm `agent-learnings/` is not ignored and that no placeholder candidate or normative learning record is created merely to establish the directory.

## 6. Exercise Setup and Lock Portability

- [ ] 6.1 Run `scripts\\setup.ps1 none` from the repository root, review `skills-lock.json`, and verify all three local skills have `source: "."`, expected `skills/<name>/SKILL.md` paths, and no machine-specific checkout path.
- [ ] 6.2 Verify every previously locked external skill remains declared and canonically installed; in a disposable checkout add a clearly named fixture lock entry with a deliberately nonexistent external source, ensure its canonical output is absent, and confirm setup exits non-zero and names the missing fixture skill even if `npx skills install` completes successfully.
- [ ] 6.3 Run the Windows setup script a second time without source changes and confirm `skills-lock.json` is byte-identical and every lockfile and tracked-local skill remains present under `.agents/skills/`.
- [ ] 6.4 Use `C:\\Program Files\\Git\\bin\\bash.exe` to run `bash -n scripts/setup.sh`, then execute the Bash setup path in a disposable checkout and confirm its portable lock, complete verification, and canonical outputs match the Windows behavior.
- [ ] 6.5 In a disposable checkout with generated agent directories absent, run each setup path and confirm external skills plus every repository-owned skill, including `/validate`, are restored solely from tracked state.

## 7. Forward-Test Skill Behavior on Planned Hosts

- [ ] 7.1 In an actual Codex session with its exact surfaced model recorded, test `learn-from-interaction` using raw prompts for an explicit correction, repeated friction, a negative one-off detail, inconclusive five-whys, conflicting counterexamples, unavailable metadata, and unavailable delegation; confirm the specified gates and classifications.
- [ ] 7.2 Repeat the same raw learning scenarios in an actual Claude Code session, recording its exact surfaced model; do not seed the fresh session with the expected diagnosis or prior conclusions.
- [ ] 7.3 Repeat the same raw learning scenarios in an actual Pi session and confirm the record omits the model field while retaining coding-agent and session provenance.
- [ ] 7.4 In an actual Codex session, forward-test `install-project-skill` in a disposable checkout for a new local skill, repeat setup, a reviewed external source, and the D27 missing-output fixture; confirm root-source selection, portable locking, setup completion, idempotence, and failure reporting.
- [ ] 7.5 Repeat the same raw installer scenarios in an actual Claude Code session with a fresh disposable checkout and its exact surfaced model recorded.
- [ ] 7.6 Repeat the same raw installer scenarios in an actual Pi session with a fresh disposable checkout and model metadata omitted.
- [ ] 7.7 Treat any unavailable planned host as an explicit implementation blocker with the unrun scenarios listed; do not substitute same-model subagents or simulated host labels for a successful host test.
- [ ] 7.8 Revise and rerun every failed scenario with a fresh session on the affected host until all planned-host scenarios pass.

## 8. Final Validation

- [ ] 8.1 Run `npx openspec validate enable-agent-learning` and resolve every structural or scenario-format error in the change artifacts.
- [ ] 8.2 Run the tracked local-skill validator, Node helper tests, both setup syntax checks, representative disposable-checkout setup tests, and the complete forward-test matrix from the final tracked state.
- [ ] 8.3 Run the repository `validate` skill against the completed change and resolve every blocker or major finding before declaring it implementation-ready.
- [ ] 8.4 Run `git diff --check` and inspect `git status` to confirm only intended tracked sources, OpenSpec artifacts, setup/tooling changes, guidance, and `skills-lock.json` are present; generated agent directories and `node_modules` remain ignored.
