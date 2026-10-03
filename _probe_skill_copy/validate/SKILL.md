---
name: validate
description: Validate that a change is ready to implement — coherent scope, tasks sized and self-contained enough for a mid-level implementer, and conformance to sourced (never assumed) best practices — reporting findings as a table with rubric-grounded severities. Use whenever the user asks to "validate this change", "/validate", "is this change consistent", "is this ready to implement", or wants confidence in a change before building or archiving it. Read-only: reports problems, never edits artifacts.
---

# Change Validation

Judge the **change**, not the paperwork. Structural checks (`openspec validate`) already exist; this skill answers four questions: is the scope coherent, can a mid-level implementer execute the tasks, do the artifacts follow best practices with a citable source, and what exactly is wrong — at a severity another run would reproduce.

**Strictly read-only.** Report findings; never fix, rewrite, or "tidy" anything, even trivially.

## Step 0: Load the change

For an OpenSpec change: resolve it (`openspec list --json` if unnamed → most recent), run `openspec status` and `openspec validate` as preflight (fold structural errors into findings), then read every artifact — decisions log first, it explains why the others say what they say — plus the main specs for touched capabilities. For a non-OpenSpec change (plain branch, PR): read the description, the diff, and any linked issue instead. In both cases skim the code the change references; validation against artifacts alone misses stale claims.

## Check 1: Scope coherence

One change = one coherent intent. Verify:

- Every artifact tells the same story: nothing appears in only one artifact (silent scope growth) and nothing promised early disappears later (silent shrinkage).
- Boundaries are explicit: out-of-scope and deferred items are stated and, where the project requires it, logged with a decision. A deferral that exists only in someone's head is scope ambiguity.
- No two artifacts disagree on vocabulary (one concept, two names), semantics (one term, two meanings), or placement (one feature, two homes).
- Scope is minimal for the stated goal: flag riders that don't serve the change's own "why".

## Check 2: Task implementability — the mid-level test

Calibrate against a competent **mid-level implementer**, defined by capability, not by model name: reliable at local edits and following explicit instructions; unreliable at inferring unstated intent, holding cross-file invariants, or recovering from ambiguous references. (Dated examples as of 2026: Sonnet-, GPT-5.4-, DeepSeek-class models.) For **each task** ask:

- **Retrievable context**: at implementation time, can everything the task needs be retrieved from the artifacts plus the repo — file paths, symbol names, expected behaviour, target values? A task that depends on conversation history, tribal knowledge, or "see discussion" fails this check.
- **Right size**: completable in one focused session; touches a bounded, predictable set of files; does not mix unrelated concerns.
- **Verifiable done-condition**: a test, analyzer/compiler result, or observable behaviour tells the implementer they are finished. "Improve X" has no done-condition.
- **No hidden design**: the task never forces an undocumented design decision. If a mid-level implementer would have to choose between plausible options — and could choose wrong — the design/spec must already have chosen.
- **Ordering**: dependencies precede dependents, and each task group leaves the system building and runnable.

## Check 3: Best practices — sourced or asked, never assumed

Identify the domain(s) the change touches (UI/design system, Flutter/Dart, API design, infra, skill authoring, …). For each domain, find an authoritative source **in this order**:

1. **Project-local sources — discover, don't assume a fixed list.** The repo accumulates its own authority as it matures; sweep for it every run rather than relying on what existed last time. Look at least in: `CLAUDE.md`/`AGENTS.md`; `openspec/config.yaml`; the main specs under `openspec/specs/` (established requirements are settled conventions); decision logs of the current *and archived* changes under `openspec/changes/` (prior decisions bind later changes unless explicitly superseded); project skills (`skill/`, plus installed ones like `flutter-*`, `home-assistant-best-practices`, `frontend-design`); lint/analysis configs; and any `docs/`, ADRs, or style guides that have appeared. Also treat consistently-established code patterns (e.g. an existing shared widget or token system the change should extend rather than bypass) as a local source — cite the file that establishes the pattern.
2. Official documentation of the technology (e.g. Effective Dart, Material 3 guidelines).
3. A source the user has previously endorsed in this repo — check the registry below.

**Endorsed source registry** (append here when the user endorses a source; this is where "previously endorsed" sources live):

- Skill authoring: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (endorsed 2026-07-11)

When local and external sources conflict, the local source wins — the project has already made its choice; flag the conflict itself only as Info unless the change deepens it.

Every best-practice finding must cite its source. **A finding with no citable source is not a finding — it is your taste.** If a domain the change touches has no discoverable source, do not improvise: pause and ask the user to supply or endorse one (name the domains that lack sources, offer candidates if you know credible ones), then continue with what they choose. Record "no source available — user declined to provide" as an Info finding rather than inventing standards.

## Severity rubric — grounded, reproducible

Assign severity by matching **conditions**, not judgment. If a finding matches two levels, take the higher. Do not invent intermediate levels.

| Severity | A finding is this level iff… |
|---|---|
| **Blocker** | Implementing the artifacts as written yields wrong or conflicting behaviour: two artifacts give contradictory instructions for the same thing; a task needs information that exists in no artifact and no repo file; a normative requirement has no covering task; or the change violates a project-local source (main spec, logged decision, pinned guidance, established shared pattern) in code it touches, without a logged decision superseding it. |
| **Major** | Implementation proceeds but a mid-level implementer would plausibly go wrong: a task fails any Check 2 bullet (unretrievable context, no done-condition, hidden design decision, unbounded size, broken ordering); scope exists in exactly one artifact; or a cited non-pinned best practice is violated. |
| **Minor** | Won't change what gets built: superseded vocabulary or stale-but-unmisleading references left in an earlier artifact; redundancy or wording drift between artifacts that agree in substance. |
| **Info** | No action required: observations, sweep-size notes, deferred items confirmed as properly logged, "no source available" records. |

## Output

Lead with a one-line verdict — **Ready to implement** / **Ready with minors** / **Not ready (N blockers/majors)** — then the findings table:

| # | Severity | Where (file · heading or line) | Finding | Evidence (both sides of the disagreement) | Suggested fix |
|---|---|---|---|---|---|

Sort by severity, most severe first. A finding the user cannot locate is not actionable — always give file plus heading or line, and quote or paraphrase the evidence on both sides. Close with one line per check (1–3) stating what was examined and whether it came back clean, and the best-practice sources used per domain. An empty table still gets the verdict line — silence is not a verdict.
