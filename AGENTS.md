# ha-flutter

Custom Home Assistant frontend built with Flutter, targeting Android and Windows.
iOS and macOS platform directories are present but builds require Xcode on a Mac.

## Commit Messages

All commits must follow this format:

```
type: concise description (<tool>, <model>)
```

**Types:** `feat` | `fix` | `refactor` | `docs` | `test` | `chore` | `build` | `ci`

Keep the description short and imperative (for example, `add login screen`, not `added login screen`). The trailer identifies the tool and exact model variant that produced the commit. Use the clearest surfaced model identifier rather than a family name: for example, `(codex, gpt-5.6-terra)`, not `(codex, gpt-5)`. For `pi`, use `(pi)` because its model is not exposed.

## Decision Log & Handoff

Every new OpenSpec change uses the `spec-driven-decisions` schema. After the proposal, create `decisions.md` immediately and append a dated entry whenever a decision or important consideration emerges--during exploration, planning, design, or implementation. Do not defer this until the end of a phase.

Each entry records the decision, why it was chosen, alternatives considered, status, and a handoff note. The log is append-only: supersede a prior choice with a new entry rather than editing history. Any agent taking over a change must read its `decisions.md` first; it is the authoritative handoff record.

The schema enforces this in three places: its dependency graph blocks specs and design until the log exists, each artifact includes logging instructions, and `openspec/config.yaml` injects project rules. Use `/grill-me` while exploring a plan or design; the proposal step requires it unless the idea was already grilled during exploration.

## Learn From Corrections Automatically

- Treat user corrections as standing constraints. Apply them immediately, update the active handoff and affected plan, and stop any conflicting activity. Do not wait for the user to request a learning step or repeat the correction.
- When a mistake exposes a repeatable workflow failure, add a concise, actionable prevention rule to the existing project instructions or relevant procedure during the same task. Record the cause and corrective action in the decision log; an apology alone is not a completed correction.
- Before claiming required data is missing or inaccessible, or asking the user to repeat completed work, check the related predecessor task and its actual results as well as local artifacts. A failed interface search is limited to that interface and time; it does not override a later successful access path.
- Preserve recovered facts with their concrete source, access path, and reusable result in the authoritative handoff. Resolve stale Context statements and append a superseding decision without rewriting decision history. Never leave essential results only in a previous conversation.
- Use existing learned codes, exports, and reference data before proposing acquisition or relearning. If the user prohibits captures, do not run capture sessions or request acquisition presses. Use the verification surface the user requested; for this LilyGo change, reception is checked on the physical OLED.
- Scope a verification request to the path being changed. For LilyGo's Broadlink-code work, "all buttons" means all updated Broadlink commands; keep physical-remote acceptance intact unless the user explicitly asks to retest those remotes. Before requesting a repeat or rewriting values, check the recorded rollout and current live state. Define a concise result format so an event-number reply can confirm the stated expected outcome without repeated follow-up questions.
- Trace wall-button action automations before interpreting switch state. In the Study/Bedroom Mistral setup, wall-button actions call the virtual fan/light entities; the Zigbee relay entities report power-circuit state and are not the virtual appliance's on/off or selected-button state. Verify the existing helper-to-template path before adding another synchronization path.
- Distinguish verified behavior, user-directed acceptance, and unobserved outcomes. Do not infer a failed physical action from silent logs when the action was never confirmed.
- For native firmware logic, prefer a native C/C++ test file and Makefile that exercises the production code. Do not add a Python compiler/test wrapper when the native toolchain can run the test directly.
- Test the real input boundary as well as normalized fixtures: preserve original framing, account for the receiver's batching and polarity, and exercise successive callbacks before a display refresh. Passing isolated reference frames does not verify the live receive path or physical display.
- When hardware verification depends on a small display, use legible type and explicit YES/NO or NONE/FULL labels for critical results. Treat a reported ambiguous digit as uncertain evidence; fix readability instead of asking the user to repeatedly decipher it.
- When editing proprietary learned packets, establish the actual waveform offset and transport/subformat metadata independently. Exact reversal and timing tests built on the same parser do not prove that hardware accepts its format assumptions; do not treat unexplained leading fields as RF idle space.
- When the user redirects priorities, remove superseded checks and blockers from the active plan immediately. For this LilyGo change, do not repeat Wi-Fi outage or already-confirmed reception checks, or build an expected-command acknowledgement workflow. Focus on separating closely spaced/interleaved command events and identifying Broadlink sends with an on-air prefix in its existing learned codes. Do not promise recovery of physically colliding RF signals or unique transmission IDs from a static stored prefix.
- In RF timing discussions, interpret duration questions against the on-air behavior being discussed before assuming development effort. Calculate added airtime and command-start delay explicitly, separate them from OLED/network latency, and label calculation versus physical measurement.
- Quantify latency overhead before selecting a wire format. Do not duplicate room/button information already carried by the appliance frame without a demonstrated need. For LilyGo, D63 selects only the physically received footer and retires header recovery. B1 C0 waveform bytes start at offset 8; preserve transport metadata and every native frame/repeat boundary. Fit the footer inside the existing final pause with zero added command-start or total duration, and verify attribution on the OLED.

- For Home Assistant automation tests, verify native script control-flow semantics as well as template values. A failing condition inside an `if` or `choose` sub-sequence must not be assumed to abort the parent automation. Put safety/precondition guards at the intended execution boundary, snapshot mutable state before dependent calculations, and cover off-state/queued races against the production action tree. Do not substitute slower user button pacing for fixing queued latency or service errors.
- Keep direct event-to-light mappings as one automation calling the target group's native services. Do not add member-confirmation waits, workers, persistent state owners or integration changes without a demonstrated need within the user's requested scope. Distinguish delays introduced by the automation from timeouts in the existing bulb integration.

## Development Setup

After cloning, run the appropriate setup script:

```
# Windows
scripts\setup.ps1

# Linux / macOS
bash scripts/setup.sh
```

The setup script installs local dependencies, installs the OpenSpec CLI globally, restores the locked skill set, initialises OpenSpec with Claude Code by default, and bridges its commands to universal agent skills. Re-run it any time skills or OpenSpec commands seem missing. Pass `none` to skip OpenSpec initialisation, or a comma-separated list such as `cursor,opencode` to configure extra supported OpenSpec agents alongside Claude.

## Skill & Tool Management

The OpenSpec CLI is installed globally because generated commands invoke `openspec` directly. The `skills` CLI and all other tooling are local npm devDependencies.

- All agent tool packages are declared in `package.json` under `devDependencies`.
- Installed artifacts and agent configs (for example `.agent/`, `.agents/`, `.claude/`, `.codex/`, `.cursor/`, `.opencode/`, `.pi/`, `.zcode/`, and `node_modules/`) are gitignored. Never commit them; the setup script regenerates them.
- Skills are restored reproducibly from `skills-lock.json` with `npx skills experimental_install`.
- To add a skill, run `npx skills add <source> --skill <name>`, then commit the updated `skills-lock.json`. Do not add per-skill installation commands to the setup scripts.
- `openspec init` supports fewer agents than the `skills` CLI. The setup script uses Claude's generated `.claude/commands/opsx/` commands as the source for `scripts/generate-opsx-skills.mjs`, which moves them into `.agents/skills/opsx-*/SKILL.md`. This gives agents that use the universal skill directory the same workflow.
- After setup, `/opsx-propose`, `/opsx-explore`, `/opsx-apply`, `/opsx-sync`, and `/opsx-archive` are available alongside standard project skills such as `/run`, `/verify`, and `/code-review`.

**Bootstrap check:** if `/opsx-*` or other expected commands are unavailable, run the setup script for your OS and restart the agent runtime.

To add a new agent tool:

1. Add its npm package to `package.json` devDependencies.
2. Add any required initialisation to both `scripts/setup.ps1` and `scripts/setup.sh`.
3. Document it in this section.

## MCP Servers

This project uses the `homeassistant-custom` MCP to interact with the Home Assistant instance during development. It is typically configured at the user or IDE level. For Claude Code/Desktop, for example:

```bash
claude mcp add homeassistant-custom <server-command> --env HA_URL=<url> --env HA_TOKEN=<token>
```

## Flutter

**Target platforms:** Android, Windows
**Deferred platforms:** iOS, macOS (require Xcode; directories are present for future use)

Run `flutter doctor` to verify the toolchain. `flutter build windows` should succeed on this machine. iOS and macOS builds are expected to fail without Xcode.

## OpenSpec

Spec files live in `openspec/`. Use `/opsx-propose` (or the corresponding workflow in your agent) to start a feature change. The project default schema is `spec-driven-decisions`, with the artifact order:

`proposal -> decisions -> specs + design -> tasks -> apply`

The project config at `openspec/config.yaml` supplies common context and rules. See the [OpenSpec workflows guide](https://github.com/Fission-AI/OpenSpec/blob/main/docs/workflows.md) for the lifecycle.

### Customizing the schema

Schema customisation is allowed and expected when the project needs a durable workflow rule. Use the smallest appropriate level:

1. Project `openspec/config.yaml` for shared context and prompt rules.
2. A project schema under `openspec/schemas/` for artifact order, dependencies, and templates.
3. A global schema only for a rule that genuinely applies across repositories.

Useful commands are `openspec schema fork <source> <name>`, `openspec schema init <name>`, `openspec schema validate <name>`, and `openspec schema which <name>`. `spec-driven-decisions` is the working example: it forks the standard workflow to require a decision log before specs or design. See the [OpenSpec customization guide](https://github.com/Fission-AI/OpenSpec/blob/main/docs/customization.md) before changing it.
