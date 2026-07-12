## ADDED Requirements

### Requirement: Concrete interactions trigger learning consideration
Repository agent guidance SHALL require the `learn-from-interaction` workflow when an interaction exposes an explicit user correction, repeated friction, a newly discovered repository invariant, or a workflow repeated enough to be reusable. The guidance SHALL NOT treat a one-off workaround, ordinary implementation detail, or unsupported preference as sufficient by itself.

#### Scenario: Explicit correction triggers consideration
- **GIVEN** a user corrects an agent's mistaken assumption about the repository
- **WHEN** the correction could affect future agent work
- **THEN** the agent invokes the learning workflow before proposing durable guidance

#### Scenario: One-off detail does not trigger learning
- **GIVEN** an agent makes a task-local implementation choice with no evidence of reuse
- **WHEN** the task completes without correction, repeated friction, or a new invariant
- **THEN** the agent completes the task without starting the learning workflow

### Requirement: Independent critical assessment precedes drafting
Before drafting or recording a repository learning, the primary agent MUST delegate critical assessment to an independent subagent. The subagent MUST receive the observation and raw evidence without a prewritten candidate or expected conclusion, and MUST assess durability, reuse, evidence, and overlap with existing guidance.

#### Scenario: Independent assessment receives unanchored evidence
- **GIVEN** a concrete learning signal has been detected
- **WHEN** the primary agent starts critical assessment
- **THEN** it sends the independent subagent the observation and evidence without supplying a proposed rule as the expected answer

#### Scenario: Subagents are unavailable
- **GIVEN** the active agent host cannot start an independent subagent
- **WHEN** a learning signal is detected
- **THEN** the agent reports that learning cannot proceed, performs no learning write, and allows the original task to continue

### Requirement: Critical assessment attempts causal analysis and generalisation
The critical subagent MUST attempt a five-whys root-cause analysis, attach evidence to each causal answer or mark it unknown, attempt to generalise the root cause, test counterexamples, and compare the result with existing repository guidance. It MUST NOT invent missing causes to complete five levels.

#### Scenario: Evidence supports a generalised lesson
- **GIVEN** the observation has repository evidence for a causal chain
- **WHEN** the subagent performs the assessment
- **THEN** it returns the supported why steps, proposed generalisation, counterexamples considered, and existing-guidance comparison

#### Scenario: Causal evidence runs out
- **GIVEN** evidence does not support another why step
- **WHEN** the subagent reaches that point
- **THEN** it marks the remaining cause as unknown and reports the analysis as inconclusive rather than fabricating an answer

### Requirement: Learning results are classified before recording
The primary agent SHALL classify an assessed observation as a repository policy candidate, reusable skill candidate, change-specific decision, non-normative inconclusive candidate, or no-learning action. An inconclusive result MAY be proposed as a candidate record but MUST NOT be promoted as normative guidance.

#### Scenario: Change-specific decision is routed to OpenSpec
- **GIVEN** an assessment applies only to an active OpenSpec change
- **WHEN** the primary agent classifies the result
- **THEN** it routes the decision to that change's decision log instead of proposing repository-wide guidance

#### Scenario: Inconclusive observation remains non-normative
- **GIVEN** an assessment finds useful evidence but cannot establish a defensible generalisation
- **WHEN** the primary agent classifies the result
- **THEN** it may preview a non-normative candidate containing the evidence and unknowns but does not propose a policy or skill change

### Requirement: Human review gates every learning write
The primary agent MUST present the proposed candidate content for human review before creating a file under `agent-learnings/`. Promotion from a candidate into `AGENTS.md` or a skill MUST require a separate human review. Rejection at either gate MUST leave the proposed target unchanged.

#### Scenario: Candidate creation is approved
- **GIVEN** the primary agent has prepared a candidate preview after independent assessment
- **WHEN** the user approves creation
- **THEN** the agent writes the reviewed content to the required learning-record path

#### Scenario: Candidate creation is rejected
- **GIVEN** the primary agent has prepared a candidate preview
- **WHEN** the user rejects or withholds approval
- **THEN** the agent creates no learning file and does not silently amend another repository artifact

#### Scenario: Candidate promotion requires new approval
- **GIVEN** a candidate record already exists
- **WHEN** an agent proposes turning it into `AGENTS.md` guidance or a skill
- **THEN** the target artifact remains unchanged until the user separately approves the promotion

### Requirement: Learning records use stable filenames and provenance
Each learning record MUST use `agent-learnings/YYYY-MM-DD-HHmmssZ-short-slug.md` with a UTC, second-resolution timestamp. Its frontmatter MUST include `status`, `observed_at`, `coding_agent`, and `session_id`, plus the exact surfaced `model` identifier for agents other than Pi. Unavailable exposed values MUST be recorded as `unavailable`; Pi records MUST omit `model`.

#### Scenario: Fully exposed metadata is recorded
- **GIVEN** the coding agent exposes its exact agent name, model variant, session ID, and observation time
- **WHEN** an approved candidate file is created
- **THEN** the filename and frontmatter contain those exact values in the required format

#### Scenario: Metadata is unavailable
- **GIVEN** a non-Pi agent does not expose its model or session ID
- **WHEN** an approved candidate file is created
- **THEN** the corresponding value is `unavailable` and no value is inferred

#### Scenario: Pi creates a record
- **GIVEN** Pi creates an approved candidate file
- **WHEN** it writes the provenance frontmatter
- **THEN** it records `coding_agent: pi` and the session ID but omits the `model` field

### Requirement: Learning records preserve assessment evidence
Each learning record MUST contain the observation, evidence, five-whys attempt, confidence and unknowns, proposed generalisation, counterexamples, existing-guidance check, recommendation, human review outcome, and links to related occurrences or promoted guidance when they exist.

#### Scenario: Approved inconclusive candidate is recorded
- **GIVEN** an inconclusive candidate has been approved for recording
- **WHEN** the agent creates the file from the bundled template
- **THEN** the file preserves the available evidence, failed or unknown why steps, tentative generalisation, counterexamples, and non-normative disposition

### Requirement: Policy remains concise and bootstrap-safe
`AGENTS.md` MUST contain the learning triggers, prohibition on immediate learning writes, independent-subagent requirement, human-review boundary, and setup fallback. The detailed procedure and record template MUST reside in `learn-from-interaction`. If that skill is missing, agents MUST NOT improvise the learning procedure.

#### Scenario: Learning skill is missing
- **GIVEN** `AGENTS.md` identifies a concrete learning signal but `learn-from-interaction` is unavailable
- **WHEN** the agent handles the signal
- **THEN** it reports the missing skill, uses the platform setup script when authorised, and performs no ad hoc learning write

### Requirement: Review-before-record remains provisional
Repository guidance SHALL identify review before candidate creation as a provisional policy and SHALL direct maintainers to reconsider its timing if prompts become frequent, candidates are routinely rejected, or ordinary task flow is noticeably disrupted. Agents MUST NOT relax the gate without a reviewed repository change.

#### Scenario: Review prompts become disruptive
- **GIVEN** normal usage shows repeated interruption or frequent candidate rejection
- **WHEN** an agent or maintainer evaluates the learning workflow
- **THEN** it proposes a reviewed policy change, such as end-of-task review, instead of bypassing approval autonomously
