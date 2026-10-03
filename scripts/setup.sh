#!/usr/bin/env bash
# Sets up all agent tooling for ha-flutter on Linux / macOS.
# Run once after cloning, and any time slash commands or skills appear missing.
# Usage: ./scripts/setup.sh [tools]
#   [tools] is a comma-separated list of EXTRA OpenSpec tools to configure
#   (e.g., "cursor,opencode") or "all". "claude" is always included because
#   its generated commands are the source for the universal skill bridge.
#   Pass "none" to skip OpenSpec init and the bridge entirely.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="${1-}"

echo "==> ha-flutter agent setup (Linux/macOS)"

# -- 1. Node dependencies -------------------------------------------------------
echo ""
echo "[1/9] Installing npm devDependencies..."
(cd "$ROOT" && npm install)

# -- 2. Global OpenSpec CLI -----------------------------------------------------
# Generated slash commands and skills invoke bare `openspec`, which must be on
# PATH. The local devDependency pins the version used by this script via npx.
echo ""
echo "[2/9] Installing global OpenSpec CLI..."
npm install -g @fission-ai/openspec@latest

# -- 3. Restore skills from skills-lock.json -----------------------------------
# External sources are registered once with
# `npx skills add <source> --skill <name>` and then restored here.
echo ""
echo "[3/9] Restoring skills from skills-lock.json..."
(cd "$ROOT" && npx skills experimental_install)

# -- 4. Reconcile repository-owned skills --------------------------------------
echo ""
echo "[4/9] Reconciling repository-owned skills..."
LOCAL_SKILL_OUTPUT="$(cd "$ROOT" && node scripts/project-skills.mjs local)"
LOCAL_SKILLS=()
while IFS= read -r skill_name; do
    if [ -n "$skill_name" ]; then
        LOCAL_SKILLS+=("$skill_name")
    fi
done <<< "$LOCAL_SKILL_OUTPUT"
for skill_name in "${LOCAL_SKILLS[@]}"; do
    (cd "$ROOT" && npx skills add . --skill "$skill_name" --yes)
done
(cd "$ROOT" && node scripts/project-skills.mjs normalize)

# -- 5. OpenSpec init -----------------------------------------------------------
echo ""
echo "[5/9] Initialising OpenSpec..."
if [ "$TOOLS" = "none" ]; then
    echo "  (skipped - tools=none)"
elif [ -z "$TOOLS" ] && compgen -G "$ROOT/.agents/skills/opsx-*" > /dev/null; then
    echo "  (skipped - existing universal opsx skills preserve project configuration)"
else
    case ",$TOOLS," in
        ,,|*,claude,*) EFFECTIVE_TOOLS="${TOOLS:-claude}" ;;
        ,all,)         EFFECTIVE_TOOLS="all" ;;
        *)             EFFECTIVE_TOOLS="claude,$TOOLS" ;;
    esac
    (cd "$ROOT" && npx openspec init --tools "$EFFECTIVE_TOOLS")
fi

# -- 6. Bridge OpenSpec commands to universal skills ---------------------------
# Moves .claude/commands/opsx/*.md to .agents/skills/opsx-*/SKILL.md and
# renames /opsx:xxx to /opsx-xxx for agents using the universal directory.
echo ""
echo "[6/9] Bridging OpenSpec commands to .agents/skills..."
if [ "$TOOLS" = "none" ]; then
    echo "  (skipped - tools=none)"
else
    (cd "$ROOT" && node scripts/generate-opsx-skills.mjs)
fi

# -- 7. Sanity checks -----------------------------------------------------------
echo ""
echo "[7/9] Checking OpenSpec configuration..."
if ! grep -q '^schema: spec-driven-decisions' "$ROOT/openspec/config.yaml"; then
    echo "WARNING: openspec/config.yaml no longer selects 'spec-driven-decisions'." >&2
    echo "         openspec init may have overwritten it - restore via git." >&2
    exit 1
fi
(cd "$ROOT" && npx openspec schema validate spec-driven-decisions)

# -- 8. Verify canonical skill outputs -----------------------------------------
echo ""
echo "[8/9] Verifying canonical skill outputs..."
EXPECTED_SKILL_OUTPUT="$(cd "$ROOT" && node scripts/project-skills.mjs expected)"
EXPECTED_SKILLS=()
while IFS= read -r skill_name; do
    if [ -n "$skill_name" ]; then
        EXPECTED_SKILLS+=("$skill_name")
    fi
done <<< "$EXPECTED_SKILL_OUTPUT"
MISSING_SKILLS=()
for skill_name in "${EXPECTED_SKILLS[@]}"; do
    if [ ! -f "$ROOT/.agents/skills/$skill_name/SKILL.md" ]; then
        MISSING_SKILLS+=("$skill_name")
    fi
done
if [ "${#MISSING_SKILLS[@]}" -gt 0 ]; then
    echo "Missing canonical skill output for: ${MISSING_SKILLS[*]}" >&2
    exit 1
fi

# -- 9. Flutter doctor ----------------------------------------------------------
echo ""
echo "[9/9] Checking Flutter environment..."
flutter doctor

echo ""
echo "Setup complete."
echo "Restart your agent runtime to pick up the /opsx-* skills."
