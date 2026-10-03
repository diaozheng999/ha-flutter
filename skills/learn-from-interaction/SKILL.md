---
name: learn-from-interaction
description: 'Assess and preserve durable repository lessons through independent causal analysis and two human review gates. Use when an interaction exposes an explicit user correction, repeated friction, a newly discovered repository invariant, or a workflow repeated enough to be reusable. Do not trigger for a one-off workaround, ordinary implementation detail, or unsupported preference by itself.'
---

# Learn from interaction

Treat every result as provisional until the required reviews finish. Never turn an observation directly into repository guidance.

## 1. Capture the signal without drafting a rule

Collect the raw observation and its evidence: user messages, commands, logs, file locations, repeated occurrences, and relevant existing guidance. Do not write a candidate, suggest the expected diagnosis, or anchor the assessment with a proposed rule.

## 2. Delegate independent critical assessment

Start an independent subagent and give it only the observation, raw evidence, and repository context needed to inspect existing guidance. Ask it to:

1. Assess whether the observation is durable, evidence-backed, reusable, and absent from current guidance.
2. Attempt up to five successive why questions. Attach evidence to every causal answer; stop and mark the next cause unknown when evidence runs out. Never invent steps to reach five.
3. Attempt a generalisation of the supported root cause.
4. Test that generalisation against counterexamples, conflicting occurrences, and existing repository guidance.
5. Return supported why steps, confidence, unknowns, the tentative generalisation, counterexamples, overlap, and a recommendation.

Do not draft before receiving this independent assessment. If the host cannot start an independent subagent, report that the learning branch cannot proceed, perform no learning write, and continue the original task.

## 3. Classify the result

Classify the assessed observation as exactly one of:

- `repository-policy-candidate`: a concise repository-wide invariant or safety boundary.
- `reusable-skill-candidate`: a repeatable procedure that belongs in a focused skill.
- `change-specific-decision`: a choice that applies only to an active OpenSpec change; append it to that change's decision log under its existing rules, not to `agent-learnings/`.
- `non-normative-inconclusive-candidate`: useful evidence whose root cause or generalisation remains uncertain.
- `no-learning-action`: a one-off detail, unsupported preference, duplicate guidance, or disproved generalisation.

For `no-learning-action`, report the disposition and stop. Never promote an inconclusive result as normative guidance.

## 4. Preview a candidate and obtain the first review

For either candidate classification, read [assets/learning-record.md](assets/learning-record.md) and prepare the complete proposed record in the conversation before writing it. Use `agent-learnings/YYYY-MM-DD-HHmmssZ-short-slug.md` with a UTC, second-resolution timestamp.

Record exact exposed provenance. Use `unavailable` rather than inferring a missing coding agent, session ID, or model. For trusted project-local Pi, use the exact per-turn values supplied by `.pi/extensions/runtime-context.ts`; if the extension or a value is unavailable, record `unavailable` rather than guessing.

Ask the user to review the proposed path and full content. Create the file only after explicit approval. If approval is rejected or withheld, create nothing and do not amend another repository artifact as a substitute.

Candidate records are non-normative evidence. Preserve inconclusive why steps, counterexamples, and unknowns rather than making the record sound certain.

## 5. Require a separate promotion review

If a candidate later supports a change to `AGENTS.md` or a skill, preview that exact target diff and obtain a new, separate human approval before editing. Candidate approval never authorises promotion. Rejection leaves the target unchanged.

## Provisional review timing

Review before candidate creation is deliberately provisional. If review prompts become frequent, candidates are routinely rejected, or ordinary task flow is noticeably disrupted, propose a reviewed repository change such as end-of-task batched review. Never relax, defer, or bypass either review gate autonomously.
